# modules/hosts/nixos-wsl/default.nix
#
# Host: nixos-wsl —— WSL2 NixOS 主机实体 + 主切面
{lossilk, ...}: {
  den.hosts.x86_64-linux.nixos-wsl = {
    wsl.enable = true;
    users.loss = {};
  };

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
