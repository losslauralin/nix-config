# modules/ai/agents.nix
#
# 本地 agent 辅助工具。需要 token/secrets 的集成不要放进这个基础切面。
{inputs, ...}: {
  lossilk.ai._.agents.homeManager = {pkgs, ...}: {
    home.packages = [
      inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.semble
    ];
  };
}
