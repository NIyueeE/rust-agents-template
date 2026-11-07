# Project structure

> English | [简体中文](structure.zh.md)

| Path | Purpose |
|------|---------|
| `src/main.rs` | binary entry point |
| `tests/cli.rs` | smoke test for the binary |
| `Cargo.toml` | manifest: strict `[lints]`, package metadata |
| `Cargo.lock` | committed (binary template convention) |
| `rust-toolchain.toml` | `channel = "stable"` + clippy/rustfmt components |
| `justfile` | `just setup` (hooks + tools) / `fmt` / `test` / `check` (local hooks) / `verify` (CI/release deterministic gates) / `build-release` / `deps` / `freshness` / `docs-gate-selfcheck` / `tag-check` / `tag` |
| `deny.toml` | cargo-deny policy: licenses / bans / advisories / sources |
| `githooks/pre-commit` | fast gates: fmt, secrets, machete, docs, clippy; a docs-only change takes the two-gate path |
| `githooks/pre-push` | heavy gates: audit, deny, test; a docs-only push takes the docs gate; a `v*` tag push runs the release review first |
| `githooks/pre-tag` | light release review: tag↔version, `Cargo.lock`, changelog shape, clean tree / absent tag, advisory checklist |
| `githooks/docs-only` | change-set classifier: all docs paths → the two-gate path; CI calls the same script |
| `githooks/check-docs` | docs ↔ code alignment gate: commands in both directions, lints, recipes, mirrors, CI/release wiring |
| `githooks/check-secrets` | secret scan on staged changes, or on a commit range in CI |
| `.github/workflows/ci.yml` | CI: classify; diff secret scan; `just verify` / `build-release` / `deps`; macOS/Windows tests; actionlint/shellcheck/check-docs self-test; always-present `full check chain` gate |
| `.github/workflows/release.yml` | tag push (`v*`) → preflight (on `main`, version/changelog/lock, verify/deps) → draft release + binaries/checksums + GHCR image → publish |
| `.github/workflows/test-build.yml` | manual per-commit test builds on pinned runners |
| `.github/workflows/security.yml` | weekly/manual `cargo audit` + `cargo deny`; advisory `cargo outdated` |
| `.github/dependabot.yml` | weekly grouped actions + cargo dependency updates |
| `AGENTS.md` | rules for AI coding agents (and humans) |
| `CONTRIBUTING.md` | how to contribute |
| `SECURITY.md` | vulnerability reporting policy |
| `LICENSE` (+ `LICENSE-MIT` / `LICENSE-APACHE`) | MIT OR Apache-2.0 |
| `Containerfile` | scratch image from the static musl binary, published to GHCR |
| `.dockerignore` | image build context: only the binary and `Containerfile` |
| `tests/check-docs.sh` | self-test: a broken docs mirror must fail |
| `.editorconfig` | cross-editor formatting basics |
| `.agents/skills/` | project-level skill root: each `<name>/SKILL.md` (or `<name>.md`) is discovered for sessions in this repo; `.gitkeep` keeps the empty directory tracked |
| `docs/` | modular documentation (this directory) |

See also: [Checks](checks.md) · [Lint policy](lint-policy.md) · [Release](release.md)
