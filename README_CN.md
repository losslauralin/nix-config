# nix-config

[![English](https://img.shields.io/badge/lang-English-blue.svg)](README.md) [![简体中文](https://img.shields.io/badge/lang-简体中文-red.svg)](README_CN.md)

基于 [denful/den](https://github.com/denful/den) 的个人 NixOS 配置 —— 面向切面、上下文感知的声明式框架。三台主机：真机笔记本、QEMU 虚拟机（桌面测试用）、WSL2 开发环境。

## 快速开始

```bash
just                # nix flake check
just switch .#<host> [--ask --update]
just build  .#<host> [--ask]
just build-vm <vm-host>        # 构建 VM 镜像到 result-<host>/
just update                    # nix flake update
just fmt; just fmt-check       # 格式化 + 检查格式
```

> Arch 主机：用 `nix shell nixpkgs#just nixpkgs#nh -c 'just ...'` 包装。见 [CLAUDE.md](CLAUDE.md) footgun #2。

`flake.nix` 手写。新增 input：在 `flake.nix` 的 `inputs` attrset 加一条、在使用模块里 import、然后 `nix flake lock`。`vic/flake-file` 已弃用，因为它的 input ↔ module 同步机制与 Nix module 严格求值冲突。

## 主机

| 主机 | 类型 | 平台 | 桌面 |
|------|------|------|------|
| `mechrevo-nixos-dms-niri` | 真机（机械革命笔记本） | x86_64-linux | niri + DankMaterialShell |
| `nixos-niri-dms-vm` | QEMU 虚拟机 | x86_64-linux | niri + DankMaterialShell |
| `nixos-wsl` | WSL2 | x86_64-linux | —（终端环境） |

## 架构

den 把配置拆成**实体** (host / user / home) 和**切面 aspect** (可组合、跨 class 的配置包)。实体声明集中在 `modules/den.nix`，切面声明实际配置，通过同名约定绑定（`den.aspects.<实体名>`）。`modules/` 布局遵循 `CONTEXT.md` 中的 concern-first 分类规则。

```
modules/
├── den.nix              ← den 接线、namespace "lossilk"、框架默认、实体声明
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

### 核心原则

| 原则 | 说明 |
|------|------|
| `den.default` 只放框架默认 | `stateVersion`、`allowUnfree`、`define-user`/`hostname` 管线。不放业务切面；`host-aspects` 由 user 显式 opt-in。 |
| 业务/Profile 基线显式 opt-in | Host 显式 include 可复用 recipe 或 Profile（例如 `lossilk.desktop._.niri-dms-desktop`）；`den.default` 只放框架默认。 |
| 一个 concern 一个切面，平凡的除外 | coreutils 替代（`bat`/`eza`/`fd`/`ripgrep`）聚合在 `cli/utils.nix`；有自定义配置的工具（`fzf`/`yazi`/`zoxide`）单开文件。以 Den 的 `templates/example` 为准。 |
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

```bash
# 1. 联网（如未自动连接）
sudo ip link set wlan0 up
wpa_supplicant -B -i wlan0 -c <(wpa_passphrase "SSID" "密码")
# 或：sudo systemctl start wpa_supplicant

# 2. 磁盘布局 —— 先按需编辑 modules/hosts/<host>/_disko.nix，
#    然后分区：
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
just switch .#<host>
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
just build .#nixos-wsl
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
│   ├── den.nix            ← den 接线 (flakeModule、namespace "lossilk"、默认、实体)
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
