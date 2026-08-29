{
  lossilk.networking = {
    nixos = {
      networking = {
        dhcpcd.enable = false;
        networkmanager.enable = true;
      };
      systemd.network.wait-online.enable = false;
      boot.initrd.systemd.network.wait-online.enable = false;
    };

    user.extraGroups = ["networkmanager"];
  };
}
