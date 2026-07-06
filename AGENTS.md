# NixOS Configuration Agent Guide

This repo is a `denful/den` + `flake-parts` NixOS configuration. Project terminology and ownership routing live in `CONTEXT-MAP.md`; Den's own concepts remain the semantic authority.

Local namespace: `lossilk` in `modules/den.nix`.

## Read First

- For project language and placement decisions, read `CONTEXT-MAP.md`.
- For Den semantics, use upstream Den docs first, especially core principles. Do not invent local replacements for Den's Entity / Aspect / Policy / Quirk model.
- Treat `docs/` as research/reference unless a claim is verified against current code.

## Commands

- Use `just` recipes instead of raw `nix`, `nh`, or `nixos-rebuild` commands when a recipe exists.
- Use `just help` to discover the current command surface.
- Use `just check` after changes that affect Nix evaluation or Den wiring.
- Use `nix develop` for the normal local maintenance shell.
- When using `rg`, always include `--glob '!/nix/store/**'`. Never pass `/nix/store` as an `rg` root or include it through another glob.
- When searching Nixpkgs packages or NixOS/Home Manager options, use `nh search packages <query>` or `nh search options [--scope=<SCOPE>] <query>` (`--scope`: `nixpkgs`, `home-manager`, `all`). These commands search via search.nixos.org; never use information from `/nix/store/**` for package or option lookup.

## Editing Boundaries

Requires explicit confirmation before modification:

- `flake.nix`
- `flake.lock`
- `pkgs/*`

Direct modification is allowed:

- `modules/*`
- `scripts/*`
- `*.md`

## Den Rules

- Entity declares what exists; Aspect declares behavior; Policy declares topology; Quirk/Pipe shares structured data.
- `includes` is Den aspect composition, not a Nix module import.
- Most `modules/` directory names are mutable category shelves, not bounded contexts or namespace contracts.
- Host-specific hardware, disk, VM, WSL, and one-off scenario details stay in host specs.
- Reusable behavior belongs in capability aspects; route-specific coordination belongs in ordinary glue aspects.
- `niri-dms-desktop` is a supported route glue aspect, not proof that desktop components are freely swappable.

## Pitfalls

- New `modules/**/*.nix` files must be `git add`ed before evaluation; import-tree only scans git-tracked files.
- Absolute `/nix/store/**` boundary: do not read, list, grep, open, search, evaluate, inspect, or otherwise query any data under `/nix/store/**`, in any scenario. This includes exact known store paths, package sources, module sources, docs, generated files, and debugging shortcuts.
- If an agent is about to query `/nix/store/**`, treat that as a hallucination-risk event: stop immediately, report the attempted action, and wait for user direction. If an agent already queried `/nix/store/**`, the session is considered invalid and must be interrupted.
- Do not move the repo toward upstream example layouts like `modules/aspects/...` just because Den examples use them.
