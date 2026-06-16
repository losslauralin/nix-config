# modules/flake-parts/nixpkgs.nix
#
# perSystem pkgs instance and flake-level overlays
{
  inputs,
  withSystem,
  ...
}: {
  systems = ["x86_64-linux"];

  # 使用 pkgs-by-name-for-flake-parts 暴露 pkgs/by-name 目录下的包
  # 它会自动扫描 pkgs/by-name/<first-letter>/<name>/package.nix 结构的包
  imports = [
    inputs.pkgs-by-name-for-flake-parts.flakeModule
  ];

  perSystem = {system, ...}: {
    _module.args.pkgs = import inputs.nixpkgs {
      inherit system;
      overlays = [];
      config = {
        allowUnfreePredicate = _pkg: true;
      };
    };

    # 配置 pkgs-by-name-for-flake-parts 使用的目录
    # 默认是 "pkgs/by-name"（相对于 flake root）
    pkgsDirectory = ../../pkgs/by-name;
  };

  # 定义 flake-level overlay 供 NixOS/Home Manager 使用
  # pkgs-by-name-for-flake-parts 会自动将包暴露到 config.packages
  # 这里通过 overlay 让它们可以通过 pkgs.<name> 直接访问
  flake.overlays = {
    default = _final: prev:
      withSystem prev.stdenv.hostPlatform.system ({config, ...}:
        config.packages);
  };
}
