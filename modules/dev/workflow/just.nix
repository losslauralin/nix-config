# modules/dev/workflow/just.nix
#
# Justfile 命令执行器 (nixpkgs: development/tools/build-managers)
{
  lossilk.dev._.workflow._.just.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.just];
  };
}
