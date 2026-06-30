# modules/networking/karing.nix
#
# Karing - sing-box/Clash-compatible proxy client.
{inputs, ...}: {
  lossilk.networking._.karing.homeManager = {pkgs, ...}: let
    karing = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.karing;
  in {
    home.packages = [karing];

    xdg.autostart.entries = [
      "${karing}/share/applications/karing.desktop"
    ];
  };
}
