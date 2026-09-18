# mechrevo-nixos-noctalia 离线安装 ISO。
#
# 为什么不直接把主机配置加个 isoImage: disko 注入的 LUKS 配置 (disko.enableConfig
# 默认 true) 会让 live 环境的 initrd 去找 disk-main-luks 标签 → emergency mode。
# 本模块生成一个独立 installer config (不注册 den host、不进 nixosConfigurations、
# 不影响 deploy/拓扑):
#
#   - live 环境: installation-cd-minimal + disko 工具链, disko.enableConfig = false
#   - isoImage.storeContents = [ 目标系统 toplevel ]: 完整闭包内嵌 ISO, 开机自动注册
#     (register-nix-paths); 目标 toplevel 由主机 nixosConfiguration 构建, 与真机零差异
#   - 仓库源码经 system.extraDependencies 进 live store, install.sh 从 store 拷贝,
#     不依赖 ISO 挂载点 (挂载方式不同路径就不同, 硬编码必错)
#
# 用法: nix build .#mechrevo-installer-iso → dd 写入 U 盘 → 引导 → root 登录 →
#   /etc/install.sh
#   install.sh: 校验内嵌闭包 NAR → disko 分区 (交互 LUKS 密码) → 拷贝仓库 →
#   nixos-install --closure (显式禁用 substituters, 全程离线, 失败立即报错)
#
# 已知坑:
#   - 预检报 "path ... was modified!" (或跳过预检时 nixos-install 报 "hash mismatch
#     importing path ...") = 构建机 store 中该 path 已损坏 (NAR 与 SQLite 记录不符),
#     先在构建机 nix store repair <path> 再重建 ISO; 脚本已禁用 substituters,
#     不会也不能联网自愈。
#   - 安装后首次 nixos-rebuild 需联网拉取 flake.lock 里的 inputs (不随 ISO 分发)。
{
  inputs,
  lib,
  ...
}: let
  hostName = "mechrevo-nixos-noctalia";
  system = "x86_64-linux";
  inherit (inputs) nixpkgs;
  modulesPath = "${nixpkgs}/nixos/modules";

  # 仓库源码: 装入 live store, install.sh 直接 cp 到目标系统。
  # 本文件位于 modules/flake-parts/, ../.. = 仓库根。
  # 用路径字面量而非 lib.cleanSource (flake 纯求值下 cleanSource 会得到非法路径)。
  repoSource = ../..;
in {
  flake = {config, ...}: let
    # 目标系统 toplevel —— 从主机 nixosConfiguration 直接引用, 与真机闭包零差异。
    targetClosure = config.nixosConfigurations.${hostName}.config.system.build.toplevel;
  in {
    packages.${system}.mechrevo-installer-iso = let
      # live/installer 配置: 独立 eval, 与主机配置隔离。
      live = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"

          inputs.disko.nixosModules.disko
          # live 只是安装现场: 不注入任何 fileSystems / boot.initrd.luks。
          {disko.enableConfig = lib.mkForce false;}

          # 复用真机磁盘布局 (只取 disko.devices, 不取主机 nixos 配置)。
          (import ../hosts/mechrevo-nixos-noctalia/_disko.nix)

          ({
            pkgs,
            config,
            lib,
            ...
          }: {
            # 仓库源码进 live 闭包 → ISO store 里就有, 不再用 isoImage.contents。
            system.extraDependencies = [repoSource];

            # 交互式安装脚本: disko 逻辑用 diskoScript 预编译产物内嵌,
            # 避免 live 环境运行时 eval nixpkgs (离线不可靠)。
            environment.etc."install.sh" = {
              mode = "0755";
              text = ''
                #!/bin/bash
                set -euo pipefail

                trap 'echo "[FAIL] 安装已中止, 请结合上方输出排查" >&2' ERR

                echo "=============================================="
                echo "  mechrevo-nixos-noctalia 离线安装"
                echo "  将擦除 /dev/nvme0n1 全部数据 (Btrfs-on-LUKS)"
                echo "=============================================="
                read -r -p "确认继续? 输入大写 YES: " answer
                [[ "$answer" == "YES" ]] || { echo "已取消"; exit 1; }

                # 预检: ISO 内嵌闭包的 NAR 必须与注册的 hash 一致; 损坏就立即中止,
                # 而不是等 nixos-install 拷到一半才 hash mismatch。
                # 跳过: SKIP_VERIFY=1 /etc/install.sh (预检要完整读一遍闭包, 慢)。
                if [[ ! -v SKIP_VERIFY ]]; then
                  echo ">> [1/4] 校验内嵌闭包 NAR 完整性"
                  nix-store --verify-path $(nix-store -qR "${targetClosure}")
                fi

                echo ">> [2/4] 分区: disko (输入新的 LUKS 密码)"
                "${config.system.build.diskoScript}"

                echo ">> [3/4] 复制仓库到 /mnt/etc/nixos"
                mkdir -p /mnt/etc/nixos
                cp -a "${repoSource}"/. /mnt/etc/nixos/
                chmod -R u+w /mnt/etc/nixos

                echo ">> [4/4] 安装系统 (离线: 禁用 substituters, 失败立即报错)"
                nixos-install \
                  --root /mnt \
                  --closure "${targetClosure}" \
                  --no-channel-copy \
                  --no-root-passwd \
                  --option substitute false \
                  --option substituters "" \
                  --option connect-timeout 5

                sync
                echo ">> 完成: 拔掉安装介质后 reboot。"
                echo ">> 之后: nixos-rebuild switch --flake /etc/nixos#${hostName}"
              '';
            };

            environment.systemPackages = [pkgs.git];

            # ISO 内嵌: 目标系统闭包 (开机 register-nix-paths 自动注册)。
            isoImage.storeContents = [targetClosure];

            # 关闭 live 自身的网络访问点 (装机要求离线确定性, 防误配)。
            networking.wireless.enable = lib.mkForce false;
            services.openssh.enable = lib.mkForce false;
          })
        ];
      };
    in
      live.config.system.build.isoImage;
  };
}
