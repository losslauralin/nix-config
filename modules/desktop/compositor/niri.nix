# modules/desktop/compositor/niri.nix
#
# lossilk.desktop._.compositor._.niri - niri compositor (互斥族 3 层 namespace 容器,host-locked, shell-agnostic)
#
# 用 sodiboo/niri-flake. nixos 层 enable niri 后, niri-flake 经 nixosModules.niri 自动
# inject HM module 到 home-manager.users.<n>, 所以 HM 块直接写 programs.niri.settings
# 即可, 不需要 imports = [inputs.niri.homeModules.config].
#
# 本 sub-aspect 是 shell-agnostic 基线: niri compositor 本身 + 通用美化 (圆角) + greetd
# 自启. Shell 特异内容 (panel 拉起 / IPC binds / shell 自启 / shell-specific window
# rules / shell-specific polkit 协调) 各 shell sub-aspect 自己贡献到 programs.niri.settings,
# 由 nix 模块系统 merge 合到最终 niri 配置. 终端/浏览器启动命令从所选 desktop
# leaf 的 home.sessionVariables seam 读取, niri 不绑定具体 implementation. host 主切面通过 includes 选用具体 shell:
#   - desktop._.shell._.noctalia → Noctalia 接管
#   - desktop._.shell._.dms      → DankMaterialShell 接管
{inputs, ...}: {
  lossilk.desktop._.compositor._.niri = {
    nixos = {
      pkgs,
      config,
      ...
    }: {
      imports = [inputs.niri.nixosModules.niri];
      programs.niri.enable = true;

      # greetd 自动启 niri-session; user 名由 host 主切面填 (因 user host-specific)
      services.greetd = {
        enable = true;
        settings.default_session.command = "${config.programs.niri.package}/bin/niri-session";
      };

      environment.systemPackages = with pkgs; [
        xwayland-satellite
      ];
    };

    homeManager = {
      lib,
      config,
      host,
      ...
    }: let
      mkOutput = _: display: {
        mode = {
          inherit (display) width height refresh;
        };
        position = {
          inherit (display) x y;
        };
        scale = display.scaling;
        variable-refresh-rate = display.vrr;
        focus-at-startup = lib.mkIf display.primary true;
      };
    in {
      programs.niri.settings = {
        input = {
          keyboard.xkb.layout = "us";
          touchpad = {
            tap = true;
            natural-scroll = true;
          };
          mouse.accel-profile = "flat";
        };

        outputs =
          if host.displays == {}
          then {"Virtual-1" = {};}
          else lib.mapAttrs mkOutput host.displays;

        prefer-no-csd = true;

        layout = {
          gaps = 8;
          border = {
            enable = true;
            width = 2;
          };
          focus-ring.enable = true;
        };

        # 全局圆角美化 (跟具体 shell 无关; 各 shell sub-aspect 追加自己的 window-rules)
        window-rules = [
          {
            geometry-corner-radius = {
              top-left = 20.0;
              top-right = 20.0;
              bottom-left = 20.0;
              bottom-right = 20.0;
            };
            clip-to-geometry = true;
          }
        ];

        # 通用自启项. shell 自启留给各 shell sub-aspect 自己决定 (Noctalia 走 niri
        # spawn-at-startup, DMS 走 systemd user service).
        spawn-at-startup = [
          {command = ["xwayland-satellite"];}
        ];

        # niri 通用 binds (shell-agnostic). 注意避开各 shell 占用键:
        #   Mod+Space / Mod+S / Mod+Comma (Noctalia 用),
        #   Mod+V / Mod+Escape           (DMS 用),
        #   XF86Audio* / XF86MonBrightness* (各 shell 自己接).
        # 各 shell sub-aspect 的 binds 由 nix 模块系统按 key merge 进来.
        binds = {
          # 窗口控制
          "Mod+Q".action.close-window = [];
          "Mod+T".action.toggle-window-floating = [];
          "Mod+G".action.switch-focus-between-floating-and-tiling = [];

          # 列宽 / 全屏
          "Mod+F".action.maximize-column = [];
          "Mod+Shift+F".action.fullscreen-window = [];
          "Mod+C".action.center-column = [];
          "Mod+R".action.switch-preset-column-width = [];
          "Mod+E".action.switch-preset-column-width-back = [];

          # Tabbed 显示
          "Mod+Shift+T".action.toggle-column-tabbed-display = [];

          # 焦点 (Vim H/J/K/L; -or-monitor / -or-workspace 形式支持跨边界)
          "Mod+H".action.focus-column-or-monitor-left = [];
          "Mod+J".action.focus-window-or-workspace-down = [];
          "Mod+K".action.focus-window-or-workspace-up = [];
          "Mod+L".action.focus-column-or-monitor-right = [];

          # 移动窗口/列
          "Mod+Shift+H".action.move-column-left-or-to-monitor-left = [];
          "Mod+Shift+J".action.move-window-down = [];
          "Mod+Shift+K".action.move-window-up = [];
          "Mod+Shift+L".action.move-column-right-or-to-monitor-right = [];

          # 滚轮切列焦点
          "Mod+WheelScrollDown".action.focus-column-right = [];
          "Mod+WheelScrollUp".action.focus-column-left = [];

          # 工作区 1-9 切换 / 移动
          "Mod+1".action.focus-workspace = 1;
          "Mod+2".action.focus-workspace = 2;
          "Mod+3".action.focus-workspace = 3;
          "Mod+4".action.focus-workspace = 4;
          "Mod+5".action.focus-workspace = 5;
          "Mod+6".action.focus-workspace = 6;
          "Mod+7".action.focus-workspace = 7;
          "Mod+8".action.focus-workspace = 8;
          "Mod+9".action.focus-workspace = 9;
          "Mod+Shift+1".action.move-column-to-workspace = 1;
          "Mod+Shift+2".action.move-column-to-workspace = 2;
          "Mod+Shift+3".action.move-column-to-workspace = 3;
          "Mod+Shift+4".action.move-column-to-workspace = 4;
          "Mod+Shift+5".action.move-column-to-workspace = 5;
          "Mod+Shift+6".action.move-column-to-workspace = 6;
          "Mod+Shift+7".action.move-column-to-workspace = 7;
          "Mod+Shift+8".action.move-column-to-workspace = 8;
          "Mod+Shift+9".action.move-column-to-workspace = 9;

          # 概览 / 帮助
          "Mod+W".action.toggle-overview = [];
          "Mod+O".action.show-hotkey-overlay = [];

          # 应用 spawn: terminal/browser leaf 通过 home.sessionVariables 提供命令,
          # niri 只消费 seam, 不硬编码具体 implementation.
          "Mod+Return".action.spawn = [config.home.sessionVariables.TERMINAL];
          "Mod+B".action.spawn = [config.home.sessionVariables.BROWSER];

          # 截图 (用 Print 系列, 避开 Mod+Shift+S 给 shell 留余地)
          "Print".action.screenshot = [];
          "Mod+Print".action.screenshot-screen = [];
          "Shift+Print".action.screenshot-window = [];

          # 退出
          "Ctrl+Alt+Delete".action.quit = [];
        };
      };
    };
  };
}
