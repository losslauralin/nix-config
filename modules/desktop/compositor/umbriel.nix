# lossilk.desktop._.compositor._.umbriel —— Umbriel compositor capability.
#
# "The Noctalia Family" 第二件: 独立 Wayland compositor (wlroots/C++23):
# scrolling / dwindle / master 布局, per-output workspace, blur / shadow / 圆角 / 动画.
#
# 与 shell 解耦: 本切面只放 compositor 基线与通用配置。Noctalia 专属的 autostart /
# IPC keybinds / window_rule / layer_rule 属于路线级协调, 由 glue aspect 补
# (见 lossilk.desktop._.umbriel-noctalia-desktop)。
#
# NixOS 侧走 nixpkgs 原生 `programs.umbriel`:
#   - 装包 + `services.displayManager.sessionPackages` (greeter 才能发现 Umbriel session)
#   - `xdg.portal` 接入 xdg-desktop-portal-umbriel + wayland-session 基座
#   - xwayland 由 Umbriel 自己拉起 `xwayland-satellite` (故 wayland-session enableXWayland=false)
#
# Home Manager 侧 nixpkgs/HM 都没有 umbriel 模块, 因此本切面声明
# `programs.umbriel.settings` 并生成 `~/.config/umbriel/config.toml` (TOML, 热重载)。
# 注意 Umbriel 的配置查找是"首个存在的文件生效", 不会合并包内默认值
# (PACKAGING.md "Configuration lookup"), 所以基线在这里写全; 未列出的键走内建默认。
#
# 输出配置复用 den.schema.host.displays (host spec 仍然是显示器事实的唯一来源)。
_: {
  lossilk.desktop._.compositor._.umbriel = {
    nixos = {pkgs, ...}: {
      programs.umbriel.enable = true;
      environment.systemPackages = [pkgs.xwayland-satellite];
    };

    homeManager = {
      lib,
      config,
      pkgs,
      host,
      ...
    }: let
      tomlFormat = pkgs.formats.toml {};

      # phinger-cursors 里的 light/dark 说的是**指针自己**的颜色, 不是桌面配色:
      # 本路线是 Catppuccin latte 浅色桌面, 所以取 dark (黑指针 + 白描边),
      # 取 light 会得到白指针, 在浅背景上基本看不见。
      # 它也是少数在 24/32/48/64/96/128 上都按原生网格绘制的主题, 所以下面的
      # cursorSize = 32 是原生尺寸, 不会像缩放出来的光标那样发糊。
      cursorTheme = "phinger-cursors-dark";
      cursorPackage = pkgs.phinger-cursors;
      cursorSize = 32; # 逻辑像素; 188ppi 的屏上 32 已经明显大于默认 24

      # 240.0 -> "240" (Umbriel mode 串不需要小数尾巴), 59.94 -> "59.94"
      fmtRefresh = value: lib.removeSuffix ".0" (builtins.toJSON value);

      mkOutput = _: display: {
        enabled = true;
        mode = "${toString display.width}x${toString display.height}@${fmtRefresh display.refresh}";
        position = [display.x display.y];
        scale = display.scaling;
        vrr =
          if display.vrr == false
          then "disabled"
          else if display.vrr == "on-demand"
          then "fullscreen"
          else "always";
      };
    in {
      # HM 没有 umbriel 模块 → 这里建立 settings 接口, 其它切面 (shell / glue) 可以继续
      # 往同一个 attrset 里写键; TOML 值类型在模块系统里按 attrset 深合并、list 拼接。
      options.programs.umbriel.settings = lib.mkOption {
        type = with lib.types; nullOr (oneOf [tomlFormat.type str path]);
        default = null;
        description = ''
          Umbriel 配置, 写入 {file}`$XDG_CONFIG_HOME/umbriel/config.toml`。
          null 时不生成用户配置, 回落到包内默认配置。
        '';
      };

      config = {
        # 光标主题包 + 环境。Umbriel 的 [input.cursor] 只管自己的指针, XWayland /
        # GTK / Qt 客户端 (微信, wemeet-xwayland) 不读那个配置, 只认 XCURSOR_THEME
        # 和 XCURSOR_SIZE —— 两边都要设, 否则合成器内光标与应用内光标大小/样式不一致。
        #
        # 这两件事交给 HM 的 home.pointerCursor 统一处理: 它会装包、写
        # XCURSOR_THEME / XCURSOR_SIZE, 并同步 GTK 的 gtk-cursor-theme-name/-size
        # 与 ~/.icons/default —— 比手写环境变量更全。下面的 [input.cursor] 读同一份
        # 值, 保证合成器内与应用内始终一致。
        home.pointerCursor = {
          enable = true; # 不显式打开的话 HM 会报 deprecation warning
          name = cursorTheme;
          package = cursorPackage;
          size = cursorSize;
          gtk.enable = true;
        };

        programs.umbriel.settings = {
          general = {
            xwayland = true; # 需要 xwayland-satellite 在 PATH
            show_cheatsheet = false;
            focus_on_activate = false;
          };

          input = {
            keyboard = {
              layout = "us";
              numlock_toggle = true;
            };
            touchpad = {
              tap = true;
              natural_scroll = true;
              # 插上外接鼠标就自动禁用触摸板, 拔掉自动恢复 (libinput 自己检测)。
              # Umbriel 没有 "enabled" 开关、Noctalia 也没有输入设备 GUI, 所以
              # 这是唯一的自动开关途径; 仅 native session 有效 (nested 无 libinput)。
              disable_on_external_mouse = true;
            };
            mouse.accel_profile = "flat";

            # 光标主题。之前这里只有 size、没有 theme, 而系统里也没有任何光标
            # 主题 (Papirus 是图标主题, 不含指针), 环境里的 XCURSOR_THEME 也是空的
            # → Umbriel 只能回落到内建兜底光标, 那个又小又糊, 调多大都难看。
            #
            # size 是逻辑像素, 不乘 output scale (官方 examples/config.toml:
            # "Logical size, 1-512"), 默认 24 在这个高密度屏上偏小, 取 32。
            # 值来自 home.pointerCursor, 与 XCURSOR_* / GTK 侧同源。
            cursor = {
              theme = config.home.pointerCursor.name;
              size = config.home.pointerCursor.size;
            };
          };

          layout = {
            mode = "scrolling";
            gap = 8;
          };

          # 外观基线; Noctalia 官方 Umbriel 指南推荐的圆角/边框/blur 组合。
          appearance = {
            prefer_no_csd = true;
            border_width = 2;
            corner_radius = 10;
            blur = {
              enabled = true;
              optimized = true;
              passes = 3;
              radius = 3;
              noise = 0.02;
              brightness = 0.9;
              contrast = 0.9;
              saturation = 1.1;
            };
          };

          # 无选择器的全窗口 blur 规则必须排在最前, 后面的匹配规则才能覆盖单项设置。
          window_rule = [
            {
              blur = true;
              blur_optimized = false;
            }
          ];

          output =
            if host.displays == {}
            then {}
            else lib.mapAttrs mkOutput host.displays;

          # 通用 compositor 键位 (沿用仓库原有键位习惯, 避开 shell 占用的键)。
          # shell 侧键位 (Noctalia IPC) 由 glue aspect 追加。
          keybinds = {
            # 会话 / 概览 / 帮助
            "Mod+Escape" = "session-quit";
            "Ctrl+Alt+Delete" = "session-quit";
            "Mod+W" = "overview-toggle";
            "Mod+O" = {
              action = "cheatsheet-toggle";
              repeat = false;
            };

            # spawn: 具体命令来自 leaf 切面的 home.sessionVariables, compositor 只消费 seam
            "Mod+Return" = "spawn:${config.home.sessionVariables.TERMINAL}";
            "Mod+B" = "spawn:${config.home.sessionVariables.BROWSER}";

            # 窗口状态
            "Mod+Q" = "window-close";
            "Mod+T" = "window-toggle-floating";
            "Mod+G" = "window-focus-switch-floating";
            "Mod+F" = "window-toggle-maximize";
            "Mod+Shift+F" = "window-toggle-fullscreen";
            "Mod+C" = "column-center";
            "Mod+R" = "window-cycle-width";
            "Mod+E" = "window-cycle-width-back";

            # 焦点 (vim)
            "Mod+H" = "window-focus-left";
            "Mod+J" = "window-focus-down";
            "Mod+K" = "window-focus-up";
            "Mod+L" = "window-focus-right";

            # 移动窗口 / 列
            "Mod+Shift+H" = "column-move-left";
            "Mod+Shift+J" = "window-move-down";
            "Mod+Shift+K" = "window-move-up";
            "Mod+Shift+L" = "column-move-right";

            # 滚轮切焦点
            "Mod+WheelDown" = "window-focus-right";
            "Mod+WheelUp" = "window-focus-left";

            # 工作区 1-9: 切换 / 移入
            "Mod+1" = "workspace-switch:1";
            "Mod+2" = "workspace-switch:2";
            "Mod+3" = "workspace-switch:3";
            "Mod+4" = "workspace-switch:4";
            "Mod+5" = "workspace-switch:5";
            "Mod+6" = "workspace-switch:6";
            "Mod+7" = "workspace-switch:7";
            "Mod+8" = "workspace-switch:8";
            "Mod+9" = "workspace-switch:9";
            "Mod+Shift+1" = "window-move-to-workspace:1";
            "Mod+Shift+2" = "window-move-to-workspace:2";
            "Mod+Shift+3" = "window-move-to-workspace:3";
            "Mod+Shift+4" = "window-move-to-workspace:4";
            "Mod+Shift+5" = "window-move-to-workspace:5";
            "Mod+Shift+6" = "window-move-to-workspace:6";
            "Mod+Shift+7" = "window-move-to-workspace:7";
            "Mod+Shift+8" = "window-move-to-workspace:8";
            "Mod+Shift+9" = "window-move-to-workspace:9";
          };
        };

        xdg.configFile."umbriel/config.toml" = lib.mkIf (config.programs.umbriel.settings != null) {
          source = tomlFormat.generate "umbriel-config.toml" config.programs.umbriel.settings;
        };
      };
    };
  };
}
