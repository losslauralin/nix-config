{
  lossilk.system._.peripherals._.printing.nixos = {pkgs, ...}: {
    services.printing = {
      enable = true;
      drivers = [
        pkgs.hplip
      ];
    };
  };
}
