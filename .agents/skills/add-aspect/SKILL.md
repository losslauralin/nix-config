---
name: add-aspect
description: Add lossilk aspects in this Den Nix config. Use when creating a modules/**/*.nix aspect, wiring an existing aspect into a host/user include list, or adding a package-backed capability aspect.
---

# Add Aspect

Add or wire one Den aspect by copying the nearest local pattern. Keep the edit narrow, never use `/nix/store/**` as evidence, and track new `modules/**/*.nix` files before any import-tree-dependent command.

## Branches

- **Wire existing aspect**: edit only the minimal include site.
- **Create aspect**: add or edit one aspect file plus the minimal include site.
- **Package-backed capability**: wire a package into an aspect; direct `pkgs/*`, `flake.nix`, or `flake.lock` edits still require explicit confirmation as described in `AGENTS.md`.

## Steps

1. Read the local pattern.

   Read `AGENTS.md`, `CONTEXT.md`, the nearest existing aspect module, and the nearest include site. Every search command includes `--glob '!/nix/store/**'`.

   Completion: you can name the copied pattern, target aspect path, include style, and include site; no command has read, listed, grepped, opened, evaluated, or inspected `/nix/store/**`.

2. Choose the route.

   Decide which branch applies: wire existing, create aspect, or package-backed capability. Choose the target attrpath and file path from the nearest local namespace style, not memory.

   Completion: the planned attrpath, file path if any, include expression, and validation command are fixed before editing.

3. Verify package and option facts when needed.

   Use user-provided facts or `nh search`: `nh search packages <query>` for packages, and `nh search options [--scope=<SCOPE>] <query>` for NixOS/Home Manager options where scope is `nixpkgs`, `home-manager`, or `all`.

   Completion: either no package or option fact is needed, or every package/option claim came from the user or `nh search`; unresolved facts are turned into a user question instead of a guess.

4. Edit narrowly.

   Add or edit only the aspect and the minimal include site. Treat an aspect as an attrset of class modules. Use `includes` for Den aspect composition. Use angle-bracket includes only where the target include site already uses that style. Prefer ordinary class modules and `den.schema`; do not introduce quirks, pipes, or fleet patterns unless the user explicitly asked for that design.

   Completion: the diff contains no unrelated refactor, no preference-only movement, no invented namespace style, and no Den `includes` confused with Nix module `imports`.

5. Track new aspect files before evaluation.

   If a new `modules/**/*.nix` file was created, run `git add <file>` before any Nix evaluation, flake-backed formatting, `just check`, or other import-tree-dependent command.

   Completion: `git status --short` shows each new `modules/**/*.nix` file as tracked (`A`), not untracked (`??`).

6. Format and validate.

   Use repo recipes. Prefer `just fmt <changed-files>` for formatting. Run `just check` when the change affects Nix evaluation or Den wiring, and use targeted host builds when the change is host-specific.

   Completion: validation passed, or the exact failing command and failure are reported without using `/nix/store/**` as evidence.

## Stop Rules

- If you are about to query `/nix/store/**`, stop immediately, report the attempted action, and wait for user direction.
- If you already queried `/nix/store/**`, interrupt the session as invalid instead of continuing from that evidence.
- If a new `modules/**/*.nix` file is still untracked and you are about to evaluate or run flake-backed tooling, stop and `git add` it first.
- If package or option lookup cannot be answered by `nh search` or the user, ask rather than guessing.
- If the work requires `flake.nix`, `flake.lock`, or `pkgs/*`, get explicit confirmation before editing.
