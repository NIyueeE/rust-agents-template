# Checks

> English | [简体中文](checks.zh.md)

Checks run at five points:

| Moment | Gate | Weight | What it guards |
|--------|------|--------|----------------|
| every commit | `githooks/pre-commit` | fast | code quality: fmt, secrets, machete, docs sync, clippy |
| every branch push | `githooks/pre-push` | heavy | security, dependency policy, tests |
| every release tag | `githooks/pre-tag` | light | release state: tag↔version, changelog shape, clean tree, advisory checklist |
| every PR / main push | `ci.yml` | full | deterministic gates, release build, three-platform tests, image smoke test, workflow/hook lint |
| weekly / manual | `security.yml` | audit | advisories and dependency policy on an unchanged tree |

pre-commit is the fast quality loop; pre-push runs the heavy checks; pre-tag
is a short release-readiness review. A tag-only push runs that review and
stops. The tagged commit's heavy gates ran when its branch was pushed, and
rerunning them on the tag would make the release depend on the local machine.
The release workflow reruns the deterministic gates and dependency policy
from the tag's commit, so a release does not depend on a local hook having
run.

`githooks/pre-tag` is not part of `just check`: it needs a release state (a
dated changelog section, an empty `[Unreleased]`) and would fail on an
ordinary development commit.

## Tools

The gates use four external tools; `just setup` installs any that are missing
(and activates the git hooks):

```bash
cargo install cargo-machete cargo-audit cargo-outdated cargo-deny --locked
```

`cargo fmt` and `cargo clippy` come with the toolchain declared in
`rust-toolchain.toml`. CI installs `cargo-machete`, `cargo-audit` and
`cargo-deny`; the scheduled security workflow also installs
`cargo-outdated` for its advisory freshness line.

The image recipe (`just image`) additionally needs `musl-gcc` (the
`musl-tools` package on Debian/Ubuntu), `rustup`, and `docker` or `podman`;
it is Linux-only. CI and the release image job install `musl-tools`.

## The docs-only path (both `pre-commit` and `pre-push`)

A change whose paths are all markdown, `docs/**` or `assets/**` cannot move the
code gates, so both hooks classify it with `githooks/docs-only` before running
anything and take a two-gate path instead:

| Where | Runs | Skips |
|-------|------|-------|
| `githooks/pre-commit` | `githooks/check-secrets`, `githooks/check-docs` | `cargo fmt`, `cargo machete`, `cargo clippy` |
| `githooks/pre-push` | `githooks/check-docs` | `cargo audit`, `cargo deny`, `cargo test` |
| CI docs job | `githooks/check-secrets` (diff range), `githooks/check-docs` | Rust toolchain and tests |
| CI lint job | `actionlint`, `shellcheck`, `tests/check-docs.sh` | nothing |

The shortcut uses the actual change set. The hooks read the staged paths for a
commit or the pushed range for a push, and `ci.yml` calls the same
`githooks/docs-only` script, so the hooks and CI classify a change the same
way.

A docs-only change still runs the gates it can break: the secret scan, the
docs-alignment check, and the workflow/hook lint.

Anything ambiguous takes the full chain: an empty change set, a new branch
with no remote to diff against, a tag push, or a commit that mixes docs and
code.

## On every commit: `githooks/pre-commit`

| # | Gate | Command | Purpose |
|---|------|---------|---------|
| 1 | fmt | `cargo fmt --all -- --check` | code style |
| 2 | secrets | `githooks/check-secrets` | secret scan on staged changes |
| 3 | machete | `cargo machete` | unused dependencies |
| 4 | docs | `githooks/check-docs` | docs ↔ code alignment |
| 5 | clippy | `cargo clippy --all-targets --all-features -- -D warnings` | strict lints |

Lines that must carry a secret-shaped string (e.g. key-format documentation)
take a `security-scan:allow` marker with a reason; `check-secrets` skips them.
A docs-only change runs gates 2 and 4 only.

`githooks/check-docs` also validates the CHANGELOG skeleton: exactly one
`[Unreleased]` section, the Keep a Changelog / Semantic Versioning header, and a
date on every version section.

## On every branch push: `githooks/pre-push`

