# lossilk.desktop._.compositor._.umbriel —— Umbriel compositor capability.
#
# "The Noctalia Family" 第二件: 独立 Wayland compositor (wlroots/C++23):
# scrolling / dwindle / master 布局, per-output workspace, blur / shadow / 圆角 / 动画.
#
# 包与 NixOS 接线来自上游 flake 的 nixosModules (inputs.umbriel):
#   - 装包 + services.displayManager.sessionPackages (greeter 才能发现 session)
#   - systemd.packages / systemd.user.services.umbriel
#   - xdg.portal 接入 xdg-desktop-portal-umbriel + wayland-session 基座
#     (enableXWayland=false, xwayland 由 Umbriel 自己拉 xwayland-satellite)
#   - 它会 disabledModules 掉 nixpkgs 的 programs/wayland/umbriel.nix, 避免两份定义冲突
#
# ---------------------------------------------------------------------------
# 配置机制 (关键, 别改成"写全"的形式)
# ---------------------------------------------------------------------------
# Umbriel 按顺序查找 "首个存在的文件生效", 不会与包内那份合并:
#   1. $XDG_CONFIG_HOME/umbriel/config.toml   ← HM 生成的那份
#   2. $XDG_CONFIG_DIRS/umbriel/config.toml
#   3. share/umbriel/config.toml              ← 包内, = 上游 examples/config.toml
#
# 所以只要 (1) 存在, (3) 就被整块跳过 —— 除非 (1) 自己用 `[include]` 把 (3)
# 拉进来。这里就是这么做的:
#
#   [include].files = [ <包内那份的 store 路径> ]
#
# 合并语义 (上游 configuration 文档):
#   - include 的文件先应用, 主文件最后应用
#   - 表按 key 合并; [[window_rule]] / [[layer_rule]] 之类规则列表**累积**
#   - 普通数组和标量**被主文件替换**
#
# 因此这里只写必须覆盖的几项, 其余 (appearance / input / layout / animation /
# window_rule / layer_rule / colors …) 一律继承包内那份。
# 上游更新 examples 时自动跟进, 不需要维护副本。
#
# ---------------------------------------------------------------------------
# 键位与「内建默认表」(加键前必读)
# ---------------------------------------------------------------------------
# examples/config.toml 里那句 "Defining this table replaces the built-in bind set"
# 是过时的注释。实际实现 (src/config/config.cpp):
#
#   loaded.keybinds = defaultKeybinds();          // 先装内建表
#   ...readKeybinds() 里按 chord 逐条:            // 再按 chord 覆盖
#     erase_if(loaded.keybinds, sameChord(...));
#     loaded.keybinds.push_back(binding);
#
# 内建表 (src/config/keybind_parse.cpp: defaultKeybinds()) 从不被清空, 只被
# **同名 chord** 顶掉。所以真正生效的键位 = 内建表 ∪ examples ∪ 本文件。
# 内建表里有 examples 没列出、但一直能用的一批, 例如:
#   Mod+H/J/K/L 焦点 · Mod+Shift+H/J/K/L 移动列/窗口 · Mod+Shift+方向
#   Mod+Comma/Period 吞并 · Mod+O 概览 · Mod+1..9 与 Mod+KP_1..9 工作区
#   Mod+Shift+1..9 移动 · Mod+Wheel* 焦点
# 判断某个 chord 是否空闲时, 必须两者都查, 只看 examples 会漏。
#
# 内建/examples 都没有 preset 的常用动作: window-swap-next / -previous
# (action 存在但没绑), 由本文件补上。
{inputs, ...}: {
  lossilk.desktop._.compositor._.umbriel = {
    nixos = {pkgs, ...}: {
      imports = [inputs.umbriel.nixosModules.default];

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
      # 包内那份配置 (= 该 commit 的 examples/config.toml), 作为 include 基线。
      # 只引用 store 路径字符串, 不读文件内容。
      baselineConfig = "${inputs.umbriel.packages.${pkgs.stdenv.hostPlatform.system}.default}/share/umbriel/config.toml";

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
      imports = [inputs.umbriel.homeModules.default];

      # 上游 HM 模块的 config 段是 `lib.mkIf cfg.enable` —— 不打开就不会
      # 生成 config.toml, 也不会装包。NixOS 侧已经装过同一个包, 这里只是
      # 让模块的 xdg.configFile 接线生效。
      programs.umbriel.enable = true;

      # 光标。包内默认 `input.cursor.theme = ""` 传给 wlroots 的是 nullptr:
      #   wlr_xcursor_manager_create(nullptr, size)
      #   → wlr_xcursor_theme_load(NULL, size) 里 `if (!name) name = "default";`
      #   → xcursor_load_theme("default", ...) 读 ~/.icons/default/index.theme
      # HM 的 home.pointerCursor 正好生成那个文件 (内容 Inherits=<name>)。
      #
      # phinger-cursors 的 light/dark 说的是**指针自己**的颜色, 不是桌面配色:
      # 本路线是 Catppuccin latte 浅色桌面, 所以取 dark (黑指针 + 白描边),
      # 取 light 会得到白指针, 在浅背景上基本看不见。
      home.pointerCursor = {
        enable = true;
        name = "phinger-cursors-dark";
        package = pkgs.phinger-cursors;
        size = 32;
        gtk.enable = true;
      };

      programs.umbriel.settings = {
        # 基线: 包内那份 examples/config.toml。下面各项覆盖它。
        include.files = [baselineConfig];

        # 包内 examples 的 `autostart = []`, 不会拉起 shell —— 没有 Noctalia
        # 就没有 bar / 壁纸 / launcher, 屏幕上只有空 workspace 的背景色。
        general.autostart = ["noctalia"];

        # 插入外接鼠标后关掉触控板, 拔掉自动恢复 (libinput 自己管这个状态, 不需要
        # 额外 udev 规则或脚本)。触控板是笔记本硬件, 但键名是 Umbriel 的通用输入选项
        # 而非机器事实 (无路径/设备名), 所以写在 compositor 切面而不是 host spec。
        # 只支持原生会话 (嵌套会话里没有 libinput 设备), 本机是 greetd 原生会话。
        # 其余 [input.touchpad] 项 (tap / natural_scroll / ...) 继续保持包内
        # examples 的默认, 这里不碰。
        input.touchpad.disable_on_external_mouse = true;

        # 显示器事实来自 host spec (den.schema.host.displays)。
        # 包内那份不写 output ("Outputs are machine-specific"), 不覆盖的话
        # Umbriel 自动选 preferred 模式 —— 那是 60Hz + scale 1, 不是本机要的。
        output =
          if host.displays == {}
          then {}
          else lib.mapAttrs mkOutput host.displays;

        # 表按 chord 合并, 所以这里只列需要覆盖/新增的键。
        keybinds =
          {
            # 包内 examples 绑的是 kitty, 本机终端是 foot (见 glue 的 TERMINAL)。
            "Mod+Return" = {
              action = "spawn:${config.home.sessionVariables.TERMINAL}";
              repeat = false;
            };

            # --- 仓库惯例 (沿用 niri 时代的键位; 只补内建/examples 都没有的) ------
            "Mod+C" = "column-center";

            # 全屏 / 全宽 互换。内建表与 examples 都是:
            #   Mod+F       = window-toggle-fullscreen (真·全屏)
            #   Mod+Ctrl+F  = window-toggle-maximize   (占满整列宽度)
            # 本仓库想要反过来: 单手 Mod+F 走常用的「占满宽度」, 全屏挪到
            # Mod+Ctrl+F。两条都要显式写 —— 只写一条只会顶掉一个 chord,
            # 另一条仍是内建的那个动作, 交换就只做了一半。
            "Mod+F" = {
              action = "window-toggle-maximize";
              repeat = false;
            };
            "Mod+Ctrl+F" = {
              action = "window-toggle-fullscreen";
              repeat = false;
            };

            # 交换窗口 (layout order 内的 swap; scrolling 布局下是同一列内换位)。
            # 上游没 preset —— 见文件头「内建默认表」一节。
            "Mod+Shift+Comma" = {
              action = "window-swap-previous";
              repeat = false;
            };
            "Mod+Shift+Period" = {
              action = "window-swap-next";
              repeat = false;
            };

            # 退出。内建只有 Mod+Escape 一条, 这里补回 Ctrl+Alt+Delete。
            "Ctrl+Alt+Delete" = {
              action = "session-quit";
              repeat = false;
            };

            # --- Noctalia shell IPC (上游 examples 一条都没绑) --------------------
            # 面板 id 以 `noctalia msg panel-open <错 id>` 的报错列表为准:
            # clipboard, control-center, launcher, polkit, session, setup-wizard,
            # test, tray-drawer, wallpaper.
            "Mod+S" = {
              action = "spawn:noctalia msg panel-toggle control-center";
              repeat = false;
            };
            "Mod+V" = {
              action = "spawn:noctalia msg panel-toggle clipboard";
              repeat = false;
            };
            "Mod+X" = {
              action = "spawn:noctalia msg panel-toggle session";
              repeat = false;
            };
            # 内建的概览键是 Mod+O; Mod+W 是仓库惯例的别名。
            "Mod+W" = {
              action = "overview-toggle";
              repeat = false;
            };
            # niri 时代专门给 shell 留的键 (见 35f94b2 里的避让注释)。
            "Mod+Shift+S" = {
              action = "spawn:noctalia msg settings-toggle";
              repeat = false;
            };
            "Mod+Alt+L" = {
              action = "spawn:noctalia msg session lock";
              repeat = false;
            };

            # 截图走 Noctalia (自带选区/标注), 不装 grim/slurp。
            "Print" = {
              action = "spawn:noctalia msg screenshot-region";
              repeat = false;
            };
            "Shift+Print" = {
              action = "spawn:noctalia msg screenshot-fullscreen";
              repeat = false;
            };

            # --- 音量 / 亮度 / 媒体键 --------------------------------------------
            # 走 Noctalia IPC 而不是文档示例里的 wpctl/brightnessctl/playerctl:
            # 本机只装了 wpctl, 而且 Noctalia 会顺带画 OSD。
            # allow_when_locked: 锁屏下仍要能调音量/亮度 (上游 keybinds 文档推荐)。
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
            "XF86AudioPlay" = {
              action = "spawn:noctalia msg media toggle";
              repeat = false;
            };
            "XF86AudioNext" = {
              action = "spawn:noctalia msg media next";
              repeat = false;
            };
            "XF86AudioPrev" = {
              action = "spawn:noctalia msg media previous";
              repeat = false;
            };
          }
          # 浏览器 / 文件管理器是路线侧可选的可执行 seam (BROWSER 由 glue 导出,
          # FILE_MANAGER 由 file-manager 切面导出)。seam 缺失时**不绑键**,
          # 而不是让 compositor 切面的求值失败。
          // lib.optionalAttrs (config.home.sessionVariables ? BROWSER) {
            "Mod+B" = {
              action = "spawn:${config.home.sessionVariables.BROWSER}";
              repeat = false;
            };
          }
          // lib.optionalAttrs (config.home.sessionVariables ? FILE_MANAGER) {
            # 上游 Mod+P 是 window-toggle-pinned, 所以文件管理器换到 Mod+E。
            "Mod+E" = {
              action = "spawn:${config.home.sessionVariables.FILE_MANAGER}";
              repeat = false;
            };
          };
      };
    };
  };
}
