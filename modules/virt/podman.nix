# modules/virt/podman.nix
#
# Podman 运行时。仅 host opt-in。
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
