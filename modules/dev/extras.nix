# modules/dev/extras.nix
#
# 杂项开发辅助工具；明确语言栈归各 lang/*，Git/JJ 归 dev/git。
{
  lossilk.dev._.extras.homeManager = {pkgs, ...}: {
    home.packages = with pkgs; [
      aube
      hexyl
      jq
      kondo
      lemmeknow
      lurk
    ];
  };
}
