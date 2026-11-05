# Architecture

## What this is

`qa-m-a` is a personal **Cypress E2E test-automation practice repo**. It has no
application of its own — there is no server, no API, no database, no build
step that produces a deployable artifact. Every spec drives a live,
third-party website over the public internet. "Architecture" in the usual
service/application sense does not apply; what follows documents the repo's
actual shape instead of forcing it into a label that wouldn't fit.

## Targets under test (plural, unrelated sites)

| Target | Spec(s) | Depth |
|---|---|---|
| `https://turbo.az` (Azerbaijani car-listing marketplace) | `turboaz.cy.js`, `turbo_az.cy.js`, `spec.cy.js` (via `baseUrl`) | `turboaz.cy.js` is the one developed test: opens make/model dropdowns, sets a price range, submits, asserts result count and listing title. `turbo_az.cy.js` is an earlier, unfinished, overlapping pass at the same dropdown. `spec.cy.js` is Cypress's own generated template, never adapted — its selector (`textarea[name="q"]`) targets a Google-style search box, not turbo.az. |
| `https://abb-bank.az` | `abb.cy.js` | One-off smoke check (page loads, URL matches); several earlier assertion attempts left in as commented-out code above the active one. |
| `https://www.yelo.az` | `yelloBank.cy.js` | One line: visits the page, asserts nothing. |

No target is a repo this program owns or controls; none is mocked, stubbed, or
run locally. Every spec is a live network call to production infrastructure
outside `RasimAghayev`'s control, so flakiness from the target site's own
markup/content changes is expected and already partially visible (`abb.cy.js`'s
commented-out earlier attempts).

## Structure

Standard Cypress scaffold layout, unmodified beyond adding the specs above:

```
cypress/
  e2e/            5 spec files (see table above)
  fixtures/       example.json — Cypress's own default fixture, unused by any spec
  support/
    commands.js   Cypress's own default scaffold, no custom commands added
    e2e.js        Cypress's own default scaffold, imports commands.js
cypress.config.js  e2e.baseUrl + an inert component-testing block (see below)
```

Alongside the Cypress project, three unrelated files sit at repo root:
`index.html`, `style.css`, `img/login_right_image.png` — a standalone static
login-page mockup (name/email/password inputs, a decorative image). No
Cypress spec visits or references `index.html`; nothing serves it. It reads as
an unrelated front-end practice exercise that was committed into the same
repository rather than a second artifact this project produces or tests.

## Test-authoring patterns used (inconsistent, as expected for a practice repo)

- `turboaz.cy.js` — most developed: `beforeEach` hook, multi-step interaction,
  multiple assertions, Azerbaijani-language `describe`/`it` text.
- `turbo_az.cy.js` — same target, same dropdown, stops after typing a filter
  value with no assertion — reads as an earlier draft, not a distinct case.
- `abb.cy.js` / `yelloBank.cy.js` — trivial one-assertion / zero-assertion
  smoke checks.
- `spec.cy.js` — Cypress's own generated template, not adapted to this
  project at all.

No custom commands, no Page Object Model, no fixtures actually consumed by
any spec, no `beforeEach`/`afterEach` shared setup beyond `turboaz.cy.js`'s
own. There is nothing to refactor into a shared pattern yet because there is
no real duplication of *working, assertion-bearing* logic — `turbo_az.cy.js`
duplicates `turboaz.cy.js`'s setup but adds no additional coverage.

## `cypress.config.js`'s dead `component` block

```js
component: {
  devServer: { framework: "angular", bundler: "webpack" },
  specPattern: "**/*.cy.ts",
},
```

No `.cy.ts` file exists anywhere in the tree (`find . -name "*.cy.ts"` → zero
results) and no `@angular-devkit/*` or webpack package is installed. This is
Cypress's own scaffold boilerplate, left over from `cypress init`, and would
fail immediately if component testing were ever invoked (missing
Angular/webpack dependencies). It does not run today and does not need to —
it is inert, not broken-in-use.

## Database layer — not applicable

Stated explicitly rather than skipped: there is no schema, no ORM, no
migration, no connection of any kind anywhere in this repo. Nothing to audit
here.

## CI/CD

One GitHub Actions workflow, `.github/workflows/cypress.yml`
("Cypress Tests with Dependency and Artifact Caching"), triggered on every
`push`. Two jobs, `install` → `cypress-run`, handing off a `build` artifact
between them. **Confirmed broken in live execution, not just by static
reading of the file:** `gh api repos/RasimAghayev/qa-m-a/actions/workflows/cypress.yml/runs`
reports **102 total runs; the 100 most recent all have `conclusion: failure`**
— every push-triggered run of this workflow has failed, for as long as GitHub's
run history for this workflow goes back. The root cause is structural:
`package.json` defines neither the `build` script the `install` job calls
(`npm run build`) nor the `start` script the `cypress-run` job calls
(`npm start`) — only `"c:o": "cypress open"` exists. The workflow fails at the
very first step on every single run; no spec in `cypress/e2e/` has ever
actually executed inside CI. See `docs/REPOSITORY_AUDIT.md` for the full
verification trail. For Phase 10 to fix — not fixed here (docs-only phase).

## Not present

No Dockerfile, no `docker-compose.yml`, no Makefile anywhere in this repo —
confirmed by `find` over the full tree. Phase 5 (container baseline) starts
from zero here, not from an existing-but-flawed baseline. No `LICENSE` file,
no `license` field in `package.json`, no `.nvmrc`/`engines` field pinning the
Node version Cypress 16.x requires, no linter/formatter config for the JS
spec files (the only linter config present, `.hintrc`, governs the unrelated
`index.html`/`style.css` pair, not Cypress).
