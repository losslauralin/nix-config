# modules/dev/workflow/hyperfine.nix
#
# hyperfine — 基准测试工具 (nixpkgs: development/tools/misc)
{
  lossilk.dev._.workflow._.hyperfine.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.hyperfine];
  };
}
