# modules/cli/shell/default.nix
#
# lossilk.cli._.shell —— shell Family Root: 跨 shell 通用 alias 与 shell 生态底座。
# 不选择具体 shell implementation；fish/zsh/nushell Selection Variant 自己 include 本根切面。
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
