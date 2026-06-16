# modules/desktop/browsers/zen.nix
#
# BROWSER default selection is owned by an explicit profile/host/user route table.
{inputs, ...}: {
  lossilk.desktop._.browsers._.zen.homeManager = {
    imports = [
      inputs.zen-browser.homeModules.default
    ];

    programs.zen-browser.enable = true;
  };
}
