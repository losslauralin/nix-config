# Host: nixos-noctalia-vm —— qemu VM, 验证 Noctalia 家族桌面配置。
# 与真机 (mechrevo-nixos-noctalia) 共享 lossilk.desktop._.umbriel-noctalia-desktop;
# 本文件只保留 VM host spec。
#
# 构建 + 启动:
#   just build-vm nixos-noctalia-vm
#   just run-vm nixos-noctalia-vm
{lossilk, ...}: {
  den.hosts.x86_64-linux.nixos-noctalia-vm.users.loss = {};

  den.aspects.nixos-noctalia-vm = {
    # host includes 收 nixos class 到本 host；其中的 homeManager/hjem 等 user classes
    # 由明确 opt-in 的 user（modules/users/loss.nix 中 den.batteries.host-aspects）接收。
    includes = with lossilk; [
      desktop._.umbriel-noctalia-desktop
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
      # Noctalia Greeter 负责 greetd 登录界面与用户会话选择.
    };

    # user class 路由到 users.users.loss.extraGroups
    user.extraGroups = ["video" "input"];
  };
}
