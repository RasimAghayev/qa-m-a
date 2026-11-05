# Improvement roadmap

## Classification

A tiny (1.2 MB, 17 tracked files), single-dependency Cypress E2E practice
repo with no Docker/Make baseline today. The roadmap below is intentionally
short — most of the heavyweight phases in this program (`PROMPT.md` Phases
8/9/13/16) either don't apply or apply only narrowly to a repo this shape.
Full detail and reasoning: `projects/info/analysis/qa-m-a.md`'s per-repo
Phase 4–11 plan (this file summarizes the same conclusions as an ordered
to-do list).

## Recommended order (highest priority first)

1. **Phase 4 — Git hygiene.** Close out 3 bot branches (2 Renovate + 1
   Dependabot, all exact ready-to-merge fixes per `docs/TECHNICAL_DEBT.md`);
   triage `qa-2` (unmerged, predates the Cypress work, no dependency
   content); secret-scan history (already done this phase — clean); harden
   `.gitignore`; add a secret-scan pre-commit hook.
2. **Phase 5 — Container baseline.** Build from zero (no Dockerfile/compose/
   Makefile exist). Run the suite for real, in Docker, for the first time
   ever in this audit process — this is the control point that turns every
   "confirmed broken" claim in `docs/REPOSITORY_AUDIT.md` from a static read
   into a live result, and the only way to find out whether `spec.cy.js`,
   `abb.cy.js`, `yelloBank.cy.js`, and `turboaz.cy.js` actually pass today
   against the live target sites.
3. **Phase 6 — Upgrade to latest.** Fast-forward the 3 open bot branches;
   re-verify `cypress` is genuinely latest at run time; re-pin the Docker
   base image Phase 5 introduces.
4. **Phase 7 — Dead code & restructure.** Delete the dead `component`
   config block, the duplicate/incomplete `turbo_az.cy.js`, and (pending an
   Orchestrator scope decision, same ambiguity `udemy_cypress_13.6.6` raised:
   does `cleaner` fix a known-broken spec, or does that wait for a defect
   loop after Phase 11?) resolve `spec.cy.js`'s broken selector.
5. **Phase 9 — Hardening.** Narrow scope: add a JS linter (none exists
   today), pin Node version, make the final call on whether this repo's
   specs should keep hitting live third-party sites or gain any
   stub/record-and-replay safety net (recommended: document and accept —
   this is an intentional practice-repo design, not a production service).
6. **Phase 10 — CI/CD.** The highest-value fix in this entire roadmap: give
   the workflow real `build`/`start` steps (or, more honestly, replace the
   two-job artifact-handoff shape with a single job that just runs
   `cypress run` — there is no app to "build" or "start"), so that a CI run
   can pass for the first time in this repo's history. Add `pull_request`
   trigger, SHA-pin actions, add job timeouts.
7. **Phase 11 — Tests.** Not "write new tests" in the usual sense — this
   repo's specs *are* the tested artifact. What applies: regression-check
   each spec's behavior against the Phase 5 baseline after Phases 6/7/9/10
   land, and write `docs/TESTING_STRATEGY.md`/`docs/TEST_REPORT.md` honestly
   reporting which of the 5 specs pass, which don't, and why.

## Not planned (explicitly `n/a`, with reason)

- **Phase 8 — Architecture.** No layered application exists to apply
  DRY/SOLID/DDD/Clean-Hexagonal/EDA/Modular-monolith to. The one legitimate
  DRY candidate (the `turboaz.cy.js`/`turbo_az.cy.js` overlap) is handled as
  a Phase 7 deletion, not an architecture refactor — there's no pattern to
  extract, just an abandoned draft to remove.
- **Phase 13 — Shared library.** The only dependency this repo shares with
  any other `RasimAghayev` repo is `cypress` itself (also used by
  `udemy_cypress_13.6.6`, same version, unrelated Cypress Cloud projects) —
  far below the "≥3 places or same domain concept" extraction bar
  (`DEPENDENCY_MAP.md` already records this and reaches the same
  conclusion).
- **Phase 16 — Platform repo.** Nothing here runs as a service; there is
  nothing to deploy to a cluster.
- **Dual-mode independence / health endpoints / OpenAPI (part of Phase 9).**
  This repo is a CLI test runner that runs to completion and exits — it does
  not serve traffic, so `/health/live`/`/health/ready` and an OpenAPI spec
  do not apply.
