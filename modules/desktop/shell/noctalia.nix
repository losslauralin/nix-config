# lossilk.desktop._.shell._.noctalia —— Noctalia shell capability (native Wayland).
#
# "The Noctalia Family" 第一件: 原生 C++ Wayland shell (无 Qt/GTK), v5。
# 接管 bar / launcher / control center / notification / lockscreen / wallpaper /
# OSD / clipboard / session panel / 桌面 widget。支持 niri / hyprland / sway /
# mango / labwc / umbriel 等多种 compositor。
#
# 与 compositor 解耦: 本切面只声明 shell 自身。启动方式、IPC 键位、
# Noctalia 窗口/图层规则等对接细节属于路线级协调, 由 glue aspect 负责
# (见 lossilk.desktop._.umbriel-noctalia-desktop)。
#
# 两侧都是原生模块, 不依赖 noctalia flake:
#   - NixOS: `programs.noctalia.{enable,recommendedServices}`
#     recommendedServices 按官方 NixOS 文档补齐 shell 的 wifi / bluetooth /
#     power-profile / battery 依赖 (NetworkManager、蓝牙、power-profiles-daemon、
#     UPower), 全部 mkDefault, 已有配置优先。
#   - HM: `programs.noctalia.{enable,checkConfig,settings}`; settings 生成
#     `~/.config/noctalia/config.toml`, checkConfig 在构建期跑
#     `noctalia config validate` 校验 schema。
#
# 不走 systemd service: shell 由 compositor 的 autostart 拉起, 避免和
# compositor session target 的启停时序耦合 (官方 Umbriel 指南也是这个做法)。
_: {
  lossilk.desktop._.shell._.noctalia = {
    nixos = {
      programs.noctalia = {
        enable = true;
        recommendedServices.enable = true;
      };
    };

    homeManager = {
      programs.noctalia = {
        enable = true;
        checkConfig = true;

        settings = {
          shell = {
            lang = "zh-Hans";
            polkit_agent = true; # compositor 不自带 polkit agent, 由 shell 提供认证代理
            clipboard_enabled = true;
          };

          # 跟路线里的 catppuccin latte/mauve 主题保持一致
          theme = {
            mode = "light";
            source = "builtin";
            builtin = "Catppuccin";
          };

          wallpaper.enabled = true;
        };
      };
    };
  };
}
