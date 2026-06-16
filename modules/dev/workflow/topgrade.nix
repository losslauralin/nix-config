# modules/dev/workflow/topgrade.nix
#
# Topgrade — 一键升级统管工具
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
