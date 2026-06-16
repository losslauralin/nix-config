# NixOS Configuration Agent Guide

NixOS / `denful/den` 切面架构 + `flake-parts`。术语和心智模型见 `CONTEXT.md`。
本地 namespace 是 `lossilk`（`modules/den.nix` 注册）。

## 命令（必须通过 just 调用）

**禁止直接调用底层命令（nix、nh 等），必须通过 justfile 包装层。**

```
just              # 验证（默认）
just check        # 验证
just fmt          # 格式化
just build        # 构建
just switch       # 部署
just build-vm     # 构建 VM
just test-vm      # 测试 VM
just run-vm       # 运行 VM
just update       # 更新 flake
just clean        # 清理
just fmt-check    # 格式检查（不改文件）
just check-all    # 格式检查 + 验证
```

Arch dev host 需要先安装：`nix shell nixpkgs#just nixpkgs#nh -c '...'`

## 约束

### 需确认的文件（修改前必须询问用户）
- `flake.nix`
- `flake.lock`
- `pkgs/*`

### 可直接修改
- `modules/*`
- `scripts/*`
- `*.md`

### 易踩坑

1. **新 nix 文件必须 git add** — `vic/import-tree` 仅扫描 git-tracked 文件，未 add 的 nix 文件不参与 evaluation，且不会报错。

2. **CLI 工具因 host 而异** — Arch dev host 无 `nixos-rebuild`，运行依赖工具前用 `command -v <tool>` 验证。

3. **`host-aspects` 是过渡方案** — 修改前比对 `flake.lock` den rev 与上游变更。

## 文档地图

| 任务 | 必读 |
|---|---|
| 新增/修改 feature 切面 | `docs/agents/adding-a-feature.md` + den `guides/configure-aspects.mdx` |
| 决定文件/切面放哪 | `CONTEXT.md` 的 Modules Taxonomy |
| den 语义工作 | `docs/frameworks/den.md` + 本地 `~/workspace/nix-ref/den/docs` |
| 术语裁决 | `CONTEXT.md` |

## 外部参考

本地参考，不在本仓库 git 内，可直接读取：

- `~/workspace/nix-ref/den` — den 框架源码
- `~/workspace/nix-ref/nixconfig` — 他人 NixOS den 配置
- `~/workspace/nix-ref/infra` — 基础设施配置

## 风格与提交

- Nix 由 treefmt/`alejandra` 格式化；shell 脚本走 `shfmt` + `shellcheck`。提交前 `just fmt`。
- 模块文件名小写描述性（如 `modules/dev/lang/python.nix`）。
- include 引用风格：新文件统一 attrpath 风格（`{lossilk, ...}` + `lossilk.x._.y`）；尖括号 `<lossilk/...>` 仅既有文件保留。
- Conventional Commits：`feat(cli): ...` / `refactor(desktop): ...` / `docs: ...`。

## Agent Skills

- **Domain docs**: `CONTEXT.md` + `docs/frameworks/den.md`
