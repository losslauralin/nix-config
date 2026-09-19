{inputs, ...}: {
  lossilk.ai._.pi.homeManager = {pkgs, ...}: {
    home.packages = [
      inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.pi
      pkgs.nodejs
    ];
  };
}
