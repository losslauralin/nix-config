# modules/den.nix
#
# Den 主入口 —— 引入框架配置和实体声明
# 保留此文件作为已知位置（文档引用）
{...}: {
  imports = [
    ./flake-parts/den-config.nix
    ./flake-parts/hosts.nix
  ];
}
