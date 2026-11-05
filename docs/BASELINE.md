# Phase 5 baseline — qa-m-a

This is the behavior contract (CLAUDE.md, "Honesty and testing discipline":
*"Existing business behavior is preserved (the Phase 5 baseline is the
contract)"*). It is the **first time ever** these specs have actually
executed — Phase 3's audit was docs-only (static reading); this repo's
GitHub Actions workflow has failed on 100/100 of its recorded runs without
a single spec ever running (confirmed live via `gh api`, Phase 3). Nothing
below was fixed; everything is reported as observed.

## What this repo is

Not an application — a personal Cypress E2E test-automation practice repo.
Every spec drives a live, third-party production site directly: `turbo.az`
(the configured `baseUrl`, an Azerbaijani car-listing marketplace) plus two
one-off smoke checks (`abb-bank.az`, `yelo.az`, both banks). No local
server, no mocking, no database, nothing of this repo's own to build or
serve — the Docker pipeline correctly stops at `base -> deps -> test-run ->
test`, with no `build`/`runtime` stage invented.

## Real result — executed 3 independent times, identical every time

| Run | Trigger | Exit code | Tests | Passing | Failing | Pending | Skipped | Duration |
|---|---|---|---|---|---|---|---|---|
| 1 | `docker build --target test-run` (initial) | 2 | 4 | 2 | 2 | 0 | 0 | 1m21s |
| 2 | `docker create`+`docker cp` re-extraction of run 1's own image (not a re-run — same image, re-read to double-check the extraction mechanism) | 2 | 4 | 2 | 2 | 0 | 0 | 1m21s |
| 3 | `docker build --target test` (cache-invalidated — the scratch evidence files `docker cp`'d out of run 1's image for inspection, e.g. `.cypress-exit-code.extracted`, briefly sat in the build context root and don't exactly match `.dockerignore`'s literal `cypress-run.log`/`.cypress-exit-code` entries → genuinely re-executed) | 2 | 4 | 2 | 2 | 0 | 0 | 96.8s |
| 4 | `docker build .` (no `--target`, the default/final gate; cache invalidated again the same way by a second round of scratch files) | 2 | 4 | 2 | 2 | 0 | 0 | 53.7s |

Runs 1, 3, and 4 are three **genuinely independent live executions** against
the real external sites (not cached layers — each re-ran `npx cypress run`
from scratch after a build-context change invalidated the Docker layer
cache); run 2 is a repeat read of run 1's own recorded evidence, included
only to show the extraction mechanism is stable. All three real executions
produced the **exact same** per-spec breakdown — this is a stable, real
result, not a flaky artifact of one run. All scratch extraction files
(`*.extracted`, `*.run2`) were deleted before anything was staged for
commit — confirmed via `git status` showing none of them, and none are
part of this phase's final diff. Subsequent `make build`/`make test`/
`make verify` runs (after cleanup, with a stable context) correctly hit
the Docker layer cache (`CACHED`) instead of re-running the suite a
fourth time — expected and desirable, not a gap in verification.

**Headline: 4 specs / 4 tests / 2 passing / 2 failing / 0 pending / 0
skipped. Exit code 2 (Cypress's own convention: number of failed tests).**

### Per-spec detail

| Spec | Result | Duration | Root cause |
|---|---|---|---|
| `abb.cy.js` | **PASS** | ~4s | `abb-bank.az` loads; the 3 `cy.url()` chained assertions (`include 'abb'`, `eq 'https://abb-bank.az/'`, `contain 'bank'`) all hold against the live site today. |
| `turbo_az.cy.js` | **PASS** | ~7s | Visits `turbo.az`, opens the make/model dropdown, types "Audi". Its one real assertion (`.should('have.text','Markanı yazın')` on the dropdown placeholder) holds against the live site today. |
| `turboaz.cy.js` | **FAIL** | ~8s | `AssertionError: Timed out retrying after 4000ms: Expected to find element: img[alt="turbo.az"], but never found it.` — **confirmed external, not a container artifact**: `curl`'d `https://turbo.az/` from the host (outside any container) → `HTTP 200`, page loads fine, but a raw-HTML grep for `<img[^>]*>` and `class="*logo*"` shows the site's logo is now rendered via `class="nav-i--home_logo"` (no `<img alt="turbo.az">` element exists anywhere in the current markup). The live site's own markup changed since this spec was written; the selector is now stale. |
| `yelloBank.cy.js` | **FAIL** | ~60s (hit Cypress's `pageLoadTimeout`) | `CypressError: Timed out after waiting 60000ms for your remote page to load.` against `https://www.yelo.az`. **Confirmed external, not a container artifact**: `curl --max-time 15 https://www.yelo.az` from the host (outside any container, outside Cypress entirely) also times out (`curl: (28) Connection timed out after 15005 milliseconds`) — the site itself is unreachable/excessively slow from this network today, independent of Docker. |

### Correction to Phase 3's static read

Phase 3's docs-only audit (`projects/info/analysis/qa-m-a.md`,
`docs/REPOSITORY_AUDIT.md`) characterized `turbo_az.cy.js` as having **"no
assertion — pure duplication, not a distinct case."** Actually executing it
shows this is not quite accurate: it has exactly one real Cypress
assertion (`.should('have.text', ...)` on the dropdown placeholder text),
which passes. It is still a near-duplicate of `turboaz.cy.js`'s setup (same
target, same dropdown interaction, far less complete — no price filter, no
submit, no results check) and still a reasonable Phase 7 deletion candidate
on duplication grounds alone — but "no assertion" was not literally true.
Flagging the correction rather than silently repeating the earlier,
unverified claim, per the actually-execute-before-trusting-a-static-read
principle this phase exists to apply (same lesson `udemy_cypress_13.6.6`'s
Phase 5 run demonstrated for its own repo's audit).

### `spec.cy.js` — already resolved, not re-litigated here

Phase 3 flagged `spec.cy.js` (Cypress's unmodified template, broken
Google-search selector) as needing a fix-vs-delete decision. Phase 4
already deleted it per Rasim's Gate-10 approval (`APPROVALS.md`, resolved
2026-11-05) — confirmed absent from `cypress/e2e/` before this phase
started (4 specs found, not 5). Nothing left for this phase to run or
report on that file.

