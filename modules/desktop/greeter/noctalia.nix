# lossilk.desktop._.greeter._.noctalia —— Noctalia Greeter capability (greetd)。
#
# "The Noctalia Family" 第三件: greetd 登录界面, 跟 Noctalia shell 用同一套
# wallpaper / palette / 字体, 所以从开机到进桌面观感一致。
# 自带 wlroots compositor (greetd 拉起 `noctalia-greeter-session`), 与桌面 compositor 无关。
#
# 走 nixpkgs 原生 `services.displayManager.noctalia-greeter`:
#   - 自动 enable greetd、Polkit、AccountsService, 并接管 greetd default_session
#   - settings → /var/lib/noctalia-greeter/greeter.toml; Nix 侧按 host schema 填 XKB 布局
#   - 登录界面自己记住上次会话 (sync.toml), 这里只钉默认会话
#
# Umbriel session 由 compositor 切面经 `programs.umbriel` 注册进
# `services.displayManager.sessionPackages`, greeter 才能发现它。
_: {
  lossilk.desktop._.greeter._.noctalia.nixos = {
    services.displayManager.noctalia-greeter = {
      enable = true;

      settings = {
        # 值是 desktop entry 的 Name=, 不是 .desktop 文件名 (大小写不敏感)
        session.default = "Umbriel";
        keyboard = {
          layout = "us";
          numlock = true;
        };
      };
    };
  };
}
