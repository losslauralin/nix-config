# modules/hosts/mechrevo-nixos-dms-niri/default.nix
#
# Host: mechrevo-nixos-dms-niri —— 真机 (MECHREVO 耀世 16 Pro GM6IX0B), niri + DankMaterialShell desktop.
# 以 nixos-niri-dms-vm 为模板, 保留同一套用户应用/服务选择, 把 virt._.vm 换成真实硬件:
#   - ./_disko.nix          声明式分区 (Btrfs-on-LUKS)
#   - ./facter.json         硬件探测报告 (真机 sudo nixos-facter 生成)
#   - nixos-hardware.*       机型通用调优
# Windows NTFS 数据盘 (nvme1n1) 只用 udisks2 按需挂, 不进 disko.
{
  inputs,
  lossilk,
  ...
}: {
  den.hosts.x86_64-linux.mechrevo-nixos-dms-niri = {
    users.loss = {};

    displays.eDP-1 = {
      primary = true;
      refresh = 240.0;
      width = 2560;
      height = 1600;
    };
  };

  den.aspects.mechrevo-nixos-dms-niri = {
    # 与 nixos-niri-dms-vm 保持相同用户应用/服务能力; 只排除 virt._.vm。
    includes = with lossilk; [
      desktop._.niri-dms-desktop
      ai._.axonhub._.local
      desktop._.gui
      desktop._.localsend
      gaming._.max
      security._.sops
      system._.boot._.plymouth # 图形启动画面 / quiet boot
      system._.filesystems._.ntfs # Windows 数据盘按需挂载支持
      system._.peripherals._.bluetooth # 真机蓝牙外设支持
      system._.power-mgmt # 笔记本电源模式 / thermal / upower
    ];

    nixos = _: {
      imports = [
        ./_disko.nix # 磁盘布局 (本目录单独文件; import-tree 按 /_ 忽略, 只经此 imports 引入)
        inputs.disko.nixosModules.disko
        inputs.nixos-facter-modules.nixosModules.facter
        inputs.nixos-hardware.nixosModules.common-cpu-intel # microcode + kvm-intel + vaapi
        inputs.nixos-hardware.nixosModules.common-gpu-nvidia-nonprime # videoDrivers=["nvidia"]; 单卡无 iGPU 用 nonprime (common-gpu-nvidia=prime 变体要 busId)
        inputs.nixos-hardware.nixosModules.common-pc-laptop # 电源/acpi
        inputs.nixos-hardware.nixosModules.common-pc-laptop-ssd # fstrim
      ];

      # facter 硬件报告: i7-14650HX / Intel Wi-Fi / Motorcomm YT6801 / NVIDIA AD107M 等。
      hardware.facter.reportPath = ./facter.json;

      # 单卡 NVIDIA RTX 4060 (Ada); facter 探测到卡但不启用驱动, 故手写:
      # (闭源放行: den.default 里 nixpkgs.config.allowUnfree = true, 项目级, 不在本文件)
      hardware.graphics.enable = true;
      hardware.nvidia = {
        modesetting.enable = true;
        open = true; # Ada 用 open 内核模块
      };

      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;
      zramSwap.enable = true;

      # Windows NTFS 数据盘 (nvme1n1p1): 只挂载, 不分区/格式化 → 不进 disko, udisks2 按需挂.
      # 真机: 文件管理器点击, 或 udisksctl mount -b /dev/disk/by-uuid/CEEB00109B98B771 (label 数据).
      services.udisks2.enable = true;

      services.fwupd.enable = true; # 固件更新 (真机)

      nixpkgs.hostPlatform = "x86_64-linux";
      # DMS greeter 负责 greetd 登录界面与用户会话选择.
    };

    # user class 路由到 users.users.loss.extraGroups
    user.extraGroups = ["video" "input"];
  };
}
