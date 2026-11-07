# rust-agents-template

> 一个 Rust 项目模板:严格 lint、分层 git hook、cargo-deny 与 CI/CD。

[![CI](https://github.com/NIyueeE/rust-agents-template/actions/workflows/ci.yml/badge.svg)](https://github.com/NIyueeE/rust-agents-template/actions/workflows/ci.yml)
[![License](https://img.shields.io/badge/license-MIT%20OR%20Apache--2.0-blue.svg)](LICENSE)

[English](README.md) | [简体中文](README.zh.md)

一个新的 Rust 二进制项目起点,包含严格 lint 策略和分层检查流水线:
pre-commit、pre-push 与 CI。

## 特性

- 最新 stable 工具链:`rust-toolchain.toml` 声明 `channel = "stable"`,
  任何人 clone 后 rustup 都会解析当时的最新 stable 版本,并自带
  `clippy` 与 `rustfmt` 组件。
- 严格 lint:`unsafe_code = "forbid"`,clippy `all` 与 `pedantic` 均为
  `deny`(见 [Lint 策略](docs/lint-policy.zh.md))。
- 分层检查门:pre-commit 运行快检查,pre-push 运行重检查;CI 另外运行 release
  构建、macOS/Windows 测试、镜像 smoke test,以及 workflow/hook lint
  (见 [检查](docs/checks.zh.md))。
- 先审查、再打标签的发布:`just tag` 在本地运行发布审查。推送 `v*` 标签后
  发布 draft release,包含 Linux、macOS 与 Windows 归档、SHA-256 文件以及
  GHCR 镜像(见 [发布](docs/release.zh.md))。
- Rust 2024 edition。

## 快速开始

```bash
git clone https://github.com/NIyueeE/rust-agents-template.git
cd rust-agents-template

# 每个 clone 一次:激活 hook + 安装缺失工具
just setup   # (或手动:git config core.hooksPath githooks)

cargo run

# 随时跑完整的本地检查链(pre-commit + pre-push)
just check

# 可选:本地构建并 smoke test GHCR 镜像
# (仅 Linux;需要 musl-tools 和 docker 或 podman)
just image
```

## 文档

| 文档 | 内容 |
|------|------|
| [docs/using-this-template.zh.md](docs/using-this-template.zh.md) | 从本模板派生新项目:改名清单 |
| [docs/checks.zh.md](docs/checks.zh.md) | 检查门、仅文档路径、分层 hook、CI |
| [docs/lint-policy.zh.md](docs/lint-policy.zh.md) | 每条 lint 与级别、放行规则 |
| [docs/release.zh.md](docs/release.zh.md) | 标签审查,以及归档、校验和与 GHCR 镜像 |
| [docs/structure.zh.md](docs/structure.zh.md) | 仓库里每个文件的用途 |
| [HANDOFF.md](HANDOFF.md) | 交接文档:当前工作状态、决策与开放事项 |
| [CONTRIBUTING.md](CONTRIBUTING.md) | 如何参与贡献 |
| [SECURITY.md](SECURITY.md) | 漏洞报告 |
| [AGENTS.md](AGENTS.md) | AI 编码代理(以及人类)的守则 |

`docs/` 下每个页面都有对应的 English 版本(同目录下去掉 `.zh` 后缀),
README 也是中英成对;仓库元文件(`AGENTS.md`、`HANDOFF.md`、`CONTRIBUTING.md`、
`SECURITY.md`、`CHANGELOG.md`)只提供英文。

## 参与贡献

欢迎提交 PR,参见 [CONTRIBUTING.md](CONTRIBUTING.md)。

## 许可证

基于 MIT OR Apache-2.0 许可证分发,详情见 [`LICENSE`](LICENSE)。

© 2026 NIyueeE (100502009+NIyueeE@users.noreply.github.com)
