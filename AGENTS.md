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
- Do not broad-scan `/nix/store`. Prefer repo files, official upstream docs, or exact known store/source paths.
- Do not move the repo toward upstream example layouts like `modules/aspects/...` just because Den examples use them.
