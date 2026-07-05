# nix-config

[![English](https://img.shields.io/badge/lang-English-blue.svg)](README.md) [![简体中文](https://img.shields.io/badge/lang-简体中文-red.svg)](README_CN.md)

我的 NixOS 配置。底层用 [denful/den](https://github.com/denful/den)，所以大部分功能都写成 aspect，由 host 或 user 显式选择。现在覆盖一台机械革命笔记本、两台 QEMU VM 和一个 WSL2 终端环境。

## 快速开始

```bash
just                # nix flake check (default)
just os-switch .#<host> [--ask --update] # 通过 NH 部署
just os-build  .#<host> [--ask]          # 通过 NH 构建 OS, 不部署
just build <installable>                 # 通用 nix build
just build-vm <vm-host>                 # 构建 VM 镜像到 /tmp/result-<host>/
just update                             # nix flake update
just fmt / just lint                    # 只格式化 / 只 lint
just fmt-check                          # treefmt --fail-on-change (format + lint)
just check-all                          # fmt-check + check
just diff <host>                        # nvd diff: /run/current-system vs new build
just help                               # just -l, 完整 recipe 列表
```

> Arch 主机：用 `nix shell nixpkgs#just nixpkgs#nh -c 'just ...'` 包装。见 [CLAUDE.md](CLAUDE.md) footgun #2。

`flake.nix` 手写。新增 input 时，先加到 `inputs` attrset，再从需要它的模块里 import，最后跑 `nix flake lock`。`vic/flake-file` 已经移除；它的 input/module 同步机制和严格 Nix module 求值打架。

clone 之后先跑一次 `nix develop`，安装 pre-commit hooks。

## 主机

| 主机 | 类型 | 平台 | 桌面 |
|------|------|------|------|
| `mechrevo-nixos-dms-niri` | 真机（机械革命笔记本） | x86_64-linux | niri + DankMaterialShell |
| `nixos-niri-dms-vm` | QEMU 虚拟机 | x86_64-linux | niri + DankMaterialShell |
| `nixos-headless-vm` | QEMU 虚拟机 | x86_64-linux | —（headless） |
| `nixos-wsl` | WSL2 | x86_64-linux | —（终端环境） |

## 架构

den 把配置拆成**实体**（`host` / `user` / `home`）和**切面 aspect**：一块有名字的配置，可以同时产出 NixOS、Home Manager、user 等 class。host 的实体声明和主切面放在同一个 `modules/hosts/<host>/default.nix`，靠名字绑定（`den.aspects.<实体名>`）。`modules/` 的目录按 `CONTEXT.md` 里的 concern-first 规则放。

```
modules/
├── den.nix              ← den 接线、namespace "lossilk"、框架默认
├── schema/host/         ← den.schema.host 元数据接口（display facts 等）
├── hosts/               ← 各 host 主切面和 host spec
├── users/               ← 各 user 主切面
├── system/              ← OS substrate：boot、filesystems、peripherals、power、XDG
├── networking/          ← NetworkManager、SSH、tailscale、wireguard、tools
├── nix/  home-manager/  flake-parts/
├── cli/                 ← shell family、prompt、CLI/TUI 工具
├── dev/                 ← editors、git workflow、languages、project workflow
├── desktop/             ← compositor、shell、terminals、browsers、platform、search、appearance
├── security/  virt/  ai/
└── gaming.nix  hacking/  audio.nix
```

## 工作流

检查分两层：本地跑 `nix develop` 安装的 hooks，远端跑 GitHub Actions。人和 CI 都走 `justfile`。

| 阶段 | 本地 | CI |
|---|---|---|
| 格式化 + 静态 lint（alejandra、deadnix、statix、shfmt、shellcheck、ruff 等） | `pre-commit` -> `treefmt --fail-on-change` | 包在 `nix flake check` 里 |
| Module / package / overlay 求值 | 需要时手动 `just check` | `nix flake check --no-warn-dirty` |
| 主 gate | hooks + `just check-all` | `.github/workflows/check.yml` |

CI 跑完整 `nix flake check`。这里不能用 `--no-build`，因为 catppuccin Home Manager bottom module 会走 IFD；magic-nix-cache 负责把成本压下来。本地需要 push 前信号时跑 `just check`。

`justfile` 由 `modules/flake-parts` 生成，包装了 `nix flake check`、`nix build`、`treefmt`、`nvd`、`nix why-depends`、`nix-tree` 和 `nix repl`。build/check 在 tty 下会过 `nix-output-monitor`；设 `NO_NOM=1` 或把输出 pipe 掉即可跳过。

### 核心原则

| 原则 | 说明 |
|------|------|
| `den.default` 只放框架默认 | `stateVersion`、`allowUnfree`、`define-user`/`hostname` 管线。不放桌面 profile，不放应用包；`host-aspects` 由 user 显式 opt-in。 |
| Profile 显式选择 | Host 直接 include 可复用 recipe 或 profile，例如 `lossilk.desktop._.niri-dms-desktop`。 |
| 一个 concern 一个切面，除非真的很小 | coreutils 替代（`bat`/`eza`/`fd`/`ripgrep`）放在 `cli/utils.nix`；有配置的工具（`fzf`/`yazi`/`zoxide`）单独成文件。 |
| 跨平台 → user 切面；host 锁定 → host 切面 | Shell 工具放 `lossilk.cli._.*`，平台配置放 `lossilk.virt`，硬件 spec inline 在 host 的 `nixos` block 里。 |

### 使用的 batteries

| Battery | 位置 | 作用 |
|---------|------|------|
| `den.provides.define-user` | `den.default` | 自动创建 OS 用户 |
| `den.provides.hostname` | `den.default` | 从实体名自动设 `networking.hostName` |
| `den.provides.host-aspects` | `den.aspects.loss` | User opt-in：接收当前 host aspect tree 中的 `homeManager`/`hjem` classes |
| `den.provides.primary-user` | `den.aspects.loss` | wheel + networkmanager 用户组 |
| `(den.provides.user-shell "fish")` | `lossilk.cli._.shell._.fish`（Selection Variant） | 设置登录 shell + 启用 fish |

## 安装（真机 PC）

从 NixOS live ISO 启动（任意带网络的变体）。

运行 disko 前先读对应 host 的 `_disko.nix`。当前真机布局是重装布局：会重新分区目标根盘。

```bash
# 1. 联网（如未自动连接）
sudo ip link set wlan0 up
wpa_supplicant -B -i wlan0 -c <(wpa_passphrase "SSID" "密码")
# 或：sudo systemctl start wpa_supplicant

# 2. 磁盘布局 —— 先按需编辑 modules/hosts/<host>/_disko.nix。
#    这一步会重新分区目标磁盘。
git clone https://github.com/losslauralin/nix-config.git
cd nix-config
sudo nix run github:nix-community/disko -- \
  --mode disko modules/hosts/<host>/_disko.nix

# 3. 硬件探测（可选 —— 生成 facter.json，自动识别驱动/内核模块）
sudo nixos-facter -o modules/hosts/<host>/facter.json

# 4. 安装
sudo nixos-install --flake .#<host>

# 5. 重启
reboot

# 6. 重启后日常更新
just os-switch .#<host>
```

### VM 测试循环（避免真机反复重建）

```bash
just build-vm nixos-niri-dms-vm     # 构建 VM 镜像
just test-vm nixos-niri-dms-vm      # 构建 + 启动
```

编辑配置 → `just build-vm` → `just run-vm` → 迭代，稳定后再部署到真机。

> 新建 VM host 时，新文件必须 `git add`（import-tree 只扫描 git-tracked 文件 —— CLAUDE.md footgun #1）。

## 安装（WSL2）

```bash
# 导入 WSL tarball（先在真机或 VM 上构建）
just os-build .#nixos-wsl
tar -czf nixos-wsl.tar.gz -C "$(nix eval --raw .#nixosConfigurations.nixos-wsl.config.system.build.toplevel)" .
wsl --import nixos-wsl C:\wsl\nixos-wsl nixos-wsl.tar.gz
wsl -d nixos-wsl
```

## 目录结构

```
nix-config/
├── flake.nix              ← 手写 (见 ADR 0005)
├── flake.lock
├── justfile               ← 任务运行器 (just check/build/switch/fmt/update/…)
├── CLAUDE.md              ← AI 助手上下文 + 常见坑
├── CONTEXT.md             ← 领域术语表 (与 den 官方术语表对齐)
├── modules/               ← 所有配置 (import-tree 自动扫描)
│   ├── den.nix            ← den 接线 (flakeModule、namespace "lossilk"、默认)
│   ├── schema/host/       ← den.schema.host 元数据接口
│   ├── audio.nix          ← lossilk.audio (pipewire)
│   ├── hosts/             ← 各 host 主切面 + host spec
│   ├── users/             ← 各 user 主切面
│   ├── system/            ← OS substrate 和 lifecycle
│   ├── networking/        ← 网络 concern，包含 SSH
│   ├── cli/               ← lossilk.cli._.*
│   ├── desktop/           ← desktop concern shelves
│   ├── dev/               ← lossilk.dev._.*
│   ├── security/  virt/  ai/
│   └── flake-parts/       ← 格式化, nixpkgs, deploy
├── pkgs/by-name/          ← 自定义包 (pkgs-by-name-for-flake-parts)
└── scripts/               ← deploy.sh, run-vm-arch.sh
```

## 技术栈

| 技术 | 角色 |
|------|------|
| [denful/den](https://github.com/denful/den) | 面向切面 Nix 框架 |
| [flake-parts](https://flake.parts/) | 模块化 flake 组合 |
| [import-tree](https://github.com/vic/import-tree) | 自动扫描 `modules/`（仅 git-tracked） |
| [Home Manager](https://github.com/nix-community/home-manager) | 用户级配置 |
| [nix-community/disko](https://github.com/nix-community/disko) | 声明式磁盘分区 |
| [numtide/nixos-facter](https://github.com/numtide/nixos-facter) | 硬件探测 |
| [NixOS/nixos-hardware](https://github.com/NixOS/nixos-hardware) | 机型硬件调优 |
| [sodiboo/niri-flake](https://github.com/sodiboo/niri-flake) | Niri 合成器（NixOS + HM 模块） |
| [AvengeMedia/DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell) | quickshell 桌面壳 |
| [noctalia-dev/noctalia-shell](https://github.com/noctalia-dev/noctalia-shell) | 备选 quickshell 桌面壳 |
| [NixOS-WSL](https://github.com/nix-community/NixOS-WSL) | NixOS on WSL2 |
| [AvengeMedia/danksearch](https://github.com/AvengeMedia/danksearch) | 本地文件索引 + 搜索守护 |
| [treefmt-nix](https://github.com/numtide/treefmt-nix) | 多语言格式化 |
| [rust-overlay](https://github.com/oxalica/rust-overlay) | Rust 工具链 |
| [pkgs-by-name-for-flake-parts](https://github.com/drupol/pkgs-by-name-for-flake-parts) | 自定义包自动发现 |

## 许可证

MIT
