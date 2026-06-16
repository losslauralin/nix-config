# modules/security/sudo-rs.nix
#
# Rust 版 sudo 替换
{
  lossilk.security._.sudo-rs.nixos.security = {
    sudo.enable = false;
    sudo-rs = {
      enable = true;
      execWheelOnly = true;
    };
  };
}
