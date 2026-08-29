{
  den,
  lossilk,
  ...
}: {
  lossilk.cli._.shell._.fish = {
    includes = [
      lossilk.cli._.shell
      (den.provides.user-shell "fish")
    ];

    homeManager = {pkgs, ...}: {
      home.packages = with pkgs.fishPlugins; [
        colored-man-pages
        done
        foreign-env
        pkgs.libnotify
      ];

      programs.fish = {
        enable = true;

        shellAliases = {
          ".." = "cd ..";
          "..." = "cd ../..";
          grep = "grep --color=auto";
        };

        functions = {
          up = ''
            set -l count $argv[1]
            if test -z "$count"
              set count 1
            end
            set -l dir ""
            for i in (seq $count)
              set dir "../$dir"
            end
            cd $dir
          '';
          mkcd = ''
            mkdir -p $argv[1]
            and cd $argv[1]
          '';
        };

        # 交互 init: fnm (Node 版本管理) 守卫式 bootstrap. PATH 通过 home.sessionPath
        # 走 shell-agnostic 路径, 不在这里重复 export.
        interactiveShellInit = ''
          set fish_greeting

          if type -q fnm
            fnm env --shell fish | source
          end
        '';
      };
    };
  };
}
