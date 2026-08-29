{
  lossilk.dev._.git._.jujutsu.homeManager = {pkgs, ...}: {
    home.shellAliases.jji = "jj --ignore-immutable";

    home.packages = [
      pkgs.difftastic
      pkgs.jjui
    ];

    programs.jujutsu = {
      enable = true;
      settings = {
        user = {
          name = "Loss";
          email = "lossilklauralin@gmail.com";
        };

        # https://isaaccorbrey.com/notes/jujutsu-megamerges-for-fun-and-profit
        revset-aliases."closest_merge(to)" = "heads(::to & merges())";
        aliases = {
          stack = [
            "rebase"
            "--after"
            "trunk()"
            "--before"
            "closest_merge(@)"
            "--revision"
          ];
          stage = [
            "stack"
            "closest_merge(@)+:: ~ empty()"
          ];
          restack = [
            "rebase"
            "--onto"
            "trunk()"
            "--source"
            "roots(trunk()..) & mutable()"
            "--simplify-parents"
          ];
          tug = [
            "bookmark"
            "advance"
            "--to"
            "@-"
          ];
        };
        ui = {
          default-command = [
            "log"
            "--no-pager"
            "--reversed"
          ];
          show-cryptographic-signatures = true;
          diff-formatter = "difft";
        };
        git = {
          private-commits = "description(glob:'private:*')";
          write-change-id-header = true;
        };
      };
    };
  };
}
