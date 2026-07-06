# modules/dev/editors/zed.nix
#
# Zed — GUI 代码编辑器。Neovim 仍是默认 EDITOR/VISUAL。
{
  lossilk.dev._.editors._.zed.homeManager = {
    programs.zed-editor = {
      enable = true;
      defaultEditor = false;
    };
  };
}
