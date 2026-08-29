{
  lossilk.dev._.workflow._.topgrade.homeManager.programs.topgrade = {
    enable = true;
    settings.misc = {
      assume_yes = true;
      cleanup = true;
      disable = [
        "system"
        "helix"
        "uv"
        "bun"
        "github_cli_extensions"
      ];
    };
  };
}
