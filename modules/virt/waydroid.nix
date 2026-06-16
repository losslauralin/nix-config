# modules/virt/waydroid.nix
#
# Waydroid Android 容器。仅 host opt-in。
{
  lossilk.virt._.waydroid.nixos.virtualisation.waydroid.enable = true;
}
