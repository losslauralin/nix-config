# nix-config

[![English](https://img.shields.io/badge/lang-English-blue.svg)](README.md) [![简体中文](https://img.shields.io/badge/lang-简体中文-red.svg)](README_CN.md)

Personal NixOS configuration built with [denful/den](https://github.com/denful/den) — an aspect-oriented, context-aware framework. Three hosts: a bare-metal laptop, a QEMU VM for desktop testing, and a WSL2 development environment.

## Quick Start

```bash
just                # nix flake check
just switch .#<host> [--ask --update]
just build  .#<host> [--ask]
just build-vm <vm-host>       # build VM image under result-<host>/
just update                   # nix flake update
just fmt; just fmt-check      # format + check formatting
```

> On Arch: wrap with `nix shell nixpkgs#just nixpkgs#nh -c 'just ...'`. See [CLAUDE.md](CLAUDE.md) footgun #2.

`flake.nix` is hand-written. To add a new input: add it to the `inputs` attrset in `flake.nix`, reference it from the importing module, then run `nix flake lock`. `vic/flake-file` was retired because its input ↔ module synchronization conflicted with strict Nix module evaluation.

## Hosts

| Host | Type | Platform | Desktop |
|------|------|----------|---------|
| `mechrevo-nixos-dms-niri` | Bare metal (MECHREVO laptop) | x86_64-linux | niri + DankMaterialShell |
| `nixos-niri-dms-vm` | QEMU VM | x86_64-linux | niri + DankMaterialShell |
| `nixos-wsl` | WSL2 | x86_64-linux | — (terminal-only) |

## Architecture

Den decomposes config into **entities** (host, user, home) and **aspects** (composable, multi-class config bundles). Entity declarations live in `modules/den.nix`; aspects declare configuration and bind by name convention (`den.aspects.<entity-name>`). The `modules/` layout follows the concern-first taxonomy documented in `CONTEXT.md`.

```
modules/
├── den.nix              ← den wiring, namespace "lossilk", framework defaults, entities
├── schema/host/         ← den.schema.host metadata interfaces (display facts, etc.)
├── hosts/               ← per-host main aspects and host specs
├── users/               ← per-user main aspects
├── system/              ← OS substrate: boot, filesystems, peripherals, power, XDG
├── networking/          ← NetworkManager, SSH, tailscale, wireguard, tools
├── nix/  home-manager/  flake-parts/
├── cli/                 ← shell family, prompt, CLI/TUI tools
├── dev/                 ← editors, git workflow, languages, project workflow
├── desktop/             ← compositor, shell, terminals, browsers, platform, search, appearance
├── security/  virt/  ai/
└── gaming.nix  hacking/  audio.nix
```

### Key principles

| Rule | Why |
|------|-----|
| `den.default` = framework defaults ONLY | `stateVersion`, `allowUnfree`, `define-user`/`hostname` pipeline. No business aspects; `host-aspects` is user opt-in. |
| Business/profile baseline = explicit opt-in | Hosts include reusable recipes or Profiles explicitly (for example `lossilk.desktop._.niri-dms-desktop`); `den.default` stays framework-only. |
| One concern per aspect, unless trivial | Coreutils replacements (`bat`/`eza`/`fd`/`ripgrep`) aggregated in `cli/utils.nix`; tools with custom config (`fzf`/`yazi`/`zoxide`) get their own file. Per Den's `templates/example`. |
| Cross-platform → user aspect; host-locked → host aspect | Shell tools go in `lossilk.cli._.*`, platform configs in `lossilk.virt`, hardware specs inline in host `nixos` block. |

### Batteries used

| Battery | Where | Effect |
|---------|-------|--------|
| `den.provides.define-user` | `den.default` | Auto-create OS users |
| `den.provides.hostname` | `den.default` | `networking.hostName` from entity name |
| `den.provides.host-aspects` | `den.aspects.loss` | User opt-in: receive `homeManager`/`hjem` classes from current host's aspect tree |
| `den.provides.primary-user` | `den.aspects.loss` | wheel + networkmanager groups |
| `(den.provides.user-shell "fish")` | `lossilk.cli._.shell._.fish` (Selection Variant) | Login shell + fish enable |

## Install (bare metal PC)

Start from a NixOS live ISO (any variant with networking).

```bash
# 1. Network (if not already up)
sudo ip link set wlan0 up
wpa_supplicant -B -i wlan0 -c <(wpa_passphrase "SSID" "password")
# or: sudo systemctl start wpa_supplicant

# 2. Disk layout — edit modules/hosts/<host>/_disko.nix first,
#    then partition:
git clone https://github.com/losslauralin/nix-config.git
cd nix-config
sudo nix run github:nix-community/disko -- \
  --mode disko modules/hosts/<host>/_disko.nix

# 3. Hardware probe (optional — generates facter.json for driver/module detection)
sudo nixos-facter -o modules/hosts/<host>/facter.json

# 4. Install
sudo nixos-install --flake .#<host>

# 5. Reboot
reboot

# 6. After reboot — deploy updates
just switch .#<host>
```

### VM test loop (avoid bare metal rebuilds)

```bash
just build-vm nixos-niri-dms-vm     # build VM image
just test-vm nixos-niri-dms-vm      # build + boot
```

Edit host config → `just build-vm` → `just run-vm` → iterate, then deploy to bare metal when stable.

> When creating a new VM host, remember `git add` for new files (import-tree only scans git-tracked files — footgun #1 in CLAUDE.md).

## Install (WSL2)

```bash
# Import the WSL tarball (build on bare-metal or VM first)
just build .#nixos-wsl
tar -czf nixos-wsl.tar.gz -C "$(nix eval --raw .#nixosConfigurations.nixos-wsl.config.system.build.toplevel)" .
wsl --import nixos-wsl C:\wsl\nixos-wsl nixos-wsl.tar.gz
wsl -d nixos-wsl
```

## Directory Structure

```
nix-config/
├── flake.nix              ← hand-written (see ADR 0005)
├── flake.lock
├── justfile               ← task runner (just check/build/switch/fmt/update/…)
├── CLAUDE.md              ← AI assistant context + footguns
├── CONTEXT.md             ← domain glossary (aligned with den's glossary)
├── modules/               ← all config (auto-scanned by import-tree)
│   ├── den.nix            ← den wiring (flakeModule, namespace "lossilk", defaults, entities)
│   ├── schema/host/       ← den.schema.host metadata interfaces
│   ├── audio.nix          ← lossilk.audio (pipewire)
│   ├── hosts/             ← per-host main aspects + host specs
│   ├── users/             ← per-user main aspects
│   ├── system/            ← OS substrate and lifecycle
│   ├── networking/        ← network concern, including SSH
│   ├── cli/               ← lossilk.cli._.*
│   ├── desktop/           ← desktop concern shelves
│   ├── dev/               ← lossilk.dev._.*
│   ├── security/  virt/  ai/
│   └── flake-parts/       ← formatter, nixpkgs, deploy
├── pkgs/by-name/          ← custom packages (pkgs-by-name-for-flake-parts)
└── scripts/               ← deploy.sh, run-vm-arch.sh
```

## Technology Stack

| Technology | Role |
|------------|------|
| [denful/den](https://github.com/denful/den) | Aspect-oriented Nix framework |
| [flake-parts](https://flake.parts/) | Modular flake composition |
| [import-tree](https://github.com/vic/import-tree) | Auto-scan `modules/` (git-tracked only) |
| [Home Manager](https://github.com/nix-community/home-manager) | User-level config |
| [nix-community/disko](https://github.com/nix-community/disko) | Declarative disk partitioning |
| [numtide/nixos-facter](https://github.com/numtide/nixos-facter) | Hardware detection |
| [NixOS/nixos-hardware](https://github.com/NixOS/nixos-hardware) | Hardware-specific tuning |
| [sodiboo/niri-flake](https://github.com/sodiboo/niri-flake) | Niri compositor (NixOS + HM modules) |
| [AvengeMedia/DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell) | quickshell-based desktop shell |
| [noctalia-dev/noctalia-shell](https://github.com/noctalia-dev/noctalia-shell) | Alternative quickshell-based shell |
| [NixOS-WSL](https://github.com/nix-community/NixOS-WSL) | NixOS on WSL2 |
| [AvengeMedia/danksearch](https://github.com/AvengeMedia/danksearch) | Local file index + search daemon |
| [treefmt-nix](https://github.com/numtide/treefmt-nix) | Multi-language formatting |
| [rust-overlay](https://github.com/oxalica/rust-overlay) | Rust toolchain |
| [pkgs-by-name-for-flake-parts](https://github.com/drupol/pkgs-by-name-for-flake-parts) | Custom package auto-discovery |

## License

MIT
