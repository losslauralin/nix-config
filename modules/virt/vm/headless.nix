# modules/virt/vm/headless.nix
#
# lossilk.virt._.vm._.headless —— qemu VM 变体: 纯 CLI / 串口, 无 GPU 透传.
#
# 不继承 virt._.vm (其 qemu.options 内置 -device virtio-vga-gl / -display gtk,
# list merge 是拼接不是替换, 子切面 mkForce 会丢掉 nixpkgs module 自动加的
# -kernel/-initrd/-append, 引起 QEMU 找不到可启设备). 这里重写一份独立的 nixos
# 块, 包含 qemuGuest + 占位 fs/grub + headless 专用的 vmVariant (graphics 关,
# 资源调小, forwardPorts 错开 2223).
# 跨变体共享的代码 (qemuGuest + 占位 fs/grub) 是 8 行, 不值得抽公共 base.
_: {
  lossilk.virt._.vm._.headless.nixos = _: {
    # 头less VM 不接显示器, 默认 console=ttyS0 拿不到, 显式给 kernel 推
    # serial console 参数. 配合 vmVariant 的 -nographic (QEMU 内含 serial
    # -> stdio) 在 launcher 终端直接交互.
    boot.kernelParams = ["console=ttyS0,115200n8"];

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
        # headless guest 没有 compositor / 浏览器, 资源不必堆得很高.
        memorySize = 2048;
        cores = 2;
        # graphics = false 让 nixpkgs module 自动加 -nographic (qemu-vm.nix:
        # mkIf (!cfg.graphics) ["-nographic"]). 不在这里手动写 -nographic
        # 避免重复选项 (QEMU 会报 "duplicate -nographic" 类似警告).
        graphics = false;
        # qemu.options 只填 nixpkgs 默认未加的额外选项; -nographic / -usb /
        # -device virtio-keyboard / -kernel / -initrd / -append 均由 nixpkgs
        # module 按平台 / graphics / directBoot 条件补上, 这里不重复.
        qemu.options = [];
        # 端口转发走 2223 (与 GUI VM 的 2222 错开, 两 VM 可同时跑在同一 host).
        forwardPorts = [
          {
            from = "host";
            host.port = 2223;
            guest.port = 22;
          }
        ];
      };
    };
  };
}
