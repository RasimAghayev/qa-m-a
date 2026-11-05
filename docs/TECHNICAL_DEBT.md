# Technical debt

Each item below states what it is, why it's debt (or isn't), and which
future phase owns fixing it. Nothing here is fixed in this phase (docs-only).

> **Phase 6 update (2026-11-05):** item 10 below is resolved — see its own
> note. Every other item is unchanged and still owned by the phase listed.

## Real debt (needs fixing)

1. **CI workflow cannot succeed — ever, as committed.** `.github/workflows/cypress.yml`'s
   `install` job runs `npm run build`, `cypress-run` runs `npm start`;
   `package.json` has neither script. Confirmed live: 100/100 most recent
   runs failed (`gh api .../actions/workflows/cypress.yml/runs`). No spec has
   ever executed in CI. Owner: Phase 10. Severity: P0/P1 (the whole point of
   a CI workflow — a trustworthy pass/fail signal — does not exist today).
2. **`spec.cy.js` is Cypress's unmodified template**, targeting a
   Google-search selector that doesn't exist on turbo.az. Will fail the
   instant CI (or anyone locally) actually runs the suite. Owner: Phase 7
   (dead/broken leftover) or Phase 11, after Phase 5's baseline run confirms
   it live. Severity: P1 once CI is fixed.
3. **`turbo_az.cy.js` duplicates `turboaz.cy.js`'s setup** and adds no
   assertion of its own — an abandoned earlier draft, not a second
   intentional test case. Owner: Phase 7. Severity: P2.
4. **Dead `component` testing block** in `cypress.config.js` (Angular +
   webpack, `**/*.cy.ts`) — no matching spec file, no matching dependency
   installed. Inert, not broken-in-use. Owner: Phase 7. Severity: P3.
5. **No `engines`/`.nvmrc` pinning the Node version Cypress 16.x requires.**
   Owner: Phase 5 (Dockerfile's base image pin) / Phase 9 (repo-level pin).
   Severity: P2.
6. **No `LICENSE` file, no `license` field in `package.json`.** Owner: Phase
   15. Severity: P3.
7. **CI actions tag-pinned, not SHA-pinned** (`actions/checkout@v7`,
   `cypress-io/github-action@v7.4.6`, `actions/upload-artifact@v7`,
   `actions/download-artifact@v8.0.2`). Owner: Phase 10. Severity: P2.
8. **No linter/formatter for the JS spec files.** Owner: Phase 9. Severity:
   P3.
9. **`README.md`'s dependency/branch narrative is stale** relative to
   `master`'s actual current content (describes `cypress@13.4.0` and 8 now-
   nonexistent branch names; actual state is `cypress@16.1.1` and a
   different, smaller branch set). Owner: Phase 15. Severity: P2
   (misleading, not just outdated — a future reader or audit pass could
   trust the wrong numbers).
10. **`cross-spawn` (HIGH, ReDoS) and `qs` (MODERATE, DoS) transitive
    advisories do not resolve automatically via the open bot branches —
    verified this phase, correcting Phase 2's hedge.** Read the open
    `renovate/cypress-16.x-lockfile` branch's actual committed
    `package-lock.json` directly (`git show
    origin/renovate/cypress-16.x-lockfile:package-lock.json`), not a
    hypothetical fresh install: `node_modules/cross-spawn` is still resolved
    to `7.0.3` (vulnerable range `7.0.0–7.0.4`) and `node_modules/qs` is
    still resolved to `6.16.0` (vulnerable range `6.7.0–6.16.0`) on that
    branch too — byte-for-byte identical to `master`. The Renovate bot's
    bump only touched `cypress`'s own version string in the lockfile
    metadata (6-line diff total, confirmed via `git diff master
    origin/renovate/cypress-16.x-lockfile --stat`); it did not re-resolve
    the rest of the dependency tree. **Phase 2's "likely resolved
    automatically" hedge on this point does not hold** — merging all 3 open
    bot branches as-is leaves `cross-spawn` and `qs` exactly as vulnerable
    as today. Owner: Phase 6, needs an explicit lockfile-only bump of these
    two transitives as its own verified step (e.g. `npm install
    cross-spawn@latest qs@latest --package-lock-only --save-dev` or
    equivalent), not an assumed side-effect of the cypress bump. Severity:
    P1/P2 (HIGH + MODERATE, both have a trivial non-breaking fix available).

    **RESOLVED — Phase 6, commit `d05a1f8`.** `npm audit fix` against the
    real lockfile bumped `cross-spawn` 7.0.3→7.0.6 and `qs` 6.16.0→6.17.1,
    both confirmed live against the npm registry as current latest-stable
    on 2026-11-05 (re-checked again at Phase 6 close-out, still current).
    `npm audit` on the resulting lockfile: 0 vulnerabilities. The
    now-superseded bot PR proposing the same individual `qs` bump (`#41`,
    Dependabot) was closed as superseded rather than merged, to avoid a
    redundant no-op merge — see `projects/info/state/handoff/6/qa-m-a.md`.

