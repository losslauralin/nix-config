{inputs, ...}: {
  imports = [
    inputs.treefmt-nix.flakeModule
  ];

  perSystem = {
    treefmt = {
      projectRootFile = "flake.nix";

      programs = {
        alejandra.enable = true;
        deadnix = {
          enable = true;
          # 忽略 _ 开头的参数 (den 的 __findFile 等)
          no-underscore = true;
        };
        statix.enable = true;

        shfmt.enable = true;
        shellcheck.enable = true;

        rustfmt.enable = true;

        black.enable = true;
        ruff-format.enable = true;
        ruff-check.enable = true;

        gofmt.enable = true;
        gofumpt.enable = true;

        biome.enable = true;

        just.enable = true;

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