## Coverage of critical paths — no characterization tests added

Per the Docker standard, characterization tests are added only "where
critical paths have no tests." This repo's own 4 specs **are** the tests —
there is no separate application layer underneath them needing coverage.
No characterization test was added.

## Image build

| Stage | Purpose | Size (bytes) | Size (human) |
|---|---|---|---|
| `base` | `cypress/included:16.2.1`, pinned by tag + digest, `WORKDIR /app` owned by the non-root `node` user | 4,883,038,875 | 4.88 GB |
| `deps` | `npm ci --ignore-scripts` (176 packages) + `cypress verify`, as `node` (uid 1000) | 4,921,132,770 | 4.92 GB |
| `test-run` | full source copied in, full suite executed headless, real exit code + full run log always committed | 4,930,653,377 | 4.93 GB |

Base image: `cypress/included:16.2.1@sha256:f1f257405a482bdf95358cd30202d9c3ac69f907d5e96342ae377b8111ff7a15`
— pinned to match the exact `cypress` version already locked in
`package-lock.json` (16.2.1, the Renovate bump Phase 4 merged as PR #37).
Node inside the image: `v26.13.0` (host) / Cypress's own bundled Node
`24.15.0`; Electron `41.7.0`. `cypress`'s own `engines.node` constraint
(`^22.0.0 || ^24.0.0 || >=26.0.0`, from `package-lock.json`) is satisfied.

Verified before committing to a non-root pipeline: `docker run --rm -u
1000:1000 cypress/included:16.2.1 ... npx cypress verify` → exit 0 — this
image's pre-existing `node` user needs no sandbox flags or extra setup.

## Security scan

`docker scout cves qa-m-a:test-run` → **364 vulnerabilities found in 126
packages** — 0 Critical / 97 High / 85 Medium / 182 Low. Every listed
package is a Debian 13 (trixie) OS package pulled in by the pinned
`cypress/included:16.2.1` base image (Chrome/Electron/Firefox's own
system-library dependencies — e.g. `libcaca`, `jbigkit`, `diffutils`),
not this phase's own `deps`/`test-run` layers (176 npm packages, one
direct dependency: `cypress`). Same pattern already verified on
`udemy_cypress_13.6.6`'s own Phase 5 scan (423 vulnerabilities / 140
packages on `cypress/included:16.1.1`, also overwhelmingly base-image OS
packages) — this repo's newer pinned tag (16.2.1) carries a somewhat
smaller count and, notably, **0 Critical** (the sibling's scan found 5).
A future Phase 6 bump to a newer `cypress/included` tag is the natural
lever to reduce this further; out of Phase 5's scope to chase now (would
be a version bump, not a Docker/Make change).

## Gate verification (bidirectional)

