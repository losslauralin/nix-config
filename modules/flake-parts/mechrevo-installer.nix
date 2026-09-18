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
# TTY 约定: live 控制台没有 CJK 字体, 所有 tty 可见输出 (install.sh / motd /
# /etc/INSTALL.md 指南) 一律 ASCII 英文; 本文件注释仍是中文。
#
# 交互设计: 全自动不可行也不该做 —— LUKS 口令是磁盘的安全边界, 只能来自操作者,
# 写进 ISO/flake 等于随介质一起泄露; 擦盘不可逆, 默认要显式确认。实际交互只有两处:
# YES 确认 (AUTO_CONFIRM=1 跳过) + LUKS 口令 (disko 输两遍, 之后格式化/打开复用,
# 不再重复问)。分区布局、闭包、拷贝、安装全部自动。
#
# 用法: nix build .#mechrevo-installer-iso → dd 写入 U 盘 → 引导 (root 自动登录,
#   motd 即操作提示) → mechrevo-install
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

  # tty 里唯一的人读文档: motd 与 install.sh 都指向它。
  installGuide = ''
    mechrevo-nixos-noctalia offline install guide
    =============================================

    Installs the host "mechrevo-nixos-noctalia" (Btrfs-on-LUKS on /dev/nvme0n1)
    from the closure embedded in this ISO. No network is used or required.

    Quick start
    -----------
      mechrevo-install          # same as: /etc/install.sh

    What the script does
    --------------------
      1/4  verify the embedded store closure (NAR hashes)   [skip: SKIP_VERIFY=1]
      2/4  partition /dev/nvme0n1 with disko (ERASES the disk)
      3/4  copy the repo source to /mnt/etc/nixos
      4/4  nixos-install --closure (substituters disabled: offline, fails fast)

    Prompts you will see
    --------------------
      "Continue? type YES"   the disk will be wiped; AUTO_CONFIRM=1 skips it
      "Enter password ..."   LUKS passphrase, typed twice (enter + confirm);
                             disko reuses it to open the volume, so this is the
                             only passphrase entry. It cannot be automated away:
                             the passphrase is the disk security boundary and is
                             never stored on the ISO.

    After the install
    -----------------
      reboot and unlock the disk with the passphrase, then:
        nixos-rebuild switch --flake /etc/nixos#mechrevo-nixos-noctalia
      This first rebuild needs network for the flake inputs pinned in flake.lock.

    If step 1/4 fails
    -----------------
      "path ... was modified!" = the store path baked into this ISO is corrupt
      (NAR bytes vs SQLite hash). Nothing has been written to disk yet. Repair
      the workstation store (nix store repair <path>) and rebuild the ISO.
  '';

  motd = ''
    mechrevo-nixos-noctalia offline installer
      install : mechrevo-install     (or /etc/install.sh)
      guide   : install-guide        (or cat /etc/INSTALL.md)
    Target disk /dev/nvme0n1 will be ERASED. The LUKS passphrase is asked
    during the install (twice: enter + confirm).
  '';
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

            environment.etc = {
              "INSTALL.md".text = installGuide;
              "install.sh" = {
                mode = "0755";
                text = ''
                  #!/bin/bash
                  set -euo pipefail

                  trap 'echo "[FAIL] install aborted, see the error above" >&2' ERR

                  echo "=========================================================="
                  echo "  mechrevo-nixos-noctalia offline installer"
                  echo "  guide: /etc/INSTALL.md  (install-guide)"
                  echo "  target disk: /dev/nvme0n1  -- all data will be ERASED"
                  echo "=========================================================="

                  if [[ ! -v AUTO_CONFIRM ]]; then
                    read -r -p "Continue? type YES: " answer
                    [[ "$answer" == "YES" ]] || { echo "cancelled."; exit 1; }
                  fi

                  # 预检: ISO 内嵌闭包的 NAR 必须与注册的 hash 一致; 损坏就立即中止,
                  # 而不是等 nixos-install 拷到一半才 hash mismatch。
                  # 跳过: SKIP_VERIFY=1 mechrevo-install (预检要完整读一遍闭包, 慢)。
                  if [[ ! -v SKIP_VERIFY ]]; then
                    echo ">> [1/4] verifying embedded closure (NAR hashes, read-only)"
                    nix-store --verify-path $(nix-store -qR "${targetClosure}")
                  fi

                  echo ">> [2/4] partitioning (disko asks for the LUKS passphrase twice:"
                  echo "         enter + confirm; it is reused to open the volume)"
                  "${config.system.build.diskoScript}"

                  echo ">> [3/4] copying repo to /mnt/etc/nixos"
                  mkdir -p /mnt/etc/nixos
                  cp -a "${repoSource}"/. /mnt/etc/nixos/
                  chmod -R u+w /mnt/etc/nixos

                  echo ">> [4/4] installing system (offline: substituters disabled)"
                  nixos-install \
                    --root /mnt \
                    --closure "${targetClosure}" \
                    --no-channel-copy \
                    --no-root-passwd \
                    --option substitute false \
                    --option substituters "" \
                    --option connect-timeout 5

                  sync
                  echo ">> done: remove the install media and reboot."
                  echo ">> after reboot: nixos-rebuild switch --flake /etc/nixos#${hostName}"
                '';
              };
            };

            environment.systemPackages = [
              pkgs.git
              pkgs.less
              (pkgs.writeShellScriptBin "mechrevo-install" ''exec /etc/install.sh "$@"'')
              (pkgs.writeShellScriptBin "install-guide" ''exec ${pkgs.less}/bin/less /etc/INSTALL.md'')
            ];

            users.motd = motd;
            # 安装介质唯一用途就是装机: 开机直接 root shell, motd 即操作提示。
            # (installation-device.nix 默认 autologin `nixos` 用户, 这里覆盖为 root,
            #  免得装个系统还要 sudo。)
            services.getty.autologinUser = lib.mkForce "root";

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
