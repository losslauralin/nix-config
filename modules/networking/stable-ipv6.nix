# 稳定 IPv6 地址策略：关闭临时地址/隐私扩展，便于服务发现与 SSH，但隐私更弱。
{
  lossilk.networking._.stable-ipv6.nixos.networking.tempAddresses = "disabled";
}
