# modules/system/peripherals/bluetooth.nix
#
# Bluetooth peripheral support for real desktop/laptop hosts.
{
  lossilk.system._.peripherals._.bluetooth.nixos = {
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
    };

    services.blueman.enable = true;
  };
}
