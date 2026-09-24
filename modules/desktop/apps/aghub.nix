# lossilk.desktop._.apps._.aghub —— aghub (AI coding agent 统一配置中心, Tauri GUI)。
#
# 包本身是仓库本地 by-name 包 (pkgs/by-name/aghub), 从上游 .deb release 资产
# 重打包: 上游不提供任何 Nix 表达式, Linux 只发 .deb/.rpm/AppImage。
# 这里只做布线, 打包逻辑 (fetch/解包/patchelf/meta) 全在那个 derivation 里。
#
# `inputs` 取在外层: den 的 class module (homeManager) 只注入 pkgs/lib 等,
# 不注入 inputs —— 写进 class module 的函数签名会在求值时炸
# ("attribute 'inputs' missing")。消费本地包的既定形态是显式取
# `inputs.self.packages.${system}.<name>` (同 fcitx5-rime-wanxiang.nix),
# 而不是靠 `pkgs.aghub`: 后者会把 "这是本地包还是 nixpkgs 包" 藏起来。
#
# 不写 `programs.aghub`: Home Manager 没有这个模块, 而且 aghub 是自带 GUI 的
# 配置管理器, 它的状态 (MCP server / skill / plugin) 由应用自己在运行期写,
# 不是 Nix 该生成的文件 —— 同 obsidian.nix 里 "settings 交给应用自己维护" 的理由。
# 所以这里只装包, 不碰任何配置文件; 声明式接管它的状态是错的分层。
{inputs, ...}: {
  lossilk.desktop._.apps._.aghub.homeManager = {pkgs, ...}: {
    home.packages = [
      inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.aghub
    ];
  };
}
