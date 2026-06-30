# Adding / Modifying Feature Aspects Guide

> Mechanical flow for agents. Read `CONTEXT.md` and `docs/frameworks/den.md` first.
> Upstream semantics authority: local `~/workspace/nix-ref/den/docs/src/content/docs/guides/configure-aspects.mdx`, `guides/mutual.mdx`.
>
> **See also**: `den-configuration-patterns.md` — practical patterns, validation checkpoints, error prevention quick reference.

## 0. Establish Den Mental Model

Den is NOT traditional "host imports modules" model.

- **Entity** declares what exists: host, user, home.
- **Aspect** declares what it does: attrset containing different Nix **Class** owned configs.
- **Owned config** is class-named ordinary Nix module: `nixos`, `homeManager`, `darwin`, `user`, `wsl`, etc.
- **includes** declares aspect DAG dependencies, NOT Nix `imports`.
- **provides** declares named sub-aspects; special `provides.to-users` / `to-hosts` do cross-entity delivery.
- **den.default** auto-applies to all entities, only for framework defaults, NOT business features.

Example:

```nix
{
  lossilk.desktop._.example = {
    nixos.services.example.enable = true;
    homeManager.programs.example.enable = true;
  };
}
```

This aspect has two owned configs. Host directly receives `nixos`; user directly receives `homeManager`; how they cross-entity arrives determined by pipeline / `host-aspects` / `provides`.

## 1. Distinguish Two Function Arg Types

### Den context function (aspect/root level)

For context-based activation. Args can only request values existing in Den pipeline: `host`, `user`, `home`, `class`, `aspect-chain`.

```nix
lossilk.gaming._.min = {host, ...}: {
  nixos = {pkgs, ...}: {
    # host accessible here from outer closure
  };
};
```

If root function writes `{pkgs, ...}:`, Den treats `pkgs` as context arg, not Nix module arg. Most contexts lack `pkgs`, aspect won't match or gets skipped.

### Nix module function (inside class block)

For NixOS/Home Manager module args, must include `...`:

```nix
lossilk.cli._.tool.homeManager = {pkgs, lib, ...}: {
  home.packages = [pkgs.tool];
};
```

## 2. Determine Semantic Type

| Need | Type | Action |
|---|---|---|
| Single host hardware/one-off config | Host spec | Write into `modules/hosts/<host>/default.nix` `nixos` block, don't create aspect |
| Normal reusable feature | Leaf Aspect | Create/modify `modules/<concern>/<name>.nix` |
| Same selection axis candidates (shell/compositor) | Selection Variant | Sub-aspect includes family root + necessary battery |
| Add capability to family/leaf | Extension | Sub-aspect, can be included independently |
| Stable combination/route table | Profile / Bundle | Usually only writes `includes`, doesn't own leaf impl |
| Glue between two concerns | Integration Edge | Only owns wiring config, not both endpoints' impl |
| Small tool without custom config | Aggregate item | Put into existing aggregate (e.g. `cli/utils.nix`, `dev/extras.nix`) |

Check den batteries first: if upstream has battery, prefer including battery.

## 3. Choose Path & Aspect Path

Choose concern by primary function intent, NOT by daemon/GUI/systemd technical shape.

| Concern | Path | Aspect path |
|---|---|---|
| CLI / shell / TUI | `modules/cli/` | `lossilk.cli._.*` |
| Dev tools / editors / languages / git | `modules/dev/` | `lossilk.dev._.*` |
| Desktop session / compositor / shell / browser / terminal / appearance | `modules/desktop/` | `lossilk.desktop._.*` |
| Network / SSH / VPN / firewall | `modules/networking/` | `lossilk.networking._.*` |
| OS substrate / boot / fs / power / peripherals | `modules/system/` | `lossilk.system._.*` |
| Virtualization / containers / WSL | `modules/virt/` | `lossilk.virt._.*` |
| Security / secrets / auth | `modules/security/` | `lossilk.security._.*` |
| AI tools | `modules/ai/` | `lossilk.ai._.*` |

Rules:

- New files use attrpath style: `{lossilk, ...}:` + `lossilk.x._.y`.
- Don't use `<lossilk/...>` in new files, angle brackets only preserved in existing files.
- File path and aspect path must fall in same primary concern.
- Don't create empty namespace roots; root only exists when owning shared behavior or Profile / Bundle.
- Including parent aspect doesn't auto-enable children; explicitly include when needing children.

