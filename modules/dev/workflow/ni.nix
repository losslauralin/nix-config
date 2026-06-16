# modules/dev/workflow/ni.nix
#
# antfu/ni — 自动检测包管理器 (npm/yarn/pnpm/bun) 并使用正确命令
{
  lossilk.dev._.workflow._.ni.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.ni];
  };
}
