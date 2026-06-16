# modules/dev/lang/javascript.nix
{
  lossilk.dev._.lang._.javascript.homeManager = {pkgs, ...}: {
    home.packages = with pkgs; [
      deno
      fnm
      nodejs
      ni
    ];
    programs.bun.enable = true;
  };
}
