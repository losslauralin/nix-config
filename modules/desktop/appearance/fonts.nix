# modules/desktop/appearance/fonts.nix
{
  lossilk.desktop._.appearance._.fonts = {
    nixos = {pkgs, ...}: {
      fonts = {
        enableDefaultPackages = true;
        packages = with pkgs; [
          noto-fonts
          noto-fonts-cjk-sans
          noto-fonts-cjk-serif
          noto-fonts-color-emoji
          nerd-fonts.jetbrains-mono
          nerd-fonts.symbols-only
        ];
        fontconfig.defaultFonts = {
          monospace = ["JetBrainsMono Nerd Font"];
          sansSerif = ["Noto Sans"];
          serif = ["Noto Serif"];
          emoji = ["Noto Color Emoji"];
        };
      };
    };

    homeManager = {
      fonts.fontconfig.enable = true;
    };
  };
}
