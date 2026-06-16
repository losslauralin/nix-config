# modules/desktop/platform/flatpak.nix
{lossilk, ...}: {
  lossilk.desktop._.platform._.flatpak = {
    includes = [
      lossilk.desktop._.platform._.portal
    ];

    nixos = {
      appstream.enable = true;
      services.flatpak.enable = true;
    };
  };
}
