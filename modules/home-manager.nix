{
  lossilk.home-manager.homeManager = {pkgs, ...}: {
    services.home-manager.autoExpire = {
      enable = true;
      frequency = "weekly";
      store.cleanup = true;
    };

    home.packages = with pkgs; [wget];
  };
}
