# modules/desktop/browsers/zen.nix
#
# 只安装 Zen; BROWSER 默认值由调用方设置.
{inputs, ...}: {
  lossilk.desktop._.browsers._.zen.homeManager = {
    imports = [
      inputs.zen-browser.homeModules.default
    ];

    programs.zen-browser.enable = true;
  };
}
