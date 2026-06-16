# lossilk.networking._.tools — 用户态网络排障与查询工具
{
  lossilk.networking._.tools.homeManager = {pkgs, ...}: {
    home.packages = [
      pkgs.doggo
      pkgs.traceroute
      pkgs.whois
    ];
  };
}
