# modules/virt/docker.nix
#
# Docker 运行时。仅 host opt-in。
{
  lossilk.virt._.docker = {
    nixos = {
      virtualisation.docker.enable = true;
      networking.firewall.trustedInterfaces = ["docker0"];
    };

    user.extraGroups = ["docker"];
  };
}
