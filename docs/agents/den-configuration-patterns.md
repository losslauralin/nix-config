# Den Configuration Patterns — Agent Reference

> **Audience**: Planning/implementation agents configuring den-based NixOS features in `lossilk` namespace.
>
> **Prerequisites**: Must read `CONTEXT.md` (terminology) and `docs/frameworks/den.md` (baseline rules) first.
>
> **Scope**: Practical config patterns, validation checkpoints, common error prevention. No den internals.

## Pre-modification Checklist

Before any den semantic modification:

1. ✅ **Read governance docs**
   - `CONTEXT.md` — terminology, Modules Taxonomy, Cross-entity Delivery
   - `docs/frameworks/den.md` — baseline rules + 15-question checklist
   - `AGENTS.md` — command wrappers, file permissions, known pitfalls

2. ✅ **Verify tool availability** (Arch dev host may lack tools)
   ```bash
   command -v just nh nix
   ```

3. ✅ **Check untracked files** (import-tree only scans git-tracked)
   ```bash
   git status --short | grep '\.nix$'
   ```

4. ✅ **Confirm file permissions**
   - Requires confirmation: `flake.nix`, `flake.lock`, `pkgs/*`
   - Direct edit allowed: `modules/*`, `scripts/*`, `*.md`

## Common Configuration Patterns

### Pattern 1: Single-class Leaf (simplest)

For standalone feature in one class.

```nix
# modules/cli/example-tool.nix
{lossilk, ...}: {
  lossilk.cli._.example-tool.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.example-tool];
    programs.example-tool.enable = true;
  };
}
```

**When**: Only needs one class (`homeManager`), no dependencies, independent enable/disable.

**Usage**:
```nix
den.aspects.loss.includes = [ lossilk.cli._.example-tool ];
```

### Pattern 2: Multi-class Feature

Cross NixOS + Home Manager coordination.

```nix
# modules/desktop/apps/firefox.nix
{lossilk, ...}: {
  lossilk.desktop._.apps._.firefox = {
    nixos = {pkgs, ...}: {
      programs.firefox.enable = true;
      environment.systemPackages = [pkgs.firefox];
    };
    homeManager = {pkgs, ...}: {
      programs.firefox = {
        enable = true;
        profiles.default.search.default = "DuckDuckGo";
      };
    };
  };
}
```

**When**: Needs system + user config coordination, one feature spans multiple classes.

### Pattern 3: Family Root + Selection Variants

Provides alternative implementations.

```nix
# modules/cli/shell/default.nix (Family Root)
{lossilk, ...}: {
  lossilk.cli._.shell = {
    homeManager = {
      # Common invariants + base config
      programs.direnv.enable = true;
      programs.starship.enable = true;
    };
  };
}

# modules/cli/shell/fish.nix (Selection Variant)
{den, lossilk, ...}: {
  lossilk.cli._.shell._.fish = {
    includes = [
      lossilk.cli._.shell  # Family Root
      (den.provides.user-shell "fish")
    ];
    homeManager = {pkgs, ...}: {
      programs.fish = {
        enable = true;
        shellInit = "set -g fish_greeting";
      };
    };
  };
}

# modules/cli/shell/zsh.nix (Another Variant)
{den, lossilk, ...}: {
  lossilk.cli._.shell._.zsh = {
    includes = [
      lossilk.cli._.shell
      (den.provides.user-shell "zsh")
    ];
    homeManager.programs.zsh.enable = true;
  };
}
```

**When**: Same feature has multiple mutually-exclusive implementations (shell, editor, browser, etc.), user chooses one.

**Usage** (user picks one variant):
```nix
den.aspects.loss.includes = [ lossilk.cli._.shell._.fish ];  # or ._.zsh
```

### Pattern 4: Profile/Bundle (config composition)

Stable aspect composition, usually only `includes`.

```nix
# modules/desktop/niri-dms-desktop.nix
{lossilk, ...}: {
  lossilk.desktop._.niri-dms-desktop = {
    includes = with lossilk; [
      system
      nix
      networking
      audio
      desktop._.compositor._.niri
      desktop._.shell._.dms
      desktop._.terminals._.kitty
      desktop._.browsers._.chrome
    ];
    # Optional: profile-level coordination config
    homeManager = {lib, ...}: {
      home.sessionVariables.BROWSER = lib.mkDefault "google-chrome-stable";
    };
  };
}
```

**When**: Need fixed aspect set (full desktop environment), multiple hosts share same config set.

**Usage** (host opt-in):
```nix
den.aspects.nixos-niri-dms-vm = {
  includes = [
    lossilk.desktop._.niri-dms-desktop
    lossilk.virt._.vm
  ];
  nixos = _: {
    nixpkgs.hostPlatform = "x86_64-linux";
    # host-specific config
  };
};
```

### Pattern 5: Parametric Aspect (conditional activation)

Activation determined by context arg shape.

```nix
# Activates only in host context
lossilk.system._.hostname = {host, ...}: {
  nixos.networking.hostName = host.name;
};

# Activates only in {host, user} context (host→user fan-out)
lossilk.users._.groups = {host, user, ...}: {
  nixos.users.users.${user.name}.extraGroups = ["wheel" "video"];
};
```

