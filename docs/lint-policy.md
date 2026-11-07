# Lint policy

> English | [简体中文](lint-policy.zh.md)

Declared in the `[lints]` table of `Cargo.toml`:

| Lint | Level |
|------|-------|
| `unsafe_code` | forbid |
| `missing_docs` | warn |
| clippy `all` | deny |
| clippy `pedantic` | deny |
| clippy `unwrap_used` / `expect_used` / `dbg_macro` | deny |
| clippy `todo` | warn |

The pre-commit hook also passes `-D warnings`, so every warning above,
including `missing_docs` and `todo`, becomes a hard error at commit time.

## Waivers

Fix the code first. A waiver is a last resort and applies only in code.

- Never "make errors disappear" by editing `[lints]`, the hooks, or CI.
- Relax at statement or single-function scope, with a one-line reason comment.
  Prefer `#[expect(clippy::lint_name)]`; it starts warning once the lint stops
  firing, which prevents stale allowances. Fall back to
  `#[allow(clippy::lint_name)]`.
- Never use module-level `#![allow(...)]` or crate-level relaxation.
- A waiver is legitimate only for genuinely unavoidable usage, or for upstream
  false positives such as macros, generated code, or dependency audit noise.

The same discipline applies to every other gate (machete, audit, deny,
docs-sync, and anything added later). Full rules: [AGENTS.md](../AGENTS.md).
