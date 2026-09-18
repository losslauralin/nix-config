# Clash Verge Rev: clash GUI + TUN 模式。
# 特权不走 setuid (本机 /nix/store 是 ro,nosuid, setuid 方案必然失败), 而由 NixOS
# 模块的 root 服务 clash-verge-service 管理 (socket 授权给 `users` 组);
# tunMode 另外提供 TUN/DNS 所需 capabilities 并把 rp_filter 设为 loose。
{
  lossilk.networking._.clash-verge.nixos.programs.clash-verge = {
    enable = true;
    serviceMode = true; # root 特权服务: 建 TUN 网卡 / 改路由 / 系统代理
    tunMode = true; # TUN 所需 capabilities + net.ipv4.conf.*.rp_filter=loose
    autoStart = true; # 随桌面会话自启 (XDG autostart)
  };
}
