# qa-m-a

A personal Cypress end-to-end (E2E) test-automation practice repo. It has
no application of its own — every test exercises live, third-party
websites (mainly [turbo.az](https://turbo.az), an Azerbaijani car-listing
marketplace, plus two bank sites used for one-off smoke checks).

This README documents `master` as it actually is; no source files were
changed to produce it.

## Architecture style

Not applicable in the usual sense — this repo has no application layer,
domain model, or runtime service to label with a design pattern. It is a
**Cypress E2E test-automation suite**, organized per Cypress's own
standard convention (`cypress/e2e`, `cypress/support`, `cypress/fixtures`),
not a custom architecture. (Per the portfolio's `[R112]` rule: this is the
honest label for what this repo is, rather than reaching for an
application-architecture term that wouldn't apply.)

## What's actually here

| Path | Purpose |
|---|---|
| `cypress.config.js` | Cypress config. `e2e.baseUrl` = `https://turbo.az`; a `component` block is also present (Angular + webpack, `**/*.cy.ts` spec pattern) but **no component test file exists anywhere in the repo** — leftover from Cypress's own scaffold, never used. `projectId: "6b645r"` ties this repo to a Cypress Cloud project (for `cypress run --record`); no recording key is committed. |
| `cypress/e2e/turboaz.cy.js` | The most developed spec: drives turbo.az's search form end-to-end — opens the make/model dropdowns, types a filter, sets a price range, submits, and asserts on the result count and listing title. Uses site-specific selectors (`.tz-dropdown`, `[data-id="q_make"]`, etc.), so it will break whenever turbo.az changes its markup. |
| `cypress/e2e/turbo_az.cy.js` | A second, smaller, unfinished pass at testing the same turbo.az search dropdown (opens the make dropdown, types "Audi", stops there — no assertion on the result). Overlaps with `turboaz.cy.js` rather than complementing it; the naming difference (`turboaz` vs `turbo_az`) is the only thing distinguishing the two files. |
| `cypress/e2e/abb.cy.js` | Smoke-checks that `https://abb-bank.az/` loads and its URL matches. Several earlier variants of the same assertion are left in as commented-out code above the active one. |
| `cypress/e2e/yelloBank.cy.js` | A single-line smoke check: visits `https://www.yelo.az` and asserts nothing beyond a successful load. |
| `cypress/e2e/spec.cy.js` | Cypress's own generated example spec, not adapted to this project — it visits `/` (i.e. `https://turbo.az/`, via `baseUrl`) and then looks for `textarea[name="q"]`, a Google-search selector left over from the template. **This test does not match anything on turbo.az and will fail if run.** |
| `cypress/support/commands.js`, `cypress/support/e2e.js` | Cypress's default scaffold files, unmodified — no custom commands have been added. |
| `cypress/fixtures/example.json` | Cypress's default example fixture, unused by any spec. |
| `index.html`, `style.css`, `img/login_right_image.png` | A standalone static login-page mockup (name/email/password inputs + a decorative image). **Not part of the test suite** — no Cypress spec visits this file or references it; it is not served by anything. It appears to be an unrelated practice/markup exercise that ended up committed alongside the Cypress project. `img/login_right_image.png` alone is ~1.1 MB, the bulk of this repo's size. |
| `.github/workflows/cypress.yml` | A GitHub Actions workflow ("Cypress Tests with Dependency and Artifact Caching") that runs on every push. **It does not work as committed**: its `install` job runs `npm run build` and its `cypress-run` job runs `npm start`, but `package.json` defines neither script (only `"c:o": "cypress open"`) — so any push-triggered run of this workflow fails at the `npm run build` step. Documented here, not fixed, since this task is a documentation pass, not a CI fix. |
| `.hintrc` | [webhint](https://webhint.io/) linter config for `index.html`/`style.css`, disabling two accessibility (axe) checks (`axe/forms`, and the image-alt part of `axe/text-alternatives`). |
| `package.json` | One dependency: `cypress ^13.4.0` (dev-only). One script: `c:o` (`cypress open`). No `test`, `build`, or `start` script exists, despite the CI workflow expecting two of those. |

## Setup

```bash
npm install
```

## Running the tests

Interactive (opens the Cypress Test Runner UI):

```bash
npm run c:o
```

Headless, all specs:

```bash
npx cypress run
```

Both use `https://turbo.az` as the base URL and will reach out to the
live sites above over the network — there is no local server, mock, or
fixture-backed target for any spec.

## Known limitations (disclosed, not fixed by this pass)

- **CI workflow is broken as committed** — see `.github/workflows/cypress.yml`
  above; it references `npm run build`/`npm start`, neither of which
  exists.
- **`spec.cy.js` is Cypress's unmodified template test** and will fail if
  run — its selector targets a Google search box, not turbo.az.
- **All specs hit live, third-party production sites directly.** They
  have no test-data isolation, no mocking/stubbing, and will break
  whenever those sites change their markup (already partially visible in
  `abb.cy.js`'s several commented-out prior assertion attempts).
- **`turboaz.cy.js` and `turbo_az.cy.js` overlap** — both drive the same
  turbo.az search dropdown; `turbo_az.cy.js` reads as an earlier,
  incomplete draft of `turboaz.cy.js` rather than a distinct test case.
- **`index.html`/`style.css`/`img/`** are a static page unrelated to and
  unexercised by the Cypress suite; `img/login_right_image.png` (~1.1 MB)
  accounts for most of the repository's size.
- **The `component` testing block in `cypress.config.js`** (Angular +
  webpack) is Cypress scaffold boilerplate — no component test file
  exists anywhere in the repo.
- **No `LICENSE` file.**
- **`npm audit` reports 11 known vulnerabilities (2 critical, 7 high, 2
  moderate)** in `cypress@13.4.0`'s transitive dependencies (`lodash`,
  `minimatch`, `tmp`, `qs`, `uuid`) — verified locally via `npm install`
  + `npm audit`, matching what GitHub's Dependabot alerts report for this
  repo. All are pulled in by Cypress itself, not by any code in this
  repo; the open `renovate/cypress-16.x` branch above (unmerged) would
  address this by upgrading Cypress, not something fixed by this
  documentation pass.
- **`master`'s actual content is older than GitHub's "last pushed" date
  suggests.** The latest commit reachable from `master` is from
  2023-11-12. GitHub reports this repo as last pushed 2026-09-16, but
  that timestamp belongs to `renovate/cypress-16.x`
  (`5d07a72`, pushed 2026-09-16T00:43:22Z) — an open, unmerged Renovate
  branch proposing a Cypress v13→v16 bump. Verified via
  `git merge-base --is-ancestor` for every remote branch: none of the
  open Renovate/Dependabot branches (`renovate/cypress-16.x`,
  `renovate/cypress-13.x-lockfile`, `renovate/cypress-io-github-action-7.x`,
  `renovate/actions-checkout-7.x`, `renovate/actions-download-artifact-8.x`,
  `renovate/actions-upload-artifact-7.x`, `renovate/ubuntu-24.x`,
  `dependabot/.../download-artifact-4.1.7`) are ancestors of `master` —
  all are routine dependency/action-version bumps still sitting open, not
  new features. (`qa-3` is the one other branch checked and it **is**
  already merged into `master`; `qa-2` is an older, smaller, unmerged
  branch predating the Cypress work — three files only, no additional
  test coverage.)
