# modules/desktop/terminals/kitty.nix
{
  lossilk.desktop._.terminals._.kitty.homeManager = {
    programs.kitty = {
      enable = true;
      font = {
        name = "JetBrainsMono Nerd Font";
        size = 12;
      };
      settings = {
        confirm_os_window_close = 0;
        enable_audio_bell = false;
        scrollback_lines = 50000;
        window_padding_width = 4;
      };
    };
  };
}
