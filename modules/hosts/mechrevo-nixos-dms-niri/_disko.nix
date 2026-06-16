# modules/hosts/mechrevo-nixos-dms-niri/_disko.nix
#
# 磁盘布局 — Btrfs-on-LUKS (= disko luks-btrfs 模板), 仅 root 盘 nvme0n1.
# 纯数据 module: 只设 disko.devices (该选项由 default.nix import 的 disko.nixosModules.disko 提供).
# 前缀 `_`: import-tree 按 /_ 规则忽略, 不被当 flake-parts 模块误解析; 只经 default.nix 的
#   `nixos.imports = [ ./_disko.nix ]` 引入 (须 git add, Nix 解析路径需它在 store 里).
# Windows NTFS 盘 (nvme1n1) 绝不在此 —— 它只用 udisks2 挂, 不分区/格式化.
{
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/disk/by-id/nvme-YMTC_PC411-1TB-B_YMA51T0KA24026073F"; # facter 实测 serial
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          type = "EF00";
          size = "2G";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
          };
        };
        luks = {
          size = "100%";
          content = {
            type = "luks";
            name = "root";
            settings.allowDiscards = true;
            content = {
              type = "btrfs";
              subvolumes = {
                "@" = {
                  mountpoint = "/";
                  mountOptions = ["compress=zstd" "noatime"];
                };
                "@home" = {
                  mountpoint = "/home";
                  mountOptions = ["compress=zstd"];
                };
                "@nix" = {
                  mountpoint = "/nix";
                  mountOptions = ["compress=zstd" "noatime"];
                };
                "@log" = {
                  mountpoint = "/var/log";
                  mountOptions = ["compress=zstd"];
                };
              };
            };
          };
        };
      };
    };
  };
}
