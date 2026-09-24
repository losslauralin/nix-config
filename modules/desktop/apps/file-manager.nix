# lossilk.desktop._.apps._.file-manager —— GUI 文件管理器 (Nautilus)。
#
# 选择 Nautilus (GNOME Files) 的理由: 本机是 Wayland-only 的
# Umbriel + Noctalia 路线, 且 xdg.portal 只挂 gtk 后端
# (desktop/platform/portal.nix), 已经是 GTK 栈。Nautilus 是 GTK4/libadwaita,
# 与这套栈 + catppuccin 主题一致, Wayland 原生, 和 gtk portal 配合最顺。
# (Dolphin 功能更强, 但会拉进整套 KDE Frameworks, 主题也跟 Noctalia 不统一;
#  Thunar/Nemo 是 GTK3, 缩略图/归档还要额外插件。)
#
# 默认文件管理器:
#   用 `xdg.mimeApps.defaultApplicationPackages` 而不是手写
#   `defaultApplications."inode/directory" = "org.gnome.Nautilus.desktop"`。
#   前者收的是 **包**, MIME 关联由 Nix 从该包自己的 .desktop 文件推出, 所以
#   不需要在这里硬编码 desktop 文件名 (那正是容易写错、且本仓库没有先例的东西)。
#   不设这一项的话, 浏览器 "打开下载目录" / portal / 其他程序的 "显示所在位置"
#   仍然会走到别处, 装了也等于没生效。
#
# 这里不写 udisks/gvfs 挂载服务: 移动盘按需挂载是 host 事实, 已在真机 spec 里
# 由 services.udisks2 提供 (mechrevo-nixos-noctalia), VM 没有该盘。
#
# `FILE_MANAGER` 环境变量: 由本切面 (文件管理器的所有者) 导出, 供 compositor
# 的键位 seam 消费 (desktop/compositor/umbriel.nix 的 `Mod+P`), 与
# `Mod+Return`/`Mod+B` 消费 `TERMINAL`/`BROWSER` 同一模式。
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

      # `xdg.mimeApps.enable` 默认是 false: 不开这个开关, 下面的
      # defaultApplicationPackages 只是把值存进 config, 不会生成 mimeapps.list,
      # 默认关联等于没设 (已用 nix eval 验证: enable=false 时 defaultApplications 为空)。
      xdg.mimeApps.enable = true;

      xdg.mimeApps.defaultApplicationPackages = [
        pkgs.nautilus
      ];
    };
  };
}
