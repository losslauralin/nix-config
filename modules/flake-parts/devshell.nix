# modules/flake-parts/devshell.nix
#
# Devshell for maintaining this nix-config repo.
#
# This shell is for repo-local validation and inspection. It deliberately does
# not provide deployment/rebuild tools (`nh`, `nixos-rebuild`, deploy-rs, sops,
# ...); those belong to the target system/profile or are invoked explicitly.
#
# Enter with `nix develop`.
_: {
  perSystem = {
    pkgs,
    config,
    ...
  }: {
    devShells.default = pkgs.mkShell {
      packages = with pkgs; [
        # Documented command entry point (see justfile).
        just

        # Repo validation / formatting helpers used directly or via `nix fmt`.
        nix-output-monitor

        # Output inspection helpers used by just recipes.
        jq
        nix-tree
        nvd

        # Eval benchmark helper (`just bench`).
        hyperfine
      ];

      shellHook = ''
        ${config.pre-commit.installationScript}
      '';
    };
  };
}
