{den, ...}: {
  lossilk.security._.bitwarden = {
    includes = [(den.batteries.insecure ["electron-39.8.10"])];
    homeManager = {pkgs, ...}: {
      home.packages = [pkgs.bitwarden-desktop pkgs.pinentry-curses];
      programs.rbw = {
        enable = true;
        # 0 = never auto-lock. Non-interactive consumers (e.g. pi's
        # `!rbw get ...` credential sources) have no tty for pinentry, so a
        # locked agent makes them fail with "command-failed".
        #
        # 一旦给 settings 赋了任何值, HM 就激活该子模块, 而 email 是必填项
        # (无默认值) —— 不存在"设了 settings 但不给 email"的状态。没写它会
        # 直接报 "was accessed but has no value defined" 挡住 eval。
        settings = {
          email = "lossilklauralin@gmail.com";
          lock_timeout = 0;
        };
      };
    };
  };
}
