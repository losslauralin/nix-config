# modules/desktop/search/dsearch.nix
#
# lossilk.desktop._.search._.dsearch - DankSearch desktop search backend
#
# 本地文件索引 + HTTP API daemon (default :43654). NixOS 模块自动建 systemd user service
# `dsearch serve`, 登录时启动. 索引 ~/Documents / ~/Projects 等路径 (默认配置),
# 提供后端给 DMS spotlight 等搜索前端调用.
#
# 官方文档: https://danklinux.com/docs/danksearch/nixos-flake
#
# 本切面是 host-locked sub-aspect (跟 DMS / Noctalia 一档), 由 host 主切面通过 includes
# 选用 —— 默认接进 DMS host (DMS spotlight 后端). Noctalia host 不引 (Noctalia 自己有
# launcher 后端). 真要用也只需要 host 主切面 includes 里加 `desktop._.search._.dsearch`.
#
# 配置块沿用上游默认值. 真机用户路径不同的话再针对 host 改.
_: {
  lossilk.desktop._.search._.dsearch.nixos = {pkgs, ...}: {
    programs.dsearch = {
      enable = true;
      package = pkgs.dsearch;
    };
  };
}
