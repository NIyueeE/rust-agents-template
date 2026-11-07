# rust-agents-template

> A Rust project template: strict lints, layered git hooks, cargo-deny, CI/CD.

[![CI](https://github.com/NIyueeE/rust-agents-template/actions/workflows/ci.yml/badge.svg)](https://github.com/NIyueeE/rust-agents-template/actions/workflows/ci.yml)
[![License](https://img.shields.io/badge/license-MIT%20OR%20Apache--2.0-blue.svg)](LICENSE)

[English](README.md) | [简体中文](README.zh.md)

An opinionated, batteries-included starting point for new Rust binary projects —
featuring a strict lint policy and an automated, layered check pipeline
(pre-commit / pre-push / CI).

## Features

- **Latest stable toolchain** — `rust-toolchain.toml` declares `channel = "stable"`,
  so rustup always resolves the newest stable release on every machine, with
  `clippy` and `rustfmt` bundled as required components.
- **Strict lints** — `unsafe_code = "forbid"`, clippy `all` + `pedantic` at `deny`
  (see [Lint policy](docs/lint-policy.md)).
- **Layered check gates** — fast gates before every commit, heavyweight gates
  before every push, and CI running the deterministic gates, a release-profile
  build, macOS/Windows tests, a container-image smoke test, and workflow/hook
  lint (see [Checks](docs/checks.md)).
- **Reviewed, tag-driven releases** — `just tag` runs a local release review;
  pushing a `v*` tag publishes a draft release, three-platform binaries
  (static Linux) with checksums, and a GHCR image (see [Release](docs/release.md)).
- **Rust 2024 edition**.

## Quick start

```bash
git clone https://github.com/NIyueeE/rust-agents-template.git
cd rust-agents-template

# one-time setup per clone: activate hooks + install missing tools
just setup   # (or manually: git config core.hooksPath githooks)

cargo run

# run the full local check chain (pre-commit + pre-push) any time
just check

# optional: build and smoke-test the GHCR image locally
# (Linux; needs musl-tools and docker or podman)
just image
```

## Documentation

| Document | Content |
|----------|---------|
| [docs/using-this-template.md](docs/using-this-template.md) | derive a new project: the rename checklist |
| [docs/checks.md](docs/checks.md) | the gates, docs-only path, layered hooks, CI |
| [docs/lint-policy.md](docs/lint-policy.md) | every lint and its level, waiver rules |
| [docs/release.md](docs/release.md) | tag review → binaries (static Linux) + checksums + GHCR image |
| [docs/structure.md](docs/structure.md) | what every file in this repo is for |
| [HANDOFF.md](HANDOFF.md) | agent handoff: current state, decisions, open threads |
| [CONTRIBUTING.md](CONTRIBUTING.md) | how to contribute |
| [SECURITY.md](SECURITY.md) | reporting vulnerabilities |
| [AGENTS.md](AGENTS.md) | rules for AI coding agents (and humans) |

Every page under `docs/` has a `*.zh.md` 简体中文 counterpart; the README pair
is mirrored too. Repository meta files (`AGENTS.md`, `HANDOFF.md`,
`CONTRIBUTING.md`, `SECURITY.md`, `CHANGELOG.md`) are English-only.

## Contributing

PRs welcome — see [CONTRIBUTING.md](CONTRIBUTING.md).

## License

Distributed under the MIT OR Apache-2.0 license. See [`LICENSE`](LICENSE) for details.

© 2026 NIyueeE (100502009+NIyueeE@users.noreply.github.com)
