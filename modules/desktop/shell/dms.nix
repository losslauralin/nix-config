# modules/desktop/shell/dms.nix
#
# lossilk.desktop._.shell._.dms - DankMaterialShell (互斥族 3 层 sub-aspect, host-locked)
#
# quickshell-based shell. 接管 bar / 通知 / launcher / lockscreen / 控制中心 / powermenu /
# notepad / processlist / night mode / clipboard manager (一整套生态).
#
# 严格按官方 NixOS flake 文档 (https://danklinux.com/docs/dankmaterialshell/nixos-flake) 装:
#   1. 用 `nixosModules.dank-material-shell` 装系统级包、依赖和 dms user service
#   2. 用 `homeModules.dank-material-shell` 管用户 settings/session
#   3. 用 `homeModules.niri` 装 niri 集成 (DMS 自家 binds + niri config 注入)
#   4. `niri.enableKeybinds = true` 一键开 DMS 全套 binds, 不需要手写
#   5. NixOS module 负责 `systemd.enable = true`; HM module 不再启动第二份 dms.service
#   6. `niri.includes.enable = false` 关掉 niri-flake KDL include 路径,
#      因为官方文档警告 enableKeybinds + includes.enable 同开不推荐,
#      enableKeybinds 已走纯 HM merge, 不需要 include 二次注入.
#   7. *** niri 包必须升 25.11+ *** —— niri-flake 自带的 niri-stable 是 25.08, DMS 要 25.11+.
#      官方文档明文:"the needed version for DankMaterialShell is the latest `25.11`
#      (available in nixpkgs)". 我们用 `pkgs.niri` (当前 nixos-unstable 是 26.04, OK).
#      只在本 sub-aspect 的 nixos class 覆写, 不影响 Noctalia host.
#   7. *** 禁 niri-flake-polkit *** —— DMS 自带 polkit agent, 官方文档 gotcha:
#      "Disable `systemd.user.services.niri-flake-polkit.enable` if using niri-flake's
#      NixOS module with DMS polkit agent to avoid conflicts."
#
# DMS 自动设的 binds (上游 distro/nix/niri.nix 写死):
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
# 跟 lossilk.desktop._.compositor._.niri base 的通用 binds (Mod+Q/H/J/K/L/1..9/Return/B/Print/...)
# 无 key 冲突, 直接 attrset merge.
{inputs, ...}: {
  lossilk.desktop._.shell._.dms = {
    nixos = {pkgs, ...}: {
      imports = [
        inputs.dank-material-shell.nixosModules.dank-material-shell
      ];

      # 升 niri 到 nixpkgs 版 (26.04), 否则 DMS quickshell 跟 niri-flake niri-stable
      # (25.08) 的 IPC schema 不兼容.
      programs.niri.package = pkgs.niri;

      programs.dank-material-shell = {
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

      # DMS 自带 polkit agent → 跟 niri-flake polkit agent 冲突, 禁掉后者
      systemd.user.services.niri-flake-polkit.enable = false;
    };

    homeManager = {
      imports = [
        inputs.dank-material-shell.homeModules.dank-material-shell
        inputs.dank-material-shell.homeModules.niri
      ];

      programs.dank-material-shell = {
        enable = true;
        systemd.enable = false;
        enableCalendarEvents = false;

        settings = {
          currentThemeName = "purple";
          currentThemeCategory = "generic";
          iconTheme = "Papirus-Light";
          terminalsAlwaysDark = false;
        };

        session = {
          isLightMode = true;
          themeModeAutoEnabled = false;
          nightModeEnabled = false;
        };

        niri = {
          enableKeybinds = true;
          # 跟 enableKeybinds 同开会触发上游 warning, 关掉走纯 HM 路径
          includes.enable = false;
          # enableSpawn = false; # 跟 systemd.enable 互斥 (官方明文 warning), 走 systemd
        };
      };
    };
  };
}
