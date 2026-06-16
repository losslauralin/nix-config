# modules/flake-parts/hosts.nix
#
# 实体声明中心 —— 所有 host + 嵌套 user 的注册位置。
# 新增 host: 此处加一行 + 在 modules/hosts/<host-name>/ 建主切面文件。
_: {
  den.hosts.x86_64-linux.nixos-wsl = {
    wsl.enable = true; # 激活 den.batteries.wsl: import nixos-wsl module
    users.loss = {}; # 声明 user 实体 → den.aspects.loss 进入解析链
  };
  # qemu VM, 验证 niri + DankMaterialShell desktop 配置
  den.hosts.x86_64-linux.nixos-niri-dms-vm.users.loss = {};
  # qemu VM, 纯 CLI / headless (无 GPU / 音频 / 桌面). 走 virt._.vm._.headless 变体
  # 关 graphics / 关 display, 错开 2223 端口转发.
  den.hosts.x86_64-linux.nixos-headless-vm.users.loss = {};
  # 真机 (MECHREVO 笔记本): niri + DankMaterialShell, 真实硬件 (disko + facter)
  den.hosts.x86_64-linux.mechrevo-nixos-dms-niri.users.loss = {};
}
