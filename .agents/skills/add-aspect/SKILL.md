---
name: add-aspect
description: Add-aspect flow for this Den Nix config. Use when creating or wiring a lossilk aspect, adding a modules/**/*.nix aspect file, or adding a package-backed capability such as an editor/tool to a user or host.
---

# Add Aspect

Purpose: add or wire one Den aspect without using `/nix/store/**` as evidence or losing new aspect files to import-tree.

## Steps

1. Establish the local pattern from repo files only: read `AGENTS.md`, `CONTEXT-MAP.md`, and the nearest existing aspect module. Every `rg` command includes `--glob '!/nix/store/**'`. Completion: no command has read, listed, grepped, opened, evaluated, or inspected `/nix/store/**`.

2. Choose the target aspect path and include site from existing local namespace style. Completion: the planned path and include expression are both copied from a nearby pattern, not invented from memory.

3. Look up package or option facts only through `nh search`: use `nh search packages <query>` for packages and `nh search options [--scope=<SCOPE>] <query>` for NixOS/Home Manager options, where `--scope` is `nixpkgs`, `home-manager`, or `all`. Completion: every package/option claim came from `nh search` or from the user, never from `/nix/store/**`.

4. Add or edit only the aspect and the minimal include site. Use `includes` for Den composition, and use angle-bracket includes only where the target file already uses that style. Completion: the diff contains no unrelated refactor or preference change.

5. If a new `modules/**/*.nix` aspect file was created, run `git add <file>` before any Nix evaluation, flake-backed formatting, or import-tree-dependent command. Run `git add` as its own completed step. Completion: `git status --short` shows the new module tracked.

6. After new files are tracked, format and validate with repo recipes. Completion: validation has passed, or the exact failure is reported without using `/nix/store/**` as evidence.

## Stop Rules

- If you are about to query `/nix/store/**`, stop immediately, report the attempted action, and wait for user direction.
- If you already queried `/nix/store/**`, interrupt the session as invalid instead of continuing from that evidence.
- If package or option lookup cannot be answered by `nh search` or the user, ask rather than guessing from local store contents.
