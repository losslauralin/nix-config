# modules/dev/workflow/devenv.nix
#
# devenv — 可复制开发沙盒 (nixpkgs: development/tools/misc)
{
  lossilk.dev._.workflow._.devenv.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.devenv];
  };
}
