---
name: nixos-den-best-practices
description: Best-practice guardrails for writing den-based NixOS and Home Manager configuration in this nix-config repository. Use when reviewing, planning, or editing den Aspects, includes, entities, policies, quirks, batteries, cross-entity delivery, or modules/**/*.nix configuration.
---

# NixOS Den Best Practices

## Quick start

Before den semantic work, read:

1. `AGENTS.md`
2. `CONTEXT.md`
3. `docs/frameworks/den.md`
4. Relevant local den docs under `/home/loss/workspace/nix-ref/den/docs` if upstream semantics are needed.

Use this skill like a preflight/review checklist, similar to a framework best-practices guide.

## Terminology discipline

- Entity declares what exists: host, user, home. Do not call it resource/instance.
- Aspect declares what it does. Do not call it a NixOS module.
- `includes` is an Aspect DAG dependency, not a Nix `imports` entry.
- Class is Nix module eval domain (`nixos`, `homeManager`, `user`, `wsl`), not Entity Kind.
- Context is den pipeline data shape (`{host}`, `{host, user}`), not `_module.args`.
- Family Root, Selection Variant, Extension, Profile / Bundle, and Integration Edge are distinct semantic roles.

## Architecture rules

- Place files by primary concern under `modules/<concern>/`, not by technical shape like daemon/systemd/GUI.
- Keep logical Aspect path aligned with physical concern: `modules/desktop/...` should expose `lossilk.desktop._...`.
- `den.default` is only for framework defaults: stateVersion, allowUnfree, define-user, hostname, pipeline defaults.
- Business baselines and desktop/dev/tool choices must be explicit host or user opt-ins.
- Parent Aspect inclusion does not enable children; explicitly include children or define a meta-aspect.
- Do not rely on `lossilk.foo._` collecting provides children; that behavior is unpublished and does not collect provides items.

## Authoring rules

- New files use attrpath style:

```nix
{lossilk, ...}: {
  lossilk.cli._.example.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.example];
  };
}
```

- Preserve legacy angle-bracket includes only in existing files that already use them.
- Aspect root function args are den Context and define activation:
  - `{host}` host context
  - `{user}` user context
  - `{host, user}` host-to-user fan-out
  - `{home}` standalone home context
- Nix module args belong inside class blocks and should include `...`.
- Do not use deprecated wrappers: `den.lib.parametric`, `den.lib.perHost`, `den.lib.take.exactly`.
- Prefer den batteries when they match: `define-user`, `hostname`, `primary-user`, `host-aspects`, `user-shell`, WSL auto battery.

## Cross-entity delivery

- User's own environment: put includes in the user primary Aspect (`den.aspects.<user>.includes`).
- Primary user receiving host desktop/profile companion config: user explicitly includes `den.batteries.host-aspects`.
- Multi-user or conditional host-to-user delivery: use `provides.to-users` or `provides.<user>`.
- User-to-host delivery via `provides.to-hosts` is rare and only for user-specific host patches.
- Do not assume `host-aspects` is required for normal user includes to work.

## File and command safety

- Ask before modifying `flake.nix`, `flake.lock`, or `pkgs/*`.
- New `modules/**/*.nix` files must be `git add`ed before evaluation because `vic/import-tree` only scans tracked files.
- Use repo wrappers only:

```bash
just fmt
just check
just check-all
just build-vm <host>
just diff <host>
just repl
```

Never call raw `nix`, `nh`, or `nixos-rebuild` when a `just` wrapper exists.

## Review checklist

Before finalizing den changes, verify:

- Correct semantic type was chosen.
- Entity Kind and Class were not conflated.
- Physical path and `lossilk.*` path follow Modules Taxonomy.
- Includes DAG is explicit and debuggable.
- Cross-entity delivery path is intentional.
- No business config leaked into `den.default`.
- No new untracked Nix file is being missed by import-tree.
- Validation command matches change impact.

For doc/skill-only changes, run `git diff --check` and state that no Nix evaluation-impacting files changed.
