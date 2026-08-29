{
  lossilk.dev._.extras.homeManager = {pkgs, ...}: {
    home.packages = with pkgs; [
      aube
      hexyl
      jq
      kondo
      lemmeknow
      lurk
    ];
  };
}
