---
name: noctalia-terminal-theming
description: Theme terminals through Noctalia in this nix-config. Use when a terminal's colors (background/foreground/16 colors) are wrong, or when the desktop appearance theme and terminal colors disagree.
---

# Noctalia Terminal Theming

Purpose: make terminal colors a single source of truth, driven by Noctalia's runtime theme, instead of hardcoding palette hex values inside a terminal aspect.

This repo's desktop route is `lossilk.desktop._.umbriel-noctalia-desktop`. The shell half is `lossilk.desktop._.shell._.noctalia`. Terminals in the route: `foot` (default, `TERMINAL=foot`), plus `kitty`/`ghostty`/`wezterm` aspects.

## Mental model (read before editing)

- **Noctalia is declarative-default + GUI-overridable.** `programs.noctalia.settings` renders `~/.config/noctalia/config.toml`, but that is only the *initial default*. The user can override the live theme in the Noctalia GUI, so the running theme can disagree with the repo. Never treat the repo's `theme.mode` as the current runtime state.
- **Terminals do not follow the shell's GUI theme automatically.** A GUI theme change affects Noctalia's own UI only. Terminal colors must be delivered separately.
- **`foot` cannot hot-reload config.** It supports OSC color sequences (`\033]11;...` background, `\033]10;...` foreground, `\033]4;N;...` the 16 colors) but not live config reload. This is exactly why Noctalia uses terminal sequences.
- **The correct mechanism is Noctalia's `terminal-sequences` template**, not a hand-written palette and not a second themer. See https://docs.noctalia.dev/noctalia/templates/community/terminal-templates/
- **catppuccin/nix is a competing themer.** `catppuccin.autoEnable = true` (in `modules/desktop/appearance/catppuccin.nix`) injects static colors into every enabled program, including terminals. That is a *second* color source and it will fight the Noctalia template.

## Steps

1. Diagnose the actual color source before editing.

   Read `AGENTS.md`, the route glue `modules/desktop/umbriel-noctalia-desktop.nix`, the shell aspect `modules/desktop/shell/noctalia.nix`, the terminal aspect `modules/desktop/terminals/<term>.nix`, and `modules/desktop/appearance/catppuccin.nix`. Every `rg` includes `--glob '!/nix/store/**'`. Confirm whether the terminal gets colors from catppuccin, from a static aspect palette, or from nothing.

   Completion: you can name which mechanism currently sets the terminal's background, and you have asked the user what they observe at runtime (declarative default is not runtime truth).

2. Choose the source of truth with the user.

   Default recommendation: the terminal follows Noctalia's live theme via the template. If the user wants a fixed palette instead, that is a different decision — ask, do not assume.

   Completion: the agreed single source of terminal color is fixed before editing.

3. Declare the template in the shell aspect.

   In `modules/desktop/shell/noctalia.nix`:
   - Generate the OSC-sequence script with `pkgs.writeShellScript` and place it at `xdg.configFile."noctalia/templates/terminal-sequences".source`. `writeShellScript` already makes it executable; do **not** pass `executable` (the `xdg.configFile.<path>` submodule rejects it).
   - Declare `programs.noctalia.settings.theme.templates.user.terminal-sequences` with `input_path`, `output_path`, and `post_hook`. Build paths from `config.xdg.configHome` / `config.xdg.cacheHome`, never a hardcoded `$HOME`.

   Use the exact sequence script from the docs (foreground, background, normal 0-7, bright 8-15, selection fg/bg, cursor). The `{{colors.terminal_*.default.hex}}` placeholders are rendered by Noctalia from the current theme.

   Completion: `programs.noctalia` has no native `templates` option — verify this rather than inventing one (see step 5). The template lives in `settings`, which is the module's only supported data entry.

4. Disable the competing themer for that terminal.

   In the route glue (not in the terminal aspect, which must not reach into the theming aspect), turn off catppuccin for the terminal using its real option, e.g. `catppuccin.foot.enable = false;`. Leave other programs on catppuccin unless the user says otherwise.

   Completion: the terminal has exactly one color source; verify other programs are still themed.

5. Verify the schema, do not guess option names.

   Check available options by evaluation, e.g. `nix eval --json .#nixosConfigurations.<host>.config.home-manager.users.<user>.programs.noctalia --apply 'builtins.attrNames'`, and the same on `catppuccin.<term>`. Use `nh search options <query>` for NixOS/Home Manager options. Never infer option shape from a doc example alone.

   Completion: every option you set was confirmed to exist; `checkConfig = true` (`noctalia config validate`) passes in `just check`.

6. Format and validate.

   Run `NO_NOM=1 just fmt` then `NO_NOM=1 just check`. treefmt/alejandra will reformat the embedded shell script indentation, so format before re-checking.

   Completion: `just check` passes. Report that the change is not live until `just os-switch`.

7. Stage as its own step (this repo requires it).

   After the edit is done, stage the exact files touched. Do not bundle into other work. Report `git status --short`.

   Completion: the changed files are staged; nothing unrelated is added.

## Known pitfalls

- The repo's `theme.mode = "light"` and `catppuccin "latte"` describe only the declarative default. If the user's Noctalia is dark, the GUI overrode it — the running state is not in the repo.
- Hardcoding Catppuccin hex values into a terminal aspect is wrong here: it bypasses the shell theme and desyncs from the user's GUI override. Do not do this.
- A GUI theme change will **not** change terminal colors by itself; foot needs the OSC sequences (and historically an rc hook to replay them on shell startup).
- Docs note: "The template is based on the built-in foot one so if you use both you will have the same colors." If both the built-in foot template and the custom one are active, confirm they agree or disable one.

## Stop Rules

- If you are about to query `/nix/store/**`, stop, report it, and wait for direction. If you already did, interrupt the session as invalid.
- If asked to theme a terminal and you cannot name the current color source, ask the user instead of guessing.
- If the work needs `flake.nix`, `flake.lock`, or `pkgs/*`, get explicit confirmation first.
- Never write a static palette into a terminal aspect when the route's source of truth is the Noctalia theme.
