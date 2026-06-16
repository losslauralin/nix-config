# modules/desktop/apps/localsend.nix
{
  lossilk.desktop._.localsend = {
    nixos.programs.localsend.enable = true;

    homeManager = {pkgs, ...}: {
      home.packages = [
        pkgs.localsend
      ];
    };
  };
}
