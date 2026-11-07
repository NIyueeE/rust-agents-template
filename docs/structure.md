# Project structure

> English | [简体中文](structure.zh.md)

| Path | Purpose |
|------|---------|
| `src/main.rs` | binary entry point |
| `tests/cli.rs` | smoke test for the binary |
| `Cargo.toml` | manifest: strict `[lints]`, package metadata |
| `Cargo.lock` | committed (binary template convention) |
| `rust-toolchain.toml` | `channel = "stable"` + clippy/rustfmt components |
| `justfile` | `just setup` (hooks + tools) / `fmt` / `test` / `check` (full chain) / `tag-check` (release review) / `tag` (review + local tag) |
| `deny.toml` | cargo-deny policy: licenses / bans / advisories / sources |
| `githooks/pre-commit` | fast gates: fmt, secrets, machete, docs, clippy; a docs-only change takes the two-gate path |
| `githooks/pre-push` | heavy gates: audit, deny, outdated, test; a docs-only push takes the docs gate; a `v*` tag push runs the release review first |
| `githooks/pre-tag` | light release review: tag↔version, `Cargo.lock`, changelog shape, clean tree / absent tag, advisory checklist |
| `githooks/docs-only` | change-set classifier: all docs paths → the two-gate path; CI calls the same script |
| `githooks/check-docs` | docs ↔ code alignment gate: commands in both directions, lints, recipes, mirrors, CI/release wiring |
| `githooks/check-secrets` | secret scan on staged changes |
| `.github/workflows/ci.yml` | CI: classify the change set, run `just check` for code or `githooks/check-docs` for docs, and report the always-present `full check chain` gate |
| `.github/workflows/release.yml` | tag push (`v*`) → version/changelog checks → release + three-platform binaries |
| `.github/workflows/test-build.yml` | manual test builds for chosen platforms at any commit |
| `.github/dependabot.yml` | weekly actions + cargo dependency updates |
| `AGENTS.md` | rules for AI coding agents (and humans) |
| `CONTRIBUTING.md` | how to contribute |
| `SECURITY.md` | vulnerability reporting policy |
| `LICENSE` (+ `LICENSE-MIT` / `LICENSE-APACHE`) | MIT OR Apache-2.0 |
| `.editorconfig` | cross-editor formatting basics |
| `.agents/skills/` | project-level skill root: each `<name>/SKILL.md` (or `<name>.md`) is discovered for sessions in this repo; `.gitkeep` keeps the empty directory tracked |
| `docs/` | modular documentation (this directory) |

See also: [Checks](checks.md) · [Lint policy](lint-policy.md) · [Release](release.md)
