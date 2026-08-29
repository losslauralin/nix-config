{
  lossilk.virt._.qemu = {
    nixos = {pkgs, ...}: {
      security.polkit.enable = true;
      networking.firewall.trustedInterfaces = ["virbr0"];

      programs.virt-manager.enable = true;
      environment.systemPackages = [
        pkgs.gnome-boxes
        pkgs.virglrenderer
      ];

      virtualisation = {
        libvirtd.enable = true;
        spiceUSBRedirection.enable = true;
      };
    };

    user.extraGroups = [
      "kvm"
      "libvirtd"
    ];
  };
}
