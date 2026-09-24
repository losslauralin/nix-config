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

### Never run interactive or privileged commands from an agent session

Agent sessions have no tty. Anything that prompts — for a password, a
confirmation, a pager, or a selection — will hang or fail, and a failed
activation can leave the machine mid-switch.

- Do **not** run `just os-switch` (or `nh os switch` / `nixos-rebuild switch`).
  It calls `sudo` and cannot authenticate without a tty. Hand the command to
  the user to run in their own terminal instead.
- Do **not** run `sudo` directly, and do not try to work around the prompt
  (`sudo -S` with a piped password, `--ask`, an askpass helper, `script`/`expect`).
- Any other command that may prompt is the user's to run. Verify with
  read-only commands and evaluation only.
- Builds and checks are fine when they do not activate: `just check`, `just
  os-build`, `nix build`. Prefer those — they catch the same class of errors
  before anything touches the live system.

If a change needs activation to take effect, say so and stop. The user runs
`just os-switch` in their own terminal; the agent waits for the result.

## Editing Boundaries

Confirm before modifying: `flake.nix`, `flake.lock`, `pkgs/*`.

Direct OK: `modules/*`, `scripts/*`, `*.md`.

### Stop when the work is unrelated to the current workspace

The working tree usually holds the user's own in-flight edits. Do not pile
unrelated work on top of it.

Stop and ask the user to open a new herdr worktree when the task is **not
about** the changes already in the tree — for example a separate feature,
fix, or experiment that the current dirty files do not depend on.

Say so before editing anything, and name the reason: the work is unrelated to
what is already in this workspace. Point at the keybind, not a command line —
the user drives herdr from its TUI, and herdr creates the worktree, opens it
as a workspace, and focuses it in one step.

```
This task is unrelated to what is already in this workspace. It belongs in a
new herdr worktree — press `prefix+shift+g` (new worktree), then re-run the
request there.
```

Continue in the current workspace only when:

- The task is a direct follow-up to the edits already present, or
- The user explicitly says to work in this workspace anyway.

Scope every commit with explicit paths, never `git add -A` / `git add .`, so a
neighbouring uncommitted change cannot be swept in. Never report, review, or
comment on files outside the requested scope; the dirty tree is not a to-do
list.

`just os-switch` works from a worktree (recipes resolve against `$PWD`), but
update `flake.lock` only in the main checkout, or the branches will conflict.

## Placement (this repo)

| What | Where |
|------|--------|
| Hardware, disk, VM, WSL, one-off host facts | **Host spec** (`modules/hosts/<name>/`) |
| Reusable capability | **Capability aspect** under `modules/` shelves |
| Multi-capability supported route | **Glue aspect** (e.g. `umbriel-noctalia-desktop`) |
| Cross-host personal env | **User** aspect (`modules/users/loss.nix`) |

- `modules/` directory names are **mutable shelves**, not ownership or namespace contracts.
- Do **not** reorganize toward upstream demo layouts like `modules/aspects/...`.
- Supported desktop route: **`lossilk.desktop._.umbriel-noctalia-desktop`** only (Umbriel + Noctalia shell + Noctalia Greeter). Not a free compositor/shell matrix.

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

## Host Specs And Capabilities

- A host spec declares **facts**; a capability **aspect** owns behaviour. Never hard-bind one to the other.
- Machine facts — disk paths, mount points, device nodes, hardware quirks — must not appear in `modules/**` capability aspects: not as defaults, not inside wrapper scripts, not even in comments. The aspect knows its own contract (e.g. `~/Music`), never the machine.
- Host specs write values only. If a host file contains an `if`, an activation, or glue for one named capability, that logic is in the wrong layer.
- Facts go on the entity as free-form host metadata: `den.hosts.<system>.<host>.<fact> = …`. `den.schema.host.<fact> = value` is **not** “this host” — den defines `den.schema.<kind>` as base modules holding *shared meta-data between all hosts*.
- A capability reads facts through the injected `host` context and keeps its own default (`host.storage.music or null`). Fact absent ⇒ no wiring, not an error.
- Two checks before writing either side: remove the capability from the host’s `includes` — does the host file still stand alone? Remove the host’s fact — does the aspect still have a sane default?
- Wrapping a package (`writeShellScriptBin`) to inject a machine path is a smell: the path belongs in another layer.

## Verification Order

Cheapest authoritative source first; source code last.

1. **Docs and option metadata**: den docs, `nh search options` / `nh search packages`, upstream README and man pages. If these answer, stop here.
2. **Ask the user** when the question is about intent, preference, or a local fact they already hold.
3. **Probes**, isolated only: `nix eval`, or a copy/scratch directory. A probe answers an unanswered factual question; it is not a debugging loop, and it must never be the first resort for something documentation already states.
4. **Upstream source** (`*.go`, `*.vala`, Nix modules) only when nothing above answers — reading source is expensive and easy to misread.

- Never run a build-time-interpolated script inside the real home directory. `HOME=…` does not isolate a path that Nix expanded at build time, and running it *is* a change to the user’s machine (evaluate with a substituted `homeDirectory`, or work in a copy).

## Pitfalls

- New `modules/**/*.nix` files must be **`git add`ed** before evaluation; **import-tree** only scans git-tracked files.
- Skills for concrete workflows: `.agents/skills/add-aspect`, `.agents/skills/pkgs-by-name-package`, `.agents/skills/noctalia-terminal-theming`, `.agents/skills/commit-conventions`.
