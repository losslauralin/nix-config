# lossilk.desktop._.umbriel-noctalia-desktop —— "The Noctalia Family" 桌面路线 glue。
#
# Umbriel (compositor) + Noctalia (shell) + Noctalia Greeter 三件一起跑。
# 三件各自是独立能力切面 (compositor._.umbriel / shell._.noctalia / greeter._.noctalia),
# 它们之间的对接属于路线级协调, 集中放在这里:
#   - Umbriel autostart Noctalia
#   - Noctalia IPC 键位 (官方 Umbriel 指南)
#   - Noctalia 窗口规则 (设置窗 / 分享选择器浮动)
#   - Noctalia 图层规则 (bar / panel / osd / widget 的 blur)
#
# VM / 硬件 / 磁盘事实留在 host spec。
{lossilk, ...}: {
  lossilk.desktop._.umbriel-noctalia-desktop = {
    includes = with lossilk; [
      system
      nix
      networking
      audio
      desktop._.appearance._.fonts
      (desktop._.appearance._.catppuccin "latte" "mauve")
      desktop._.browsers._.chrome
      desktop._.terminals._.kitty
      desktop._.platform._.flatpak
      desktop._.input._.fcitx5-rime-wanxiang
      desktop._.compositor._.umbriel
      desktop._.shell._.noctalia
      desktop._.greeter._.noctalia
    ];

    homeManager = {lib, ...}: {
      home.sessionVariables = {
        BROWSER = lib.mkDefault "google-chrome-stable";
        TERMINAL = lib.mkDefault "kitty";
      };

      programs.umbriel.settings = {
        # Umbriel 启动后拉起 shell (autostart 只在 session 启动时执行一次)
        general.autostart = ["noctalia"];

        # Noctalia IPC 键位, 官方 Umbriel 指南 + 锁屏下仍可用的音量/亮度。
        keybinds = {
          "Mod+Space" = "spawn:noctalia msg panel-toggle launcher";
          "Mod+S" = "spawn:noctalia msg panel-toggle control-center";
          "Mod+Comma" = "spawn:noctalia msg settings-toggle";
          "Mod+V" = "spawn:noctalia msg panel-toggle clipboard";
          "Mod+X" = "spawn:noctalia msg panel-toggle session";
          "Alt+Tab" = {
            action = "spawn:noctalia msg window-switcher";
            repeat = false;
          };

          # 截图 / 标注
          "Print" = "spawn:noctalia msg screenshot-region";
          "Shift+Print" = "spawn:noctalia msg screenshot-fullscreen";
          "Mod+Shift+A" = "spawn:noctalia msg screenshot-annotate";
          "Mod+Ctrl+A" = "spawn:noctalia msg annotate";

          # 锁屏 / 夜灯
          "Super+Alt+L" = "spawn:noctalia msg session lock";
          "Mod+Alt+N" = {
            action = "spawn:noctalia msg nightlight-toggle";
            allow_when_locked = true;
          };

          # 音量 / 麦克风 / 亮度: 锁屏后仍要能用
          "XF86AudioRaiseVolume" = {
            action = "spawn:noctalia msg volume-up";
            allow_when_locked = true;
          };
          "XF86AudioLowerVolume" = {
            action = "spawn:noctalia msg volume-down";
            allow_when_locked = true;
          };
          "XF86AudioMute" = {
            action = "spawn:noctalia msg volume-mute";
            allow_when_locked = true;
          };
          "XF86AudioMicMute" = {
            action = "spawn:noctalia msg mic-mute";
            allow_when_locked = true;
          };
          "XF86MonBrightnessUp" = {
            action = "spawn:noctalia msg brightness-up";
            allow_when_locked = true;
          };
          "XF86MonBrightnessDown" = {
            action = "spawn:noctalia msg brightness-down";
            allow_when_locked = true;
          };
        };

        # Noctalia 自己的窗口: 设置窗与 portal 分享选择器浮动 + 固定尺寸
        window_rule = [
          {
            match.app_id = "^dev.noctalia.Noctalia$";
            default_floating = true;
            default_floating_size_px = {
              width = 1020;
              height = 900;
            };
          }
          {
            match.app_id = "^dev.noctalia.UmbrielSharePicker$";
            default_floating = true;
            default_floating_size_px = {
              width = 800;
              height = 600;
            };
          }
        ];

        # Noctalia layer-shell 表面 (bar / notification / dock / panel / osd / widget) blur
        layer_rule = [
          {
            match.namespace = "^noctalia-(bar-[^\"]+|notification|dock|panel|attached-panel|osd|desktop-widget-[^\"]*)$";
            blur = true;
            blur_ignore_alpha = 0.5;
            blur_popups = true;
            blur_optimized = false;
          }
        ];
      };
    };
  };
}
