# 检查

> [English](checks.md) | 简体中文

三道分层检查门按运行时机与重量划分:

| 时机 | 检查门 | 重量 | 守护什么 |
|------|--------|------|----------|
| 每次提交 | `githooks/pre-commit` | 快 | 代码质量:fmt、secrets、machete、docs 同步、clippy |
| 每次分支推送 | `githooks/pre-push` | 重 | 安全、依赖策略、新鲜度、测试 |
| 每个发布标签 | `githooks/pre-tag` | 轻 | 发布状态:标签↔版本、changelog 形态、干净工作树、人工清单 |

这个划分是刻意的:pre-commit 是每次提交的快循环,pre-push 是每次分支推送都要
付的重循环,pre-tag 是轻量的发布就绪审查。只推标签时,审查跑完就停——被标记的
commit 的重门在它推分支时已经跑过,在标签上重跑会让发布依赖本地机器。
`githooks/pre-tag` 不属于 `just check`:它需要发布态(带日期的 changelog 小节、
空的 `[Unreleased]`),在普通开发提交上必然失败。`release.yml` 会在远端重新
校验版本与 changelog 约束。

## 工具

检查门依赖四个外部工具;`just setup` 会自动安装缺失的(并激活 git hook):

```bash
cargo install cargo-machete cargo-audit cargo-outdated cargo-deny --locked
```

`cargo fmt` 和 `cargo clippy` 由 `rust-toolchain.toml` 声明的工具链自带。

## 仅文档改动的快车道(`pre-commit` / `pre-push`)

当一次改动的所有路径都是 markdown、`docs/**` 或 `assets/**` 时,它动不了代码
门,所以两个 hook 在运行任何东西之前先用 `githooks/docs-only` 分类,改走两门
路径:

| 位置 | 运行 | 跳过 |
|------|------|------|
| `githooks/pre-commit` | `githooks/check-secrets`、`githooks/check-docs` | `cargo fmt`、`cargo machete`、`cargo clippy` |
| `githooks/pre-push` | `githooks/check-docs` | `cargo audit`、`cargo deny`、`cargo outdated`、`cargo test` |

三条性质让它安全,而不是绕过:

- 分类器读的是**真实改动集**——提交时读暂存路径,推送时读推送的 commit 范围
  ——并且 `ci.yml` 调用同一个脚本,所以 hook 与 CI 不可能对"仅文档"有不同
  理解;
- 仅文档改动**仍然可能**弄坏的两道门始终运行:密钥扫描(README 里泄漏的 key
  仍然是泄漏的 key)和文档对齐检查;
- 任何有歧义的情况都回退到全链:空的改动集、没有远端可比的新分支、**标签
  推送**,以及文档和代码混在一起的提交。

## 每次提交 —— `githooks/pre-commit`

| # | 检查 | 命令 | 用途 |
|---|------|------|------|
| 1 | fmt | `cargo fmt --all -- --check` | 代码格式 |
| 2 | secrets | `githooks/check-secrets` | 暂存区密钥扫描 |
| 3 | machete | `cargo machete` | 未使用的依赖 |
| 4 | docs | `githooks/check-docs` | 文档与代码对齐 |
| 5 | clippy | `cargo clippy --all-targets --all-features -- -D warnings` | 严格 lint |

某一行必须出现密钥形态的字符串时(如密钥格式说明文档),在该行加
`security-scan:allow` 标记并注明原因;`check-secrets` 会跳过它。仅文档改动
只运行第 2、4 道。

## 每次分支推送 —— `githooks/pre-push`

| # | 检查 | 命令 | 用途 |
|---|------|------|------|
| 6 | audit | `cargo audit` | RustSec 安全通告 |
| 7 | deny | `cargo deny check` | 许可证 / 禁用项 / 通告策略 |
| 8 | outdated | `cargo outdated --root-deps-only` | 直接依赖是否过期 |
| 9 | test | `cargo test --quiet` | 测试套件 |

仅文档推送只运行文档门。携带 `v*` 标签的推送先跑发布审查;只推标签时到此
为止。

## 每个发布标签 —— `githooks/pre-tag`

`githooks/pre-tag` 是轻量发布审查,在两个时机触发:`just tag` 在本地创建标签
前运行它,`githooks/pre-push` 对推送里的每个 `v*` 标签运行它(针对标签的
commit,所以重推旧标签审查的是那个标签的状态,不是工作树)。

| # | 检查 | 用途 |
|---|------|------|
| 10 | 标签名 ↔ `Cargo.toml` 版本;`Cargo.lock` 同步 | 发布身份 |
| 11 | 恰好一个带日期的 `## [x.y.z] - YYYY-MM-DD` 小节、有正文、`[Unreleased]` 为空 | 发布说明唯一来源 |
| 12 | 工作树干净、标签不存在(仅本地 `just tag`) | 标签就是发布状态 |
| 13 | 人工清单:changelog 审阅、docs 审阅、`just check` 绿、发布是显式决定 | 人/agent 审阅 |

只推标签时,审查完就停:被标记 commit 的重门在它推分支时已经跑过。如果标签
的 commit 从未经过分支推送,先在它上面跑 `just check`。`release.yml` 会在
标签的 commit 上重新校验版本与 changelog 约束。

## CI:一个必需的检查门

`ci.yml` 在每次 PR 和每次推送到 `main` 时运行。`changes` job 用
`githooks/docs-only` 分类 diff;代码改动由 `rust gates` 运行 `just check`,
仅文档改动由 `docs alignment` 运行 `githooks/check-docs`,而 `full check chain`
job 始终运行,并要求对应路径通过。这个 job 就是分支保护里的那个必需 context,
所以仅文档的 PR 不会因为等一个永远不会出现的检查而卡住。同样出于这个原因,
工作流没有使用 workflow 级的 `paths-ignore`:必需的 context 必须在每个 PR 上
存在。

## 一键运行

```bash
just check       # pre-commit + pre-push(完整开发链)
just tag-check   # 只跑发布审查,不创建标签
just tag         # 发布审查 + 创建本地 annotated v* 标签
```

`just check` 不包含发布审查:它是给普通开发提交用的。其他 recipe:`just fmt`
(自动修复)、`just test`。

## 检查门拦住了你怎么办

先修代码。放行是最后手段:只能代码级局部放松(优先 `#[expect(...)]` 而非
`#[allow]`)、最小作用域、附原因注释;禁止削弱 `[lints]`、hook 或 CI。
详见 [Lint 策略](lint-policy.zh.md) 与 [AGENTS.md](../AGENTS.md)。
