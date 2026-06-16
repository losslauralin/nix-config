# modules/system/default.nix
#
# lossilk.system —— 系统域底座: locale / 时区 / TTY 控制台 (全机通用, 内联合并)
# 按需扩展 (boot/filesystems/performance/power 等) 由各 system/* leaf Aspect 显式 include。
{
  lossilk.system.nixos = {
    i18n.defaultLocale = "zh_CN.UTF-8";

    time.timeZone = "Asia/Shanghai";

    console = {
      earlySetup = true;
      useXkbConfig = true;
    };
  };
}
