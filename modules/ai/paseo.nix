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
        # relay: 默认 true (走上游 app.paseo.sh 中继) 用于手机配对。
        # 纯本机使用不需要它; 关掉可少一个出站依赖。要手机连就改成 true。
        relay.enable = false;
      };
    };
  };

  # ---- desktop: GUI 客户端 (HM) -----------------------------------------
  lossilk.ai._.paseo.homeManager = {pkgs, ...}: {
    home.packages = [
      # Wayland 四件套必须走 wrapper 的 --add-flags, 不能用 electron-flags.conf:
      # 上游 desktop-package.nix 的 makeWrapper 只固定加了 --no-sandbox /
      # --class=paseo-desktop, 既**不**读 electron-flags.conf, 也不读
      # NIXOS_OZONE_WL (nixpkgs 的 electron wrapper 也不处理后者)。照搬
      # codex-desktop 那套配置在这里会被静默忽略。
      (inputs.paseo.packages.${pkgs.stdenv.hostPlatform.system}.desktop.overrideAttrs (old: {
        nativeBuildInputs = old.nativeBuildInputs or [];
        postInstall =
          (old.postInstall or "")
          + ''
            # 重新生成 wrapper, 追加 Wayland 相关 flag。
            wrapProgram $out/bin/paseo-desktop \
              --add-flags "--ozone-platform=wayland" \
              --add-flags "--enable-features=WaylandWindowDecorations" \
              --add-flags "--enable-wayland-ime=true" \
              --add-flags "--wayland-text-input-version=3"
          '';
      }))
    ];
  };
}
