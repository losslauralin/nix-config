# lossilk.desktop._.greeter._.noctalia-greeter —— Noctalia Greeter capability (greetd)。
#
# "The Noctalia Family" 第三件: greetd 登录界面, 跟 Noctalia shell 用同一套
# wallpaper / palette / 字体, 所以从开机到进桌面观感一致。
# 自带 wlroots compositor (greetd 拉起 `noctalia-greeter-session`), 与桌面 compositor 无关。
#
# 走 nixpkgs 原生 `services.displayManager.noctalia-greeter`:
#   - 自动 enable greetd、Polkit、AccountsService, 并接管 greetd default_session
#   - settings → /var/lib/noctalia-greeter/greeter.toml; Nix 侧按 host schema 填 XKB 布局
#   - 登录界面自己记住上次会话 (sync.toml), 这里只钉默认会话
#   - cursorTheme 指定的主题会自动加进 environment.systemPackages
#
# Umbriel session 由 compositor 切面经 `programs.umbriel` 注册进
# `services.displayManager.sessionPackages`, greeter 才能发现它。
#
# 上游文档:
#   https://docs.noctalia.dev/greeter/installation/  (NixOS 声明式安装)
#   https://docs.noctalia.dev/greeter/displays/      ([output] 一节)
#   https://docs.noctalia.dev/greeter/sync/          (外观同步)
#
# ---------------------------------------------------------------------------
# 单会话 (为什么 greeter 里只有一个 Umbriel)
# ---------------------------------------------------------------------------
# greeter 自身是通用的: 它列出 sessionPackages 里所有会话的 Name=,
# `settings.session.default` 只是默认选中项, 不是白名单。当前只有一个会
# 出现在登录界面里 —— 本机实测 `noctalia-greeter sessions` 输出 `Umbriel`。
#
# 这是刻意的: AGENTS.md 钉死了本仓库的 supported desktop route 只有
# `lossilk.desktop._.umbriel-noctalia-desktop` (Umbriel + Noctalia shell +
# Noctalia Greeter), "Not a free compositor/shell matrix"。想加第二个会话
# 先改那条路线决策, 不是改这个文件。
#
# 加之前要知道的坑: greeter.toml 由 nixpkgs 模块经 systemd-tmpfiles 生成
# ("L+" 覆盖式软链), 模块自己的注释写明它 "can contain some state, like the
# most recently used session, which will be clobbered on every activation and
# boot"。也就是说这里的 `session.default` 每次 rebuild / 开机都会被重写回去。
# 单会话时无害; 一旦有第二个会话, 用户在登录界面选的默认会话 (存在
# sync.toml 里的那份状态) 每次 activation 后都会被顶掉。
# 这是已知的上游限制 (状态本该搬到另一个文件), 不是本仓库配错了。
#
# 外观同步 (https://docs.noctalia.dev/greeter/sync/) 只写 sync.toml,
# 从不覆盖 greeter.toml, 所以上面的 clobber 不会连累同步过来的
# 壁纸 / 调色板 / layout。
_: {
  lossilk.desktop._.greeter._.noctalia-greeter.nixos = {
    pkgs,
    host,
    ...
  }: {
    services.displayManager.noctalia-greeter = {
      enable = true;

      # 登录界面光标跟桌面一致。桌面侧由 HM 的 home.pointerCursor 设成
      # phinger-cursors-dark (见 desktop/compositor/umbriel.nix) —— 但那是
      # **HM 侧**的包 + ~/.icons/default, greeter 是另一个账号 (greeter)、
      # 在 HM 之前跑的独立 session, 两样都读不到, 所以这里必须单独指定。
      # 不指定就落到模块默认 Adwaita: 登录界面指针一种样式, 进桌面换另一种。
      #
      # 本仓库没把 phinger-cursors 放进系统包 (只有 HM 侧有), 所以
      # `package` 不能省 —— 模块会把它加进 environment.systemPackages。
      # name 用 dark: 与桌面同一套 (light/dark 说的是指针自身颜色, 不是桌面配色)。
      cursorTheme = {
        name = "phinger-cursors-dark";
        package = pkgs.phinger-cursors;
      };

      # 免密码外观同步 (Noctalia Settings → Security → Noctalia Greeter → Sync Now)。
      # 留空 = 每次 sync 都弹管理员认证。这是文档明确支持的长期模式, 不是过渡状态:
      #   "Passwordless authorization is entirely optional... That authenticated
      #    workflow is a supported long-term mode, not a migration step that users
      #    are expected to replace."
      # 弹窗要求桌面会话里有 polkit agent —— 由 Noctalia 的 shell.polkit_agent
      # 提供 (见 desktop/shell/noctalia.nix), 所以认证流程可用。
      passwordlessSyncUsers = [];

      settings = {
        # 值是 desktop entry 的 Name=, 不是 .desktop 文件名 (大小写不敏感)
        session.default = "Umbriel";
        keyboard = {
          layout = "us";
          numlock = true;
        };

        # 显示器: 必须跟桌面会话的 mode/scale 对齐。
        # 不做的话 greeter 用 EDID-preferred mode + 按 EDID 物理尺寸自动算的
        # scale (上限 2), 而桌面跑 2560x1600@240 scale 1.35 —— 登录那一刻会
        # 多一次 modeset + 画面尺寸跳变。上游文档原话:
        #   "Match the resolution and refresh rate to the desktop session to
        #    avoid an unnecessary mode change when logging in."
        #
        # 值从 host spec 的 displays fact 来, 与 compositor 切面同一份来源,
        # 所以两边不可能漂移。连接器名用 host fact 的键 (eDP-1)。
        #
        # 这里用的是上游的**全局形式** (width/height/refresh_rate/scale),
        # 它只能描述一个输出; 多屏要换成映射形式 ("DP-1:120; HDMI-A-1:60" /
        # "DP-1:1; DP-2:1.25"), 那需要给 host fact 加一层每屏覆盖。
        # 真要多屏时在这里补, 别默默取头一个。
        output =
          if host.displays == {}
          then {}
          else let
            connector = builtins.head (builtins.attrNames host.displays);
            display = host.displays.${connector};
          in {
            name = connector;
            inherit (display) width height;
            # 上游字段名是 refresh_rate, host fact 里叫 refresh (240.0)
            refresh_rate = display.refresh;
            # 上游字段名是 scale, host fact 里叫 scaling
            scale = display.scaling;
          };
      };
    };
  };
}
