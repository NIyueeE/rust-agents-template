# Using this template

> English | [简体中文](using-this-template.zh.md)

After you click **Use this template**, the new repository already has strict
lints, layered hooks, CI and a release pipeline. Rename it so the project is
yours. The checklist below lists every file to change. To find leftovers:

```bash
grep -rn "rust-agents-template" . --exclude-dir={.git,target}
```

## Rename checklist

| # | File | What to change |
|---|------|----------------|
| 1 | `Cargo.toml` | `name`, `description`, `repository`; reset `version` if you like |
| 2 | `Cargo.lock` | no manual edit: regenerate with `cargo build` (or delete it first) |
| 3 | `tests/cli.rs` | `env!("CARGO_BIN_EXE_rust-agents-template")` → your new binary name |
| 4 | `.github/workflows/release.yml` | `bin: rust-agents-template` → your new binary name |
| 5 | `.github/workflows/test-build.yml` | both `target/.../release/rust-agents-template[.exe]` artifact paths → your new binary name |
| 6 | `Containerfile` | `COPY bin/${TARGETARCH}/rust-agents-template` → your new binary name |
| 7 | `justfile` | top comment (cosmetic); `just image` derives the package name automatically |
| 8 | `README.md` / `README.zh.md` | title, badge URLs, clone URL, intro text |
| 9 | `LICENSE` / `LICENSE-MIT` / `LICENSE-APACHE` | copyright holder and year |
| 10 | `SECURITY.md`, `CONTRIBUTING.md`, `AGENTS.md` | optional: adjust contact or wording |
| 11 | `src/main.rs` | crate-level doc comment (missing_docs is enforced) |

Files that need no change: `rust-toolchain.toml`, `deny.toml`, `githooks/*`,
`.editorconfig`, `docs/*` (relative links), `.github/dependabot.yml`.

## After renaming

```bash
just setup        # activate hooks + install tools
just check        # full chain — will catch anything you missed
git add -A && git commit -m "chore: rename project"   # pre-commit runs here
```

`just check` reruns the checks and catches a rename you missed.

## Daily development

- commits run the fast gates; pushes run the heavy gates (see
  [Checks](checks.md))
- when a gate blocks the change, fix the code first. Waivers are code-level and
  need a reason ([Lint policy](lint-policy.md))
- to ship binaries, run `just tag` for the local review and tag, then push the
  `v*` tag ([Release](release.md))
- the GHCR image name follows the repository name automatically; make the
  package public in its package settings if the derived project should publish
  it publicly
