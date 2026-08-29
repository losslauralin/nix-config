{
  lossilk.dev._.workflow._.ansible.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.ansible];
  };
}
