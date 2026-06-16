# modules/system/boot/plymouth.nix
#
# Plymouth 图形启动画面。仅 host opt-in；不启用 Secure Boot/lanzaboote。
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
