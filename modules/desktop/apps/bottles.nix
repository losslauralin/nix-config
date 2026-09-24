# lossilk.desktop._.apps._.bottles —— Bottles (Wine/Proton prefix 管理器)。
#
# GUI 应用, 纯用户会话语义: 只用 homeManager class, 装在 home.packages。
# 不写 nixos 半边 —— Bottles 自己管理 prefix, 没有需要 root 的系统服务或 udev 规则;
# wine/umu-launcher/gamescope 这些运行时依赖已经由包本身 (propagatedBuildInputs) 带入,
# 不需要在 host 上另开 gaming 切面。
#
# override removeWarningPopup: nixpkgs 的 bottles 默认带一个"非沙箱环境不支持"的启动弹窗
# (upstream 只支持 Flatpak 沙箱; nixpkgs 打包版是官方不背书的第三方分发)。这个弹窗纯提示,
# 不影响功能, 但每次启动都弹。removeWarningPopup = true 换掉那个 patch, 去掉弹窗。
# 若只想保留提示, 去掉 override 用 pkgs.bottles 即可。
_: {
  lossilk.desktop._.apps._.bottles.homeManager = {pkgs, ...}: {
    home.packages = [
      (pkgs.bottles.override {removeWarningPopup = true;})
    ];
  };
}
