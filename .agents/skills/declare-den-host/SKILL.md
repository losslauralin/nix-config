---
name: declare-den-host
description: Guide agents through declaring a new den host Entity and composing its host primary Aspect from reusable Aspects in this nix-config repository. Use when the user asks to add a host, define a machine, create a VM/WSL/desktop/headless system, or build a host from existing den Aspects.
---

# Declare Den Host

## Quick start

1. Read `AGENTS.md`, `CONTEXT.md`, `docs/frameworks/den.md`, and `docs/agents/den-configuration-patterns.md`.
2. Determine the host kind and intent: WSL, VM, headless VM, physical machine, desktop profile, server/headless, or special test host.
3. Register the host Entity in `modules/flake-parts/hosts.nix`.
4. Add `modules/hosts/<host-name>/default.nix` with `den.aspects.<host-name>` as the host primary Aspect.
5. Compose reusable capabilities through `includes`; keep host-specific hardware/scenario config inline in the host `nixos` block.
6. Validate with repo `just` wrappers.

## Host declaration shape

Host Entity declarations live in `modules/flake-parts/hosts.nix`:

```nix
den.hosts.x86_64-linux.<host-name>.users.loss = {};
```

For WSL hosts, set the freeform WSL flag on the Entity:

```nix
den.hosts.x86_64-linux.<host-name> = {
  wsl.enable = true;
  users.loss = {};
};
```

## Host primary Aspect shape

Create `modules/hosts/<host-name>/default.nix`:

```nix
{lossilk, ...}: {
  den.aspects.<host-name> = {
    includes = with lossilk; [
      system
      nix
      # Add reusable host opt-ins / profiles here.
    ];

    nixos = _: {
      nixpkgs.hostPlatform = "x86_64-linux";
      # Host spec only: hardware, disk, display, VM-only tweaks, one-host toggles.
    };

    user.extraGroups = ["video" "input"];
  };
}
```

## Composition rules

- Reusable recipe across hosts → create/use Host opt-in Aspect and include it.
- Stable desktop/system combination → include a Profile / Bundle such as `lossilk.desktop._.niri-dms-desktop`.
- Hardware, disk layout, facter report, one-host toggles → Host spec inline in the host `nixos` block.
- User's own tools → `modules/users/<user>.nix` user primary Aspect includes, not host Aspect.
- Primary user receives host-selected `homeManager` companion config only if the user includes `den.batteries.host-aspects`.
- Multi-user or conditional host-to-user delivery → prefer explicit `provides.to-users` / `provides.<user>`.

## Common host patterns

### Desktop VM

```nix
{lossilk, ...}: {
  den.aspects.nixos-niri-dms-vm = {
    includes = with lossilk; [
      desktop._.niri-dms-desktop
      virt._.vm
    ];
    nixos = _: {
      nixpkgs.hostPlatform = "x86_64-linux";
      services.greetd.settings.default_session.user = "loss";
    };
    user.extraGroups = ["video" "input"];
  };
}
```

### WSL

```nix
{lossilk, ...}: {
  den.aspects.nixos-wsl = {
    includes = with lossilk; [
      system
      nix
      virt._.wsl
    ];
    nixos = _: {
      wsl.docker-desktop.enable = true;
      wsl.useWindowsDriver = true;
      nixpkgs.hostPlatform = "x86_64-linux";
    };
  };
}
```

## Critical checks

- Use the exact host name consistently in Entity and `den.aspects.<host-name>`.
- Do not hide host business profiles in `den.default`.
- Do not create a new reusable Aspect for a single-host one-line setting.
- New host files under `modules/hosts/**/*.nix` must be `git add`ed before eval.
- Ask before touching `flake.nix`, `flake.lock`, or `pkgs/*`.

## Validation

```bash
just fmt
just check
```

For VM hosts:

```bash
just build-vm <host-name>
```

For image variants:

```bash
just list-image-variants <host-name>
just build-image <host-name> <variant>
```
