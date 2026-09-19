# lossilk.desktop._.apps._.wemeet —— 腾讯会议 (Linux 客户端)。
#
# nixpkgs 的 `wemeet` 已经带上游修复补丁:
#   - libwemeetwrap          (把 sink 伪装成硬件 sink, 避免播不出声)
#   - wemeet-x11-fix         (Wayland 下 XSetInputFocus 崩溃)
#   - wemeet-camera-fix      (Wayland 摄像头预览)
#   - wemeet-wayland-screenshare hook (Wayland 下通过 portal + PipeWire 共享屏幕)
#
# wrapper 提供两个入口:
#   - `wemeet`          原生 Wayland; 共享 hook 只在 `XDG_SESSION_TYPE=wayland` 时预载
#   - `wemeet-xwayland` 强制 `QT_QPA_PLATFORM=xcb` 并取消 `WAYLAND_DISPLAY` (同样预载共享 hook)
#
# 屏幕共享走 xdg-desktop-portal-umbriel 的 ScreenCast (Umbriel 的 portal 已由
# `programs.umbriel.enable` 接进 xdg.portal, 选择器窗口规则在桌面路线 glue 里)。
#
# 中文输入: wemeet 自带 Qt5, 不认 nixpkgs 的 Qt 插件前缀, 依赖 `QT_IM_MODULE=fcitx`
# 加上 fcitx5-qt5 的 platforminputcontext 插件。该插件目录由 fcitx5 切面补进
# `QT_PLUGIN_PATH` (见 desktop/input/fcitx5-rime-wanxiang.nix)。
# 如果原生 Wayland 下仍无法输入中文, 用 `wemeet-xwayland` 兜底 —— X11 走 XIM
# (本机 fcitx5 的 X Input Method Frontend 已启用, steam 等原生 XWayland 程序即走这条)。
_: {
  lossilk.desktop._.apps._.wemeet.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.wemeet];
  };
}