1. Real run, red: the three independent live executions above all
   recorded exit code `2` in `/app/.cypress-exit-code`; `docker build
   --target test` and the default `docker build .` (no `--target`) both
   failed with `ERROR: ... exit code: 1` on the gate's own `RUN test
   "$(cat /app/.cypress-exit-code)" = "0"` line.
2. Isolated logic check, both directions, independent of any real suite
   run: `sh -c 'test "$(cat f)" = "0"'` against a file containing `0` →
   exit 0 (passes); against a file containing `2` → exit 1 (fails). The
   gate mechanism itself is sound, not just coincidentally red.

## `.env.example`

No code anywhere in this repo reads `process.env` or `Cypress.env()`
today (confirmed by search — zero matches outside `node_modules`).
`.env.example` was still created per the Docker standard, with
`CYPRESS_PROJECT_ID`/`CYPRESS_RECORD_KEY` as empty placeholders,
anticipating the Cypress Cloud wiring the project's own `projectId`
(`cypress.config.js`, `"6b645r"`) implies but does not yet use. No real
value was ever present anywhere in this repo (Phase 3/4's full-history
secret scans both confirmed clean) — unlike `udemy_cypress_13.6.6`, which
had an already-leaked, parked Gate-1 record key. Nothing here is a Gate-1
item.

## Why `make up` means "run the suite once"

This repo has no persistent service of its own — every spec drives a
public, third-party production site. `make up` therefore depends on
`verify` (Docker standard) and then runs the suite once via
`docker compose up --abort-on-container-exit`, rather than starting a
long-lived process that doesn't exist here. Same mapping already verified
on `udemy_cypress_13.6.6`.

## Phase 6 — dependency upgrade re-verification (2026-11-05)

Phase 6 re-ran the same `make verify` gate after confirming (live registry
checks, see `projects/info/state/handoff/6/qa-m-a.md`) that every
dependency, the Docker base image, and every CI action were already at
true latest-stable — some via this phase's own commits
(`cross-spawn` 7.0.3→7.0.6 and `qs` 6.16.0→6.17.1, both transitive;
`docker/dockerfile` syntax directive `1.7`→`1.28`), the rest via bot PRs
already merged in earlier phases (`cypress`→16.2.1, `systeminformation`→
5.33.19, `cypress-io/github-action`→v7.4.9, `ubuntu-26.04`,
`actions/download-artifact`@v8.0.2 — all independently re-confirmed as
current against the registry on 2026-11-05, not assumed from prior docs).

`docker build --target test-run` → real `npx cypress run` against the
live sites, 51.9s. Extracted via `docker cp` from the built image:

| Spec | Result |
|---|---|
| `abb.cy.js` | PASS |
| `turbo_az.cy.js` | PASS |
| `turboaz.cy.js` | **FAIL** (same stale-selector cause as the Phase 5 baseline above — unchanged) |
| `yelloBank.cy.js` | PASS |

**3 passing / 1 failing, exit code 1** — one fewer failure than the Phase
5 baseline (2 passing / 2 failing, exit code 2). `yelloBank.cy.js` now
passes because `www.yelo.az` is reachable again today; the Phase 5 run
hit a timeout against that same external site. This is **not** a product
of any dependency bump in this phase — nothing in the cypress/Node/action
bump touches that spec or its target. Documented honestly rather than
claimed as a fix: the one remaining failure (`turboaz.cy.js`'s stale
`img[alt="turbo.az"]` selector) is the exact same pre-existing defect
already recorded above and in `docs/TECHNICAL_DEBT.md` item 2 — Phase 6
did not touch it, and it remains Phase 7/11 scope.

**No regression against the Phase 5 baseline.** `docker build --target
test` / `docker build .` still fail on the gate's own
`RUN test "$(cat /app/.cypress-exit-code)" = "0"` line, exactly as
expected for a repo whose documented baseline is red for a reason outside
this phase's scope (the stale selector, not a dependency issue).

## Out-of-scope findings (for other phases, not fixed here)

1. **`turboaz.cy.js`'s selector is stale against the live site's current
   markup** (`img[alt="turbo.az"]` no longer exists; the logo is now a
   `class="nav-i--home_logo"` element) — a real defect, independently
   confirmed via `curl` from the host. Fixing the selector is Phase 11
   (`tester`)/Phase 6 territory, not Docker/Make — not touched here.
2. **`yelloBank.cy.js`'s target (`www.yelo.az`) is unreachable from this
   network today** (confirmed independently via `curl`, times out
   identically outside any container or Cypress). Whether this is a
   transient outage, a bot-detection/geo-block, or a permanently dead
   target is not determined by this phase — flagged for whoever next
   triages this spec (Phase 6/11) to re-check with a fresh `curl` before
   assuming either way.
3. **`turbo_az.cy.js` is still a near-duplicate of `turboaz.cy.js`**
   (Phase 3's finding, re-confirmed above with the one correction noted) —
   Phase 7 (`cleaner`) scope, not touched here.
4. **The dead `component` testing block in `cypress.config.js`** (Phase
   3/4 already confirmed dead, re-confirmed still present) — Phase 7
   scope, not touched here.
5. **The repo's own CI workflow still cannot succeed** — unrelated to
   anything in this phase's diff (`package.json` has neither a `build` nor
   `start` script, which the workflow's two jobs both call). This phase's
   own PR is expected to show the same pre-existing red check; documented,
   not treated as a merge blocker, per CLAUDE.md's working-procedure
   clause. Phase 10 (`ci-engineer`) scope.
