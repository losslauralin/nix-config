{den, ...}: {
  lossilk.security._.bitwarden = {
    includes = [(den.batteries.insecure ["electron-39.8.10"])];
    homeManager = {pkgs, ...}: {
      home.packages = [pkgs.bitwarden-desktop];
      programs.rbw.enable = true;
    };
  };
}
