# modules/networking/wireguard.nix
#
# WireGuard 内核/脚本后端支持。这里只启用框架，不声明任何 VPN peer。
{
  lossilk.networking._.wireguard.nixos.networking.wireguard.enable = true;
}
