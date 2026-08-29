# NixOS Configuration Agent Guide

Personal NixOS + Home Manager config on **denful/den** + **flake-parts**.
Local namespace: **`lossilk`** (`modules/den/default.nix`).

- Placement terms and glossary: **`CONTEXT.md`**
- Den semantics: **upstream Den docs** (Entity / Aspect / Policy / Quirk). Do not invent a parallel local model.
- `docs/` is research only until verified against live `modules/` + evaluation.

## Hard Stop: Nix Store

- Never read, list, grep, open, search, evaluate, or inspect `/nix/store/**` (including flake input materializations like `/nix/store/...-source`).
- If a task requires that: stop, say the repo forbids it, wait for the user.
- If an agent already queried `/nix/store/**`, treat the session as invalid and interrupt.
- `rg`: always `--glob '!/nix/store/**'`; never use `/nix/store` as a search root.
- Packages / NixOS / HM options: `nh search packages <q>` or `nh search options [--scope=nixpkgs|home-manager|all] <q>` (search.nixos.org). Never infer from the store.

## Commands

- Prefer **`just`** over raw `nix` / `nh` / `nixos-rebuild` when a recipe exists (`just help`).
- After Nix / Den wiring changes: **`just check`**.
- Dev shell: `nix develop`.

## Editing Boundaries

Confirm before modifying: `flake.nix`, `flake.lock`, `pkgs/*`.

Direct OK: `modules/*`, `scripts/*`, `*.md`.

## Placement (this repo)

| What | Where |
|------|--------|
| Hardware, disk, VM, WSL, one-off host facts | **Host spec** (`modules/hosts/<name>/`) |
| Reusable capability | **Capability aspect** under `modules/` shelves |
| Multi-capability supported route | **Glue aspect** (e.g. `niri-dms-desktop`) |
| Cross-host personal env | **User** aspect (`modules/users/loss.nix`) |

- `modules/` directory names are **mutable shelves**, not ownership or namespace contracts.
- Do **not** reorganize toward upstream demo layouts like `modules/aspects/...`.
- Supported desktop route: **`lossilk.desktop._.niri-dms-desktop`** only. Not a free compositor/shell matrix; `noctalia` etc. are unsupported candidates.

## Den wiring (must not silent-fail)

- **Entity** = what exists (host/user). **Aspect** = behavior. **Policy** = topology. **Quirk/Pipe** = structured data (prefer class modules + `den.schema` first).
- **`includes`** = Den aspect composition, **not** Nix `imports`.
- **Host aspect / user aspect** are not separate types: same aspect model, opened under different entity roots and contexts (`{ host }` vs `{ host, user }`).
- **Class** chooses the module system: typically **host walk → `nixos`**, **user walk → `homeManager`** (and other `user.classes`).
- **OS / privileged / machine-global** contributions → host includes (or host glue). **Home / user-session** → user includes.
- Mixed aspects (`nixos` + `homeManager` in one capability): put the capability on the **host** when the OS half is needed; HM half reaches the user via user includes **or** opt-in projection—not by assuming auto-merge.
- **`den.batteries.host-aspects`**: user **opt-in** only (see `modules/users/loss.nix`). Projects `user.classes` (e.g. `homeManager`) from the **current host’s aspect tree**. Not enabled in `den.default`. Do not rely on “`({ user }: …)` on the host tree auto-applies to users without the battery” (that path is accidental/leaky, not API).
- Prefer **host includes capability + user `host-aspects`** over double-including the same mixed aspect on both host and user.
- Classify by **scope + privilege + which eval root must see it**, not by “whether a fancy `services.*` option exists”. Pure user tools often only need `homeManager` / `home.packages`.

## Pitfalls

- New `modules/**/*.nix` files must be **`git add`ed** before evaluation; **import-tree** only scans git-tracked files.
- Skills for concrete workflows: `.agents/skills/add-aspect`, `.agents/skills/pkgs-by-name-package`.
