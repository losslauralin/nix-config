# EDITOR/VISUAL 环境变量在此声明 (系统级编辑器选择).
{
  lossilk.dev._.editors._.neovim.homeManager = {
    programs.neovim = {
      enable = true;
      withRuby = false;
      withPython3 = false;
    };
    home.sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
    };
  };
}
