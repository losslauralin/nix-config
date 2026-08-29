{
  lossilk.system._.peripherals._.bluetooth.nixos = {
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
    };

    services.blueman.enable = true;
  };
}
