# modules/system/peripherals/printing.nix
#
# Printing is OS peripheral support (CUPS/HPLIP), not desktop session substrate.
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
