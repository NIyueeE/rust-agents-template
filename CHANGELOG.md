# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.0] - 2026-11-07

### Added

- A local release review (`githooks/pre-tag`, `just tag`, `just tag-check`):
  tag↔`Cargo.toml` version, `Cargo.lock` sync, exactly one dated CHANGELOG
  section with prose and an empty `[Unreleased]`, a clean tree and an absent
  tag, plus an advisory checklist. `pre-push` runs it for every `v*` tag.
- A docs-only path in the hooks and CI: `githooks/docs-only` classifies the
  actual change set, so docs edits skip the Rust gates but still run the
  secret scan and docs alignment. CI exposes one always-present
  `full check chain` gate, so a docs-only PR cannot wait for a missing check.
- `githooks/check-docs` now also checks the reverse direction (documented gates
  still exist), `just` recipe citations, bilingual mirror completeness, and
  heading-structure parity.
- `githooks/check-docs` validates the CHANGELOG skeleton: exactly one
  `[Unreleased]` section, the Keep a Changelog / Semantic Versioning header,
  and a date on every version section.
- Track `.agents/skills/` as the project-level skill root; a
  `<name>/SKILL.md` bundle added there is discovered by sessions in this
  repository.
- CI now runs a diff-range secret scan, macOS/Windows `cargo test --locked`,
  a release-profile build, actionlint, shellcheck and a `check-docs` self-test.
- A scheduled security workflow re-checks advisories on an unchanged tree;
  dependency freshness is advisory there rather than blocking a push.
- Release publishes a draft first, attaches SHA-256 checksums, builds and
  pushes a GHCR image from a scratch `Containerfile`, and only then publishes
  the release. A failed platform or image leaves a draft.
- A tuned `[profile.release]`: thin LTO, one codegen unit, abort on panic and
  stripped symbols.
- `just image` builds the static musl binary and the scratch GHCR image, then
  smoke-tests it; CI runs the same recipe on every code change, and the
  release image job reuses it.
- Pre-release tags (`vX.Y.Z-rc.N`) are supported: the GitHub release is
  marked prerelease, and neither GitHub's "Latest" nor the GHCR `latest` tag
  moves.

### Changed

- `release.yml` verifies the tag against `Cargo.toml` and requires exactly one
  dated, non-empty CHANGELOG section with an empty `[Unreleased]`; the
  date-aware matcher replaces the old first-match extractor.
- The README gate count and mirror-scope claims were corrected; repository meta
  files are explicitly English-only, while every `docs/` page keeps a mirror.
- The PR template and CONTRIBUTING ask for an entry in the current release
  section (`[Unreleased]`, or the upcoming version's dated section) on
  user-visible changes; internal refactors, tests and CI-only changes are
  exempt.
- CI runs context-free `just verify`, `just build-release` and `just deps`
  instead of the local hooks; the release preflight proves the tag is on
  `main`, verifies the lockfile and re-runs those gates. Runner images are
  pinned, jobs have timeouts and least-privilege permissions, and Dependabot
  groups its updates.
- `githooks/check-docs` now checks the CI, release, security and GHCR wiring,
  and `githooks/check-secrets` accepts a commit range for CI.
- Release binaries build with `--locked`; Linux archives use static musl, and
  the test-build Linux target matches the release target.

### Fixed

- The release `publish` job sets `GH_REPO`, so `gh release edit` works without
  a checkout in the workspace.
- Prerelease tags no longer publish as stable or overwrite the GHCR `latest`
  tag.

## [0.1.0] - 2026-08-31

### Added

- Initial release of the **rust-agents-template**: an agent-facing Rust
  project template with strict lints, layered git hooks,
  changelog-driven releases, and CI/CD test builds.
