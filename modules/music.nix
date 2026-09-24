# lossilk.music —— 本地音乐库工作流: yt-dlp 下载 → beets 建库 → 播放。
#
# 分工的关键是"谁拥有文件":
#   - yt-dlp 只负责把音轨抓成 opus (内嵌原始元数据与封面), 落到 ~/Music/incoming
#     暂存区。它不重命名也不建库: 抓来的标签来自上传者, 质量参差, 直接入库只会留
#     下一堆要手工改的文件名。
#   - beets 是 ~/Music/Library 的唯一持有者: 认领 incoming, 查 MusicBrainz 订正
#     标签 (import.write), 按 paths 模板重命名, 再用 move 把文件搬进库。move 而不是
#     copy, 因为 incoming 是"待认领队列"而非仓库 —— copy 会让同一批文件被反复认领。
#   - gapless (包名 gapless, 可执行文件 g4music) 读本地库, 不写任何标签。GTK4 原生
#     Wayland, 不需要 obsidian.nix 里那套 ozone / text-input 参数 (那是 Electron
#     才要补的)。
#   - go-musicfox (可执行文件 musicfox) 是另一条"在线听"的支线: 网易云客户端的终端
#     TUI, 流媒体播放走自己的账号, 不碰上面的本地库流水线。默认播放引擎 Beep 是纯 Go
#     实现 (nixpkgs 包已带 flac + alsa 依赖), 不需要另外装 mpv/mpg123。
#
# 不给 musicfox 代管配置: 它自己维护 $XDG_CONFIG_HOME/go-musicfox/config.toml (TOML),
# 连 `musicfox upgrade-config` 都是向该文件原子写回 —— HM 的只读链接会直接把它挡死。
# 同理也不预置主题/快捷键, 那些是应用内改的运行期状态 (参照 obsidian.nix 对 app.json
# 的处理: 只声明该由 Nix 拥有的部分, 应用自己会写的状态不碰)。
# 想换存储位置可以用 MUSICFOX_ROOT (上游明确支持的接口), 也是同一个理由: 那是运行期
# 环境而不是 Nix 代管的内容。
#
# ~/Music 是唯一入口: g4music 首次启动按 XDG Music dir 找库 (递归扫子目录), 而 beets
# 的 directory 就在它下面 (~/Music/Library), 播放器不需要另配库路径就能看到整理结果。
# 该目录由 modules/system/xdg.nix 的 xdg.userDirs 创建 (此前 music = null,
# XDG_MUSIC_DIR 缺失, xdg-user-dir MUSIC 会退回 $HOME, 播放器就把整个家目录当音乐库)。
#
# 配置文件用 xdg.configFile 手写, 不走 HM 的 programs.*: yt-dlp 固定读
# $XDG_CONFIG_HOME/yt-dlp/config, beets 固定读 $XDG_CONFIG_HOME/beets/config.yaml,
# 上游都不提供 HM 模块, 手写文件就是唯一入口。
#
# 日常用法:
#   yt-dlp <URL>                      # 下载到 ~/Music/incoming
#   beet import -s ~/Music/incoming   # 逐曲认领 (整张专辑去掉 -s)
#   g4music                           # 播放 ~/Music/Library
#   musicfox                          # 终端里在线听 (网易云账号)
#
# 来源边界: 本地库只用 yt-dlp 支持的公开来源 (YouTube / Bandcamp / SoundCloud 等) 建立。
# 不配置任何绕过 DRM、付费墙或平台限制的东西, 也不为此加 cookies 或额外抓取工具;
# musicfox 是账号内的在线播放器, 它的下载功能不接进 beets 的 incoming。
_: {
  lossilk.music.homeManager = {
    config,
    lib,
    pkgs,
    ...
  }: {
    home.packages = [
      pkgs.gapless # 本地库播放器 (二进制名 g4music)
      pkgs.go-musicfox # 网易云 TUI 播放器 (二进制名 musicfox)
      pkgs.yt-dlp # 下载
      pkgs.beets # 标签整理 + 建库 (nixpkgs 的 beets 已随包构建全部插件依赖)
    ];

    # beets 不自动创建 library 所在的目录: 目录缺失时它会卡在
    # "The database directory ... does not exist. Create it (Y/n)?" 的交互询问上,
    # 非交互场景 (脚本) 直接报错退出。库根 ~/Music 由 xdg.userDirs 建, 这里补索引目录。
    home.activation.createBeetsDataDir = lib.hm.dag.entryAfter ["writeBoundary"] ''
      run mkdir -p "${config.xdg.dataHome}/beets"
    '';

    xdg.configFile = {
      "yt-dlp/config".text = ''
        # 只取音轨。opus 是库里唯一会写入的有损格式: beets 能读写它, 容器也支持内嵌
        # 封面。--audio-quality 0 = 该格式的最佳质量。
        --extract-audio
        --audio-format opus
        --audio-quality 0

        # 内嵌原始元数据与封面。beets 之后会用 MusicBrainz 的版本覆盖标签, 但下载来的
        # 缩略图往往比 Cover Art Archive 那张清楚, 而且 incoming 里的文件在认领前也能
        # 直接被播放器认出。webp → opus 容器支持的格式由 yt-dlp 自己转,
        # 不需要 --convert-thumbnails。
        --embed-metadata
        --embed-thumbnail

        # 暂存层平铺, 不按上传者建子目录: beets 把"一个目录 = 一张专辑", 同一下载者
        # 的不相干曲目混在一个目录里会被误判成专辑。真正入库的目录结构由 beets 的
        # paths 模板决定。
        --paths home:${config.home.homeDirectory}/Music/incoming
        --output "%(title)s [%(id)s].%(ext)s"

        # 断点续传 + 不覆盖已有文件: 重复跑同一条命令时直接跳过抓到的曲目。
        --continue
        --no-overwrites
      '';

      "beets/config.yaml".text = ''
        # directory (音乐文件) 与 library (sqlite 索引) 分开:
        #   - directory 是音乐库根, 落在 g4music 扫的那棵树下 (~/Music);
        #   - library 是索引, 按 XDG 放 dataHome —— 索引属于"程序状态", 混进音乐目录
        #     只会让 library.db 和它一串 -before-*.bak 出现在音乐文件夹里。
        # 两个都不是 beets 默认值 (默认 directory=~/Music, library=<配置目录>/library.db),
        # 默认把状态放在 ~/.config/beets。
        # 写绝对路径而不是 ~: 展开时机取决于启动环境, 写死更好排查。
        # 分开不影响可移植性: beets 2.10 起条目路径按库根 (directory) 相对存储,
        # 搬动整个 ~/Music 不会留下失效路径。
        directory: ${config.home.homeDirectory}/Music/Library
        library: ${config.xdg.dataHome}/beets/library.db

        import:
          move: yes
          # write: 把订正后的标签/封面写回音频文件本身, 而不是只存在 beets 的 sqlite
          # 库里 —— 否则换播放器 (g4music 直接读文件标签) 就看不到任何整理结果。
          write: yes
          autotag: yes
          detail: yes
          # 不设 timid (保持默认 yes): 匹配不确定时停下来问。下载来的"标题党"视频名
          # 不配被静默写进库。

        # 入库后的目录结构。%aunique{} 给同名专辑加区分符, 免得同专辑的不同版本互相覆盖。
        paths:
          default: $albumartist/$album%aunique{}/$track $title
          singleton: $artist/$title
          comp: Compilations/$album%aunique{}/$track $title

        # 只开需要的两个:
        #   fetchart 从 Cover Art Archive 等来源补封面
        #   embedart 把封面写进音频文件 (g4music 读的是内嵌封面)
        # 常用但没开: lyrics (g4music 不显示歌词), replaygain (会改写音频文件)。
        plugins: fetchart embedart

        fetchart:
          auto: yes
        embedart:
          auto: yes
          # 保留目录内的 cover.jpg: 文件管理器与其他播放器可以直接用它。
          remove_art_file: no
      '';
    };
  };
}
