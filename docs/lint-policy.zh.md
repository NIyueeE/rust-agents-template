# Lint 策略

> [English](lint-policy.md) | 简体中文

在 `Cargo.toml` 的 `[lints]` 表中声明:

| Lint | 级别 |
|------|------|
| `unsafe_code` | forbid |
| `missing_docs` | warn |
| clippy `all` | deny |
| clippy `pedantic` | deny |
| clippy `unwrap_used` / `expect_used` / `dbg_macro` | deny |
| clippy `todo` | warn |

pre-commit hook 还会传入 `-D warnings`,因此上面每一条警告,包括
`missing_docs` 和 `todo`,在提交时都会变成硬错误。

## 放行

先修代码。放行是最后手段,而且只作用于代码。

- 不要通过修改 `[lints]`、hook 或 CI 来"让错误消失"。
- 放行范围限于单条语句或单个函数,并且必须写一行原因注释。优先使用
  `#[expect(clippy::lint_name)]`:lint 不再触发时它会开始警告,可以避免过期
  的放行。也可以退回 `#[allow(clippy::lint_name)]`。
- 不要使用模块级 `#![allow(...)]` 或 crate 级放松。
- 只有两种情况可以放行:确实无法避免的用法,或上游误报,例如宏、生成代码
  或依赖审计噪音。

同一套规则适用于其他所有检查门(machete、audit、deny、docs-sync 以及以后
新增的检查)。完整规则见 [AGENTS.md](../AGENTS.md)。
