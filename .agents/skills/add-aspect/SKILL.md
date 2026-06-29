---
name: add-aspect
description: Aspect work for reusable den features, selection variants, extensions, profiles, bundles, integration edges, host opt-ins, or module includes under modules/.
---

# Add Aspect

Add or change a reusable `lossilk.*` Aspect. Keep host-only hardware/scenario settings out of this skill; use `declare-den-host` for new hosts and inline host specs.

## Flow

1. Load the Den gate: read `AGENTS.md`, `CONTEXT.md`, `docs/frameworks/den.md`, and `.agents/skills/nixos-den-best-practices/SKILL.md`. Continue only after the request is Den semantic work and the repo command/file constraints are known.
2. Read task docs by branch: for feature/config work read `docs/agents/adding-a-feature.md` and `docs/agents/den-configuration-patterns.md`; for uncertain upstream semantics read the relevant local docs under `/home/loss/workspace/nix-ref/den/docs`. The branch is complete when every rule needed for the requested change has an authority file.
3. Classify the change before editing: Leaf Aspect, Family Root, Selection Variant, Extension, Profile / Bundle, Integration Edge, Host opt-in, Policy, Quirk, Battery usage, or ordinary class config. If it is Host spec, move the change to the host primary Aspect instead of creating a reusable Aspect.
4. Choose physical ownership by primary concern and logical ownership by matching `lossilk.<concern>._.*`; use `.agents/skills/nixos-den-best-practices/REFERENCE.md#taxonomy` only when the concern is not obvious. Placement is complete when the path and Aspect path name the same concern.
5. Write or update the smallest Aspect that owns the behavior. New files use attrpath style, root Aspect functions request only Den Context args, class blocks request Nix module args with `...`, and parent Aspects do not stand in for child includes.
6. Wire the include at the owning site: user primary Aspect, host primary Aspect, profile/bundle, family root, variant, extension, integration edge, or explicit cross-entity provides. Wiring is complete when the DAG edge explains who selected the capability.
7. If a new `modules/**/*.nix` file was created, `git add` it before evaluation so `vic/import-tree` can see it.
8. Validate through repo wrappers only. Run `just fmt` and `just check` for Nix changes; add `just build-vm nixos-niri-dms-vm` for desktop/host-impacting changes. For docs/skills-only edits, `git diff --check` is sufficient.

## Authoring Shapes

Single-class leaf:

```nix
{lossilk, ...}: {
  lossilk.cli._.example-tool.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.example-tool];
  };
}
```

Multi-class feature:

```nix
{lossilk, ...}: {
  lossilk.desktop._.example = {
    nixos.services.example.enable = true;
    homeManager.programs.example.enable = true;
  };
}
```

Selection variant:

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

## Completion Check

- Semantic type and ownership path are stated or obvious from the edit.
- Include path is explicit; no business config moved into `den.default`.
- Cross-entity delivery, if present, uses user includes, `host-aspects`, or explicit provides intentionally.
- No new untracked `modules/**/*.nix` file is left invisible to import-tree.
- Validation matched the change impact and used only `just` wrappers.
