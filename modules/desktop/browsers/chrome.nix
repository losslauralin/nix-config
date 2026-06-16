# modules/desktop/browsers/chrome.nix
#
# lossilk.desktop._.browsers._.chrome — Google Chrome browser leaf.
# BROWSER default selection is owned by an explicit profile/host/user route table.
#
# 注: chrome 是 unfree; 全局 allowUnfree 已在 den.default 的 nixos class 设 (useGlobalPkgs 让 HM 继承), 本文件不重复.
{
  lossilk.desktop._.browsers._.chrome.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.google-chrome];
  };
}
