{
  lossilk.system._.diagnostics.nixos = {pkgs, ...}: {
    environment.systemPackages = [
      pkgs.pciutils
      pkgs.tcpdump
    ];
  };
}
