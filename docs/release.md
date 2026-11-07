# Release

> English | [简体中文](release.zh.md)

The released baseline is `v0.1.0`; the prepared next release is `v0.2.0`.
Cutting a release is a review plus a tag push:

```bash
just tag                 # release review, then create the local v0.2.0 tag
git push origin v0.2.0   # the deliberate release act
```

`just tag` reads the version from `Cargo.toml`, runs `githooks/pre-tag`, and
only creates the annotated tag when the review passes. If you create the tag by
hand, `githooks/pre-push` still runs the review for every `v*` tag, and
`.github/workflows/release.yml` re-checks the same invariants remotely.

## Tag review

`githooks/pre-tag` is a light, seconds-fast review of the release state. It
runs at two moments: before `just tag` creates the tag locally, and inside
`githooks/pre-push` for every `v*` tag in a push. The push path reviews the
tag's commit, not the working tree, so re-pushing an old tag reviews that
tag's state. To run the review without creating a tag, use `just tag-check`.

| Check | What it rejects |
|-------|-----------------|
| tag name ↔ `Cargo.toml` version; `Cargo.lock` in sync | a tag that names a version the code does not carry |
| exactly one dated `## [x.y.z] - YYYY-MM-DD` section in `CHANGELOG.md`, with prose, and an empty `[Unreleased]` | a missing, duplicated, undated or empty section |
| clean working tree and an absent tag (local `just tag` only) | a tag that would miss uncommitted state, or a tag that already exists |
| advisory checklist | nothing mechanical — it is a human/agent audit of the changelog, docs and the `just check` result |

A tag-only push stops after the local review: the tagged commit's heavy gates
ran when its branch was pushed. The remote workflow does not rely on that
history. It proves the tag commit is on `main`, verifies `Cargo.lock` with
`--locked`, and re-runs `just verify` and `just deps` before building
anything. A tag cut from an unmerged commit or a red tree fails there.

## Container image (GHCR)

The Linux release archive is built from a static musl binary, so it does not
depend on the runner's glibc, and the release also builds a `linux/amd64` image
from the same static musl target. `just image` is the single recipe used
locally, in CI and by the release image job: it builds the musl binary, builds
the scratch image and smoke-tests it. [Containerfile](../Containerfile) is the recipe; the build
context contains only the binary under `bin/amd64` plus that file. CI runs
`just image` on every code change, so a broken Containerfile does not wait for
a release.

The image is pushed to `ghcr.io/<owner>/<repo>` with the release tag and, for
stable releases only, `latest`. A pre-release tag (`vX.Y.Z-rc.N`) is marked as
a GitHub prerelease and does not move `latest`, matching the release itself.
The OCI `org.opencontainers.image.source` label links the package to the
repository.

GHCR package visibility is a repository setting: the first push creates a
private package; make it public in the package settings if the template should
publish publicly. To add `linux/arm64`, build a second musl binary into
`bin/arm64` and extend the recipe with buildx.

The image job runs after every release binary and before the draft release is
published. If it fails, the GitHub Release stays a draft.

## Test builds (not releases)

`.github/workflows/test-build.yml` builds **test artifacts** for chosen
platforms from any commit — dispatch it from the Actions tab
(**Test build → Run workflow**), pick a `ref` (full commit SHA, branch, or
tag) and `targets` (`linux`, `macos`, `windows`). Artifacts are ephemeral (7-day
retention) and never published as a Release. Releases stay tag-driven.

## Notes

- **Release notes come from `CHANGELOG.md`** (Keep a Changelog format): record
  changes under `## [Unreleased]`, then move that content into a dated
  `## [x.y.z] - YYYY-MM-DD` section before tagging. The release fails unless
  there is exactly one dated section with prose and `[Unreleased]` is empty.
  A duplicated empty section is a known way to publish empty notes; the
  uniqueness check exists for that defect.
- **The tag and `Cargo.toml` must agree.** `githooks/pre-tag` checks it
  locally and `release.yml` checks it again on the tag; the version in
  `Cargo.toml` is the single source.
- **Archives and the image use the tuned release profile.** Linux is
  `x86_64-unknown-linux-musl`, macOS is `aarch64-apple-darwin`, Windows is
  `x86_64-pc-windows-msvc`. Every binary is built with `--locked` and the
  `[profile.release]` settings (thin LTO, one codegen unit, abort on panic,
  stripped symbols).
- **The release is draft-first.** A tag creates a draft release; binaries,
  SHA-256 checksums and the container image are attached while it is still a
  draft, and only the final `publish` job makes it public. A failed platform or
  image leaves a draft, not a partial public release.
- **The workflow re-enforces the changelog invariants.** A local tag created
  with `git tag` instead of `just tag` is still reviewed on push, and a
  missing or malformed section fails the release rather than publishing empty
  notes.
- **Permissions are per job.** Release jobs need `contents: write`; the image
  job needs `packages: write`; the preflight job only reads.
- Re-running a failed build: re-run the workflow from the Actions tab.
  `create-release` reuses the existing draft and the upload action replaces
  existing assets; a re-run refuses to mutate a release that is already
  public. If the draft is gone, delete and re-push the tag
  (`git push origin :v0.2.0`). Deleting a tag is allowed only to fix a failed
  release.
- Verify a commit without releasing with the test build above; never use a
  release tag as a build test.
