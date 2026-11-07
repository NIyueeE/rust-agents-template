# Checks

> English | [简体中文](checks.zh.md)

Three layered gates guard the repository, split by moment and weight:

| Moment | Gate | Weight | What it guards |
|--------|------|--------|----------------|
| every commit | `githooks/pre-commit` | fast | code quality: fmt, secrets, machete, docs sync, clippy |
| every branch push | `githooks/pre-push` | heavy | security, dependency policy, freshness, tests |
| every release tag | `githooks/pre-tag` | light | release state: tag↔version, changelog shape, clean tree, advisory checklist |

The split is deliberate: pre-commit is the fast quality loop, pre-push is the
heavyweight loop every branch push pays, and pre-tag is a light release
readiness review. A tag-only push runs that review and stops there — the
tagged commit's heavy gates ran when its branch was pushed, and re-running
them on the tag would make the release depend on the local machine.
`githooks/pre-tag` is not part of `just check`: it needs a release state (a
dated changelog section, an empty `[Unreleased]`) and would fail on an
ordinary development commit. `release.yml` re-enforces the version and
changelog invariants remotely.

## Tools

The gates use four external tools; `just setup` installs any that are missing
(and activates the git hooks):

```bash
cargo install cargo-machete cargo-audit cargo-outdated cargo-deny --locked
```

`cargo fmt` and `cargo clippy` come with the toolchain declared in
`rust-toolchain.toml`.

## The docs-only path (both `pre-commit` and `pre-push`)

A change whose paths are all markdown, `docs/**` or `assets/**` cannot move the
code gates, so both hooks classify it with `githooks/docs-only` before running
anything and take a two-gate path instead:

| Where | Runs | Skips |
|-------|------|-------|
| `githooks/pre-commit` | `githooks/check-secrets`, `githooks/check-docs` | `cargo fmt`, `cargo machete`, `cargo clippy` |
| `githooks/pre-push` | `githooks/check-docs` | `cargo audit`, `cargo deny`, `cargo outdated`, `cargo test` |

Three properties make this safe rather than a bypass:

- the classifier reads the **actual change set** — the staged paths for a
  commit, the pushed commit range for a push — and `ci.yml` calls the same
  script, so the hooks and CI cannot disagree about what "docs-only" means;
- the two gates a docs-only change *can* still break always run: the secret
  scan (a leaked key in a README is still a leaked key) and the docs-alignment
  check;
- anything ambiguous falls back to the full chain: an empty change set, a new
  branch with no remote to diff against, a **tag push**, and a commit that
  mixes docs with code paths.

## On every commit — `githooks/pre-commit`

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

## On every branch push — `githooks/pre-push`

| # | Gate | Command | Purpose |
|---|------|---------|---------|
| 6 | audit | `cargo audit` | RustSec security advisories |
| 7 | deny | `cargo deny check` | licenses / bans / advisories policy |
| 8 | outdated | `cargo outdated --root-deps-only` | outdated direct dependencies |
| 9 | test | `cargo test --quiet` | test suite |

A docs-only push runs the docs gate only. A push carrying a `v*` tag runs the
release review first; a tag-only push stops there.

## On every tag — `githooks/pre-tag`

`githooks/pre-tag` is the light release review, fired at two moments: `just tag`
runs it before creating the tag locally, and `githooks/pre-push` runs it for
every `v*` tag in a push (against the tag's commit, so re-pushing an old tag
reviews that tag's state, not the working tree).

| # | Check | Purpose |
|---|-------|---------|
| 10 | tag name ↔ `Cargo.toml` version; `Cargo.lock` in sync | release identity |
| 11 | exactly one dated `## [x.y.z] - YYYY-MM-DD` section, with prose, and an empty `[Unreleased]` | release notes single source |
| 12 | clean working tree and absent tag (local `just tag` only) | the tag is the release state |
| 13 | advisory checklist: changelog audit, docs audit, `just check` green, deliberate release | human/agent review |

A tag-only push stops after this review: the tagged commit's heavy gates ran
when its branch was pushed. If the tag's commit never went through a branch
push, run `just check` on it first. `release.yml` re-enforces the version and
changelog invariants on the tag's commit.

## CI: one required gate

`ci.yml` runs on every PR and every push to `main`. A `changes` job classifies
the diff with `githooks/docs-only`; `rust gates` runs `just check` for code
changes, `docs alignment` runs `githooks/check-docs` for docs-only changes, and
the `full check chain` job always runs and requires whichever path applies.
That single job is the required context in branch protection, so a docs-only
PR cannot wait for a check that never appears. For the same reason the
workflow does not use workflow-level `paths-ignore`: the required context must
exist on every PR.

## One-shot run

```bash
just check       # pre-commit + pre-push (the full development chain)
just tag-check   # release review only, without creating a tag
just tag         # release review + create the local annotated v* tag
```

`just check` does not include the release review: it is meant for ordinary
development commits. Other recipes: `just fmt` (auto-fix), `just test`.

## When a gate blocks you

Fix the code first. A waiver is the last resort: code-level only
(`#[expect(...)]` preferred over `#[allow]`), minimal scope, with a reason
comment. Never weaken `[lints]`, the hooks, or CI. See
[Lint policy](lint-policy.md) and [AGENTS.md](../AGENTS.md).
