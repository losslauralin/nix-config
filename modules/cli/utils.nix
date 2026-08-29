{
  lossilk.cli._.utils.homeManager = {
    pkgs,
    lib,
    ...
  }: {
    home.packages = [
      pkgs.aria2 # 多协议下载 (HTTP/FTP/BitTorrent)
      pkgs.choose # cut/awk 替代，人类友好的字段选择
      pkgs.dua # 磁盘用量分析 (交互式)
      pkgs.dust # du 替代，可视化磁盘占用
      pkgs.edir # 用 $EDITOR 批量重命名/删除文件
      pkgs.file # 文件类型检测
      pkgs.glow # 终端 Markdown 渲染
      pkgs.isd # 交互式 systemd 服务浏览器
      pkgs.ouch # 通用压缩/解压 (zip/tar/zstd/...)
      pkgs.procs # ps 替代，彩色进程列表
      pkgs.psmisc # pstree / killall / fuser
      pkgs.psutils # PDF 操作工具集
      pkgs.rclone # 云存储同步 (S3/GDrive/OneDrive/...)
      pkgs.ripgrep-all # ripgrep 包装器，可搜 PDF/压缩包/数据库
      pkgs.rsync # 增量文件同步
      pkgs.sd # sed 替代，直观的查找替换
      pkgs.wget # HTTP 下载
    ];

    programs = {
      bat = {
        enable = true;
        config.theme = lib.mkDefault "TwoDark";
      };
      eza = {
        enable = true;
        git = true;
        icons = "auto";
        extraOptions = [
          "--group-directories-first"
          "--header"
        ];
      };
      fd.enable = true;
      ripgrep = {
        enable = true;
        arguments = [
          "--hidden"
          "--glob=!.git/*"
          "--smart-case"
        ];
      };

      bottom.enable = true; # btop 替代，TUI 进程/系统监控
      tealdeer = {
        enable = true; # tldr 客户端，简化版 man pages
        settings.updates.auto_update = true;
      };
      zellij.enable = true; # tmux 替代，终端复用器
    };
  };
}
