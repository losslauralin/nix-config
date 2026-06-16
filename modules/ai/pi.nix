# modules/ai/pi.nix
#
# Pi coding agent 配置与 WebDAV 同步 (Den 重构版 - 优化激活脚本)
{inputs, ...}: {
  # 1. 提升为全功能的 Aspect 函数，自动获取当前主机与用户上下文
  lossilk.ai._.pi = {user}: {
    # 2. 系统级配置（在 NixOS 解密，最安全）
    nixos = _: {
      sops.secrets.pi_webdav_password = {
        sopsFile = ../../secrets/secrets.yaml;
        # 绝招：动态提取当前用户名，自动将密钥所有权安全地赋给当前用户
        owner = user.name;
      };
    };

    # 3. 用户级配置（Home Manager）
    homeManager = {
      pkgs,
      config,
      ...
    }: {
      home.packages = [
        # 保持使用 llm-agents 的原生 Node 包
        inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.pi
        pkgs.nodejs # 注入 nodejs，保障激活脚本中的 npm 命令在 PATH 中可用
      ];

      # 4. 修复并优化后的激活脚本
      home.activation.installPiWebdavSync = config.lib.dag.entryAfter ["writeBoundary"] ''
        export PATH="${pkgs.nodejs}/bin:${pkgs.git}/bin:$PATH"
        TARGET_DIR="$HOME/.pi/agent/npm"

        # 确保目录一致：统一使用 $TARGET_DIR (即 /npm 目录)
        if [ ! -d "$TARGET_DIR/node_modules/pi-webdav-sync" ]; then
          echo "Installing pi-webdav-sync via npm..."
          mkdir -p "$TARGET_DIR"
          $DRY_RUN_CMD npm --prefix "$TARGET_DIR" install pi-webdav-sync --no-audit --no-fund --yes 2>&1 || true
        fi
      '';

      home.file.".pi/agent/settings.webdav.json".text = builtins.toJSON {
        backend = "webdav";
        remoteBaseUrl = "https://dav.jianguoyun.com/dav/";
        username = "948872003@qq.com";
        passwordEnv = "PI_WEBDAV_PASSWORD";
        remoteDir = "/pi-agent-sync";
        installMissingPackages = "ask";
        backupRetention = 5;
      };

      # PI_WEBDAV_PASSWORD 走 fish conf.d 按文件存在才设，不用 home.sessionVariables。
      # home.sessionVariables 会无条件设空字符串，覆盖用户手动 set -gx 的值。
      home.file.".config/fish/conf.d/pi-webdav.fish".text = ''
        if test -f /run/secrets/pi_webdav_password
          set -gx PI_WEBDAV_PASSWORD (cat /run/secrets/pi_webdav_password)
        end
      '';
    };
  };
}
