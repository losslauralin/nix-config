# lossilk.desktop._.umbriel-noctalia-desktop —— "The Noctalia Family" 桌面路线 glue。
#
# Umbriel (compositor) + Noctalia (shell) + Noctalia Greeter 三件一起跑。
# 三件各自是独立能力切面 (compositor._.umbriel / shell._.noctalia / greeter._.noctalia-greeter)。
#
# 本 glue 不向 Umbriel 写任何配置: Umbriel 若存在 `~/.config/umbriel/config.toml`,
# 包内那份 (= 上游 examples/config.toml, 含完整默认 input/appearance/layout/keybinds/
# window_rule/layer_rule/hot_corners) 就会被整块跳过。因此 Noctalia 的 autostart /
# IPC 键位 / 窗口与图层规则都不在这里注入, 由上游默认负责。
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
      desktop._.terminals._.foot
      desktop._.platform._.flatpak
      desktop._.input._.fcitx5-rime-wanxiang
      desktop._.compositor._.umbriel
      desktop._.shell._.noctalia
      desktop._.greeter._.noctalia-greeter
    ];

    homeManager = {lib, ...}: {
      # 终端 (foot) 的配色改由 Noctalia 的 terminal-sequences 模板提供 (见
      # desktop/shell/noctalia.nix): 颜色跟随 Noctalia 当前主题 (含 GUI 覆盖)。
      # 关闭 catppuccin 对 foot 的静态注入, 否则 latte 的浅色会与模板打架, 且终端
      # 配色会有两个来源。其余 GUI 程序的 catppuccin 主题不受影响 (autoEnable 仍在)。
      catppuccin.foot.enable = false;

      home.sessionVariables = {
        BROWSER = lib.mkDefault "google-chrome-stable";
        TERMINAL = lib.mkDefault "foot";
      };
    };
  };
}
