# lossilk.desktop._.social._.telegram —— Telegram Desktop (官方 Qt 客户端)。
#
# 选 nixpkgs 的 `telegram-desktop` (main program `Telegram`)。它是普通 Qt6 程序,
# 不是 Electron 打包, 所以不需要 qq 那样的 ozone / wayland-ime 启动标志:
#   - Wayland 原生支持来自 buildInputs 里的 `qtwayland`; Qt6 默认按
#     QT_QPA_PLATFORM 自动选 wayland, 会话已经跑在 Umbriel 下。
#   - 它由 `wrapQtAppsHook` 包装。该 hook 在 wrapper 里用 `--prefix QT_PLUGIN_PATH`
#     追加自己 bundle 的插件目录, 而不是覆盖 —— 所以继承的 QT_PLUGIN_PATH 仍有效,
#     fcitx5-qt6 的 platforminputcontext 插件能被找到 (由
#     desktop/input/fcitx5-rime-wanxiang.nix 写进 QT_PLUGIN_PATH)。
#     配合 fcitx5 的 `QT_IM_MODULE=fcitx`, 中文输入走 Wayland text-input /
#     Qt6 immodule, 与 fcitx5 的 Wayland frontend 一致。
#
# 本切面只负责装包。要改缩放/语言等业务设置, 在应用内调, 不在这里塞配置。
_: {
  lossilk.desktop._.social._.telegram.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.telegram-desktop];
  };
}
