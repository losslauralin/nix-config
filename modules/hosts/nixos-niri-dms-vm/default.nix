# Host: nixos-niri-dms-vm —— qemu VM, 验证 niri + DankMaterialShell desktop 配置。
# 与真机共享 lossilk.desktop._.niri-dms-desktop；本文件只保留 VM host spec。
#
# 构建 + 启动:
#   sudo nix build .#nixosConfigurations.nixos-niri-dms-vm.config.system.build.vm
#   ./result/bin/run-nixos-niri-dms-vm-vm
{lossilk, ...}: {
  den.hosts.x86_64-linux.nixos-niri-dms-vm.users.loss = {};

  den.aspects.nixos-niri-dms-vm = {
    # host includes 收 nixos class 到本 host；其中的 homeManager/hjem 等 user classes
    # 由明确 opt-in 的 user（modules/users/loss.nix 中 den.batteries.host-aspects）接收。
    includes = with lossilk; [
      desktop._.niri-dms-desktop
      virt._.vm
      ai._.axonhub._.local
      desktop._.gui
      desktop._.localsend
      security._.sops
      system._.boot._.plymouth
    ];

    # host spec nios class
    nixos = _: {
      nixpkgs.hostPlatform = "x86_64-linux";
      # DMS greeter 负责 greetd 登录界面与用户会话选择.
    };

    # user class 路由到 users.users.loss.extraGroups
    user.extraGroups = ["video" "input"];
  };
}
