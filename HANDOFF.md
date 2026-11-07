# HANDOFF.md — working state for agents

Agent-facing handoff notes. AGENTS.md owns the **rules**; this file owns the
**state**: where the project stands, which decisions were made and why, and
what is still open. Update this file (in the same commit) whenever you change
something the next session needs to know.

## Quick orientation

- What this repo is: `rust-agents-template` — a public GitHub template repo
  for Rust binary projects with strict lints, layered git hooks,
  changelog-driven releases, and agent-facing rules.
  Live: https://github.com/NIyueeE/rust-agents-template
- Read order: AGENTS.md (rules) → this file (state) → docs/ (topic pages).
- Local loop: `just setup` (once) → `just check` (local hooks) → commit/push.
  CI/release use the context-free `just verify`, `just build-release` and
  `just deps`.
- Tests: `just test` (cargo-nextest when installed, otherwise `cargo test`).

## Current state (2026-11-07)

- First abstraction batch from molehill landed: `githooks/pre-tag` + `just tag`
  / `just tag-check`, release-workflow version/changelog checks, a docs-only
  path shared by the hooks and CI, and the strengthened `githooks/check-docs`
  (reverse gate checks, recipe citations, mirror completeness and heading
  parity).
- CI now classifies the change set inside `ci.yml` with the same
  `githooks/docs-only` script the hooks use. The required branch-protection
  context is the always-present `full check chain` gate, not a job that
  `paths-ignore` might suppress.
- Mirror scope is explicit: `docs/*` and the README pair are bilingual;
  `AGENTS.md`, `HANDOFF.md`, `CONTRIBUTING.md`, `SECURITY.md` and
  `CHANGELOG.md` are English-only.
- CI/CD overhaul landed: the diff-range secret scan, context-free CI gates
  (`just verify` / `build-release` / `deps` / `image`), macOS/Windows tests,
  actionlint/shellcheck/check-docs self-test, weekly security workflow, and a
  draft-first release with SHA-256 checksums and a GHCR image. Main CI at
  `bb68c4e` is green, including the new image smoke test and the macOS 26 /
  Windows 2022 test legs; the manual security workflow is green. A full-SHA
  `test-build.yml` dispatch at `851831e` built the static Linux musl, macOS
  arm64 and Windows msvc artifacts.
- The image path is now exercised in CI (`just image` builds the static musl
  binary, the scratch image and smoke-tests it), so the Containerfile is no
  longer release-only. The release review found and fixed four gaps: the
  publish job had no `GH_REPO`, upload builds were not `--locked`, the
  documented LTO/panic/strip release profile was missing from `Cargo.toml`,
  and prerelease tags would have moved `latest`. The v0.2.0 tag exercised the
  full draft/upload/GHCR/publish chain end to end; see the release state below.
- Release state: **v0.2.0 is the released baseline** — annotated tag `v0.2.0`
  at `b2d273a`, release run `42380028565`, published as Latest. It has three
  archives with matching SHA-256 sidecars: static Linux musl, macOS arm64 and
  Windows msvc. `v0.1.0` is the previous release. The next release starts by
  bumping `Cargo.toml` / `CHANGELOG.md` and running `just tag`.
- v0.2.0 verification: all three checksums pass; the Linux binary is
  `static-pie`, stripped, and prints `Hello, world!`; GHCR pushed both
  `v0.2.0` and `latest` at digest
  `sha256:7a358a9b55d4a3f092d8b919c2caed4ee120fcbbfc98173d6a82efe1bae00995`.
  The package is private (anonymous pull returns 403).

## Previous state (2026-08-31)

- **Template finalized** at user request: release history and tags were reset,
  and a clean baseline release `v0.1.0` was re-created to validate the whole
  CI/CD flow after finalization.
- Toolchain: floating stable (1.98.0 at the time of writing).
- Gates: pre-commit fast gates (incl. secret scan) / pre-push heavy gates /
  CI identical; `githooks/check-docs` carries the docs↔code invariants
  (AGENTS.md §3).
- Releases: tag-driven, notes extracted from CHANGELOG.md; the baseline
  release is `v0.1.0` (placeholder notes, three platform assets).
- CD: `test-build.yml` verified on all three platforms.
- Everything currently green: CI on main, pre-commit, pre-push.

## Decision log (why things are the way they are)

- Bilingual docs (`*.md` + `*.zh.md`) — user preference; mechanically enforced
  by `check-docs` where greppable.
- clippy `pedantic` at `deny` plus `-D warnings` in the hook — the user chose
  the strict variant over a pedantic-warn baseline.
- cargo-deny runs **alongside** cargo audit on purpose (both were requested);
  do not deduplicate them without asking.
- Release notes come only from CHANGELOG.md; a missing section fails the
  release by design.