| # | Gate | Command | Purpose |
|---|------|---------|---------|
| 6 | audit | `cargo audit` | RustSec security advisories |
| 7 | deny | `cargo deny check` | licenses / bans / advisories policy |
| 8 | test | `cargo test --quiet` | test suite |

A docs-only push runs the docs gate only. A push carrying a `v*` tag runs the
release review first; a tag-only push stops there. The freshness check is no
longer a blocking gate: it is an advisory line in the scheduled security
workflow, because a new upstream release is not a defect in this tree.

## On every tag: `githooks/pre-tag`

`githooks/pre-tag` is a short release review. `just tag` runs it before
creating the tag locally, and `githooks/pre-push` runs it for every `v*` tag
in a push. The push path reviews the tag's commit, not the working tree, so
re-pushing an old tag reviews that tag's state.

| # | Check | Purpose |
|---|-------|---------|
| 9 | tag name ↔ `Cargo.toml` version; `Cargo.lock` in sync | release identity |
| 10 | exactly one dated `## [x.y.z] - YYYY-MM-DD` section, with prose, and an empty `[Unreleased]` | release notes single source |
| 11 | clean working tree and absent tag (local `just tag` only) | the tag is the release state |
| 12 | advisory checklist: changelog audit, docs audit, green gates, explicit release decision | human/agent review |

A tag-only push stops after this review. The remote release workflow does not
rely on the local hook: it proves the tag commit is on `main`, reruns the
deterministic gates and dependency policy, and only then builds artifacts.

## CI: one required gate

`ci.yml` runs on every PR and every push to `main`. A `changes` job classifies
the diff with `githooks/docs-only` and publishes the commit range. For code
changes:

- `rust gates` scans the range for secrets, then runs `.github/actions/rust-gates`:
  `just verify`, `just build-release`, `just deps`, and a static musl GHCR
  image build with `just image`;
- `platform tests` runs `cargo test --locked` on `macos-26` and `windows-2022`;
- `lint` runs `actionlint`, `shellcheck -x githooks/* tests/check-docs.sh`, and
  the `check-docs` self-test.

The Rust setup and gate steps are composite actions under `.github/actions/`.
CI, release and test-build use the same setup path, so toolchain, cache and
tool installation do not drift between workflows.

For docs-only changes, `docs alignment` scans the range for secrets and runs
`githooks/check-docs`; the `lint` job still runs. Every path reports through
the always-running `full check chain` job, which is the required context in
branch protection, so a docs-only PR cannot wait for a check that never
appears. For the same reason the workflow does not use workflow-level
`paths-ignore`: the required context must exist on every PR.

`just check` is the local hook entry point (pre-commit + pre-push).
`just verify` is the context-free subset CI and release preflight use: fmt,
docs, clippy, and tests with the lockfile. It leaves out the network-dependent
audit and freshness gates.

## Scheduled security

`.github/workflows/security.yml` runs weekly (Monday 03:00 UTC) and on manual
dispatch. It re-checks the unchanged tree with `cargo audit` and
`cargo deny check`, so an advisory published after the last PR still surfaces.
`cargo outdated --root-deps-only` runs as an advisory step with
`continue-on-error`, never as a blocking gate.

## One-shot run

```bash
just check              # local hooks: pre-commit + pre-push
just verify             # deterministic CI/release gates (no network audit)
just build-release      # release profile (LTO/panic=abort/strip)
just image              # static musl binary + scratch GHCR image (smoke-tested)
just deps               # machete + audit + deny
just freshness          # advisory: outdated direct dependencies
just docs-gate-selfcheck # a broken docs mirror must fail
just tag-check          # release review only, without creating a tag
just tag                # release review + create the local annotated v* tag
```

`just check` does not include the release review: it is meant for ordinary
development commits. Other recipes: `just fmt` (auto-fix), `just test`.

## When a gate blocks a change

Fix the code first. A waiver is a last resort and applies only in code,
preferably `#[expect(...)]` rather than `#[allow]`, at minimal scope, with a
reason comment. Never weaken `[lints]`, the hooks, or CI. See
[Lint policy](lint-policy.md) and [AGENTS.md](../AGENTS.md).
