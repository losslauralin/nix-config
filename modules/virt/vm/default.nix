# modules/virt/vm/default.nix
#
# lossilk.virt._.vm - qemu VM guest 配置 (sub-aspect, host-locked)
#
# 通用 qemu guest 设置 (跨多 VM host 可复用), vmVariant 内调资源 + 转发端口 + 开 sshd.
# vmVariant 内的设置仅在 `nixos-rebuild build-vm` 输出中生效, 不污染真机配置.
#
# 变体 (headless / 带 GPU 透传等) 在 modules/virt/vm/<variant>.nix 内各自重写一
# 份独立的 nixos 块: 不直接 include 父切面, 是因为 qemu.options 是 listOf str,
# NixOS module 系统的 list merge 是拼接不是替换 —— 子切面 mkForce 会丢掉 nixpkgs
# module 自动加的 -kernel/-initrd/-append, QEMU 找不到可启设备. 重写 nixos 块
# 需要重复 qemuGuest + 占位 fs/grub (8 行), 成本低, 不抽公共 base.
{
  lossilk.virt._.vm.nixos = {
    services.qemuGuest.enable = true;

    # 占位 fs + bootloader: VM host 走 vmVariant 自动覆盖, 这些值仅为让 toplevel
    # 评估通过 (nix flake check 会检 system.build.toplevel, 不止 build.vm).
    fileSystems."/" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "ext4";
    };
    boot.loader.grub = {
      enable = true;
      devices = ["nodev"];
    };

    virtualisation.vmVariant = {
      virtualisation = {
        memorySize = 4096;
        cores = 4;
        graphics = true;
        qemu.options = [
          # virtio-vga-gl + virgl: 给 guest 提供真 EGL_EXT_device_drm, niri 起来必须.
          "-device virtio-vga-gl"
          # gtk + gl=on: 配合 virtio-vga-gl, host GPU 经 virglrenderer 加速 guest GL.
          # grab-on-hover=on: 鼠标进 VM 窗口自动抓键盘, 释放是 Ctrl+Alt+G. 这是为
          # 让 Mod (Super) 键不被宿主机的 hyprland/niri/sway/i3 等 Wayland WM 截获,
          # 而是直接传给 VM 内的 niri. 不抓的话 host WM 会先收 Super 触发自己绑定.
          # 注: NixOS-built qemu (nix store 的) 在非-NixOS host 上找 /run/opengl-driver
          # 失败, 必须用 host 系统的 qemu binary 跑 (Arch: 经 scripts/run-vm-arch.sh
          # 把 /nix/store/...-qemu/.../qemu-system-x86_64 替换成 /usr/bin/qemu-system-x86_64).
          "-display gtk,gl=on,show-cursor=on,grab-on-hover=on"
          "-device virtio-rng-pci"
          # 诊断兜底: serial 接到 launcher 终端 stdio. NixOS vmVariant 默认 kernel
          # 参数已含 console=ttyS0,115200n8 console=tty0, 黑屏时仍能在启动 VM 的终端
          # 看到 kernel + userspace 日志 (greetd / niri 失败原因等). monitor 跟 stdio
          # 多路复用 (mon:stdio), 不需要额外终端.
          "-serial mon:stdio"
        ];
        forwardPorts = [
          {
            from = "host";
            host.port = 2222;
            guest.port = 22;
          }
        ];
      };

      # VM 内开 sshd 方便从 Arch host 调试
      services.openssh = {
        enable = true;
        settings = {
          PermitRootLogin = "no";
          PasswordAuthentication = true;
        };
      };
    };
  };
}
