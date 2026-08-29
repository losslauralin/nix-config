{
  den,
  lossilk,
  ...
}: {
  lossilk.cli._.shell._.zsh = {
    includes = [
      lossilk.cli._.shell
      (den.provides.user-shell "zsh")
    ];

    homeManager = {
      pkgs,
      lib,
      ...
    }: {
      home.packages = with pkgs; [
        zsh-completions
      ];

      programs.zsh = {
        enable = true;
        autosuggestion.enable = true;
        syntaxHighlighting.enable = true;

        oh-my-zsh = {
          enable = true;
          plugins = ["git" "fzf"];
        };

        history = {
          ignoreDups = true;
          share = true;
          extended = true;
          size = 50000;
          save = 50000;
        };

        envExtra = ''
          # Private env config sourcing (zsh 用 POSIX set -a + source; fish 端等价需 babelfish/fenv)
          PRIVATE_ENV_CONFIG="''${XDG_CONFIG_HOME:-$HOME/.config}/private/env"
          if [ -r "$PRIVATE_ENV_CONFIG" ] && [ -f "$PRIVATE_ENV_CONFIG" ]; then
            set -a
            source "$PRIVATE_ENV_CONFIG"
            set +a
          fi
          export PATH="$HOME/.local/bin:$PATH"
        '';

        shellAliases = {
          ".." = "cd ..";
          "..." = "cd ../..";
          grep = "grep --color=auto";
        };

        initContent = let
          toolsInit = lib.mkOrder 1000 ''
            if command -v fnm &> /dev/null; then
              eval "$(fnm env)"
            fi
          '';
          functionsInit = lib.mkOrder 1000 ''
            up() {
              local count=''${1:-1}
              local dir=""
              for ((i=0; i<count; i++)); do
                dir="../$dir"
              done
              cd "$dir"
            }

            mkcd() {
              mkdir -p "$@" && cd "$_";
            }
          '';
        in
          lib.mkMerge [toolsInit functionsInit];
      };
    };
  };
}
