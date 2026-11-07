# Contributing

This repository runs a layered check pipeline. Keep it green.

## Setup

```bash
just setup        # activate git hooks + install missing check tools
just check        # run the local hooks (pre-commit + pre-push)
just verify       # run the deterministic CI/release gates (no network audit)
```

## Check gates

Details and the full gate tables: [docs/checks.md](docs/checks.md) (简体中文:
[docs/checks.zh.md](docs/checks.zh.md)).

- pre-commit (fast): `cargo fmt --check`, `cargo machete`, docs↔code
  alignment (`githooks/check-docs`), strict clippy; a docs-only change runs
  the secret scan and the docs gate only
- pre-push (heavy): `cargo audit`, `cargo deny check`, `cargo test`; a
  docs-only push runs the docs gate only; `cargo outdated` is advisory in the
  scheduled security workflow
- pre-tag (release review): `githooks/pre-tag` checks tag↔version,
  `Cargo.lock`, the CHANGELOG section shape, the working tree and an advisory
  checklist; run it with `just tag-check`, create a tag with `just tag`
- CI: for code changes, `just verify`, `just build-release`, `just deps`,
  `just image`, the diff secret scan, macOS/Windows `cargo test --locked`, and
  actionlint/shellcheck/check-docs self-test; for docs-only changes, the diff
  secret scan and the docs gate. All paths report through the `full check
  chain` gate.

The full discipline, including when a lint waiver is acceptable, is in
[AGENTS.md](AGENTS.md). Fix code first; waivers are code-level, minimal-scope,
and must carry a reason comment.

## Docs must stay in sync

Documentation under `docs/` is bilingual (`docs/*.md` + `docs/*.zh.md`, plus
the two README landing pages) and must change together. Repository meta files
(`AGENTS.md`, `HANDOFF.md`, `CONTRIBUTING.md`, `SECURITY.md`, `CHANGELOG.md`)
are English-only. Changing lint config or the check chain requires updating
the affected pages in both languages in the same change.
`githooks/check-docs` enforces the greppable parts automatically, including
mirror completeness and heading parity.

## Changelog

Record user-visible changes in the current release section (`## [Unreleased]`,
or the upcoming version's dated section while it is being prepared) in the
same commit ([AGENTS.md](AGENTS.md) §9); internal refactors, tests and CI-only
changes do not need an entry. `githooks/check-docs` validates the file skeleton,
and the release review (`just tag-check`) validates the dated section before
tagging.

## Pull requests

- Keep CI green; a failing `full check chain` job blocks merge.
- Small, focused PRs are easier to review.
