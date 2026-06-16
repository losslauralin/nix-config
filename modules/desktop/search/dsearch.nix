# modules/desktop/search/dsearch.nix
#
# lossilk.desktop._.search._.dsearch - DankSearch desktop search backend (HM-only)
#
# 本地文件索引 + HTTP API daemon (default :43654). HM 模块自动建 systemd user service
# `dsearch serve`, 登录时启动. 索引 ~/Documents / ~/Projects 等路径 (默认配置),
# 提供后端给 DMS spotlight 等搜索前端调用.
#
# 官方文档: https://danklinux.com/docs/danksearch/nixos-flake
#
# 本切面是 host-locked sub-aspect (跟 DMS / Noctalia 一档), 由 host 主切面通过 includes
# 选用 —— 默认接进 DMS host (DMS spotlight 后端). Noctalia host 不引 (Noctalia 自己有
# launcher 后端). 真要用也只需要 host 主切面 includes 里加 `desktop._.search._.dsearch`.
#
# 配置块沿用上游默认值 (~/Documents max_depth=6, ~/Projects max_depth=8, 标准文本扩展).
# 真机用户路径不同的话再针对 host 改 (用 host 主切面 `provides.<user-name>` 路由).
{inputs, ...}: {
  lossilk.desktop._.search._.dsearch.homeManager = {pkgs, ...}: {
    imports = [inputs.danksearch.homeModules.dsearch];

    programs.dsearch = {
      enable = true;
      # 上游 flake 自带的 go-modules vendorHash 跟 nixpkgs-unstable 漂移
      # (danksearch 锁的 nixpkgs.follows = "nixpkgs", 我们的 nixpkgs 是 nixos-unstable,
      # Go module 解析得到不同 hash). 官方文档明文: "DankSearch is now available in
      # nixpkgs unstable! ... native nixpkgs installation method which doesn't require flakes."
      # 退路: 用 nixpkgs 那份打好的包 (0.2.1), 仅 HM 模块还从 flake 引 (nixpkgs 还没收 HM 模块).
      package = pkgs.dsearch;
    };
  };
}
