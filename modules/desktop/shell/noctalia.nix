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
      config,
      pkgs,
      ...
    }: {
      # foot / kitty 等终端支持 OSC 序列改色, 但不支持热重载配置。
      # Noctalia 的官方做法: 生成一个输出 OSC 序列的模板脚本, 由 shell 在
      # 主题变化时把序列 (tee /dev/pts/*) 打进所有终端 → 终端颜色跟随 Noctalia
      # 当前主题 (含 GUI 覆盖), 无需终端侧静态配色, 也不用 monkey patch。
      # 见 https://docs.noctalia.dev/noctalia/templates/community/terminal-templates/
      xdg.configFile."noctalia/templates/terminal-sequences".source = pkgs.writeShellScript "noctalia-terminal-sequences" ''
        printf '\033]10;{{colors.terminal_foreground.default.hex}}\007'
        printf '\033]11;{{colors.terminal_background.default.hex}}\007'
        printf '\033]4;0;{{colors.terminal_normal_black.default.hex}}\007'
        printf '\033]4;1;{{colors.terminal_normal_red.default.hex}}\007'
        printf '\033]4;2;{{colors.terminal_normal_green.default.hex}}\007'
        printf '\033]4;3;{{colors.terminal_normal_yellow.default.hex}}\007'
        printf '\033]4;4;{{colors.terminal_normal_blue.default.hex}}\007'
        printf '\033]4;5;{{colors.terminal_normal_magenta.default.hex}}\007'
        printf '\033]4;6;{{colors.terminal_normal_cyan.default.hex}}\007'
        printf '\033]4;7;{{colors.terminal_normal_white.default.hex}}\007'
        printf '\033]4;8;{{colors.terminal_bright_black.default.hex}}\007'
        printf '\033]4;9;{{colors.terminal_bright_red.default.hex}}\007'
        printf '\033]4;10;{{colors.terminal_bright_green.default.hex}}\007'
        printf '\033]4;11;{{colors.terminal_bright_yellow.default.hex}}\007'
        printf '\033]4;12;{{colors.terminal_bright_blue.default.hex}}\007'
        printf '\033]4;13;{{colors.terminal_bright_magenta.default.hex}}\007'
        printf '\033]4;14;{{colors.terminal_bright_cyan.default.hex}}\007'
        printf '\033]4;15;{{colors.terminal_bright_white.default.hex}}\007'
        printf '\033]19;{{colors.terminal_selection_fg.default.hex}}\007'
        printf '\033]17;{{colors.terminal_selection_bg.default.hex}}\007'
        printf '\033]12;{{colors.terminal_cursor.default.hex}}\007'
      '';

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

            # 终端配色模板: shell 渲染上方脚本的 {{colors.*}} 占位符到
            # output_path, 再用 post_hook 把 OSC 序列广播给所有终端 pty。
            # 放在 theme.templates.user.<name> (Noctalia 官方 schema, 非补丁)。
            templates.user.terminal-sequences = {
              input_path = "${config.xdg.configHome}/noctalia/templates/terminal-sequences";
              output_path = "${config.xdg.cacheHome}/terminal-sequences";
              post_hook = "tee /dev/pts/[0-9]* < ${config.xdg.cacheHome}/terminal-sequences";
            };
          };

          wallpaper.enabled = true;
        };
      };
    };
  };
}
