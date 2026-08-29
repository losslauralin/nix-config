# nftables 防火墙后端。仅 host opt-in；Docker/libvirt 等 iptables 用户需单独验证。
{
  lossilk.networking._.nftables.nixos.networking.nftables.enable = true;
}
