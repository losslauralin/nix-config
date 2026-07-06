# modules/desktop/niri-dms-desktop.nix
#
# lossilk.desktop._.niri-dms-desktop —— niri + DankMaterialShell desktop.
# VM / hardware / disk facts stay in host specs.
#
# include 引用风格:本文件用 attrpath 风格(`with lossilk; desktop._.foo`);
# angle-bracket(`<lossilk/...>`)仅 modules/users/loss.nix 等既有文件保留。
{lossilk, ...}: {
  lossilk.desktop._.niri-dms-desktop = {
    includes = with lossilk; [
      system
      nix
      networking
      audio
      desktop._.appearance._.fonts
      (desktop._.appearance._.catppuccin "latte" "mauve")
      desktop._.browsers._.chrome
      desktop._.terminals._.kitty
      desktop._.platform._.flatpak
      desktop._.compositor._.niri
      desktop._.shell._.dms
      desktop._.search._.dsearch
    ];

    homeManager = {lib, ...}: {
      home.sessionVariables = {
        BROWSER = lib.mkDefault "google-chrome-stable";
        TERMINAL = lib.mkDefault "kitty";
      };
    };
  };
}
