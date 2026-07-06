---
name: pkgs-by-name-package
description: Pkgs-by-name package flow for this nix-config. Use when adding or repackaging a local package under pkgs/by-name, exposing a package through this flake, or wiring inputs.self.packages.${system}.<name> into a Den aspect.
---

# Pkgs-By-Name Package

Purpose: add one repo-local package through `pkgs/by-name` and consume it without hiding packaging logic inside Den aspects.

## Steps

1. Establish the local pattern before editing: read `AGENTS.md`, `modules/flake-parts/nixpkgs.nix`, and the nearest package example such as `pkgs/by-name/karing/package.nix` or `pkgs/by-name/gf/package.nix`. Every `rg` command includes `--glob '!/nix/store/**'`. Completion: the user has explicitly asked for or approved `pkgs/*` edits, and the package path/style is copied from a repo-local example.

2. Source package facts from the user, upstream release/source files, or `nh search packages <query>`. Do not use `/nix/store/**` as evidence for version, source layout, installed paths, package options, or module behavior. Completion: every package fact in the implementation came from the user, upstream, `nh search`, or repo files.

3. Add the package at `pkgs/by-name/<name>/package.nix`. Keep the package derivation the single source of truth for fetches, unpacking, install layout, local repackaging deltas, `passthru.updateScript`, and `meta`. Use `finalAttrs` when `version` is reused in `src` or `meta`; use `stdenvNoCC` for data-only packages; install data under the path the consumer actually reads, such as `$out/share/...`. Completion: no Den aspect or module contains ad hoc derivation logic for this package.

4. Stage new package files before any flake-backed formatting, build, or package-scan-dependent command. Run `git add pkgs/by-name/<name>/package.nix` as its own completed step. Completion: `git status --short` shows the new package tracked.

5. Wire consumers thinly. When a Den aspect needs the repo-local package, follow the `karing` pattern: accept `inputs`, derive `inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.<name>` in a `let`, and put that package into the relevant NixOS or Home Manager option. Do not assume `pkgs.<name>` is the local package unless the local file already demonstrates that exact pattern. Completion: the consumer diff contains only wiring and configuration, not packaging or source-layout fixes.

6. Format and validate with repo recipes: run `just fmt <changed files>`, `NO_NOM=1 just build .#<name>`, and `NO_NOM=1 just check` when the package is wired into configurations. Completion: validation passed, or the exact external failure is reported separately from package behavior.

## Reference

- Local packages are exposed by `pkgs-by-name-for-flake-parts` from `pkgsDirectory = ../../pkgs/by-name` in `modules/flake-parts/nixpkgs.nix`.
- The repo's current local layout is `pkgs/by-name/<name>/package.nix`.
- Local package consumers in modules should prefer `inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.<name>`, matching `modules/networking/karing.nix`.
- If a mirror or certificate failure blocks validation, fix Nix substituter/CA configuration or report it. Do not change package code to work around a transport failure.

## Stop Rules

- If you are about to inspect `/nix/store/**` for package facts or installed contents, stop and ask for direction.
- If the requested package requires editing `flake.nix`, `flake.lock`, or broader `pkgs/*` infrastructure, ask for explicit confirmation before editing those files.