## 4. Write Owned Configs

### T1: Single-class leaf

```nix
# modules/cli/example.nix
{
  lossilk.cli._.example.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.example];
    programs.example.enable = true;
  };
}
```

### T2: Multi-class feature

```nix
# modules/desktop/apps/example.nix
{
  lossilk.desktop._.example = {
    nixos.services.example.enable = true;

    homeManager = {pkgs, ...}: {
      home.packages = [pkgs.example-client];
    };
  };
}
```

### T3: Parametric aspect

```nix
# Only activates when user context exists
{
  lossilk.ai._.example = {user}: {
    nixos = _: {
      users.users.${user.name}.extraGroups = ["example"];
    };
  };
}
```

Don't put `pkgs`, `config`, `lib` in aspect root function; they belong to class modules.

### T4: Selection Variant

```nix
# modules/cli/shell/example.nix
{
  den,
  lossilk,
  ...
}: {
  lossilk.cli._.shell._.example = {
    includes = [
      lossilk.cli._.shell
      (den.provides.user-shell "example")
    ];

    homeManager.programs.example.enable = true;
  };
}
```

### T5: Profile / Bundle

```nix
# modules/desktop/example-desktop.nix
{lossilk, ...}: {
  lossilk.desktop._.example-desktop.includes = with lossilk; [
    system
    networking
    desktop._.compositor._.example
    desktop._.terminals._.kitty
  ];
}
```

Profile / Bundle only owns stable choices, NOT unrelated leaf implementation.

## 5. Decide Wiring Location

| Scenario | Wiring |
|---|---|
| User's own general environment (shell/dev/AI/dotfiles) | `modules/users/loss.nix` `den.aspects.loss.includes` |
| Host selects system/desktop profile | `modules/hosts/<host>/default.nix` or profile's `includes` |
| Feature internal dependencies | feature's own `includes` |
| Host delivers companion config to all/some users | `provides.to-users` / `provides.<user>` |
| User delivers patches to its host | `provides.to-hosts` / `provides.<host>`, only for user-specific host patches |
| Primary user receives user classes from host aspect tree | user includes `den.batteries.host-aspects` |

### Cross-entity rules

- `loss.includes` doesn't depend on `host-aspects`. It's resolved by built-in `host-to-users` policy in `{host, user}` context.
- `host-aspects` means user opts-in to receive `homeManager`/`hjem` etc user classes from host aspect tree.
- For multi-user or complex conditions, prefer explicit `provides.to-users` / `provides.<user>`.
- `provides.to-hosts` only for user-specific host patches; don't write general host config.

## 6. New Files Must be git-added

`vic/import-tree` only scans git-tracked Nix files. After adding `modules/**/*.nix` immediately:

```bash
git add modules/<path>.nix
```

Without add, file not evaluated, `just check` may still pass.

## 7. Validation

Must use repo just wrappers:

```bash
just fmt
just check
```

For host/desktop changes also run:

```bash
just build-vm nixos-niri-dms-vm
```

Also do targeted eval / repl. `just check` only proves evaluable, NOT proves behavior in final config.

Example:

```bash
printf '%s\n' \
  ':p nixosConfigurations."nixos-niri-dms-vm".config."home-manager".users.loss.programs.kitty.enable' \
  ':q' | just repl
```

## Common Errors

| Symptom | Cause | Fix |
|---|---|---|
| New file has no effect, check still passes | Not `git add`ed | `git add` then re-run |
| `undefined variable 'lossilk'` | File args not declared | `{lossilk, ...}:` |
| `undefined variable '__findFile'` | New file used angle brackets | Change to attrpath style |
| `function called with unexpected argument` | class module args missing `...` | `{pkgs, ...}:` |
| Aspect skipped | root function requests arg current context lacks | Check `{host}` / `{host, user}` / `{user}` |
| user includes not working | Mistakenly thinks depends on host-aspects, or not wired to user aspect | Check `den.aspects.loss.includes` and host user entity declaration |
| Host-selected HM companion doesn't reach user | User didn't opt-in `den.batteries.host-aspects`, or needs explicit provides | Add host-aspects to user includes, or write `provides.to-users` |
| After including parent aspect, children don't work | Children not auto-emitted | Explicitly include children or build meta-aspect |

## Red Lines

Must ask user before modifying:

- `flake.nix`
- `flake.lock`
- `pkgs/*`

Don't commit unless user explicitly requests.
