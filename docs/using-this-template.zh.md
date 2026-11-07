# 从本模板派生新项目

> [English](using-this-template.md) | 简体中文

点击 **Use this template** 后,新仓库已经自带严格 lint、分层 hook、CI 和发布
流水线。接下来把项目改成你的名字。下表列出需要改动的全部文件。要查找残留:

```bash
grep -rn "rust-agents-template" . --exclude-dir={.git,target}
```

## 改名清单

| # | 文件 | 要改什么 |
|---|------|----------|
| 1 | `Cargo.toml` | `name`、`description`、`repository`;`version` 想重置就重置 |
| 2 | `Cargo.lock` | 无需手动改:用 `cargo build` 重新生成(也可以先删掉) |
| 3 | `tests/cli.rs` | `env!("CARGO_BIN_EXE_rust-agents-template")` → 新的二进制名 |
| 4 | `.github/workflows/release.yml` | `bin: rust-agents-template` → 新的二进制名 |
| 5 | `.github/workflows/test-build.yml` | 两处 `target/.../release/rust-agents-template[.exe]` 产物路径 → 新的二进制名 |
| 6 | `Containerfile` | `COPY bin/${TARGETARCH}/rust-agents-template` → 新的二进制名 |
| 7 | `justfile` | 顶部注释(仅文案);`just image` 会自动读取包名 |
| 8 | `README.md` / `README.zh.md` | 标题、徽章 URL、克隆 URL、简介文案 |
| 9 | `LICENSE` / `LICENSE-MIT` / `LICENSE-APACHE` | 版权持有人与年份 |
| 10 | `SECURITY.md`、`CONTRIBUTING.md`、`AGENTS.md` | 可选:调整联系方式或措辞 |
| 11 | `src/main.rs` | crate 级文档注释(missing_docs 强制) |

无需改动的文件:`rust-toolchain.toml`、`deny.toml`、`githooks/*`、
`.editorconfig`、`docs/*`(均为相对链接)、`.github/dependabot.yml`。

## 改完之后

```bash
just setup        # 激活 hook + 安装工具
just check        # 全链检查 —— 会帮你抓出漏改的地方
git add -A && git commit -m "chore: rename project"   # pre-commit 在此自动运行
```

`just check` 会重新运行检查,抓出漏掉的名字。

## 日常开发

- 提交运行快检查,推送运行重检查(见 [检查](checks.zh.md))
- 检查门拦住改动时,先修代码。放行只能作用于代码,并需要原因注释
  ([Lint 策略](lint-policy.zh.md))
- 要发布二进制,先运行 `just tag` 做本地审查并创建标签,再推送 `v*` 标签
  ([发布](release.zh.md))
- GHCR 镜像名自动跟随仓库名;派生项目要公开发布时,在包的设置里把可见性
  改成 public
