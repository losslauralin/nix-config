# lossilk.system._.filesystems — 文件系统辅助工具
{
  lossilk.system._.filesystems.nixos = {pkgs, ...}: {
    environment.systemPackages = [
      pkgs.bindfs
    ];
  };

  # Windows 数据盘/移动硬盘按需挂载支持；具体挂载仍由 host/udisks2 管。
  lossilk.system._.filesystems._.ntfs.nixos.boot.supportedFilesystems = ["ntfs"];
}
