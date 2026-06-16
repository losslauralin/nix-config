# modules/hosts/nixos-headless-vm/default.nix
#
# Host: nixos-headless-vm —— qemu VM, 纯 CLI / 服务端使用.
# 走 lossilk.virt._.vm._.headless 变体 (-nographic, 无 GPU / 无 display,
# 资源调小, forward 2223 错开 GUI VM 的 2222).
#
# 不引任何 desktop/audio/gaming/plymouth 切面 —— 这些都依赖 GPU / framebuffer,
# 与 headless 场景冲突. CLI 用户环境 (cli/dev/ai/security) 由
# modules/users/loss.nix 主切面 + den.batteries.host-aspects 自动注入.
#
# 实体声明在 modules/flake-parts/hosts.nix.
#
# 构建 + 启动:
#   just build-vm nixos-headless-vm
#   just run-vm nixos-headless-vm
#   # 或:
#   nix build .#nixosConfigurations.nixos-headless-vm.config.system.build.vm -o result-nixos-headless-vm
#   ./result-nixos-headless-vm/bin/run-nixos-headless-vm-vm
{lossilk, ...}: {
  den.aspects.nixos-headless-vm = {
    # host includes 收 nixos class 到本 host; user classes (homeManager/hjem)
    # 由 users/loss.nix 中显式 opt-in 的 den.batteries.host-aspects 接收.
    #
    # 仅挑不互相冲突且不依赖 GPU / 显示器 / 音频的服务型切面:
    #   - system / nix / networking: 全机通用底座 (locale / timezone / nix.conf / NetworkManager)
    #   - security: polkit + pam loginLimits, 任何 host 都用
    #   - networking._.ssh._.server: headless 必开, 否则只能从 VM console 进去
    #   - networking._.tools: doggo / traceroute / whois, CLI 排障
    #   - networking._.stable-ipv6: 禁隐私扩展, 服务发现更稳
    #   - security._.sudo-rs: 替换 sudo, 无 GUI 依赖
    #   - security._.sops: 密钥解密, 配合 ai._.pi / ai._.axonhub 用
    #   - system._.diagnostics: pciutils / tcpdump, 排障
    #   - system._.filesystems._.ntfs: 万一要读 host 透传的 NTFS 镜像
    #   - ai._.axonhub._.local: AI API gateway, 跑在容器里无 GUI 依赖
    #   - virt._.vm._.headless: VM guest 配置 (覆盖父切面 vmVariant 关 graphics)
    includes = with lossilk; [
      system
      nix
      networking
      security
      networking._.ssh._.server
      networking._.tools
      networking._.stable-ipv6
      security._.sudo-rs
      security._.sops
      system._.diagnostics
      system._.filesystems._.ntfs
      ai._.axonhub._.local
      virt._.vm._.headless
    ];

    # host spec nixos class
    nixos = _: {
      nixpkgs.hostPlatform = "x86_64-linux";
      # 没有 greetd, 没有 niri —— headless VM 直接走 TTY getty 自动登录 loss.
      # autologinUser 是全局选项, 对 ttyS0 (vmVariant 设的 console) 也生效.
      # 远程用 SSH 进来不需要这套, 但留本地 fallback 方便 console 调试.
      services.getty.autologinUser = "loss";
    };

    # user class 路由到 users.users.loss.extraGroups
    # headless 无 GPU / 音频, 不加 video / input / sound; 仅保留 networkmanager.
    user.extraGroups = ["networkmanager"];
  };
}
