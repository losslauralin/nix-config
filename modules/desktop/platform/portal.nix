{
  lossilk.desktop._.platform._.portal.nixos = {pkgs, ...}: {
    xdg.portal = {
      enable = true;
      extraPortals = [pkgs.xdg-desktop-portal-gtk];
      config.common.default = ["gtk"];
    };
    programs.dconf.enable = true;
  };
}
