---
name: declare-den-host
description: Host declaration work for den host Entities, modules/hosts/<host>/default.nix, desktop/VM/WSL/server composition, or Host spec versus Host opt-in decisions.
---

# Declare Den Host

Declare a machine and its host primary Aspect. Use `add-aspect` first when the requested host needs a reusable capability that does not already exist.

## Flow

1. Load the Den gate: read `AGENTS.md`, `CONTEXT.md`, `docs/frameworks/den.md`, `.agents/skills/nixos-den-best-practices/SKILL.md`, and `docs/agents/den-configuration-patterns.md`. Continue only when host Entity, host primary Aspect, and validation constraints are clear.
2. Classify the host: WSL, VM, headless VM, physical desktop/laptop, server/headless, image/test host, or special one-off. Classification is complete when the host kind determines required batteries, profiles, and validation.
3. Create `modules/hosts/<host-name>/default.nix` and register the host Entity there. For WSL set `wsl.enable = true`; for normal hosts declare `users.loss = {};` unless the request names another user topology.
4. In the same file, declare `den.aspects.<host-name>` as the host primary Aspect. Keep the exact host name consistent between Entity and Aspect.
5. Compose reusable behavior through `includes`: existing system/desktop/virt/security profiles, Host opt-ins, or bundles. If a missing reusable behavior is needed by multiple hosts or owns real coordination, switch to `add-aspect` for that behavior before including it.
6. Put host-only facts inline in the host `nixos` block: hardware imports, disk/facter paths, VM-only tweaks, display manager user, single-host toggles, and `nixpkgs.hostPlatform`.
7. Add `user.extraGroups` or explicit cross-entity delivery only when the host truly owns that relationship. User's own tools stay in the user primary Aspect, not the host primary Aspect.
8. `git add modules/hosts/<host-name>/default.nix` before evaluation so `vic/import-tree` can see it.
9. Validate with repo wrappers only: `just fmt` and `just check`; add `just build-vm <host-name>` for VM hosts, image commands for image variants, and the relevant known desktop VM build when a shared desktop profile changed.

## Shapes

Host Entity:

```nix
den.hosts.x86_64-linux.<host-name>.users.loss = {};
```

WSL Entity:

```nix
den.hosts.x86_64-linux.<host-name> = {
  wsl.enable = true;
  users.loss = {};
};
```

Host primary Aspect:

```nix
{lossilk, ...}: {
  den.aspects.<host-name> = {
    includes = with lossilk; [
      system
      nix
      # Reusable profiles / host opt-ins here.
    ];

    nixos = _: {
      nixpkgs.hostPlatform = "x86_64-linux";
      # Host spec only: hardware, disk, display, VM-only tweaks.
    };

    user.extraGroups = ["video" "input"];
  };
}
```

## Decision Rules

- Host spec: one host, hardware, disk, facter, image detail, display/session tweak, or one-line toggle.
- Host opt-in Aspect: reusable across hosts, non-trivial coordination, or a named capability hosts intentionally choose.
- Profile / Bundle: stable route table of existing Aspects; it should not become the implementation home for unrelated leaf config.
- User primary Aspect: user's shell/dev/AI/dotfile choices and other personal environment includes.
- Explicit provides: multi-user or conditional host-to-user delivery.

## Completion Check

- Entity and `den.aspects.<host-name>` use the same name and intended system.
- WSL, VM, image, and desktop-specific requirements are reflected in includes and validation.
- Host spec is inline; reusable behavior is not buried in one host file.
- New host files are git-tracked before evaluation.
- Validation command matches host kind and uses only `just` wrappers.
