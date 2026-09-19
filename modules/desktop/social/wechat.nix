# lossilk.desktop._.social._.wechat —— 微信 (Linux 原生客户端)。
#
# 选 nixpkgs 的 `wechat-uos` 而不是同名的 `wechat`:
#   - `wechat` 是官方 AppImage, nixpkgs 从 web.archive.org 取包 (上游下载链接
#     不稳定, hash 只能锁存档快照), 国内取包很慢, 容易卡在 FOD 下载上;
#     `wechat-uos` 取的是统信商店里的 deb —— 同一份腾讯官方客户端, 走国内 CDN。
#   - `wechat-uos` 的 launcher 自带输入法处理: 设 `QT_QPA_PLATFORM=xcb`, 并在
#     `XMODIFIERS` 含 fcitx 时设 `QT_IM_MODULE`/`GTK_IM_MODULE=fcitx`。
#
# 它跑在 buildFHSEnv 里; 该环境会把宿主机的顶层目录 (含 /run/current-system) 与
# /nix 一起 bind 进去, 所以会话里继承的 GTK_PATH / QT_PLUGIN_PATH 仍有效 ——
# fcitx5-gtk immodule 和 fcitx5-qt 插件都能被找到 (后者的 Qt5 目录由输入法切面补)。
#
# 兜底: 想换官方 AppImage 版就把下面换成 `pkgs.wechat`; 代价是走 web.archive.org
# 下载, 而且没有上面那套 launcher 环境处理, 输入法/缩放要自己接。
_: {
  lossilk.desktop._.social._.wechat.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.wechat-uos];
  };
}
