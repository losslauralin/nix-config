# modules/desktop/shell/noctalia.nix
#
# lossilk.desktop._.shell._.noctalia - Noctalia for niri (candidate)
#
# quickshell-based shell, 接管 bar / 通知 / launcher / lockscreen.
# 跟 DMS 区别: Noctalia 不提供 niri-specific HM 集成 (没 enableSpawn/enableKeybinds),
# 完全靠 declarative niri spawn-at-startup + binds 接入 (本文件贡献到 programs.niri.settings).
#
# HM wrapper 选项 (源码 nix/home-module.nix):
#   - enable          : bool
#   - systemd.enable  : bool (我们用 niri spawn-at-startup, 不走 systemd)
#   - package         : 包覆写, 一般不动
#   - settings        : 自由 TOML attrset → ~/.config/noctalia/config.toml
#   - customPalettes  : 自定义调色板, JSON map
#
# settings 完整 schema 见 noctalia 源码 root example.toml ([shell]/[wallpaper]/[theme]/
# [bar.main]/[dock]/[notification]/[osd]/[weather]/[audio]/[brightness]/[nightlight]/
# [idle]/[keybinds]/[hooks] 等十几个 section).
#
# i18n 现状 (2026-05-24): noctalia v5 share/noctalia/assets/translations/ **只有 en.json**.
# shell.lang 设非 en 都会 fallback English. 修法只能给 upstream 提翻译 PR.
#
# niri 集成内容 (binds / spawn / window-rules / polkit 协调) 全部在本文件贡献。
{
  inputs,
  lossilk,
  ...
}: {
  lossilk.desktop._.shell._.noctalia = {
    includes = [lossilk.desktop._.compositor._.niri];

    # Noctalia 自己有 polkit, 禁掉 niri-flake polkit 避免双 polkit prompt
    nixos = {
      systemd.user.services.niri-flake-polkit.enable = false;
    };

    homeManager = {
      imports = [inputs.noctalia.homeModules.default];

      programs.noctalia = {
        enable = true;

        # settings 非空, HM 会生成 ~/.config/noctalia/config.toml.
        # 空 attrset 则不生成 (noctalia 启动报 `no config files found, using defaults`).
        settings = {
          shell = {
            # 即便 zh-CN catalog 不存在, 声明值会落到 config.toml; noctalia 启动
            # 时会读这个值, 然后再 fallback English. 这能验证声明式落地链路通.
            lang = "zh-CN";
          };
        };
      };

      # niri 集成
      # 走 programs.niri.settings 贡献, nix 模块系统跟 niri base 的设置自动合 (list concat / attrset merge).
      programs.niri.settings = {
        # Noctalia 自己 Settings 窗口浮动 + 固定尺寸 (官方推荐)
        window-rules = [
          {
            matches = [{app-id = "dev.noctalia.Noctalia.Settings";}];
            open-floating = true;
            default-column-width.fixed = 1080;
            default-window-height.fixed = 920;
          }
        ];

        # XDG activation 容错 (Noctalia 推荐, 避免 launcher 拉起来时 focus 错乱)
        debug.honor-xdg-activation-with-invalid-serial = [];

        # Noctalia 没有 niri-flake-style auto-spawn, 显式拉起
        spawn-at-startup = [
          {command = ["noctalia"];}
        ];

        # Noctalia IPC 推荐绑定 (官方文档 https://docs.noctalia.dev/v5/getting-started/compositor-settings/niri/)
        binds = {
          # 面板 toggle
          "Mod+Space".action.spawn-sh = "noctalia msg panel-toggle launcher";
          "Mod+S".action.spawn-sh = "noctalia msg panel-toggle control-center";
          "Mod+Comma".action.spawn-sh = "noctalia msg settings-toggle";
          # 音量
          XF86AudioRaiseVolume.action.spawn = ["noctalia" "msg" "volume-up"];
          XF86AudioLowerVolume.action.spawn = ["noctalia" "msg" "volume-down"];
          XF86AudioMute.action.spawn = ["noctalia" "msg" "volume-mute"];
          # 亮度
          XF86MonBrightnessUp.action.spawn = ["noctalia" "msg" "brightness-up"];
          XF86MonBrightnessDown.action.spawn = ["noctalia" "msg" "brightness-down"];
        };
      };
    };
  };
}
