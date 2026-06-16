# modules/home-manager.nix
#
# lossilk.home-manager —— HM 平台策略: 自动过期回收 + 基础工具 (由 user 显式引)
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
