# modules/users/loss.nix
#
# User "loss" 主切面 —— 仅引跨平台/跨架构通用切面。
# 平台/host 锁定的切面在对应 host 主切面 includes 里。
# User entity 由各 host 文件在 den.hosts.<system>.<host>.users.loss 声明。
{
  den,
  # den angle-bracket syntax needs __findFile in lexical scope.
  # deadnix is configured with no-underscore=true so it will not remove it.
  __findFile,
  ...
}: {
  den.aspects.loss = {
    includes = [
      den.provides.primary-user
      # loss 是个人主用户，显式 opt-in 接收所在 host aspect tree 中的 user classes
      # (homeManager/hjem 等)。user 自己的 includes 不依赖 host-aspects。
      den.batteries.host-aspects
      # shell 选择: 切 zsh ↔ fish 只改这个 Selection Variant；root 与 user-shell battery 由 variant 带入。
      <lossilk/cli/shell/fish>

      # HM 平台策略 (autoExpire weekly + wget)
      <lossilk/home-manager>
      <lossilk/system/xdg> # XDG Base Directory 与 user dirs
      # cli (XDG: Terminal=true, nixpkgs: shells/ + tools/)
      <lossilk/cli/starship> # 命令行提示符
      <lossilk/cli/atuin> # shell history
      <lossilk/cli/utils> # coreutils 替代 + 杂项
      <lossilk/cli/fzf> # 模糊搜索
      <lossilk/cli/yazi> # TUI 文件管理器
      <lossilk/cli/zoxide> # 智能 cd

      # dev (nixpkgs: development/)
      <lossilk/dev/git> # Git 栈 (includes _.gh + _.lazygit)
      <lossilk/dev/git/jujutsu> # Git-compatible source-control workflow
      <lossilk/dev/extras> # 杂项开发辅助包
      <lossilk/dev/workflow/just> # Justfile 命令执行器
      <lossilk/dev/workflow/direnv> # 自动加载项目环境变量
      <lossilk/dev/workflow/devenv> # 可复制开发沙盒
      <lossilk/dev/workflow/hyperfine> # 基准测试工具
      <lossilk/dev/workflow/ni> # 自动检测包管理器
      <lossilk/dev/workflow/ansible> # 自动化运维
      <lossilk/dev/lang/go>
      <lossilk/dev/lang/rust>
      <lossilk/dev/lang/python>
      <lossilk/dev/lang/nix>
      <lossilk/dev/lang/javascript>
      <lossilk/dev/editors/neovim> # 默认编辑器 + EDITOR/VISUAL
      <lossilk/dev/editors/emacs> # Emacs 编辑器
      <lossilk/dev/editors/helix> # Helix 模态编辑器
      <lossilk/dev/editors/zed> # Zed GUI 编辑器

      # AI 辅助工具
      <lossilk/ai/pi>

      # security / networking
      <lossilk/hacking>
      <lossilk/security/sops>
      <lossilk/security/bitwarden>
      <lossilk/networking/karing>
    ];

    # initialPassword 走 user class (den.provides.os-user 自动路由到 users.users.loss.*)
    user.initialPassword = "password";
  };
}
