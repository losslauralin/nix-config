# modules/networking/default.nix
#
# lossilk.networking —— 网络域底座: 主机名 / DNS / NetworkManager + systemd-resolved
# 按需扩展 (ssh/tailscale/wireguard 等) 由各 networking/* leaf Aspect 显式 include。
{
  lossilk.networking = {
    nixos = {
      networking = {
        dhcpcd.enable = false;
        networkmanager.enable = true;
      };
      systemd.network.wait-online.enable = false;
      boot.initrd.systemd.network.wait-online.enable = false;
    };

    user.extraGroups = ["networkmanager"];
  };
}
