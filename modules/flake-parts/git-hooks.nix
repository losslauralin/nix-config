# modules/flake-parts/git-hooks.nix
#
# Declarative git hooks via cachix/git-hooks.nix.
#
# Hooks intentionally reuse the project's existing treefmt-nix configuration
# (see modules/flake-parts/formatter.nix) — fmt + static lint
# (alejandra/deadnix/statix/shellcheck/ruff-check) are all treefmt formatters,
# so a single `treefmt` hook covers everything we need pre-commit.
#
#   pre-commit  → treefmt (--fail-on-change): format + static lint
#   pre-push    → nix flake check
#
# Hooks are installed automatically when entering the devshell
# (devshell.nix wires in config.pre-commit.installationScript).
{inputs, ...}: {
  imports = [
    inputs.git-hooks.flakeModule
  ];

  perSystem = {pkgs, ...}: {
    pre-commit.settings = {
      hooks = {
        treefmt = {
          enable = true;
          # Native integration — already runs in --fail-on-change mode.
        };

        nix-flake-check = {
          enable = true;
          name = "nix flake check";
          entry = "${pkgs.nix}/bin/nix flake check --no-build --no-warn-dirty";
          language = "system";
          pass_filenames = false;
          stages = ["pre-push"];
        };
      };
    };
  };
}
