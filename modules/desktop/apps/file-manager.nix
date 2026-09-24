# lossilk.desktop._.apps._.file-manager —— GUI 文件管理器 (Nautilus)。
#
# 选择 Nautilus (GNOME Files) 的理由: 本机是 Wayland-only 的
# Umbriel + Noctalia 路线, 且 xdg.portal 只挂 gtk 后端
# (desktop/platform/portal.nix), 已经是 GTK 栈。Nautilus 是 GTK4/libadwaita,
# 与这套栈 + catppuccin 主题一致, Wayland 原生, 和 gtk portal 配合最顺。
# (Dolphin 功能更强, 但会拉进整套 KDE Frameworks, 主题也跟 Noctalia 不统一;
#  Thunar/Nemo 是 GTK3, 缩略图/归档还要额外插件。)
#
# 默认文件管理器: 不用 Nix 声明, 在 GUI 里点一次 "设为默认"。
#   (曾经用 `xdg.mimeApps.defaultApplicationPackages`, 但那个开关会整体
#    接管 `~/.config/mimeapps.list`, 跟运行时会写该文件的 GTK 应用冲突;
#    详见下面 homeManager 块里的注释。)
#
# 这里不写 udisks/gvfs 挂载服务: 移动盘按需挂载是 host 事实, 已在真机 spec 里
# 由 services.udisks2 提供 (mechrevo-nixos-noctalia), VM 没有该盘。
#
# `FILE_MANAGER` 环境变量: 由本切面 (文件管理器的所有者) 导出, 供 compositor
# 的键位 seam 消费 (desktop/compositor/umbriel.nix 的 `Mod+E`), 与
# `Mod+Return`/`Mod+B` 消费 `TERMINAL`/`BROWSER` 同一模式。
# (`Mod+P` 曾被用作这个 seam, 但上游 Umbriel 把 `Mod+P` 绑给了
#  window-toggle-pinned, 所以文件管理器换到 `Mod+E`。)
# 与那两者不同之处: `TERMINAL`/`BROWSER` 是 XDG 通用名且在 glue 里设, 因为它们
# 没有单一所有者 (谁装终端谁装浏览器是 host 的事); 而 "文件管理器是 nautilus"
# 这个事实属于本切面, 所以值写在这里而不是 glue, 免得知识被拆成两处。
_: {
  lossilk.desktop._.apps._.file-manager = {
    homeManager = {
      pkgs,
      lib,
      ...
    }: {
      home.packages = [
        pkgs.nautilus
      ];

      # 键位 seam 的值。mkDefault 是为了让别的 host 将来想换文件管理器时,
      # 能在自己的 include 里覆盖而不用改这里。
      home.sessionVariables.FILE_MANAGER = lib.mkDefault "nautilus";

      # 这里**故意不设** xdg.mimeApps(默认关联) —— 两个原因:
      #
      # 1. `~/.config/mimeapps.list` 是运行时状态, 不是声明式配置。GTK 应用
      #    (codex-desktop, clash-verge, telegram, thunderbird 等) 每次启动
      #    都会重写整个文件来抢占自己的协议关联, 条目跨应用累积。
      #    这正是本仓库对 aghub / obsidian 用的同一条规矩: 应用自己维护的
      #    运行时状态交给应用, 用 Nix 生成会跟它打架。
      #
      # 2. 一旦 xdg.mimeApps.enable = true, HM 就整体接管该文件, 激活会因为
      #    "Existing file would be clobbered" 直接失败 (真机已复现); 就算加
      #    force = true 压过去, 运行时改默认关联也会静默失效。
      #
      # 代价: nautilus 的 `inode/directory` 默认关联需要你在 GUI 里点一次
      # "设为默认文件管理器", 那是一次性操作。注意 `defaultApplicationPackages`
      # 在 enable = false 时完全不生效 (不是"只存值不生成文件", 而是文件根本
      # 不被声明), 所以留着它只会误导, 已一并去掉。
    };
  };
}
