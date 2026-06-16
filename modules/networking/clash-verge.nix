# modules/networking/clash-verge.nix
#
# Clash Verge Rev — 代理客户端，NixOS 官方 module 集成 (serviceMode / tunMode / autoStart)。
# 通过 provides.to-hosts 从 user 交付到 host，host 不需要 includes。
_: {
  lossilk.networking._.clash-verge.provides.to-hosts.nixos = {
    programs.clash-verge = {
      enable = true;
      serviceMode = true;
      autoStart = true;
    };
  };
}
