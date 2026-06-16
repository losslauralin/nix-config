# modules/networking/wake-on-lan.nix
#
# Wake-on-LAN：允许以 magic packet 唤醒以太网卡。需 BIOS/网卡侧也支持。
{
  lossilk.networking._.wake-on-lan.nixos.systemd.network.links."10-wol" = {
    matchConfig.Type = "ether";
    linkConfig.WakeOnLan = "magic";
  };
}
