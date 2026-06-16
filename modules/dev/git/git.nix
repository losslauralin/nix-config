# modules/dev/git/git.nix
#
# lossilk.dev._.git —— 完整 git 栈: core + gh (GitHub CLI) + lazygit (TUI)
{
  lossilk.dev._.git = {
    homeManager = {
      programs = {
        # GitHub CLI
        gh = {
          enable = true;
          settings = {
            git_protocol = "ssh";
            prompt = "enabled";
            aliases = {
              co = "pr checkout";
              pv = "pr view";
            };
          };
        };

        # TUI Git 客户端
        lazygit.enable = true;

        difftastic.enable = true;
        git = {
          enable = true;
          lfs.enable = true;
          settings = {
            user = {
              name = "Loss";
              email = "lossilklauralin@gmail.com";
            };
            init.defaultBranch = "main";
            pull.rebase = true;
            rerere = {
              enabled = true;
              autoupdate = true;
            };
            core = {
              autocrlf = false;
              eol = "lf";
              excludesfile = "~/.global.gitignore";
            };
            column.ui = "auto";
            branch.sort = "-committerdate";
            tag.sort = "version:refname";
            diff = {
              renames = true;
              algorithm = "histogram";
              colorMoved = "plain";
              mnemonicPrefix = true;
            };
            push = {
              followTags = true;
              default = "simple";
              autoSetupRemote = true;
            };
            fetch = {
              prune = true;
              pruneTags = true;
            };
            rebase = {
              autoSquash = true;
              autoStash = true;
              updateRefs = true;
            };
            merge.conflictstyle = "zdiff3";
            interactive.singlekey = true;
            help.autocorrect = "prompt";
            alias = {
              br = "branch";
              co = "checkout";
              st = "status";
              ls = "log --pretty=format:\"%C(yellow)%h%Cred%d\\\\ %Creset%s%Cblue\\\\ [%cn]\" --decorate";
              ll = "log --pretty=format:\"%C(yellow)%h%Cred%d\\\\ %Creset%s%Cblue\\\\ [%cn]\" --decorate --numstat";
              cm = "commit -m";
              ca = "commit -am";
              dc = "diff --cached";
              amend = "commit --amend -m";
              unstage = "reset HEAD --";
              merged = "branch --merged";
              unmerged = "branch --no-merged";
            };
          };
        };
      };

      home.file.".global.gitignore".text = ''
        .DS_Store
        .env
        *.local.*
        .scratch
        *sync-conflict*
        .letta
      '';
    };
  };
}
