{
  lossilk.cli._.zoxide.homeManager = {
    programs.zoxide = {
      enable = true;
      options = ["--cmd cd"];
    };

    home.shellAliases.zi = "z -i";
  };
}
