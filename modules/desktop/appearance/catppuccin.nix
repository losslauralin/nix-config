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

    homeManager = {pkgs, ...}: {
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
    };
  };
}
