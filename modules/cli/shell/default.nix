{lossilk, ...}: {
  lossilk.cli._.shell = {
    includes = [
      lossilk.cli._.shell._.nix-your-shell
    ];

    homeManager.home.shellAliases = {
      cat = "bat";
      ls = "eza";
      ll = "eza -lh --git";
      la = "eza -lah --git";
      wget = "aria2c";
    };
  };
}
