# modules/security/default.nix
#
# 安全加固层 — 基础安全规则
{
  lossilk.security.nixos.security = {
    polkit.enable = true;

    pam = {
      services.systemd-run0 = {};
      loginLimits = [
        {
          domain = "*";
          item = "nofile";
          type = "hard";
          value = 128000;
        }
        {
          domain = "*";
          item = "nofile";
          type = "soft";
          value = 20480;
        }
      ];
    };
  };
}
