# modules/virt/wsl.nix
#
# lossilk.virt._.wsl - WSL 通用切面 (任何 WSL host 都能引)
#
# 注: den.batteries.wsl 由 host 实体的 `wsl.enable = true` 触发, 已自动:
#   - imports nixos-wsl module
#   - 设 nixos.wsl.enable = true
#   - 激活 wsl-host context (让 <den/primary-user> 自动设 wsl.defaultUser)
#   - 路由 wsl class → nixos.wsl.*
# 因此这里不写 imports / wsl.enable, 改用 wsl class 简写 wslConf.
let
  winUser = "Lossilklauralin";
in {
  lossilk.virt._.wsl = {
    # wsl class 由 den.batteries.wsl 路由到 nixos.wsl.*
    wsl = _: {
      wslConf.automount.root = "/mnt";
      wslConf.interop.appendWindowsPath = false;
    };

    nixos = _: {
      programs.nix-ld.enable = true;
    };

    homeManager = {
      home.sessionVariables = {
        WIN_USER = winUser;
        BROWSER = "/mnt/c/Program Files/Google/Chrome/Application/chrome.exe";
        DISPLAY = ":0";
      };

      home.shellAliases = {
        explorer = "/mnt/c/Windows/explorer.exe";
        notepad = "/mnt/c/Windows/System32/notepad.exe";
        cdwin = "cd /mnt/c/Users/$WIN_USER";
        cddownloads = "cd /mnt/c/Users/$WIN_USER/Downloads";
        cddesktop = "cd /mnt/c/Users/$WIN_USER/Desktop";
      };

      # Windows VS Code 在 WSL 内的 CLI. 用 home.sessionPath 让 HM 给所有 shell
      # (zsh/fish/bash) 都生成 PATH 注入, 不再绑 programs.zsh.initContent.
      home.sessionPath = [
        "/mnt/c/Users/${winUser}/AppData/Local/Programs/Microsoft VS Code/bin"
      ];
    };
  };
}
