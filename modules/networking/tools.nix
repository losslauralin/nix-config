{
  lossilk.networking._.tools.homeManager = {pkgs, ...}: {
    home.packages = [
      pkgs.doggo
      pkgs.traceroute
      pkgs.whois
    ];
  };
}
