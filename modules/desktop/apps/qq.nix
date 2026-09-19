# lossilk.desktop._.apps._.qq —— 腾讯 QQ (Linux 原生 NT 客户端)。
#
# nixpkgs 的 `qq` 是 Electron 打包, wrapper 只在 `NIXOS_OZONE_WL` 非空时追加
# `--ozone-platform=wayland --enable-features=WaylandWindowDecorations
#  --enable-wayland-ime=true --wayland-text-input-version=3`
# (见 pkgs/by-name/qq/qq/package.nix 的 makeShellWrapper 调用)。
#
# 本机是 Wayland-only (Umbriel)。fcitx5 的 Wayland frontend 在跑 (输入法依赖
# text-input-v3 才能进 Electron 正文), 所以这里用包自带的 `commandLineArgs`
# 显式补同样一组标志, 而不是全局开 NIXOS_OZONE_WL —— 后者会把所有
# Chromium/Electron 程序一起切到 Wayland 并改变它们的输入法路径。
#
# 包装/依赖 (autoPatchelf、libayatana-appindicator 托盘等) 都由 nixpkgs 处理,
# 本切面只负责追加启动标志。
_: {
  lossilk.desktop._.apps._.qq.homeManager = {pkgs, ...}: {
    home.packages = [
      (pkgs.qq.override {
        commandLineArgs = "--ozone-platform=wayland --enable-features=WaylandWindowDecorations --enable-wayland-ime=true --wayland-text-input-version=3";
      })
    ];
  };
}
