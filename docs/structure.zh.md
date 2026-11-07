# 项目结构

> [English](structure.md) | 简体中文

| 路径 | 用途 |
|------|------|
| `src/main.rs` | 二进制入口 |
| `tests/cli.rs` | 二进制冒烟测试 |
| `Cargo.toml` | 清单:严格 `[lints]`、包元数据 |
| `Cargo.lock` | 入库提交(二进制模板惯例) |
| `rust-toolchain.toml` | `channel = "stable"` + clippy/rustfmt 组件 |
| `justfile` | `just setup`(hook + 工具)/ `fmt` / `test` / `check`(全链)/ `tag-check`(发布审查)/ `tag`(审查 + 本地标签) |
| `deny.toml` | cargo-deny 策略:许可证 / 禁用项 / 通告 / 来源 |
| `githooks/pre-commit` | 快门:fmt、secrets、machete、docs、clippy;仅文档改动走两门路径 |
| `githooks/pre-push` | 重门:audit、deny、outdated、test;仅文档推送走文档门;`v*` 标签推送先跑发布审查 |
| `githooks/pre-tag` | 轻量发布审查:标签↔版本、`Cargo.lock`、changelog 形态、干净树 / 标签不存在、人工清单 |
| `githooks/docs-only` | 改动集分类器:全部是文档路径 → 两门路径;CI 调用同一个脚本 |
| `githooks/check-docs` | 文档与代码对齐门:双向命令、lint、recipe、镜像、CI/发布接线 |
| `githooks/check-secrets` | 暂存区密钥扫描 |
| `.github/workflows/ci.yml` | CI:分类改动集,代码走 `just check`、文档走 `githooks/check-docs`,并上报始终存在的 `full check chain` 门 |
| `.github/workflows/release.yml` | 打 `v*` 标签 → 版本/changelog 检查 → 发布 + 三平台二进制 |
| `.github/workflows/test-build.yml` | 手动为任意 commit 构建指定平台测试产物 |
| `.github/dependabot.yml` | 每周自动升级 actions + cargo 依赖 |
| `AGENTS.md` | AI 编码代理(以及人类)的守则 |
| `CONTRIBUTING.md` | 贡献指南 |
| `SECURITY.md` | 漏洞报告政策 |
| `LICENSE`(+ `LICENSE-MIT` / `LICENSE-APACHE`)| MIT OR Apache-2.0 |
| `.editorconfig` | 跨编辑器基础格式约定 |
| `.agents/skills/` | 项目级 skill 根目录:每个 `<name>/SKILL.md`(或 `<name>.md`)会被本仓库会话发现;`.gitkeep` 用于跟踪空目录 |
| `docs/` | 模块化文档(本目录) |

延伸阅读:[检查](checks.zh.md) · [Lint 策略](lint-policy.zh.md) · [发布](release.zh.md)
