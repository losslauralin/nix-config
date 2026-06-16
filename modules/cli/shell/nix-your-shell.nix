# modules/cli/shell/nix-your-shell.nix
#
# nix-your-shell — shell family extension for Nix environment nesting.
# 让 nix shell / nix develop 等命令自动进入对应 shell 环境.
# 具体 shell 集成由 HM programs 模块默认值处理（enableFishIntegration / enableZshIntegration 默认跟随 enable）。
{lossilk.cli._.shell._.nix-your-shell.homeManager.programs.nix-your-shell.enable = true;}
