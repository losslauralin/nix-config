# Host: mechrevo-nixos-noctalia —— 真机 (MECHREVO 耀世 16 Pro GM6IX0B),
# "The Noctalia Family" 桌面: Umbriel compositor + Noctalia shell + Noctalia Greeter。
# 由原 niri + DankMaterialShell 方案就地改造; 硬件/磁盘事实保持不变:
#   - ./_disko.nix          声明式分区 (Btrfs-on-LUKS)
#   - ./facter.json         硬件探测报告 (真机 sudo nixos-facter 生成)
#   - nixos-hardware.*       机型通用调优
# Windows NTFS 数据盘 (nvme1n1) 只用 udisks2 按需挂, 不进 disko.
{
  inputs,
  lossilk,
  ...
}: {
  # den.schema.host.displays 是 host entity 的 schema option: 必须声明在 entity 上
  # (`den.hosts...`), 写在生成切面 (`den.aspects...`) 上会被静默忽略, 消费方
  # (compositor outputs / gaming Display）会拿到空值。
  den.hosts.x86_64-linux.mechrevo-nixos-noctalia = {
    users.loss = {};
    displays.eDP-1 = {
      primary = true;
      refresh = 240.0;
      width = 2560;
      height = 1600;
      scaling = 1.35;
    };
  };

  den.aspects.mechrevo-nixos-noctalia = {
    users.loss = {};
    includes = with lossilk; [
      desktop._.umbriel-noctalia-desktop
      ai._.axonhub._.local
      desktop._.gui
      desktop._.social._.qq
      desktop._.social._.telegram
      desktop._.social._.wemeet
      desktop._.social._.wechat
      desktop._.localsend
      gaming._.max
      security._.sops
      system._.boot._.plymouth # 图形启动画面 / quiet boot
      system._.filesystems._.ntfs # Windows 数据盘按需挂载支持
      system._.peripherals._.bluetooth # 真机蓝牙外设支持
      system._.power-mgmt # 笔记本电源模式 / thermal / upower
      networking._.clash-verge # Clash Verge Rev GUI: TUN 走 root 特权服务 (非 setuid)
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

      # Early KMS: 把 nvidia KMS 栈提前到 initrd 加载。
      # 本机是 Wayland-only (greetd), services.xserver.enable=false, 所以 nixpkgs 里那段
      # `boot.kernelModules = [nvidia nvidia_modeset nvidia_drm]` (被 xserver.enable 门控) 不生效;
      # 否则 simpledrm(EFI fb) 一直撑到 stage-2, nvidia 接管时与 plymouth 交接 → 进桌面偶发花屏。
      # 不需要重复写 modeset/fbdev (hardware.nvidia.moduleParams 经 extraModprobeConfig 已带入 initrd),
      # 也不需要 nvidia_uvm (CUDA 用, 保持 nixpkgs 的 stage-2 softdep 加载)。GSP 固件随 hardware.firmware 进 initrd。
      boot.initrd.kernelModules = ["nvidia" "nvidia_modeset" "nvidia_drm"];

      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;
      zramSwap.enable = true;

      # Windows NTFS 数据盘 (nvme1n1p1, label 数据): 绝不分区/格式化 → 不进 disko;
      # 开机 rw 挂到 /mnt/win_d. nofail: 盘不在也不阻塞开机.
      # 注意: Windows 侧保持快速启动/休眠关闭, 否则脏卷会让 ntfs3 降级只读挂载.
      fileSystems."/mnt/win_d" = {
        device = "/dev/disk/by-uuid/CEEB00109B98B771";
        fsType = "ntfs3";
        options = ["rw" "uid=1000" "gid=100" "iocharset=utf8" "nofail" "x-systemd.device-timeout=10"];
      };

      # 其余移动盘/临时盘仍由 udisks2 按需挂 (文件管理器点击 / udisksctl).
      services.udisks2.enable = true;

      services.fwupd.enable = true; # 固件更新 (真机)

      nixpkgs.hostPlatform = "x86_64-linux";
      # Noctalia Greeter 负责 greetd 登录界面与用户会话选择.
    };

    # user class 路由到 users.users.loss.extraGroups
    user.extraGroups = ["video" "input"];
  };
}