## Debt that resolves itself once Phase 6 runs

- `cypress` 16.1.1 → 16.2.1: the open `renovate/cypress-16.x-lockfile`
  branch already contains this exact, verified bump (lockfile-only, in-range
  — `package.json`'s `^16.0.0` constraint already covers it).
- `cypress-io/github-action` v7.4.6 → v7.4.9 in the workflow: the open
  `renovate/cypress-io-github-action-7.x` branch already contains this exact
  bump.
- `systeminformation` 5.33.11 → 5.33.19 (transitive, HIGH advisory trio): the
  open `dependabot/npm_and_yarn/npm_and_yarn-0bf0c00b27` branch already
  contains this exact, lockfile-only bump — found this phase, not present in
  Phase 2's branch inventory (created afterward).

`cross-spawn`/`qs` (item 10 above) deliberately do **not** appear in this
list — they are the one gap neither open bot branch actually closes.

**Phase 6 confirmation (2026-11-05):** all three items above landed
before Phase 6 started work (merged via earlier phases' bot-PR handling,
re-verified live against the registry/releases at Phase 6 close-out —
`cypress` 16.2.1, `cypress-io/github-action` v7.4.9, `systeminformation`
5.33.19 are each still current latest-stable today). Phase 6's own
remaining work was therefore: the `cross-spawn`/`qs` bump (item 10,
resolved above), the `docker/dockerfile` syntax directive `1.7`→`1.28`
(latest, commit `51d4351`), and adding `renovate.json` so grouping/
scheduling/PR-limits are explicit instead of implicit app defaults. No
other dependency, runtime, base image, or CI action in this repo had a
gap against latest-stable as of this date — see
`projects/info/state/handoff/6/qa-m-a.md` for the full live-registry
evidence per item.

Phase 4 should close out (merge/supersede) all three bot branches once
re-verified; Phase 6 is the backstop for the cypress/action/systeminformation
bumps, and is the **only** fix for cross-spawn/qs since no open branch
touches them.

## Not treated as debt

- **The unrelated `index.html`/`style.css`/`img/login_right_image.png`
  mockup page.** It is dead weight relative to the Cypress suite (not
  exercised by any spec, ~1.1 MB of the repo's 1.2 MB total size), but it is
  not *broken* — it is a complete, functioning static page that simply
  doesn't belong to this project's stated purpose. Classified as a dead-code
  / scope question for Phase 7, not a defect.
- **Every spec driving a live, uncontrolled third-party production site with
  no mocking.** This is the deliberate nature of a personal E2E practice
  repo, not a design mistake to "fix" into something else — flagged in
  `docs/ARCHITECTURE.md` as a real limitation (specs will break whenever the
  target sites change markup) but not reclassified as technical debt to
  remove.
- **The overall lack of a layered architecture, DI, or design patterns.**
  There is no application code here to apply SOLID/DDD/Clean Architecture
  to — see the per-repo Phase 8 plan in `projects/info/analysis/qa-m-a.md`.
