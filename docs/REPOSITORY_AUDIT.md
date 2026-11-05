# Repository audit

Audited 2026-11-05 by `auditor` (Phase 3). Docs-only phase — no code in this
repository was changed to produce this audit. Builds on, and does not
re-derive, `projects/info/deps/qa-m-a.md` (Phase 2's dependency inventory).

## How each finding below was verified

- Full working-tree read: every tracked file (`git ls-files`, 17 files)
  opened and read in full, not sampled.
- `git status`, `git log --oneline -15`, `git branch -a` → clean tree, on
  `master`, up to date with `origin/master`, HEAD `6fe9366`.
- Live CI history via `gh api repos/RasimAghayev/qa-m-a/actions/workflows/cypress.yml/runs`
  and `gh run list` — not inferred from the workflow file alone.
- `find . -name "*.cy.ts"` → zero results (confirms the dead `component`
  config block).
- Full-history secret scan: `git log --all -p` across all 64 commits on all
  branches, grepped for API-key/secret/password/token/AWS-key/PEM patterns.
- Branch inventory cross-checked against Phase 2's record — found one branch
  Phase 2 did not have (see "Third finding" below).
- `qa-2` branch diffed against `master` (`git diff --stat`, `git ls-tree`).

## Secret scan (redacted — locations only, no values reproduced)

**Clean.** No live credential, API key, token, or private key found anywhere
in the working tree or in the full commit history of any branch. The only
password-shaped string anywhere is `cypress/fixtures/example.json:4`
(`"password":"123456"`) — Cypress's own unmodified default example fixture,
not consumed by any spec, not a real credential. `cypress/support/commands.js:13`
contains a commented-out *template* line showing the shape of a future
`login` command (`Cypress.Commands.add('login', (email, password) => { ... })`)
with no value at all. `index.html`'s mockup login form has a
`placeholder="Password"` attribute — placeholder text, not a value. This
repo carries no Cypress Cloud recording key despite declaring a Cypress
Cloud `projectId` (`6b645r`) in `cypress.config.js` — confirmed clean on this
specific point (contrast with `udemy_cypress_13.6.6`, which had a hardcoded
record key committed across 4 history commits).

## Key finding — the CI workflow has never once succeeded

Phase 2 flagged this as a static read of the workflow file against
`package.json`'s scripts ("this workflow cannot succeed as committed").
This phase confirmed it live:

```
gh api repos/RasimAghayev/qa-m-a/actions/workflows/cypress.yml/runs --jq '.total_count'
→ 102
gh api "repos/RasimAghayev/qa-m-a/actions/workflows/cypress.yml/runs?per_page=100" --jq '.workflow_runs[].conclusion'
→ 100 × "failure" (0 success, 0 other)
```

Every run of this workflow — across `master`, both open Renovate branches,
and the Dependabot branch found below — has failed. The root cause is
exactly what Phase 2 identified: `package.json` has only one script
(`"c:o": "cypress open"`); the workflow's `install` job calls `npm run build`
(doesn't exist) and its `cypress-run` job calls `npm start` (doesn't exist).
The `install` job fails at the `npm run build` step on every run, so no spec
under `cypress/e2e/` has ever actually executed inside CI — not once, for
this workflow's entire recorded run history. This is a real, user-visible
defect (a green checkmark is never possible today) — **P0/P1**, for Phase 10
to fix (add real `build`/`start` scripts, or — more honestly, since this repo
has no app to build/serve — replace the workflow's job shape with a direct
`cypress run` step that doesn't depend on either script).

## Second finding — a third open bot branch, not seen by Phase 2

Phase 2's `git branch -a` recorded exactly two open dependency-bot branches
(`renovate/cypress-16.x-lockfile`, `renovate/cypress-io-github-action-7.x`).
This phase found a third, created after Phase 2 ran:

```
remotes/origin/dependabot/npm_and_yarn/npm_and_yarn-0bf0c00b27
```

One commit (`4e571bc`, "Bump systeminformation"), based directly on current
`master` HEAD (`git merge-base master origin/dependabot/... ` →
`6fe9366`, i.e. master's own tip — not stale, not conflicting). It bumps the
*lockfile-only* transitive `systeminformation` entry from `5.33.11` → `5.33.19`
— exactly the fix Phase 2's `npm audit` recommended for that package's HIGH
advisory trio (Windows command-injection, prototype pollution, path
traversal). `gh run list` confirms this branch's own CI run also fails, for
the same pre-existing `npm run build`/`npm start` reason — the branch's
*dependency* content is a clean, ready-to-merge fix; its CI failure is
inherited from the unrelated workflow defect above, not caused by this bump.
For Phase 4 (bot-PR triage) / Phase 6 (dependency merge) to action.

## Third finding — the dead `component` testing block, confirmed dead

`cypress.config.js` declares an Angular+webpack `component` testing block
with `specPattern: "**/*.cy.ts"`. `find . -name "*.cy.ts"` → zero results;
no `@angular-devkit/*`, no webpack package is installed (confirmed against
`package.json`/`package-lock.json`, only dependency is `cypress`). This block
is Cypress's own `cypress init` scaffold output, never used, and would error
immediately if component testing were ever invoked. Low severity (it's
inert, not live-broken) — for Phase 7 to delete.

## Fourth finding — `README.md` narrates a stale, pre-upgrade snapshot of this same repo

`README.md` is current on `master`'s tip (last touched by the HEAD commit,
"docs: add GitHub view counter badge") and is otherwise detailed and mostly
accurate about *file-level* content — but its dependency/branch narrative
describes an earlier point in this repo's own history, not what `master`
actually contains today:

- README states: `cypress@13.4.0`, "11 known vulnerabilities (2 critical, 7
  high, 2 moderate)".
- Actual `master` (per Phase 2, re-confirmed this phase via `package-lock.json`):
  `cypress@16.1.1` (constraint `^16.0.0`), `npm audit` → 3 vulnerabilities (0
  critical, 2 high, 1 moderate) — a materially different, already-improved
  picture.
- README lists 8 named open Renovate/Dependabot branches
  (`renovate/cypress-16.x`, `renovate/cypress-13.x-lockfile`,
  `renovate/actions-checkout-7.x`, `renovate/actions-download-artifact-8.x`,
  `renovate/actions-upload-artifact-7.x`, `renovate/ubuntu-24.x`,
  `dependabot/.../download-artifact-4.1.7`, plus `qa-3` as already-merged) —
  **none of these branches exist anymore** (`git branch -a` shows only
  `qa-2` and the two Renovate branches named above, plus the new Dependabot
  branch from the second finding). Those bumps were merged into `master`
  individually (visible in `git log`: `4d335ac`, `968f9b5`, `7ec4c23`,
  `0fe4418`, and the four merge commits above them) sometime after this
  README section was written, and the README was never refreshed to match.

This isn't a secret or a security problem — it's a documentation-currency
gap that would mislead anyone (including a future audit pass) who trusted
the README's dependency claims at face value. **P2**, for Phase 15 to
rewrite from the real current state, not edited here (docs-only phase, and
rewriting README itself is Phase 15's job, not Phase 3's).

## Fifth finding — real duplication is modest but present

`turboaz.cy.js` and `turbo_az.cy.js` both drive turbo.az's make/model
dropdown from scratch (`cy.visit`, open the make dropdown, type a filter).
`turbo_az.cy.js` stops after typing "Audi" with no assertion; `turboaz.cy.js`
continues through model selection, price range, submit, and three
assertions. This reads as an earlier, abandoned draft left alongside its own
more complete successor, not two intentionally distinct test cases (contrast
with `udemy_cypress_13.6.6`'s deliberate teaching-progression duplication,
which had a stated pedagogical reason) — there is no comparable reason to
keep both here. **P2**, for Phase 7 to resolve (delete the incomplete draft,
keep `turboaz.cy.js`) once Phase 5's baseline run confirms current behavior.

## Sixth finding — `spec.cy.js` is a known-broken leftover template

Cypress's own generated template test, never adapted: it visits `/` (i.e.
`https://turbo.az/` via `baseUrl`) and asserts on
`textarea[name="q"]` — a Google-search-box selector that does not exist on
turbo.az. This spec would fail immediately if the CI workflow ever reached
the point of running specs (it currently never does, see the Key finding
above). **P1** once CI is fixed (Phase 10) and specs actually run for the
first time — flagged now so Phase 5's first live baseline run isn't
surprised by it.

