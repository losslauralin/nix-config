# modules/flake-parts/devshell.nix
#
# Minimal devshell for editing this nix-config repo.
#
# Sole purpose: provide a shell whose entry installs the git hooks declared in
# modules/flake-parts/git-hooks.nix. Nothing else belongs here — runtime tools
# (deploy-rs, sops, nh, ...) are invoked via `nix run` or come from the host
# system itself.
#
# Enter with `nix develop`.
_: {
  perSystem = {
    pkgs,
    config,
    ...
  }: {
    devShells.default = pkgs.mkShell {
      # `just` is the documented command entry point (see justfile).
      packages = [pkgs.just];

      shellHook = ''
        ${config.pre-commit.installationScript}
      '';
    };
  };
}
