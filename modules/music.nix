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
#     才要补的)。它只认 XDG Music dir, 没有"库在哪"这个设置项。
#   - go-musicfox (可执行文件 musicfox) 是另一条"在线听"的支线: 网易云客户端的终端
#     TUI, 默认播放引擎 Beep 是纯 Go 实现 (nixpkgs 包已带 flac + alsa 依赖),
#     不需要另外装 mpv/mpg123。
#
# 本切面只认 ~/Music 这一条路径 (XDG Music dir, 由 modules/system/xdg.nix 定义)。
# "~/Music 背后是谁提供的存储" 是 host 事实, 由 host spec 决定, 所以这里不出现任何盘符,
# 也不需要 MUSIC_ROOT 之类的运行期开关: 路径永远不变, 变的只是 ~/Music 指向哪。盘不在时
# 它是悬空软链, 写入直接失败, 不会静默落到系统盘。
#
# 三个程序都会自己建目录, 所以这里不建任何目录: yt-dlp 落 --paths 时自己 mkpath,
# beets 的 import.move 会创建 directory (实测: 目标目录不存在也能直接 import),
# musicfox 的 track manager 保存前 MkdirAll。唯一必须预先存在的是 beets 的索引目录
# (~/.local/share/beets): 它缺失时 beets 会卡在 "The database directory ... does not
# exist. Create it (Y/n)?" 的交互询问上, 非交互场景直接报错退出 —— 只为此留一条
# activation。
#
# 配置文件用 xdg.configFile 手写, 不走 HM 的 programs.*: yt-dlp 固定读
# $XDG_CONFIG_HOME/yt-dlp/config, beets 固定读 $XDG_CONFIG_HOME/beets/config.yaml,
# 上游都不提供 HM 模块, 手写文件就是唯一入口。
#
# musicfox 的配置归它自己管 (连 `musicfox upgrade-config` 都会原子写回它), HM 的只读
# 链接会把它挡死, 所以这里只在 activation 里补/改它那份 config.toml 的 [storage],
# 而且是幂等的文本编辑, 应用自己随时可以再改。
#
# 日常用法:
#   yt-dlp <URL>                      # 下载到 ~/Music/incoming
#   beet import -s ~/Music/incoming   # 逐曲认领 (整张专辑去掉 -s)
#   g4music                           # 播放 ~/Music
#   musicfox                          # 终端里在线听 (网易云账号)
#
# 来源边界: 本地库只用 yt-dlp 支持的公开来源 (YouTube / Bandcamp / SoundCloud 等) 建立。
# 不配置任何绕过 DRM、付费墙或平台限制的东西, 也不为此加 cookies 或额外抓取工具;
# musicfox 是账号内的在线播放器, 单首收藏走它自己的下载功能落进 incoming, 不做批量抓取。
{
  lossilk.music.homeManager = {
    config,
    lib,
    pkgs,
    host,
    ...
  }: let
    # ~/Music 指向哪由 host spec 给 (host.storage.music 是本机 fact)。没写这台就没有
    # 这个属性 —— 那时模块什么都不做, ~/Music 就是本地普通目录, 不假设任何机器有外置盘。
    externalMusic = host.storage.music or null;
    # musicfox 的 [storage] 里 downloadDir / fileNameTpl 两个条目: 存在就改值, 不存在
    # 就按 marker 注释插在节尾。纯文本编辑 + 幂等, 因为它管的文件是应用自己的。
    musicfoxStorage = ''
      set -euo pipefail
      conf="''${XDG_CONFIG_HOME:-$HOME/.config}/go-musicfox/config.toml"
      [ -f "$conf" ] || exit 0
      setKey() {
        key="$1" value="$2"
        if grep -qE "^''${key}[[:space:]]*=" "$conf"; then
          sed -i -E "s|^''${key}[[:space:]]*=.*|''${key} = \"''${value}\"|" "$conf"
        elif grep -qF "# musicfox-nix-storage" "$conf"; then
          sed -i "s|# musicfox-nix-storage|''${key} = \"''${value}\"\n# musicfox-nix-storage|" "$conf"
        else
          printf '\n# musicfox-nix-storage\n%s = \"%s\"\n' "$key" "$value" >> "$conf"
        fi
      }
      setKey downloadDir "$HOME/Music/incoming"
      setKey fileNameTpl "{{.SongName}} [{{.SongId}}].{{.FileExt}}"
    '';
  in {
    home.packages = [
      pkgs.gapless # 本地库播放器 (二进制名 g4music)
      pkgs.go-musicfox # 网易云 TUI 播放器 (二进制名 musicfox)
      pkgs.yt-dlp # 下载
      pkgs.beets # 标签整理 + 建库 (nixpkgs 的 beets 已随包构建全部插件依赖)
    ];

    # 唯一的 activation: beets 的索引目录。其它目录由各程序自己创建 (见文件头)。
    home.activation.createBeetsDataDir = lib.hm.dag.entryAfter ["writeBoundary"] ''
      run mkdir -p "${config.xdg.dataHome}/beets"
    '';

    # host 声明了外置音乐存储 (host.storage.music) 就把 ~/Music 指过去, 用 user 级
    # tmpfiles 而不是 activation: 它是声明式的, boot/会话启动与 switch 都幂等,
    # 且不在 HM 那套文件管理里跟 xdg.userDirs 抢 ~/Music。
    # 用 L 不用 L+: L 只在路径不存在时建链, 遇到挡路的实体目录会在日志里报错而不动手;
    # L+ 会删掉已存在的目录再建链, 那等于给会话启动一个删家目录的权力。
    # 盘没挂时它是悬空链接 —— 写入直接 ENOENT, 不会静默落到系统盘。
    systemd.user.tmpfiles.rules =
      lib.optionals (externalMusic != null) ["L %h/Music - - - - ${externalMusic}"];

    # musicfox 的下载目录直接指到 beets 的 incoming 队列: 网络侧下的歌走同一条入库
    # 流水线, 不另开一条支线。lyricDir 故意不设 —— 留空时歌词跟着歌曲落在同一个目录,
    # 而那个目录一定已经存在 (歌曲写成功才有歌词), 不需要为它再建一个目录。
    home.activation.musicfoxStorage = lib.hm.dag.entryAfter ["writeBoundary"] musicfoxStorage;

    xdg.configFile = {
      "yt-dlp/config".text = ''
        # 只取音轨。opus 是库里唯一会写入的有损格式: beets 能读写它, 容器也支持内嵌
        # 封面。--audio-quality 0 = 该格式的最佳质量。
        # 想要"不重编码"就用 `yt-dlp --audio-format best <URL>` 覆盖这一行。
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
        # paths 模板决定。目录不存在时 yt-dlp 自己建。
        --paths home:${config.home.homeDirectory}/Music/incoming
        --output "%(title)s [%(id)s].%(ext)s"

        # 断点续传 + 不覆盖已有文件: 重复跑同一条命令时直接跳过抓到的曲目。
        --continue
        --no-overwrites
      '';

      "beets/config.yaml".text = ''
        # directory (音乐文件) 与 library (sqlite 索引) 分开:
        #   - directory 是音乐库根, 就是 g4music 扫的那棵树下 (~/Music/Library);
        #   - library 是索引, 按 XDG 放 dataHome —— 索引属于"程序状态", 混进音乐目录
        #     只会让 library.db 和它一串 -before-*.bak 出现在音乐文件夹里。
        # 两个都不是 beets 默认值 (默认 directory=~/Music, library=<配置目录>/library.db)。
        # 写绝对路径而不是 ~: 展开时机取决于启动环境, 写死更好排查。
        # 这里不需要为库根做任何"可能换盘"的假设: ~/Music 指向哪是 host 的事。
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