- Commits are free, `v*` tags are deliberate (AGENTS.md §5) — agents never
  tag without an explicit human request.
- Pre-commit secret scan (`githooks/check-secrets`) added at user request;
  waiver marker `security-scan:allow` with a reason; placeholder-looking
  values (example/dummy/{{ }}) are filtered to keep false positives low.
- The README roadmap section was removed at user request; open items live in
  this file.

- Release review is deliberately not part of `just check`: it needs a release
  state (dated section, empty `[Unreleased]`) and would fail on ordinary
  commits. A tag-only push runs the review and skips the heavy gates because
  the tagged commit's heavy gates already ran on its branch push.
- CI does not use workflow-level `paths-ignore`: the required `full check
  chain` context must exist on docs-only PRs too. Job-level classification plus
  an always-running gate solves that without weakening the required check.
- Docs mirroring is scoped to `docs/` + the README pair. Mirroring agent state
  (`HANDOFF.md`) or governance (`AGENTS.md`) would double the maintenance of
  files that change every session.
- The changelog has two mechanical layers: `githooks/check-docs` checks the
  file skeleton on every commit, and `githooks/pre-tag` checks the dated
  release section at tag time. The "same commit" rule stays prose because
  "user-visible" is a judgement call; the PR template asks for it.
- CI is context-free on purpose: `just check` invokes local hooks, so CI uses
  `just verify` / `build-release` / `deps` and adds its own diff secret scan.
  This keeps the secret scan from silently becoming a no-op in CI.
- Releases are draft-first: a tag creates a draft; binaries, checksums and the
  GHCR image are attached; a final `publish` job makes it public. A failed
  platform or image leaves a draft.
- The image is built by one `just image` recipe shared by local runs, CI and
  the release image job; CI smoke-tests it, so the Containerfile is not
  release-only. Linux release archives use the same static musl target.
- `Cargo.toml` now carries the documented release profile (thin LTO, one
  codegen unit, abort on panic, stripped symbols), and release uploads build
  with `--locked`.
- The `publish` job has no checkout, so it must set `GH_REPO`; without it
  `gh release edit` cannot resolve the repository. Prerelease tags are marked
  prerelease and do not move GitHub or GHCR `latest`.
- `cargo outdated` moved out of the blocking chain: a new upstream release is
  not a defect in this tree. It runs advisory in the scheduled security
  workflow.

## Open threads

- MSRV (`rust-version`): deliberately undecided — it tensions with the
  floating stable toolchain; ask before adding one.
- Action pins: SHAs with `# vX` comments; Dependabot tracks those comments —
  merge its bumps to stay current.
- cargo-nextest evaluation (2026-08-31): works, but the suite is a single
  smoke test, so there is nothing to speed up yet. Adopted as optional via
  `just test`; pre-push and CI still run `cargo test`. Revisit when the suite
  grows past ~10 tests.
- Consider tag-protection rulesets (restrict `v*` creation) if the repo gains
  collaborators.
- `test-build.yml` was re-dispatched at `851831e` with all three targets and
  passed, including the static Linux musl build. Its `ref` input needs a
  **full** commit SHA, branch, or tag: an abbreviated SHA makes
  `actions/checkout` look for a branch of that name and fails; the docs now
  say so. The image push was exercised by the v0.2.0 release.
- Branch protection on `main` must keep requiring the `full check chain`
  context; that name is now produced by the always-running `gate` job.
- The next release is deliberate: bump `Cargo.toml` / `CHANGELOG.md`, run
  `just tag`, and push the tag (AGENTS.md §5). The v0.2.0 release already
  exercised draft creation, asset upload, GHCR push and the final publish.
- The v0.2.0 GHCR package is private (anonymous pull returned 403); make it
  public in package settings if the image should be publicly pullable. The
  image is amd64-only; arm64 is a documented extension, not implemented.
- `dtolnay/rust-toolchain` is pinned to a branch-head commit (`# stable branch
  head`), so it may need a manual bump rather than a Dependabot PR.
- Next batches (not started): ownership/audience table (B4), `native_target`
  cfg (C2), `panic` lint (C4), HANDOFF archive rotation (C7).

## Gotchas

- `actions/checkout` etc. are SHA-pinned with `# vX` comments; bump via
  Dependabot PRs, or update the SHA and the comment together.
- Renaming anything? Follow docs/using-this-template.md and re-grep for the
  old name afterwards. Note: renaming the package can leave a stale
  `target/` cache that makes `cargo test` fail with
  `Os { code: 2, NotFound }` (the cached test binary still points at the old
  bin path). `cargo clean -p <name>` — or touching the test — fixes it
  locally; fresh checkouts and CI are unaffected.
- Private vulnerability reporting must stay enabled in repo settings.
- Never use `--no-verify` (AGENTS.md §4) and never bypass a gate (§2).
