# SSH remote-access concerns. Agent and server are explicit children; no generic ssh
# root Aspect exists because there is no shared SSH behavior to activate implicitly.
#
# agent 半边除 ssh-agent 外还声明 GitHub over SSH 的绕行配置: 本机网络环境下
# github.com:22 的 SSH 握手会被中断 (TCP 可达但密钥交换被阻断), 必须改走
# ssh.github.com:443 并经本地 clash 的 HTTP 代理。TUN 模式不足以绕过 —— clash
# 默认规则把该域名判 DIRECT, 所以仍需显式 ProxyCommand。
{
  lossilk.networking._.ssh._.agent.homeManager = {pkgs, ...}: {
    services.ssh-agent.enable = true;

    programs.ssh = {
      enable = true;

      # HM 的 programs.ssh 有一组隐式默认值 (ForwardAgent=false,
      # AddKeysToAgent=no, ServerAliveInterval=0 等), 未来会被移除并改为报错。
      # 下面 settings."*" 已逐条显式写出这些键 (其中 AddKeysToAgent 与
      # ServerAliveInterval 是本仓库有意改的值), 所以关掉隐式默认值行为不变,
      # 只是消掉迁移警告。
      enableDefaultConfig = false;

      # `netcat` 走显式 store 引用, 不依赖系统 PATH 里恰好存在的 nc。
      # 注意: 上面的 "*" 块要覆盖 HM 隐式默认值列表里的全部键, 否则关闭
      # enableDefaultConfig 后那些键会退回 OpenSSH 内建默认 (例如
      # AddKeysToAgent 默认 no, 会让 ssh-agent 失效)。
      settings = {
        # 全局默认。HM 从 legacy matchBlocks 迁移过来的默认值把
        # AddKeysToAgent/ForwardAgent 设为 no, 会让上面的 ssh-agent 白开;
        # 这里改成 yes 让 key 首次使用时自动入 agent。
        "*" = {
          AddKeysToAgent = "yes";
          ForwardAgent = false;
          Compression = false;
          ServerAliveInterval = 60;
          ServerAliveCountMax = 3;
          HashKnownHosts = false;
          UserKnownHostsFile = "~/.ssh/known_hosts";
          ControlMaster = "no";
          ControlPath = "~/.ssh/master-%r@%n:%p";
          ControlPersist = "no";
        };

        # key 不能写成 `github.com` —— Nix 会把带点的 attrpath 拆成嵌套
        # (github -> com), 于是整块被子 attrset 包住而无法渲染。
        # 用不带点的 key + 显式 header 指定 Host 模式。
        github = {
          header = "Host github.com";
          # 改写 HostName/Port 到 GitHub 的 443 SSH 端点。
          HostName = "ssh.github.com";
          Port = 443;
          User = "git";
          IdentityFile = "~/.ssh/id_ed25519";
          IdentitiesOnly = true;
          # 代理端口是 clash 的 HTTP/SOCKS 混合监听端口, 不是 TUN 网卡。
          # 换端口只需改这一行。
          # 刻意不加直连回落 (`|| nc %h %p`): 实测 TUN 下直连 22/443 均超时,
          # 回落只会把"clash 没开"变成含糊的连接超时, 反而难排障。
          ProxyCommand = "${pkgs.netcat}/bin/nc -X connect -x 127.0.0.1:7897 %h %p";
        };
      };
    };
  };

  lossilk.networking._.ssh._.server.nixos = {
    services.openssh = {
      enable = true;
      openFirewall = true;
    };
  };
}
