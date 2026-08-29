# 用户确认需要的 GUI 应用；不要在这里堆未确认的大包集合。
{
  lossilk.desktop._.gui.homeManager = {pkgs, ...}: {
    home.packages = [
      pkgs.libreoffice
      pkgs.remmina
      pkgs.thunderbird
    ];
  };
}
