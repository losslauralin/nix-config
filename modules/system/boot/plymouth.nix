{
  lossilk.system._.boot._.plymouth.nixos.boot = {
    plymouth.enable = true;
    initrd.verbose = false;
    kernelParams = [
      "quiet"
      "udev.log_priority=3"
      "rd.systemd.show_status=false"
    ];
  };
}