## Other observations

- `index.html`/`style.css`/`img/login_right_image.png` — an unrelated static
  login-page mockup, confirmed by both file reading and the README's own
  disclosure. Not exercised by any Cypress spec. `img/login_right_image.png`
  (~1.1 MB) is the majority of this repo's 1.2 MB total size. **P2/P3**, for
  Phase 7 (dead code — not part of the test suite's product) and Phase 15
  (if kept, document what it actually is in the README rather than leaving
  it unexplained).
- `.hintrc` (webhint linter config) disables two accessibility checks
  (`axe/forms`, the image-alt portion of `axe/text-alternatives`) for
  `index.html`/`style.css` — irrelevant to the Cypress suite itself, travels
  with the unrelated mockup page above.
- No `LICENSE` file, no `license` field in `package.json`. **P3**, for Phase
  15.
- No root `engines` field or `.nvmrc` pinning the Node version Cypress 16.x
  requires (`^22.0.0 || ^24.0.0 || >=26.0.0`, per Phase 2). **P2/P3**, for
  Phase 5/9.
- No linter/formatter/type-checker configured for the JavaScript spec files
  (`.hintrc` only covers the unrelated static HTML/CSS pair). **P3**, for
  Phase 9.
- `qa-2` remote branch (3 files: `.hintrc`, `index.html`, `style.css`, no
  `package.json`) confirmed to predate the Cypress work entirely and carry no
  test-automation content — re-confirmed this phase via `git diff --stat
  master origin/qa-2`. Branch-hygiene decision belongs to Phase 4, not
  analyzed further here.
- CI actions are tag-pinned, not SHA-pinned (`actions/checkout@v7`,
  `cypress-io/github-action@v7.4.6`, `actions/upload-artifact@v7`,
  `actions/download-artifact@v8.0.2`) — carried over from Phase 2, for Phase
  10.

## No code changed

This audit pass wrote only documentation: this file, `docs/ARCHITECTURE.md`,
`docs/TECHNICAL_DEBT.md`, `docs/IMPROVEMENT_ROADMAP.md`,
`projects/info/analysis/qa-m-a.md`, and this phase's handoff file. No commit
was made inside `projects/repos/qa-m-a`, no branch was created, no PR was
opened, nothing was installed, upgraded, merged, or executed against the
live repository.
