# syntax=docker/dockerfile:1.7
#
# Phase 5 container baseline for a Cypress E2E *test* repo — there is no app
# to build or serve here. Every spec drives a live, third-party production
# site directly (turbo.az — the configured baseUrl — plus one-off smoke
# checks against abb-bank.az and yelo.az). The pipeline therefore stops at
# base -> deps -> test-run -> test; no build/runtime stage is invented, per
# the Docker standard's own allowance for repos with nothing to build/serve
# (same shape verified green on this program's other Cypress repo,
# udemy_cypress_13.6.6).
#
# Base image pinned by exact tag AND digest, matching the cypress version
# already locked in package-lock.json (cypress@16.2.1, the Renovate bump
# Phase 4 merged) — this phase containerizes the current, already-installed
# version; it does not perform an upgrade (that is Phase 6's job).
FROM cypress/included:16.2.1@sha256:f1f257405a482bdf95358cd30202d9c3ac69f907d5e96342ae377b8111ff7a15 AS base

# The image ships Chrome/Electron plus an already-created non-root `node`
# user (uid/gid 1000). Verified at pin time (`cypress verify` as uid 1000,
# no sandbox flags) that the whole pipeline can run as this non-root user
# instead of root.
WORKDIR /app
ENV CI=true \
    NO_COLOR=1 \
    npm_config_cache=/home/node/.npm
RUN chown node:node /app
USER node

# ---------------------------------------------------------------------------
FROM base AS deps
# Only one declared dependency (cypress, dev-only) — no runtime
# `dependencies` in this repo's package.json (Phase 2/3 finding).
COPY --chown=node:node package.json package-lock.json ./
# Reproducible install from the committed lockfile. --ignore-scripts: this
# repo has no lifecycle scripts, kept for parity with the verified Node/npm
# Phase-5 pitfall (a `prepare`/husky-style script failing in a git-less
# build context) even though none exists here today.
RUN --mount=type=cache,target=/home/node/.npm,uid=1000,gid=1000 \
    npm ci --no-audit --no-fund --ignore-scripts && \
    npx cypress verify

# ---------------------------------------------------------------------------
# test-run: actually executes the full suite headless against the live
# baseUrl (turbo.az) and the two one-off smoke-check targets, and ALWAYS
# commits its layer (the real exit code + full run log), whether the suite
# passed or failed. This is deliberate: Phase 5's job is to capture the
# real, honest baseline, not to let a failing spec abort the build before
# the evidence is written to disk.
FROM deps AS test-run
COPY --chown=node:node . .
# No reporter package (mochawesome et al.) is declared in this repo's own
# package.json (Phase 2/3 confirmed: cypress is the only devDependency) —
# adding one here would be a new dependency with no Phase 2 decision entry
# (standing decision 3), so the full stdout/stderr transcript (Cypress's
# own built-in "spec" reporter, which already prints a per-spec pass/fail
# table and a final summary) is captured verbatim as the evidence instead.
RUN npx cypress run > /app/cypress-run.log 2>&1 ; echo $? > /app/.cypress-exit-code

# ---------------------------------------------------------------------------
# test: the gate. Only succeeds if the run captured above was actually
# green. `docker build .` (no --target, i.e. this default final stage,
# since this repo has no build/runtime stage to chain further) therefore
# fails whenever the suite is red — per the Docker standard, "build fails
# if tests fail". A pre-existing red baseline (expected here — these specs
# have never executed in this repo's CI even once, per Phase 3's audit) is
# documented in docs/BASELINE.md, not hidden as a pass.
FROM test-run AS test
RUN test "$(cat /app/.cypress-exit-code)" = "0"

# `test` is deliberately the LAST stage in this file, so the default build
# target (`docker build .`, no --target) is the gate itself. Ad-hoc/live
# re-runs (`make run`, `docker compose run e2e`) target `test-run` instead
# (same image contents, but its own layer always commits regardless of the
# suite's result).
