# modules/den.nix
#
# Den 主入口 —— 框架接线、namespace、全局默认。
{
  inputs,
  den,
  lib,
  ...
}: {
  _module.args.__findFile = den.lib.__findFile;

  imports = [
    inputs.den.flakeModule
    (inputs.den.namespace "lossilk" true)
  ];

  # 全局默认切面: 框架级默认。
  # host->user 拓扑由 den 内建 host-to-users policy 处理；user 主切面 includes
  # 会在 user resolution 中解析，并作为 nixos contribution 汇回 host。
  # 不在这里全局启用 host-aspects：它只用于把 host aspect tree 中的
  # homeManager/hjem 等 user.classes 投影给 user，不能解释 user includes 是否生效。
  den.default = {
    includes = [
      den.batteries.define-user
      den.batteries.hostname

      ({class, ...}: {
        # 仅当前 class 是 nixos 时注入系统级特质。
        ${
          if class == "nixos"
          then "nixos"
          else null
        } = {
          nixpkgs.config.allowUnfree = true;
          system.stateVersion = "26.05";
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
        };
        # 仅当前 class 是 nix-darwin 时注入 Darwin 特质。
        ${
          if class == "darwin"
          then "darwin"
          else null
        } = {
          nixpkgs.config.allowUnfree = true;
          system.stateVersion = 6;
        };
      })

      (_: {
        homeManager = {
          programs.home-manager.enable = true;
          home.stateVersion = "26.05";
        };
      })
    ];
  };

  den.schema.user.classes = lib.mkDefault ["user" "homeManager"];
}
