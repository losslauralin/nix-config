# modules/system/power-mgmt.nix
#
# 笔记本电源管理服务。仅 host opt-in。
{
  lossilk.system._.power-mgmt.nixos.services = {
    upower.enable = true;
    thermald.enable = true;
    power-profiles-daemon.enable = true;
  };
}
