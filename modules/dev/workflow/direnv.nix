# modules/dev/workflow/direnv.nix
#
# direnv — 自动加载项目环境变量 (nixpkgs: development/tools/misc)
{
  lossilk.dev._.workflow._.direnv.homeManager.programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
