---
name: pkgs-by-name-package
description: Pkgs-by-name package flow for this nix-config. Use when adding or repackaging a local package under pkgs/by-name, exposing a package through this flake, or wiring inputs.self.packages.${system}.<name> into a Den aspect.
---

# Pkgs-By-Name Package

Purpose: add one repo-local package through `pkgs/by-name` and consume it without hiding packaging logic inside Den aspects.

## Steps

1. Establish the local pattern before editing: read `AGENTS.md`, `modules/flake-parts/nixpkgs.nix`, and the nearest package example such as `pkgs/by-name/rime-wanxiang/package.nix` or `pkgs/by-name/gf/package.nix`. Every `rg` command includes `--glob '!/nix/store/**'`. Completion: the user has explicitly asked for or approved `pkgs/*` edits, and the package path/style is copied from a repo-local example.

2. Source package facts from the user, upstream release/source files, or `nh search packages <query>`. Do not use `/nix/store/**` as evidence for version, source layout, installed paths, package options, or module behavior. Completion: every package fact in the implementation came from the user, upstream, `nh search`, or repo files.

3. Add the package at `pkgs/by-name/<name>/package.nix`. Keep the package derivation the single source of truth for fetches, unpacking, install layout, local repackaging deltas, `passthru.updateScript`, and `meta`. Use `finalAttrs` when `version` is reused in `src` or `meta`; use `stdenvNoCC` for data-only packages; install data under the path the consumer actually reads, such as `$out/share/...`. Completion: no Den aspect or module contains ad hoc derivation logic for this package.

4. Stage new package files before any flake-backed formatting, build, or package-scan-dependent command. Run `git add pkgs/by-name/<name>/package.nix` as its own completed step. Completion: `git status --short` shows the new package tracked.

5. Wire consumers thinly, as a **new aspect file** (`modules/<shelf>/<name>.nix`), following `modules/desktop/input/fcitx5-rime-wanxiang.nix`: bind `inputs` in the **outer** aspect function, then reference `inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.<name>` from inside the class module, and put that package into the relevant NixOS or Home Manager option.

   `inputs` must come from the outer function. Den's class modules (`homeManager = {pkgs, ...}:`, `nixos = {pkgs, ...}:`) inject only `pkgs`/`lib`/config args — **not** `inputs`. Putting `inputs` in a class module's signature fails evaluation with ``error: attribute 'inputs' missing``. A `let` inside the class module does not grant access either — it works in `fcitx5-rime-wanxiang.nix` only because `inputs` is already bound by the enclosing aspect function and captured by closure. The `let` there binds a *derived* value, not `inputs` itself.

   Do not assume `pkgs.<name>` is the local package unless the local file already demonstrates that exact pattern; `inputs.self.packages.…` keeps it explicit that this is a repo-local package rather than a nixpkgs one.

   Leave the host/user include list to the user (see Parallel Work in `.agents/skills/add-aspect`). Completion: the consumer diff contains only wiring and configuration, not packaging or source-layout fixes; the evaluated configuration actually contains the package.

6. Format and validate with repo recipes: run `just fmt <changed files>`, `NO_NOM=1 just build .#<name>`, and `NO_NOM=1 just check` when the package is wired into configurations. Completion: validation passed, or the exact external failure is reported separately from package behavior.

## Reference

- Local packages are exposed by `pkgs-by-name-for-flake-parts` from `pkgsDirectory = ../../pkgs/by-name` in `modules/flake-parts/nixpkgs.nix`.
- The repo's current local layout is `pkgs/by-name/<name>/package.nix`.
- Local package consumers in modules should prefer `inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.<name>`, matching `modules/desktop/input/fcitx5-rime-wanxiang.nix` and `modules/hacking/default.nix`.
- Verify wiring by evaluating, not by reading the file: `nix eval --raw '.#nixosConfigurations.<host>.config.home-manager.users.<user>.home.packages' --apply 'ps: builtins.concatStringsSep "\n" (map (p: p.pname or p.name) ps)'` and grep for the package name. Compare its `outPath` against `.#packages.<system>.<name>` to prove it resolves to the local derivation. Aspects are only *defined* when the file is imported by import-tree; they take effect solely via an include, so an unreferenced host is expected not to contain the package.
- If a mirror or certificate failure blocks validation, fix Nix substituter/CA configuration or report it. Do not change package code to work around a transport failure.
- Repackaging a release binary (no Nix expression upstream): prefer an unpackable artifact over an AppImage. A `.deb`/`.rpm`/`.tar.gz` unpacks with plain tools and yields binaries that link system libraries, so `autoPatchelfHook` can rewrite the interpreter and rpath. An AppImage needs FUSE and an FHS-like layout that NixOS does not provide, and Tauri/Electron AppImages still expect the host to supply `libwebkit2gtk-4.1.so.0`/GTK at standard paths — `appimage-run` alone will not save it. Read the real dependencies from the artifact (`readelf -d <binary>`) and map each `NEEDED` to a `buildInputs` entry; do not guess the library set. Set `meta.sourceProvenance = [lib.sourceTypes.binaryNativeCode]`. Ship any co-installed helper binaries the app shells out to, not just the main executable.

## Stop Rules

- If you are about to inspect `/nix/store/**` for package facts or installed contents, stop and ask for direction.
- If the requested package requires editing `flake.nix`, `flake.lock`, or broader `pkgs/*` infrastructure, ask for explicit confirmation before editing those files.