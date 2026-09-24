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
    # 本机外置音乐库的挂载点 (fact): 音乐只增不减, 不跟 LUKS 里的系统盘抢快照。
    # 只有真机有这块盘, 所以只写在这台的 spec; 别的 host 不写, 消费者 (lossilk.music)
    # 读到缺失就退回本地 ~/Music。
    storage.music = "/mnt/win_d/Music";
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
      ai._.paseo-daemon # Paseo daemon: host 级常驻服务, 跑在 loss 用户下
      ai._.paseo # Paseo 桌面客户端: GUI 应用, 只上有桌面的机器
      desktop._.gui
      desktop._.platform._.gstreamer # WebKitGTK 媒体 element: 缺了会让 Tauri 应用白屏/卡加载
      desktop._.apps._.bottles # Wine prefix 管理器: 用户会话 GUI 应用
      desktop._.apps._.aghub # AI coding agent 统一配置中心 (Tauri GUI)
      desktop._.apps._.file-manager # GUI 文件管理器 (Nautilus): 真机有 GUI + udisks2
      desktop._.apps._.obsidian
      desktop._.social._.qq
      desktop._.social._.telegram
      desktop._.social._.wemeet
      desktop._.social._.wechat
      desktop._.localsend
      gaming._.max
      music # 本地音乐库: yt-dlp 下载 + beets 整理 + Gapless 播放
      security._.sops
      system._.boot._.plymouth # 图形启动画面 / quiet boot
      system._.filesystems._.ntfs # Windows 数据盘按需挂载支持
      system._.peripherals._.bluetooth # 真机蓝牙外设支持
      system._.power-mgmt # 笔记本电源模式 / thermal / upower
      networking._.clash-verge # Clash Verge Rev GUI: TUN 走 root 特权服务 (非 setuid)
      networking._.tailscale # tailnet 组网: 远程访问 + exit node
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

      # WebKitGTK + NVIDIA 专有驱动在 Wayland 下的既有缺陷 (tauri-apps/tauri#9394,
      # 官方文档 https://v2.tauri.app/develop/debug/linux-graphics/ 收录):
      # WebKitGTK 的 DMA-BUF 渲染器会向 NVIDIA 驱动要它不提供的 buffer 格式,
      # 导致 Tauri 应用启动即崩:
      #   Gdk-Message: Error 71 (协议错误) dispatching to Wayland display.
      #
      # 官方四级缓解措施里, 这是第 2 级 —— 关掉 explicit sync 后 NVIDIA 回退到
      # implicit sync, 官方说法是 "often fixes the Wayland Error 71 crash without
      # a performance cost", 即**保留硬件加速**。本机已实测: 单加这个变量就不再
      # 崩溃 (完整跑完, 后端 200 OK, 前端 JS 执行)。
      #
      # 为什么不一起加第 3 级 WEBKIT_DISABLE_DMABUF_RENDERER=1:
      # 那一级是第 2 级不管用时才用的, 代价是关掉一条更快的渲染路径。本机这个
      # 变量从未被隔离验证过 —— 当时它和别的变量混在一起测, 而真正让 GLib
      # CRITICAL / 白屏消失的是 GStreamer 插件 (见 desktop/platform/gstreamer.nix,
      # 那才是白屏的真因)。所以这里不加, 除非将来实测证明非加不可。
      #
      # 为什么写在这里 (host 而非 aghub 的切面): "这台机器有 NVIDIA" 是机器事实。
      # 同一个 aghub 包也装在 VM host 上, VM 没有 NVIDIA, 无条件给包加变量
      # 会让它白白降级渲染。这里也不写 `if host.gpu == ...`: host spec 只写值。
      #
      # 曾经这里还叠过 WEBKIT_SKIA_ENABLE_CPU_RENDERING=1, 理由是 SkiaGPUWorker
      # 线程在 libnvidia-eglcore 析构期段错误 (WebKitWebProcess SIGSEGV,
      # GrDirectContextD1Ev <- SkiaGLContext strongDeref <- __call_tls_dtors)。
      # 已实测隔离: 那个崩溃的**真正触发条件是关掉上面这个 implicit sync**,
      # 不是缺 CPU 渲染。三层对照 (同一 aghub, 复现「模型设置」弹窗):
      #   保留 L2 + 保留 CPU_RENDERING -> 正常 (旧配置)
      #   保留 L2 + 去掉 CPU_RENDERING -> 正常  <- 证明 CPU_RENDERING 冗余
      #   去掉 L2 + 去掉 CPU_RENDERING -> SIGSEGV, 栈与上面记录一致
      # 即: 只要 __NV_DISABLE_EXPLICIT_SYNC=1 在, SkiaGPUWorker 就不会踩到那个
      # 析构路径, 无需放弃 GPU 绘制。曾把该崩溃误判为独立缺陷, 是因为当时它和
      # 缺 GSettings schema (见 pkgs/by-name/aghub: 缩放错乱, 会放大异常渲染路径)
      # 混在一起观察。故**不再**设 CPU_RENDERING, 保留硬件加速。
      # 若将来 NVIDIA 修掉 explicit sync 下的这个崩溃, 可再删掉这一行回到完全默认。
      environment.sessionVariables = {
        __NV_DISABLE_EXPLICIT_SYNC = "1";
      };

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
