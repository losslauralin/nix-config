# Paseo — 自托管的 AI coding agent 界面 (daemon + 客户端)。
# 上游: https://github.com/getpaseo/paseo (AGPL-3.0+, daemon 与 desktop 分开打包)
#
# 架构与 codex-desktop 完全不同, 所以这个切面分两半:
#
#   1. daemon — 常驻服务, 管 agent 进程 (codex/claude/pi...), **host 级**。
#      它必须跑在 loss 用户下: agent 用到的凭证与配置 (~/.codex/config.toml、
#      claude 的 settings) 都是 per-user 的, 跑成默认的 paseo 系统用户就取不到。
#      上游 module 的 inheritUserEnvironment 会在 user != "paseo" 时自动把
#      loss 的 profile PATH 注入 agent 进程, 正好配合。
#
#   2. desktop — Electron GUI 客户端, **user 级**(HM), 但只由有桌面的 host 显式
#      include (与 codex-desktop 同一条纪律: 放进 user 主切面的话,
#      den.batteries.host-aspects 会把它带到 headless VM 上)。
#
# daemon/desktop 用同一个 flake 的不同 output: packages.paseo / packages.desktop。
{
  inputs,
  # den angle-bracket syntax needs __findFile in lexical scope.
  # deadnix is configured with no-underscore=true so it will not remove it.
  __findFile,
  ...
}: {
  # ---- daemon: host 级 systemd 服务 -------------------------------------
  # 只声明切面, 由需要的 host 显式 include (见 modules/hosts/*/default.nix)。
  # 用 nixosModules.paseo 而不是手写 systemd unit: 上游 module 管好了
  # tmpfiles、PASEO_HOME、PATH 注入与 relay 接线, 重写没有收益。
  lossilk.ai._.paseo-daemon = {
    nixos = {...}: {
      # 让本切面能被 nixos class 消费, 同时把上游 module 接进来。
      imports = [inputs.paseo.nixosModules.paseo];

      services.paseo = {
        enable = true;
        # 必须用真实用户: 默认的 paseo 系统用户拿不到 loss 的 agent 凭证。
        user = "loss";
        group = "users";
        # dataDir 默认值按 `user != "paseo"` 推导成 ~/.paseo, 留空即用默认。
        # 监听地址保持上游默认 (127.0.0.1:6767): 本机自用, 不开防火墙。
        #
        # relay: 走上游 app.paseo.sh 中继, 手机配对/绑定设备走的就是它。
        # 必须是启动期配置: 上游 module 据此生成 daemon 的启动覆盖
        # (PASEO_RELAY_ENABLED / relay flag), 优先级高于运行时配置。
        # 设成 false 会让客户端的"启用中继"开关报 handler_error
        # (Relay is controlled by a daemon launch override) —— 关掉就等于
        # 放弃中继配对, 纯本机使用才这么做。
        relay.enable = true;
      };
    };
  };

  # ---- desktop: GUI 客户端 (HM) -----------------------------------------
  # 直接用上游 desktop 包, 不要 override 加 Wayland flag。
  #
  # 曾经这里用 wrapProgram --add-flags 追加过 --ozone-platform=wayland 等,
  # 结果是 GUI 完全起不来 (error: unknown option '--ozone-platform=wayland')。
  # 原因: 上游 launcher 已经把 electron 的 app 路径写死在中间
  #   exec electron <app-path> --no-sandbox --class=paseo-desktop "$@"
  # 而 --add-flags 只会把参数拼到整条命令行的**末尾**, 也就是 app 路径之后;
  # Electron 只解析 app 路径**之前**的 Chromium switch, 之后的全部透传给 app,
  # app 不认识就报错退出。上游那份不加任何 flag, 本来就是好的。
  lossilk.ai._.paseo.homeManager = {pkgs, ...}: {
    home.packages = [
      inputs.paseo.packages.${pkgs.stdenv.hostPlatform.system}.desktop
    ];
  };
}
