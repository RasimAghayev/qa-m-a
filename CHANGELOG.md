# Changelog

All notable changes to this repo are documented here. Format loosely
follows [Keep a Changelog](https://keepachangelog.com/); dates are UTC.

## Phase 6 — Dependency upgrade (2026-11-05)

Every dependency, the Docker base image, and every CI action were
checked live against the registry/releases and brought to (or confirmed
already at) latest-stable. Full evidence:
`projects/info/state/handoff/6/qa-m-a.md`.

### Changed
- `cross-spawn` 7.0.3 → 7.0.6 (transitive, via `cypress`) — fixes a HIGH
  ReDoS advisory (`GHSA-3xgq-45jj-v275`).
- `qs` 6.16.0 → 6.17.1 (transitive, via `cypress`) — fixes a MODERATE DoS
  advisory (`GHSA-6pq8-jhm2-2vcw`).
- `docker/dockerfile` BuildKit syntax directive `1.7` → `1.28`.

### Added
- `renovate.json` — explicit grouping (npm minor/patch together, GitHub
  Actions together), weekly schedule, PR/hourly limits, and digest
  pinning for the `cypress/included` Docker tag. Renovate had been
  proposing bumps on this repo via its own app defaults with no in-repo
  config; this makes the policy explicit.

### Confirmed already at latest-stable (no change needed)
- `cypress` 16.2.1 (npm latest, direct devDependency).
- `systeminformation` 5.33.19 (transitive, via `cypress`).
- `cypress/included:16.2.1` Docker image, digest-verified against Docker
  Hub's current manifest for that tag.
- `actions/checkout@v7`, `actions/upload-artifact@v7` (floating majors —
  already resolve to the current latest release automatically).
- `actions/download-artifact@v8.0.2`, `cypress-io/github-action@v7.4.9`
  (exact pins, each equal to current latest release).
- `ubuntu-26.04` GitHub Actions runner label (still the newest generally
  available x64 Ubuntu hosted image).

### Dependency-bot PRs closed as superseded
- `#41` (Dependabot, `qs` 6.16.0 → 6.17.1) — identical target already
  landed via this phase's own commit; closed without merging.
- `#43` (Renovate, `docker/dockerfile` syntax `1.7` → `1.28`) — identical
  target already landed via this phase's own commit; closed without
  merging.

### No regression
Re-ran the Phase 5 `make verify` gate after the above: `turboaz.cy.js`'s
pre-existing stale-selector failure is unchanged (documented in
`docs/BASELINE.md` and `docs/TECHNICAL_DEBT.md` item 2, owned by a later
phase); no new failure was introduced by this phase's changes.
