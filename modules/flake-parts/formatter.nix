# modules/flake-parts/formatter.nix
#
# Formatter configuration using treefmt-nix
{inputs, ...}: {
  imports = [
    inputs.treefmt-nix.flakeModule
  ];

  perSystem = {
    treefmt = {
      projectRootFile = "flake.nix";

      programs = {
        # Nix
        alejandra.enable = true;
        deadnix = {
          enable = true;
          # 忽略 _ 开头的参数 (den 的 __findFile 等)
          no-underscore = true;
        };
        statix.enable = true;

        # Shell
        shfmt.enable = true;
        shellcheck.enable = true;

        # Rust
        rustfmt.enable = true;

        # Python
        black.enable = true;
        ruff-format.enable = true;
        ruff-check.enable = true;

        # Go
        gofmt.enable = true;
        gofumpt.enable = true;

        # JavaScript/TypeScript
        biome.enable = true;

        # Just
        just.enable = true;

        # General
        yamlfmt.enable = true;
        jsonfmt.enable = true;
      };

      settings = {
        on-unmatched = "warn";
        excludes = [
          "*.md"
          "LICENSE"
          ".pi-dev-output/**"
          ".ralph/**"
          "secrets/**"
          "**/facter.json"
        ];
      };
    };
  };
}
