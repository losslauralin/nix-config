# lossilk.system._.diagnostics — 主机级诊断工具
{
  lossilk.system._.diagnostics.nixos = {pkgs, ...}: {
    environment.systemPackages = [
      pkgs.pciutils
      pkgs.tcpdump
    ];
  };
}