**When**: Config needs entity properties (`host.name`, `user.name`, etc.), only makes sense in specific context.

**Key rules**:
- Arg shape = activation condition (no `mkIf` needed)
- `{host}` → host context only
- `{user}` → user context only
- `{host, user}` → host→user fan-out
- `{home}` → standalone home

### Pattern 6: Host Spec (host-specific config)

Bound to physical hardware or single-host scenario, not reusable.

```nix
# modules/hosts/mechrevo-nixos-dms-niri/default.nix
{inputs, ...}: {
  den.aspects.mechrevo-nixos-dms-niri = {
    includes = with lossilk; [
      desktop._.niri-dms-desktop  # Reuse profile
    ];
    nixos = _: {
      # Hardware-specific config
      imports = [
        ./_disko.nix  # _ prefix = import-tree skip
        inputs.nixos-hardware.nixosModules.common-cpu-intel
      ];
      hardware.facter.reportPath = ./facter.json;
      boot.loader.systemd-boot.enable = true;
      nixpkgs.hostPlatform = "x86_64-linux";
    };
    user.extraGroups = ["video" "input"];
  };
}
```

**When**: Single-line NixOS option toggle, only meaningful for one host, hardware/disk config.

**Decision criteria**:
- Multiple hosts need → Host opt-in (new aspect file)
- Single host specific → Host spec (inline in host nixos block)

## Cross-entity Config Delivery

### Method 1: User Self-declared (default, recommended)

User aspect `includes` auto-resolve in `{host, user}` context, produced `homeManager` class auto-wraps into host's NixOS config.

```nix
den.aspects.loss = {
  includes = [
    lossilk.cli._.shell._.fish
    lossilk.dev._.git
    lossilk.ai._.pi
  ];
  user.initialPassword = "password";
};
```

**When**: User's own tools + environment, doesn't depend on host choice.

**Mechanism**: Built-in `host-to-users` policy auto fan-out, `homeManager` class auto-wraps as `home-manager.users.<name>`.

### Method 2: host-aspects opt-in (primary user receives host preferences)

User explicitly includes `den.batteries.host-aspects` to receive `homeManager`/`hjem` from host aspect tree.

```nix
den.aspects.loss = {
  includes = [
    den.batteries.host-aspects  # Receive host's companion config
    # ... user's own includes ...
  ];
};
```

**When**: Primary user needs to follow host's desktop/profile choice, host aspect tree has `homeManager` class config.

**Don't use for**: Not all users need opt-in (don't put in `den.default`), user's own includes work anyway (don't depend on host-aspects).

### Method 3: Explicit provides delivery (multi-user or conditional)

Use `provides.to-users`, `provides.<user>`, `provides.to-hosts` for explicit cross-entity delivery.

```nix
# Host aspect delivers to all users
den.aspects.shared-tools = {
  provides.to-users = {user, ...}: {
    homeManager.programs.helix.enable = user.name == "alice";
  };
  # Deliver to specific user
  provides.alice.homeManager.programs.vim.enable = true;
};

# User delivers to host (rare)
den.aspects.alice = {
  provides.to-hosts = {host, ...}: {
    nixos.programs.nh.enable = host.name == "laptop";
  };
};
```

**When**: Multi-user scenario, conditional host→user delivery. **Not recommended**: `provides.to-hosts` only for pure user-specific host patches.

## File Organization Rules

### New File Placement Decision Tree

```
1. Determine semantic type
   ├─ Family Root → modules/<concern>/default.nix or <family>/default.nix
   ├─ Selection Variant → modules/<concern>/<family>/<variant>.nix
   ├─ Extension → modules/<concern>/<feature>/<extension>.nix
   ├─ Profile/Bundle → modules/<concern>/<name>-desktop.nix
   ├─ Integration Edge → modules/<concern>/<tool1>-<tool2>.nix
   ├─ Host opt-in → modules/<concern>/<feature>.nix
   └─ Host spec → inline in modules/hosts/<host>/default.nix

2. Determine primary concern
   ├─ CLI/shell/TUI → modules/cli/
   ├─ Editor/language/toolchain → modules/dev/
   ├─ Desktop/browser/terminal → modules/desktop/
   ├─ Network/SSH/VPN → modules/networking/
   ├─ Boot/FS/power → modules/system/
   ├─ VM/container/WSL → modules/virt/
   ├─ Secret/auth → modules/security/
   └─ AI tools → modules/ai/

3. Align aspect path with file path
   Physical: modules/<concern>/<feature>.nix
   Logical: lossilk.<concern>._.<feature>
```

### Reference Style Standard

**New files (unified attrpath style)**:
```nix
{lossilk, ...}: {
  lossilk.cli._.shell = { ... };
}
```

**Existing files (preserve angle brackets)**:
```nix
# modules/users/loss.nix uses legacy style
den.aspects.loss.includes = [
  <lossilk/cli/shell/fish>
];
```

**Forbidden**: New files using angle brackets `<lossilk/...>`, mixing styles.

## Validation Workflow

