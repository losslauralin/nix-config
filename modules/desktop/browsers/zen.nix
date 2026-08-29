{inputs, ...}: {
  lossilk.desktop._.browsers._.zen.homeManager = {
    imports = [
      inputs.zen-browser.homeModules.default
    ];

    programs.zen-browser.enable = true;
  };
}
