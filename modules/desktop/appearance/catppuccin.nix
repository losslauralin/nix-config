# modules/desktop/appearance/catppuccin.nix
#
# Catppuccin 配色主题声明
{
  inputs,
  lib,
  ...
}: let
  iconTheme = "Papirus-Light";
in {
  lossilk.desktop._.appearance._.catppuccin = flavor: accent: {
    nixos = {
      imports = [
        inputs.catppuccin.nixosModules.default
      ];

      catppuccin = {
        enable = true;
        autoEnable = true;
        inherit flavor accent;
      };
    };

    homeManager = {
      config,
      pkgs,
      ...
    }: {
      imports = [
        inputs.catppuccin.homeModules.catppuccin
        inputs.nix-colors.homeManagerModule
      ];

      catppuccin = {
        enable = true;
        autoEnable = true;
        inherit flavor accent;
        wezterm.apply = true;
        kvantum.enable = false;
        qt5ct.enable = true;
      };

      colorScheme = inputs.nix-colors.colorSchemes."catppuccin-${flavor}";

      home.sessionVariables.QS_ICON_THEME = iconTheme;
      systemd.user.sessionVariables.QS_ICON_THEME = iconTheme;

      qt = {
        platformTheme.name = "qtct";
        kde.settings.kdeglobals = {
          Icons.Theme = iconTheme;
          UiSettings = {
            ColorScheme = "catppuccin-${flavor}-${accent}";
            IconTheme = iconTheme;
          };
        };
        qt5ctSettings.Appearance = {
          icon_theme = iconTheme;
          style = "Fusion";
        };
        qt6ctSettings.Appearance = {
          icon_theme = iconTheme;
          style = "Fusion";
        };
      };

      gtk = {
        enable = true;
        iconTheme = {
          name = lib.mkDefault iconTheme;
          package = lib.mkDefault pkgs.papirus-icon-theme;
        };
        gtk3.theme = {
          name = "adw-gtk3";
          package = pkgs.adw-gtk3;
        };
      };

      programs = lib.optionalAttrs (config.programs ? niri) {
        niri.settings = let
          palette =
            (builtins.fromJSON (builtins.readFile (config.catppuccin.sources.palette + /palette.json)))
              .${flavor}.colors;
        in {
          overview.backdrop-color = palette.crust.hex;
          layout = {
            background-color = palette.crust.hex;
            focus-ring.active.color = palette.${accent}.hex;
            focus-ring.urgent.color =
              if accent == "red"
              then palette.blue.hex
              else palette.red.hex;
            tab-indicator.active.color =
              if accent == "peach"
              then palette.blue.hex
              else palette.peach.hex;
          };
        };
      };
    };
  };
}
