{
  lossilk.virt._.podman.nixos = {
    networking.firewall.trustedInterfaces = ["podman0"];

    virtualisation.podman = {
      enable = true;
      autoPrune = {
        enable = true;
        flags = ["--all"];
      };
    };
  };
}
