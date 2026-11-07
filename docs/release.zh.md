# 发布

> [English](release.md) | 简体中文

已发布的基线是 `v0.1.0`;正在准备的下一个版本是 `v0.2.0`。
发布 = 一次审查 + 一次标签推送:

```bash
just tag                 # 发布审查,然后创建本地 v0.2.0 标签
git push origin v0.2.0   # 这才是真正的发布动作
```

`just tag` 从 `Cargo.toml` 读取版本,运行 `githooks/pre-tag`,只有审查通过才
创建 annotated 标签。如果你手工创建标签,`githooks/pre-push` 仍会对每个
`v*` 标签运行审查,`.github/workflows/release.yml` 也会在远端重新校验同一组
约束。

## 标签审查

`githooks/pre-tag` 是对发布状态的轻量、秒级审查。它在两个时机运行:本地
`just tag` 创建标签之前,以及 `githooks/pre-push` 处理推送里的每个 `v*` 标签
时。推送路径审查的是标签的 commit,不是工作树,所以重推旧标签审查的是那个
标签的状态。只想审查、不创建标签时用 `just tag-check`。

| 检查 | 拒绝什么 |
|------|----------|
| 标签名 ↔ `Cargo.toml` 版本;`Cargo.lock` 同步 | 标签声明的版本与代码不一致 |
| `CHANGELOG.md` 里恰好一个带日期的 `## [x.y.z] - YYYY-MM-DD` 小节、有正文、`[Unreleased]` 为空 | 缺失、重复、无日期或为空的小节 |
| 工作树干净、标签不存在(仅本地 `just tag`) | 会漏掉未提交状态的标签,或已经存在的标签 |
| 人工清单 | 没有机械检查——由人/agent 审阅 changelog、docs 和 `just check` 结果 |

只推标签时,本地审查完就停:被标记 commit 的重门在它推分支时已经跑过。远端
工作流不依赖这段历史。它证明标签的 commit 在 `main` 上,用 `--locked` 校验
`Cargo.lock`,并在构建任何产物之前重跑 `just verify` 和 `just deps`。从未合并
的 commit 或红的树切出的标签会在这里失败。

## 容器镜像(GHCR)

发布还会构建一个 `linux/amd64` 镜像,从静态 musl 二进制打包,推送到
`ghcr.io/<owner>/<repo>`,带两个 tag:发布标签和 `latest`。镜像配方是
[Containerfile](../Containerfile);构建上下文只包含 `bin/amd64` 下的二进制和
这个文件。

镜像在推送前会先构建并做 smoke test。GHCR 包的可见性是仓库设置:首次推送会
创建 private 包;如果模版要公开发布,在包设置里改成 public。要加
`linux/arm64`,把第二个 musl 二进制放进 `bin/arm64`,并用 buildx 扩展镜像
步骤。

镜像 job 在所有发布二进制之后、draft release 发布之前运行。它失败时,GitHub
Release 会保持 draft。

## 测试构建(不是发布)

`.github/workflows/test-build.yml` 可以为任意 commit 构建指定平台的**测试
产物**——在 Actions 页手动触发(**Test build → Run workflow**),选择 `ref`
(commit SHA、分支或标签)和 `targets`(`linux`、`macos`、`windows`)。产物
仅保留 7 天,绝不会作为 Release 发布。发布永远由标签驱动。

## 注意事项

- **发布说明来自 `CHANGELOG.md`**(Keep a Changelog 格式):开发中的改动先记在
  `## [Unreleased]` 小节,打标签前把它移进带日期的
  `## [x.y.z] - YYYY-MM-DD` 小节。只有恰好一个带日期且有正文的小节、
  且 `[Unreleased]` 为空时,发布才会继续。重复的空小节是发布空说明的已知
  缺陷;唯一性检查就是为它存在的。
- **标签必须与 `Cargo.toml` 一致。** `githooks/pre-tag` 在本地检查,
  `release.yml` 在标签上再检查一次;`Cargo.toml` 里的版本是唯一来源。
- **发布是 draft 优先的。** 打标签先创建 draft release;二进制、SHA-256
  校验和与容器镜像都挂在 draft 上,最后才由 `publish` job 公开发布。平台或
  镜像失败只会留下 draft,不会出现残缺的公开 release。
- **工作流会重新校验 changelog 约束。** 用 `git tag` 而不是 `just tag` 创建的
  本地标签,在推送时仍会被审查;缺失或形态不对的小节会让发布失败,而不是
  发布空说明。
- **权限按 job 分配。** 发布 job 需要 `contents: write`;镜像 job 需要
  `packages: write`;preflight job 只读。
- 构建失败重跑:删除并重推标签(`git push origin :v0.2.0`),或在 Actions 页面
  直接 re-run。删除标签只允许用于修复失败的发布。
- 要验证某个 commit 而不发布,用上面的测试构建;不要把发布标签当构建测试。
