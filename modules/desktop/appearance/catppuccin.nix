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
        # 上游自己的二进制缓存 (选项会往 nix.settings 写入 catppuccin.cachix.org
        # 与官方公钥, 不要手写 key)。注意: 构建期依赖 catppuccin-whiskers 本来就在
        # cache.nixos.org 里, 开这个不是为了它, 而是为了上游其它构建产物。
        cache.enable = true;
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