### Standard Validation Sequence (all den semantic changes)

```bash
# 1. Format
just fmt

# 2. Check evaluation
just check

# 3. Desktop/GUI changes need extra validation
just build-vm nixos-niri-dms-vm

# 4. Interactive test (optional)
just test-vm nixos-niri-dms-vm
```

### Quick Feedback (iterative dev)

```bash
just check-all  # fmt-check + check, no auto-fix
```

### Git Tracking Verification

```bash
# New files must be git-added before import-tree discovers them
git add modules/path/to/new-file.nix
just check
```

### Arch dev host tool wrapper

```bash
# If just/nh missing
nix shell nixpkgs#just nixpkgs#nh -c just check
```

## Common Error Prevention

### Error 1: New file not git-added (most severe)

**Symptom**: New aspect file added, config has no effect, `just check` still passes.

**Cause**: `vic/import-tree` only scans git-tracked files.

**Prevention**:
```bash
# Execute immediately after creating new file
git add modules/<path>.nix
just check
```

**Detection**:
```bash
git status --short | grep '??' | grep '\.nix$'
```

### Error 2: Context shape mismatch

**Symptom**: Aspect class modules not activated.

**Cause**: Parametric aspect requests context arg not in current scope.

**Example**:
```nix
# ❌ Wrong: requests {user} but activates in host-only context
den.aspects.broken = {user}: {
  nixos.programs.git.enable = true;  # Never activates
};

# ✅ Correct: host context requests {host}
den.aspects.working = {host}: {
  nixos.networking.hostName = host.name;
};
```

**Prevention**:
- Host-only config → `{host}: { nixos = ...; }`
- User-only config → `{user}: { homeManager = ...; }`
- Host→user config → `{host, user}: { homeManager = ...; }`

### Error 3: Class module missing `...`

**Symptom**: `function called with unexpected argument` error.

**Cause**: Flat-form class module entering Nix module system must accept extra args.

**Example**:
```nix
# ❌ Wrong: missing ...
{ nixos = {host, config, pkgs}: { ... }; }

# ✅ Correct: accepts extra args
{ nixos = {host, config, pkgs, ...}: { ... }; }
```

### Error 4: Module placement violates Taxonomy

**Symptom**: File hard to find/maintain.

**Cause**: Didn't follow `CONTEXT.md` Modules Taxonomy placement.

**Prevention**:
1. Determine primary function intent (not technical shape)
2. Consult Modules Taxonomy table
3. Place in corresponding `modules/<concern>/` dir

### Error 5: Misunderstanding cross-entity delivery

**Symptom**: User config not working, or host config polluted.

**Prevention**:
- User's own environment → user aspect `includes`
- Primary user receives host preferences → user includes `host-aspects`
- Multi-user conditional → explicit `provides.to-users`

### Error 6: den.default has business config

**Symptom**: All entities forced to enable some business feature.

**Prevention**:
- `den.default` only for framework defaults (stateVersion, allowUnfree, define-user, hostname)
- Business baseline → host opt-in
- `host-aspects` → user opt-in

### Error 7: Depending on `._` auto-collecting provides

**Symptom**: After including parent aspect, child aspects don't work.

**Cause**: `._` doesn't collect provides children, and is unpublished behavior.

**Prevention**:
- Explicitly include child aspects
- Or design meta-aspect to aggregate children

### Error 8: Modifying confirmation-required files

**Symptom**: Accidental changes to `flake.nix`, `flake.lock` or `pkgs/*`.

**Prevention**:
- Check `AGENTS.md` file permission list before modification
- Confirmation-required files → ask user

## Debugging Tips

### Check context scope

When aspect doesn't activate, first verify current context has your requested args:

```nix
# Needs {host} → available in host resolution
# Needs {user} → available in host-to-users fan-out
# Needs {host, user} → available in host-to-users fan-out
# Needs {home} → available in standalone home resolution
```

### REPL query

```bash
just repl
```

```nix
# Query host config
:p nixosConfigurations.nixos-niri-dms-vm.config.networking.hostName

# Query user home config
:p nixosConfigurations.nixos-niri-dms-vm.config.home-manager.users.loss.programs.fish.enable
```

### Verify aspect is included

Check if `den.aspects.<name>.includes` list contains target aspect.

## Quick Reference Card

**Must-do after new file**:
```bash
git add modules/<path>.nix && just check
```

**Validation sequence**:
```bash
just fmt && just check
# Desktop changes add:
just build-vm nixos-niri-dms-vm
```

**Confirmation-required files**:
- `flake.nix`, `flake.lock`, `pkgs/*` → ask first

**Command wrapper rule**:
- ❌ `nix flake check`
- ✅ `just check`

**Context arg patterns**:
```nix
{host}:           # Host-only
{user}:           # User-only
{host, user}:     # Host→user fan-out
{home}:           # Standalone home
```

**Reference style**:
- New files: `{lossilk, ...}: lossilk.x._.y`
- Existing files (preserve): `<lossilk/...>`

---

**This doc serves as practical reference, doesn't replace authoritative term definitions (see `CONTEXT.md`) and baseline rules (see `docs/frameworks/den.md`).**
