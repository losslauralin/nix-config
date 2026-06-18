---
name: add-aspect
description: Guide agents through adding or modifying a den feature Aspect in this nix-config repository. Use when the user asks to add a NixOS/Home Manager feature, create a den Aspect, wire an include, add a selection variant, extension, profile, bundle, integration edge, or reusable host opt-in under modules/.
---

# Add Aspect

## Quick start

1. Read, in order: `AGENTS.md`, `CONTEXT.md`, `docs/frameworks/den.md`, `docs/agents/adding-a-feature.md`, `docs/agents/den-configuration-patterns.md`.
2. Classify the request before editing: Host spec, Host opt-in, Leaf Aspect, Family Root, Selection Variant, Extension, Profile / Bundle, Integration Edge, Policy, Quirk, or Battery usage.
3. Choose `modules/<concern>/...` by primary functional intent, not by implementation shape.
4. Create/modify the `lossilk.<concern>._.<name>` Aspect using new-file attrpath style.
5. Wire the include in the owner location: user primary Aspect, host primary Aspect, profile/bundle, family root, or feature dependency.
6. Validate with repo wrappers only.

## Placement rules

Use the repo taxonomy:

| Concern | Path | Aspect path |
|---|---|---|
| CLI, shell, TUI | `modules/cli/` | `lossilk.cli._.*` |
| Dev, editors, languages, git | `modules/dev/` | `lossilk.dev._.*` |
| Desktop, browser, terminal, appearance | `modules/desktop/` | `lossilk.desktop._.*` |
| Network, SSH, VPN, firewall | `modules/networking/` | `lossilk.networking._.*` |
| Boot, filesystem, power, peripherals | `modules/system/` | `lossilk.system._.*` |
| VM, container, WSL | `modules/virt/` | `lossilk.virt._.*` |
| Security, secrets, auth | `modules/security/` | `lossilk.security._.*` |
| AI tools | `modules/ai/` | `lossilk.ai._.*` |

Do not create empty namespace roots. Do not put business features in `den.default`.

## Authoring patterns

### Single-class leaf

```nix
# modules/cli/example-tool.nix
{lossilk, ...}: {
  lossilk.cli._.example-tool.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.example-tool];
  };
}
```

### Multi-class feature

```nix
{lossilk, ...}: {
  lossilk.desktop._.example = {
    nixos.services.example.enable = true;
    homeManager.programs.example.enable = true;
  };
}
```

### Selection variant

```nix
{den, lossilk, ...}: {
  lossilk.cli._.shell._.fish = {
    includes = [
      lossilk.cli._.shell
      (den.provides.user-shell "fish")
    ];
    homeManager.programs.fish.enable = true;
  };
}
```

## Critical checks

- New files use `{lossilk, ...}:` / `{den, lossilk, ...}:`; do not use `<lossilk/...>` in new files.
- Aspect root function args are den Context (`{host}`, `{user}`, `{host, user}`, `{home}`), not Nix module args.
- Class blocks receive Nix module args and should include `...`, e.g. `{pkgs, lib, ...}:`.
- Parent Aspect includes do not auto-enable children. Include children explicitly or create a meta-aspect.
- New `modules/**/*.nix` files must be `git add`ed before evaluation because `vic/import-tree` scans tracked files.
- Ask before modifying `flake.nix`, `flake.lock`, or `pkgs/*`.

## Validation

Use just wrappers, never raw `nix` / `nh` / `nixos-rebuild`:

```bash
just fmt
just check
```

For desktop/host changes also run:

```bash
just build-vm nixos-niri-dms-vm
```

For documentation or skill-only edits, `git diff --check` is sufficient unless Nix files changed.
