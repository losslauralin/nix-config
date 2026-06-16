# modules/hosts/nixos-wsl/default.nix
#
# Host: nixos-wsl —— WSL2 NixOS 主机主切面
# 实体声明在 modules/den.nix (`wsl.enable = true` 触发 den.batteries.wsl)
{lossilk, ...}: {
  den.aspects.nixos-wsl = {
    includes = with lossilk; [
      system # 系统底座 (locale / 时区 / TTY console)
      nix # nix.conf 底座 (substituters / GC / 实验特性)
      virt._.wsl # 通用 WSL 切面 (wslConf + programs.nix-ld + HM 别名/wslu)
    ];

    # host 专属 nixos 配置 (不是通用 WSL 切面会有的东西)
    nixos = _: {
      wsl.docker-desktop.enable = true;
      wsl.useWindowsDriver = true;
      nixpkgs.hostPlatform = "x86_64-linux";
    };
  };
}
