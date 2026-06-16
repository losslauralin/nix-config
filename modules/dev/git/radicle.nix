# modules/dev/git/radicle.nix
{
  lossilk.dev._.git._.radicle.homeManager = {
    pkgs,
    config,
    ...
  }: {
    home = {
      packages = [
        pkgs.radicle-node
      ];
      sessionVariables.RAD_HOME = "${config.xdg.configHome}/radicle";
    };
  };
}
