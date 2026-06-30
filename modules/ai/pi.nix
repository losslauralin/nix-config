# modules/ai/pi.nix
#
# Pi coding agent 配置
{inputs, ...}: {
  lossilk.ai._.pi.homeManager = {
    pkgs,
    config,
    ...
  }: let
    piAgentConfigDir = "${config.home.homeDirectory}/nix-config/dotfiles/.pi";
  in {
    home.packages = [
      inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.pi
      pkgs.nodejs
    ];

    home.file.".pi/agent" = {
      source = config.lib.file.mkOutOfStoreSymlink piAgentConfigDir;
      force = true;
    };
  };
}
