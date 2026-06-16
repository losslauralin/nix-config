{
  lossilk.cli._.yazi.homeManager = {
    programs.yazi = {
      enable = true;
      shellWrapperName = "y";
      settings = {
        manager = {
          show_hidden = false;
          sort_by = "natural";
          sort_dir_first = true;
        };
      };
    };
  };
}
