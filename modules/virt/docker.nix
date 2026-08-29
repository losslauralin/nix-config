{
  lossilk.virt._.docker = {
    nixos = {
      virtualisation.docker.enable = true;
      networking.firewall.trustedInterfaces = ["docker0"];
    };

    user.extraGroups = ["docker"];
  };
}
