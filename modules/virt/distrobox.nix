# modules/virt/distrobox.nix
{lossilk, ...}: {
  lossilk.virt._.distrobox = {
    includes = [
      lossilk.virt._.podman
    ];

    homeManager.programs.distrobox = {
      enable = true;
      enableSystemdUnit = false;
    };
  };
}
