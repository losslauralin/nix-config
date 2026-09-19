# lossilk.desktop._.apps._.obsidian —— Obsidian (Electron 打包的知识库客户端)。
#
# 走 Home Manager 的 `programs.obsidian`, 不用裸 `home.packages`:
#   - 它做的就是在 `obsidian.json` 里登记 vault 列表 (`vaults.<name>.target`),
#     手动装包不会建这个索引, 首次启动还得在 GUI 里逐个 "Open folder as vault"。
#   - 只声明 `vaults` 而不声明 settings/缩进插件/snippet: 那些是应用内会改写的状态
#     (app.json / appearance.json / community-plugins.json), 交给 obsidian 自己维护,
#     免得每次 switch 把用户在 GUI 里改的偏好覆盖回去。
#   - 该模块的 activation 是 merge 而不是覆盖: 已有的 obsidian.json 用
#     `jq -s '.[0] * .[1]'` 合并, 所以窗口位置、最近 vault 等运行期键不会被清掉。
#   - `updateDisabled = true` 由模块写进 obsidian.json: nix store 是只读的,
#     应用内自动更新必然失败, 关掉它避免无谓的重启提示。
#
# 不在这里加 ozone/wayland 启动参数。Electron 的 wrapper 只在 `NIXOS_OZONE_WL`
# 非空且 `WAYLAND_DISPLAY` 存在时才追加 `--ozone-platform=wayland
# --enable-wayland-ime=true --wayland-text-input-version=3`, 那组标志是给
# "只想在个别程序上开 Wayland" 用的。本机是 Wayland-only (Umbriel), 没有全局开
# NIXOS_OZONE_WL, 所以这里跟 qq.nix 一样用包自带的 `commandLineArgs` 显式补:
#   - text-input-v3 是 fcitx5 的 Wayland frontend 唯一通道, 缺了 Obsidian 的正文
#     编辑器就吞中文输入 (fcitx5-rime-wanxiang 依赖它)。
#   - `WaylandWindowDecorations`: Umbriel 是 client-side decoration 模型, 缺了它
#     窗口没有服务端边框, 会变成无边框窗口。
# 该包是预编译 Electron 应用, 没有 Qt/GTK immodule 路径问题, 不需要 qt 那套包装。
_: {
  lossilk.desktop._.apps._.obsidian.homeManager = {pkgs, ...}: {
    programs.obsidian = {
      enable = true;
      package = pkgs.obsidian.override {
        commandLineArgs = "--ozone-platform=wayland --enable-features=WaylandWindowDecorations --enable-wayland-ime=true --wayland-text-input-version=3";
      };

      # vault 是普通 Markdown 目录, 不是 Nix 管理的内容 (内容在应用内写),
      # 这里只登记路径。x86_64-linux 下 obsidian 是正牌 Linux 桌面程序,
      # 所以 target 用相对 $HOME 的相对路径 (与 xdg.userDirs 的 Documents 对齐)。
      vaults.notes.target = "Documents/notes";
    };
  };
}
