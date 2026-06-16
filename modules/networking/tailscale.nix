# modules/networking/tailscale.nix
#
# Tailscale Mesh VPN。仅 host opt-in。
{
  lossilk.networking._.tailscale.nixos.services.tailscale = {
    enable = true;
    openFirewall = true;
  };
}
