# 发布

> [English](release.md) | 简体中文

已发布的基线是 `v0.2.0`。发布下一个版本 = 一次审查 + 一次标签推送:

```bash
just tag                 # 发布审查,然后创建本地 vX.Y.Z 标签
git push origin vX.Y.Z   # 这才是真正的发布动作
```

`just tag` 从 `Cargo.toml` 读取版本,运行 `githooks/pre-tag`,只有审查通过才
创建 annotated 标签。如果你手工创建标签,`githooks/pre-push` 仍会对每个
`v*` 标签运行审查,`.github/workflows/release.yml` 也会在远端重新校验同一组
约束。

标签应指向包含最终发布状态的 commit。标签之后推送的文档 commit 不属于该
release。

发布目标写在 `.github/targets.json`:Linux x86_64 与 arm64(静态 musl)、
macOS arm64 与 x86_64、Windows x86_64。二进制名来自 `Cargo.toml`;release
与 test-build 工作流都从那里读取。

## 标签审查

`githooks/pre-tag` 是对发布状态的短审查。它在 `just tag` 创建本地标签之前
运行,也在 `githooks/pre-push` 处理推送里的每个 `v*` 标签时运行。推送路径
审查的是标签的 commit,不是工作树,所以重推旧标签审查的是那个标签的状态。
只想审查、不创建标签时用 `just tag-check`。

| 检查 | 拒绝什么 |
|------|----------|
| 标签名 ↔ `Cargo.toml` 版本;`Cargo.lock` 同步 | 标签声明的版本与代码不一致 |
| `CHANGELOG.md` 里恰好一个带日期的 `## [x.y.z] - YYYY-MM-DD` 小节、有正文、`[Unreleased]` 为空 | 缺失、重复、无日期或为空的小节 |
| 工作树干净、标签不存在(仅本地 `just tag`) | 会漏掉未提交状态的标签,或已经存在的标签 |
| 人工清单 | 没有机械检查,由人/agent 审阅 changelog、docs 和 `just check` 结果 |

只推标签时,本地审查完就停。被标记 commit 的重检查在它推分支时已经跑过,
远端工作流不依赖这段历史。它证明标签的 commit 在 `main` 上,用 `--locked`
校验 `Cargo.lock`,并在构建任何产物之前重跑 `just verify` 和 `just deps`。
从未合并的 commit 或红的树切出的标签会在这里失败。

## 容器镜像(GHCR)

Linux 发布归档从静态 musl 二进制构建,因此不依赖 runner 的 glibc。发布还会
用同一个静态 musl target 构建 `linux/amd64` 镜像。`just image` 是本地、CI 和
release 镜像 job 共用的 recipe:构建 musl 二进制、构建 scratch 镜像、做
smoke test。[Containerfile](../Containerfile) 是镜像配方;构建上下文只包含
`bin/amd64` 下的二进制和这个文件。CI 在每次代码改动上运行 `just image`,
所以坏掉的 Containerfile 会在发布前暴露。

镜像推送到 `ghcr.io/<owner>/<repo>`,带发布标签;只有稳定版发布才额外推
`latest`。预发布标签(`vX.Y.Z-rc.N`)会标记为 GitHub prerelease,且不移动
`latest`,与 release 本身一致。OCI `org.opencontainers.image.source` label
会把包链接到仓库。

GHCR 包的可见性是仓库设置:首次推送会创建 private 包。如果模板要公开发布,
在包设置里改成 public。要加 `linux/arm64`,把第二个 musl 二进制放进
`bin/arm64`,并用 buildx 扩展 recipe。

镜像 job 在所有发布二进制之后、draft release 发布之前运行。它失败时,GitHub
Release 会保持 draft。

## 测试构建(不是发布)

`.github/workflows/test-build.yml` 可以为任意 commit 构建测试产物。在 Actions
页手动触发(**Test build → Run workflow**),选择 `ref`(完整 commit SHA、
分支或标签)和 `targets`(`linux`、`macos`、`windows`)。产物保留 7 天,
绝不会作为 Release 发布。发布仍然由标签驱动。

## 注意事项

- 发布说明来自 `CHANGELOG.md`(Keep a Changelog 格式)。开发中的改动先记在
  `## [Unreleased]` 小节,打标签前把它移进带日期的
  `## [x.y.z] - YYYY-MM-DD` 小节。只有恰好一个带日期且有正文的小节,并且
  `[Unreleased]` 为空时,发布才会继续。重复的空小节会发布空说明,所以检查
  要求恰好一个小节。
- 标签必须与 `Cargo.toml` 一致。`githooks/pre-tag` 在本地检查,
  `release.yml` 在标签上再检查一次;`Cargo.toml` 里的版本是唯一来源。
- 发布归档与镜像使用调优后的 release profile。Linux 是
  `x86_64-unknown-linux-musl`,macOS 是 `aarch64-apple-darwin`,Windows 是
  `x86_64-pc-windows-msvc`。所有二进制都用 `--locked` 和
  `[profile.release]` 设置(thin LTO、单 codegen unit、`panic=abort`、strip
  symbols)构建。
- 发布是 draft 优先。打标签先创建 draft release;二进制、SHA-256 校验和与
  容器镜像都挂在 draft 上,最后才由 `publish` job 公开发布。平台或镜像失败
  只会留下 draft,不会出现残缺的公开 release。
- 工作流会再次校验 changelog 规则。用 `git tag` 而不是 `just tag` 创建的
  本地标签,在推送时仍会被审查;缺失或形态不对的小节会让发布失败,而不是
  发布空说明。
- 权限按 job 分配。发布 job 需要 `contents: write`;镜像 job 需要
  `packages: write`;preflight job 只读。attestation job 需要
  `id-token: write` 与 `attestations: write`。
- SBOM job 用 CycloneDX 生成 `sbom.cdx.json`,并上传到 draft。attestation
  job 下载全部发布产物,为归档、校验和与 SBOM 生成 GitHub build provenance。
- `publish` job 在 release environment(名为 `release`)中运行。如果公开
  release 需要人工批准,在该 environment 上配置 required reviewers;没有
  保护时,构建完成后会直接发布。
- 构建失败重跑:在 Actions 页面直接 re-run。`create-release` 会复用已有的
  draft,上传 action 会替换同名产物;已经公开的 release 不会被 re-run 修改。
  如果 draft 已经不存在,再删除并重推标签(`git push origin :vX.Y.Z`)。
  删除标签只允许用于修复失败的发布。
- 要验证某个 commit 而不发布,用上面的测试构建;不要把发布标签当构建测试。
