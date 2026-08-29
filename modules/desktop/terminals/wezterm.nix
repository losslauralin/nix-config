{
  lossilk.desktop._.terminals._.wezterm = {
    homeManager = {
      programs.wezterm = {
        enable = true;
        extraConfig = builtins.readFile ./wezterm/config.lua;
      };
    };

    nixos = {pkgs, ...}: {
      environment.systemPackages = [
        pkgs.wezterm
      ];

      xdg.terminal-exec = {
        enable = true;
        settings.default = ["org.wezfurlong.wezterm.desktop"];
      };
    };
  };
}
