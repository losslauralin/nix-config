# nix-config

My NixOS config. It uses [denful/den](https://github.com/denful/den), so most features live as aspects that hosts and users opt into. The repo currently covers a MECHREVO laptop, two QEMU VMs, and a WSL2 shell.

## Quick Start

```bash
just                # nix flake check (default)
just os-switch .#<host> [--ask --update] # deploy via NH
just os-build  .#<host> [--ask]          # build OS via NH without deploying
just build <installable>                 # generic nix build
just build-vm <vm-host>                 # build VM image to /tmp/result-<host>/
just update                             # nix flake update
just fmt / just lint                    # format only / lint only
just fmt-check                          # treefmt --fail-on-change (format + lint)
just check-all                          # fmt-check + check
just diff <host>                        # nvd diff: /run/current-system vs new build
just help                               # just -l — full recipe list
```

> On a common Linux distro: wrap with `nix shell nixpkgs#just nixpkgs#nh -c 'just ...'` when `just` or `nh` is not already available.

`flake.nix` is hand-written. To add an input, add it to the `inputs` attrset, import it from the module that needs it, then run `nix flake lock`. `vic/flake-file` is gone; its input/module sync fought with strict Nix module evaluation.

After cloning, run `nix develop` once to install the pre-commit hooks.

## Hosts

| Host | Type | Platform | Desktop |
|------|------|----------|---------|
| `mechrevo-nixos-dms-niri` | Bare metal (MECHREVO laptop) | x86_64-linux | niri + DankMaterialShell |
| `nixos-niri-dms-vm` | QEMU VM | x86_64-linux | niri + DankMaterialShell |
| `nixos-headless-vm` | QEMU VM | x86_64-linux | — (headless) |
| `nixos-wsl` | WSL2 | x86_64-linux | — (terminal-only) |

## Architecture

Den splits config into **entities** (`host`, `user`, `home`) and **aspects**: named chunks of config that can emit NixOS, Home Manager, user, or other classes. A host's entity and its primary aspect live together in `modules/hosts/<host>/default.nix`; the name does the binding (`den.aspects.<entity-name>`). Project language and placement rules live in `CONTEXT.md`; most `modules/` directory names are mutable category shelves, not ownership boundaries.

```
modules/
├── den/                 ← den wiring plus den.schema.* metadata interfaces
│   ├── default.nix      ← flakeModule, namespace "lossilk", framework defaults
│   └── schema/host/     ← den.schema.host metadata interfaces (display facts, etc.)
├── hosts/               ← per-host main aspects and host specs
├── users/               ← per-user main aspects
├── system/              ← OS substrate: boot, filesystems, peripherals, power, XDG
├── networking/          ← NetworkManager, SSH, tailscale, wireguard, tools
├── nix/  home-manager/  flake-parts/  ← git-hooks.nix, formatter.nix, devshell.nix live here
├── cli/                 ← shell family, prompt, CLI/TUI tools
├── dev/                 ← editors, git workflow, languages, project workflow
├── desktop/             ← compositor, shell, terminals, browsers, platform, search, appearance
├── security/  virt/  ai/
└── gaming.nix  hacking/  audio.nix
```

## Workflow

Validation runs in two places: local hooks from `nix develop`, and GitHub Actions. The `justfile` is the entry point for both humans and CI.

| Stage | Local | CI |
|---|---|---|
| Format + static lint (alejandra, deadnix, statix, shfmt, shellcheck, ruff, ...) | `pre-commit` -> `treefmt --fail-on-change` (installed by `nix develop`) | covered by `nix flake check` |
| Module / package / overlay evaluation | manual `just check` before push when desired | `nix flake check --no-warn-dirty` |
| Authoritative gate | hooks + `just check-all` | `.github/workflows/check.yml` (ubuntu + determinate-nix-action v3 + magic-nix-cache v14) |

CI runs the full `nix flake check`. It cannot use `--no-build` because the catppuccin Home Manager bottom module goes through IFD; magic-nix-cache keeps the cost tolerable. Locally, use `just check` when you want the same pre-push signal.

`justfile` is generated from `modules/flake-parts`. It wraps `nix flake check`, `nix build`, `treefmt`, `nvd`, `nix why-depends`, `nix-tree`, and `nix repl`. Build/check recipes use `nix-output-monitor` when stdout is a tty; set `NO_NOM=1` or pipe output to skip it. Run `just help` for the full recipe list.

### Key principles

| Rule | Why |
|------|-----|
| `den.default` = framework defaults only | `stateVersion`, `allowUnfree`, and the `define-user`/`hostname` pipeline. No desktop route, no app bundle; `host-aspects` is user opt-in. |
| Glue aspects are explicit | Hosts include supported route glue directly, for example `lossilk.desktop._.niri-dms-desktop`. This is still an ordinary Den aspect, not a separate primitive. |
| One concern per aspect, unless it is genuinely tiny | Coreutils replacements (`bat`/`eza`/`fd`/`ripgrep`) live together in `cli/utils.nix`; configured tools (`fzf`/`yazi`/`zoxide`) get their own file. |
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

Read the host's `_disko.nix` before running disko. The current bare-metal layout is a reinstall layout: it repartitions the target root disk.

```bash
# 1. Network (if not already up)
sudo ip link set wlan0 up
wpa_supplicant -B -i wlan0 -c <(wpa_passphrase "SSID" "password")
# or: sudo systemctl start wpa_supplicant

# 2. Disk layout — edit modules/hosts/<host>/_disko.nix first.
#    This repartitions the target disk.
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
just os-switch .#<host>
```

### VM test loop (avoid bare metal rebuilds)

```bash
just build-vm nixos-niri-dms-vm     # build VM image
just test-vm nixos-niri-dms-vm      # build + boot
```

Edit host config -> `just build-vm` -> `just run-vm` -> iterate, then deploy to bare metal when stable.

> When creating a new VM host, remember `git add` for new files (import-tree only scans git-tracked files — footgun #1 in AGENTS.md).

## Install (WSL2)

```bash
# Import the WSL tarball (build on bare-metal or VM first)
just os-build .#nixos-wsl
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
├── AGENTS.md              ← AI assistant context + footguns
├── CONTEXT.md             ← project context and canonical terminology
├── modules/               ← all config (auto-scanned by import-tree)
│   ├── den/               ← den wiring plus den.schema.* metadata interfaces
│   │   ├── default.nix    ← flakeModule, namespace "lossilk", defaults
│   │   └── schema/host/   ← den.schema.host metadata interfaces
│   ├── audio.nix          ← lossilk.audio (pipewire)
│   ├── hosts/             ← per-host main aspects + host specs
│   ├── users/             ← per-user main aspects
│   ├── system/            ← OS substrate and lifecycle
│   ├── networking/        ← network concern, including SSH
│   ├── cli/               ← lossilk.cli._.*
│   ├── desktop/           ← desktop module category shelf
│   ├── dev/               ← lossilk.dev._.*
│   ├── security/  virt/  ai/
│   └── flake-parts/       ← formatter.nix, git-hooks.nix, devshell.nix, deploy
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
| [treefmt-nix](https://github.com/numtide/treefmt-nix) | Multi-language formatting (alejandra, shfmt, shellcheck, deadnix, statix, …) |
| [cachix/git-hooks.nix](https://github.com/cachix/git-hooks.nix) | Declarative pre-commit hooks |
| [DeterminateSystems/determinate-nix-action](https://github.com/DeterminateSystems/determinate-nix-action) | Nix installer for GitHub Actions runners |
| [DeterminateSystems/magic-nix-cache](https://github.com/DeterminateSystems/magic-nix-cache-action) | Shared store cache between CI runs |
| [rust-overlay](https://github.com/oxalica/rust-overlay) | Rust toolchain |
| [pkgs-by-name-for-flake-parts](https://github.com/drupol/pkgs-by-name-for-flake-parts) | Custom package auto-discovery |

## License

MIT
