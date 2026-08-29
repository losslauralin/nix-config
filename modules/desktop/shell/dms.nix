# lossilk.desktop._.shell._.dms - DankMaterialShell for niri (host-locked)
#
# quickshell-based shell. 接管 bar / 通知 / launcher / lockscreen / 控制中心 / powermenu /
# notepad / processlist / night mode / clipboard manager (一整套生态).
#
# 使用 nixpkgs 内置模块:
#   1. `programs.dms-shell` 装系统级包、依赖和 dms user service
#   2. `services.displayManager.dms-greeter` 接管 greetd 登录界面
#   3. HM 侧只声明 DMS JSON settings/session 与 niri IPC binds, 不再依赖 DMS flake module
#   4. *** niri 包必须升 25.11+ *** —— niri-flake 自带的 niri-stable 偏旧, DMS 要新版
#      IPC schema. 我们用 `pkgs.niri` (当前 nixos-unstable 是 26.04, OK).
#   5. *** 禁 niri-flake-polkit *** —— DMS 自带 polkit agent, 避免双 polkit prompt.
#
# DMS niri IPC binds (从上游模块迁入本地 HM 配置, 避免继续依赖 DMS flake):
#   Mod+Space    → spotlight toggle (launcher)
#   Mod+N        → notifications toggle
#   Mod+Comma    → settings toggle
#   Mod+P        → notepad toggle
#   Mod+V        → clipboard toggle
#   Mod+X        → powermenu toggle
#   Mod+M        → processlist toggle (仅 enableSystemMonitoring=true)
#   Super+Alt+L  → lock lock
#   Mod+Alt+N    → night mode toggle
#   XF86Audio{Raise,Lower,Mute,MicMute}Volume → audio
#   XF86MonBrightness{Up,Down}                 → brightness
#
# Assumes niri: package override, greeter compositor, and IPC binds live here.
{lossilk, ...}: {
  lossilk.desktop._.shell._.dms = {
    includes = [lossilk.desktop._.compositor._.niri];

    nixos = {
      lib,
      pkgs,
      config,
      ...
    }: {
      # 升 niri 到 nixpkgs 版 (26.04), 否则 DMS quickshell 跟 niri-flake niri-stable
      # (25.08) 的 IPC schema 不兼容.
      programs.niri.package = pkgs.niri;

      programs.dms-shell = {
        enable = true;
        systemd = {
          enable = true;
          restartIfChanged = true;
        };
        enableSystemMonitoring = true;
        enableVPN = true;
        enableDynamicTheming = true;
        enableAudioWavelength = true;
        enableCalendarEvents = false;
        enableClipboardPaste = true;
      };

      services.displayManager.dms-greeter = {
        enable = true;
        compositor.name = "niri";
        # 复用用户 DMS 主题 / session / wallpaper 配置生成 greeter 缓存.
        configHome = config.users.users.loss.home or "/home/loss";
      };

      # DMS 自带 polkit agent → 跟 niri-flake polkit agent 冲突, 禁掉后者
      systemd.user.services.niri-flake-polkit.enable = false;
      security.polkit.enable = lib.mkDefault true;
    };

    homeManager = {
      pkgs,
      config,
      ...
    }: let
      jsonFormat = pkgs.formats.json {};
      dmsIpc = config.lib.niri.actions.spawn "dms" "ipc";
    in {
      xdg.configFile."DankMaterialShell/settings.json".source = jsonFormat.generate "settings.json" {
        currentThemeName = "purple";
        currentThemeCategory = "generic";
        iconTheme = "Papirus-Light";
        terminalsAlwaysDark = false;
      };

      xdg.stateFile."DankMaterialShell/session.json".source = jsonFormat.generate "session.json" {
        isLightMode = true;
        themeModeAutoEnabled = false;
        nightModeEnabled = false;
      };

      programs.niri.settings.binds = {
        "Mod+Space" = {
          action = dmsIpc "spotlight" "toggle";
          hotkey-overlay.title = "Toggle Application Launcher";
        };
        "Mod+N" = {
          action = dmsIpc "notifications" "toggle";
          hotkey-overlay.title = "Toggle Notification Center";
        };
        "Mod+Comma" = {
          action = dmsIpc "settings" "toggle";
          hotkey-overlay.title = "Toggle Settings";
        };
        "Mod+P" = {
          action = dmsIpc "notepad" "toggle";
          hotkey-overlay.title = "Toggle Notepad";
        };
        "Super+Alt+L" = {
          action = dmsIpc "lock" "lock";
          hotkey-overlay.title = "Toggle Lock Screen";
        };
        "Mod+X" = {
          action = dmsIpc "powermenu" "toggle";
          hotkey-overlay.title = "Toggle Power Menu";
        };
        "XF86AudioRaiseVolume" = {
          allow-when-locked = true;
          action = dmsIpc "audio" "increment" "3";
        };
        "XF86AudioLowerVolume" = {
          allow-when-locked = true;
          action = dmsIpc "audio" "decrement" "3";
        };
        "XF86AudioMute" = {
          allow-when-locked = true;
          action = dmsIpc "audio" "mute";
        };
        "XF86AudioMicMute" = {
          allow-when-locked = true;
          action = dmsIpc "audio" "micmute";
        };
        "XF86MonBrightnessUp" = {
          allow-when-locked = true;
          action = dmsIpc "brightness" "increment" "5" "";
        };
        "XF86MonBrightnessDown" = {
          allow-when-locked = true;
          action = dmsIpc "brightness" "decrement" "5" "";
        };
        "Mod+Alt+N" = {
          allow-when-locked = true;
          action = dmsIpc "night" "toggle";
          hotkey-overlay.title = "Toggle Night Mode";
        };
        "Mod+V" = {
          action = dmsIpc "clipboard" "toggle";
          hotkey-overlay.title = "Toggle Clipboard Manager";
        };
        "Mod+M" = {
          action = dmsIpc "processlist" "toggle";
          hotkey-overlay.title = "Toggle Process List";
        };
      };
    };
  };
}
