# Declarative git hooks via cachix/git-hooks.nix.
#
# Hooks intentionally reuse the project's existing treefmt-nix configuration
# (see modules/flake-parts/formatter.nix) — fmt + static lint
# (alejandra/deadnix/statix/shellcheck/ruff-check) are all treefmt formatters,
# so a single `treefmt` hook covers everything we need pre-commit.
#
#   pre-commit  → treefmt (--fail-on-change): format + static lint
#
# Heavy validation (`nix flake check`) is deferred to GitHub Actions.
# Run `nix flake check --no-warn-dirty` manually before push when desired.
#
# Hooks are installed automatically when entering the devshell
# (devshell.nix wires in config.pre-commit.installationScript).
{inputs, ...}: {
  imports = [
    inputs.git-hooks.flakeModule
  ];

  perSystem = _: {
    pre-commit.settings = {
      hooks = {
        treefmt = {
          enable = true;
          # Native integration — already runs in --fail-on-change mode.
          #
          # Excludes must be repeated here, not only in formatter.nix: this
          # hook runs with pass_filenames=true, so pre-commit hands treefmt an
          # explicit file list. treefmt only applies its own `excludes` when it
          # walks directories itself — with explicit paths it formats
          # everything it is given. The generated .pre-commit-config.yaml
          # `exclude` regex is what actually filters that list.
          # Keep this in sync with treefmt excludes in formatter.nix.
          excludes = [
            "^\\.agents/skills/"
          ];
        };
      };
    };
  };
}
