# modules/system/performance.nix
#
# 性能 profiles。具体策略仅通过子切面 opt-in；不声明空 root Aspect。
{lossilk, ...}: {
  lossilk.system._.performance._.responsive = {
    nixos.boot = {
      kernel.sysctl."vm.swappiness" = 1;
      kernelParams = [
        "nowatchdog"
        "nosoftlockup"
        "audit=0"
        "skew_tick=1"
        "threadirqs"
        "preempt=full"
        "nohz_full=all"
      ];
    };
  };

  lossilk.system._.performance._.max = {
    includes = [
      lossilk.system._.performance._.responsive
    ];

    nixos.boot.kernelParams = [
      "usbcore.autosuspend=60"
      "workqueue.power_efficient=false"
      "cpufreq.default_governor=performance"
    ];
  };
}
