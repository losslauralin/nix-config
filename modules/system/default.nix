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
