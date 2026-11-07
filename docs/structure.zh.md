# 项目结构

> [English](structure.md) | 简体中文

| 路径 | 用途 |
|------|------|
| `src/main.rs` | 二进制入口 |
| `tests/cli.rs` | 二进制冒烟测试 |
| `Cargo.toml` | 清单:严格 `[lints]`、包元数据 |
| `Cargo.lock` | 入库提交(二进制模板惯例) |
| `rust-toolchain.toml` | `channel = "stable"` + clippy/rustfmt 组件 |
| `justfile` | `just setup`(hook + 工具)/ `fmt` / `test` / `check`(本地 hook)/ `verify`(CI/发布确定性门)/ `build-release` / `deps` / `freshness` / `docs-gate-selfcheck` / `tag-check` / `tag` |
| `deny.toml` | cargo-deny 策略:许可证 / 禁用项 / 通告 / 来源 |
| `githooks/pre-commit` | 快门:fmt、secrets、machete、docs、clippy;仅文档改动走两门路径 |
| `githooks/pre-push` | 重门:audit、deny、test;仅文档推送走文档门;`v*` 标签推送先跑发布审查 |
| `githooks/pre-tag` | 轻量发布审查:标签↔版本、`Cargo.lock`、changelog 形态、干净树 / 标签不存在、人工清单 |
| `githooks/docs-only` | 改动集分类器:全部是文档路径 → 两门路径;CI 调用同一个脚本 |
| `githooks/check-docs` | 文档与代码对齐门:双向命令、lint、recipe、镜像、CI/发布接线 |
| `githooks/check-secrets` | 暂存区密钥扫描,或在 CI 中扫描 commit range |
| `.github/workflows/ci.yml` | CI:分类;diff 密钥扫描;`just verify` / `build-release` / `deps`;macOS/Windows 测试;actionlint/shellcheck/check-docs 自测;始终存在的 `full check chain` 门 |
| `.github/workflows/release.yml` | 打 `v*` 标签 → preflight(在 `main`、版本/changelog/lock、verify/deps)→ draft release + 二进制/校验和 + GHCR 镜像 → 发布 |
| `.github/workflows/test-build.yml` | 在固定 runner 上手动为任意 commit 构建测试产物 |
| `.github/workflows/security.yml` | 每周/手动 `cargo audit` + `cargo deny`;建议性 `cargo outdated` |
| `.github/dependabot.yml` | 每周分组升级 actions + cargo 依赖 |
| `AGENTS.md` | AI 编码代理(以及人类)的守则 |
| `CONTRIBUTING.md` | 贡献指南 |
| `SECURITY.md` | 漏洞报告政策 |
| `LICENSE`(+ `LICENSE-MIT` / `LICENSE-APACHE`)| MIT OR Apache-2.0 |
| `Containerfile` | 从静态 musl 二进制构建 scratch 镜像,发布到 GHCR |
| `.dockerignore` | 镜像构建上下文:只含二进制和 `Containerfile` |
| `tests/check-docs.sh` | 自测:坏掉的文档镜像必须失败 |
| `.editorconfig` | 跨编辑器基础格式约定 |
| `.agents/skills/` | 项目级 skill 根目录:每个 `<name>/SKILL.md`(或 `<name>.md`)会被本仓库会话发现;`.gitkeep` 用于跟踪空目录 |
| `docs/` | 模块化文档(本目录) |

延伸阅读:[检查](checks.zh.md) · [Lint 策略](lint-policy.zh.md) · [发布](release.zh.md)
