# modules/dev/lang/python.nix
{
  lossilk.dev._.lang._.python.homeManager = {pkgs, ...}: {
    home.packages = [
      pkgs.python3
    ];

    programs.uv.enable = true;
  };
}
