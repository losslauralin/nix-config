# lossilk.music —— 本地音乐库: yt-dlp 下载, beets 建库, g4music / musicfox 播放。
#
# 四个程序按"谁写文件"分工, 不重叠:
#   yt-dlp 只把音轨抓进 ~/Music/incoming, 不重命名不建库 (上传者的标签质量参差,
#     直接入库只会留一堆要手工改的文件名)。
#   beets 独占 ~/Music/Library: 认领 incoming, 查 MusicBrainz 订正标签 (import.write),
#     按 paths 模板重命名后用 move 搬进去。move 而不是 copy, 因为 incoming 是待认领
#     队列, copy 会让同一批文件被反复认领。
#   gapless (包名 gapless, 二进制 g4music) 只读库。GTK4 原生 Wayland, 不需要
#     obsidian.nix 里那套 ozone / text-input 参数。它只认 XDG Music dir, 没有
#     "库在哪" 设置项。
#   go-musicfox (二进制 musicfox) 是网易云的终端 TUI, 走账号在线听。默认引擎 Beep
#     是纯 Go 实现, nixpkgs 包已带 flac + alsa, 不需要另装 mpv/mpg123。
#
# 本切面只认 ~/Music 一条路径 (XDG Music dir, 见 modules/system/xdg.nix)。
# "~/Music 背后是谁提供的存储" 是 host 事实, 由 host spec 给, 所以这里不出现盘符,
# 也没有 MUSIC_ROOT 之类的运行期开关: 路径不变, 变的只是 ~/Music 指向哪。
#
# 目录不由这里创建: yt-dlp 落 --paths 时自己 mkpath, beets 的 import.move 会创建
# directory, musicfox 保存前 MkdirAll。只有 beets 的索引目录必须预先存在, 缺了它会卡在
# "The database directory ... does not exist. Create it (Y/n)?" 的交互询问上。
#
# 配置文件手写在 xdg.configFile, 不走 HM 的 programs.*: yt-dlp 固定读
# $XDG_CONFIG_HOME/yt-dlp/config, beets 固定读 $XDG_CONFIG_HOME/beets/config.yaml,
# 上游都不提供 HM 模块。
#
# musicfox 的配置归它自己管 (`musicfox upgrade-config` 会原子写回), HM 的只读链接会
# 挡死它, 所以只在 activation 里补它那份 config.toml 的 [storage] 两项, 幂等文本编辑。
#
# 日常用法:
#   yt-dlp <URL>                      # 下载到 ~/Music/incoming
#   beet import -s ~/Music/incoming   # 逐曲认领 (整张专辑去掉 -s)
#   g4music                           # 播放 ~/Music
#   musicfox                          # 终端里在线听
#
# 来源边界: 本地库只用 yt-dlp 支持的公开来源 (YouTube / Bandcamp / SoundCloud 等),
# 不配置绕过 DRM、付费墙或平台限制的东西, 也不为此加 cookies 或抓取工具。
{
  lossilk.music.homeManager = {
    config,
    lib,
    pkgs,
    host,
    ...
  }: let
    # host spec 里没有这项 (别的机器没有外置音乐盘) 时什么都不做, ~/Music 就是本地目录。
    externalMusic = host.storage.music or null;

    # 改 musicfox 自己那份 config.toml 的 [storage]: 存在就改值, 不存在就按 marker
    # 注释插在节尾。
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
      pkgs.gapless # 本地库播放器, 二进制名 g4music
      pkgs.go-musicfox # 网易云 TUI 播放器, 二进制名 musicfox
      pkgs.yt-dlp
      pkgs.beets # nixpkgs 的 beets 已随包构建全部插件依赖
    ];

    # 唯一的 activation: beets 的索引目录。
    home.activation.createBeetsDataDir = lib.hm.dag.entryAfter ["writeBoundary"] ''
      run mkdir -p "${config.xdg.dataHome}/beets"
    '';

    # host 给了外置音乐存储就把 ~/Music 指过去。用 user 级 tmpfiles 而不是 activation:
    # 声明式, 会话启动和 switch 都幂等, 不跟 HM 的文件管理抢。
    # 用 L 不用 L+: L 只在路径不存在时建链, 遇到挡路的实体目录不动手; L+ 会先删掉它,
    # 那等于给会话启动一个删家目录的权力。代价是链缺失时要手动清一次目录。
    # 盘没挂时它是悬空链接, 写入直接 ENOENT, 不会静默落到系统盘。
    systemd.user.tmpfiles.rules =
      lib.optionals (externalMusic != null) ["L %h/Music - - - - ${externalMusic}"];

    # musicfox 下载的歌直接进 beets 的 incoming 队列, 走同一条入库流水线。
    # lyricDir 故意不设: 留空时歌词跟随歌曲落在同一目录, 而那个目录写入成功才存在。
    home.activation.musicfoxStorage = lib.hm.dag.entryAfter ["writeBoundary"] musicfoxStorage;

    xdg.configFile = {
      "yt-dlp/config".text = ''
        # 只取音轨, 转成 opus (beets 能读写它, 容器支持内嵌封面)。--audio-quality 0
        # 是该格式最佳质量; 想不重编码用 `yt-dlp --audio-format best <URL>` 覆盖。
        --extract-audio
        --audio-format opus
        --audio-quality 0

        # 内嵌原始元数据与封面。beets 之后会用 MusicBrainz 覆盖标签, 但下载来的缩略图
        # 常常比 Cover Art Archive 那张清楚, 认领前也能被播放器认出。webp → opus 支持
        # 的格式由 yt-dlp 自己转, 不需要 --convert-thumbnails。
        --embed-metadata
        --embed-thumbnail

        # 暂存层平铺。beets 把"一个目录 = 一张专辑", 同一下载者的不相干曲目混在一个
        # 目录里会被误判成专辑; 入库后的结构由 beets 的 paths 模板决定。
        --paths home:${config.home.homeDirectory}/Music/incoming
        --output "%(title)s [%(id)s].%(ext)s"

        # 断点续传, 不覆盖已有文件: 重复跑同一条命令直接跳过。
        --continue
        --no-overwrites
      '';

      "beets/config.yaml".text = ''
        # 音乐文件与索引分开: directory 是库根 (~/Music/Library, g4music 扫的地方),
        # library 按 XDG 放 dataHome —— 索引是程序状态, 混进音乐目录只会让 library.db
        # 和它一串 -before-*.bak 出现在音乐文件夹里。
        # 写绝对路径而不是 ~: 展开时机取决于启动环境, 写死更好排查。
        # 库根不做"可能换盘"的假设: ~/Music 指向哪是 host 的事。
        directory: ${config.home.homeDirectory}/Music/Library
        library: ${config.xdg.dataHome}/beets/library.db

        import:
          move: yes
          # write: 把订正后的标签/封面写回音频文件本身, 而不是只存在 sqlite 库里 ——
          # 否则 g4music 直接读文件标签, 看不到任何整理结果。
          write: yes
          autotag: yes
          detail: yes
          # 不设 timid, 保持默认 yes: 匹配不确定时停下来问, 下载来的标题党文件名不配
          # 被静默写进库。

        # 入库后的目录结构。%aunique{} 给同名专辑加区分符, 免得同专辑的不同版本互撞。
        paths:
          default: $albumartist/$album%aunique{}/$track $title
          singleton: $artist/$title
          comp: Compilations/$album%aunique{}/$track $title

        # fetchart 从 Cover Art Archive 等来源补封面, embedart 把它写进音频文件
        # (g4music 读的是内嵌封面)。没开 lyrics (g4music 不显示) 和 replaygain
        # (会改写音频文件)。
        plugins: fetchart embedart

        fetchart:
          auto: yes
        embedart:
          auto: yes
          # 保留目录内的 cover.jpg, 文件管理器与其他播放器可以直接用。
          remove_art_file: no
      '';
    };
  };
}
