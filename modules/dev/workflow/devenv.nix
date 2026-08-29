{
  lossilk.dev._.workflow._.devenv.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.devenv];
  };
}
