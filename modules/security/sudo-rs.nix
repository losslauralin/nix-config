{
  lossilk.security._.sudo-rs.nixos.security = {
    sudo.enable = false;
    sudo-rs = {
      enable = true;
      execWheelOnly = true;
    };
  };
}
