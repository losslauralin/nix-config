{
  lossilk.cli._.fzf.homeManager = {
    programs.fzf = {
      enable = true;
      # atuin owns Ctrl-R (shell history); keep fzf for files/completion only.
      historyWidget.command = "";
      defaultCommand = "fd --type f --hidden --follow --exclude .git";
      defaultOptions = [
        "--height 40%"
        "--layout=reverse"
        "--border"
      ];
    };
  };
}
