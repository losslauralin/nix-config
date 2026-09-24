# lossilk.desktop._.platform._.gstreamer —— GStreamer 运行时插件。
#
# 为什么需要这个切面:
#   WebKitGTK 内部用 GStreamer 做媒体处理, 启动时会去要 `appsink` 和
#   `autoaudiosink` 两个 element。NixOS 默认只装了 pipewire 那一个插件
#   (`/run/current-system/sw/lib/gstreamer-1.0/libgstpipewire.so`), 于是:
#
#     GStreamer element appsink not found. Please install it.
#     GStreamer element autoaudiosink not found. Please install it
#     (WebKitWebProcess:NNN): GLib-GObject-CRITICAL: invalid (NULL) pointer instance
#     (WebKitWebProcess:NNN): g_signal_connect_data: assertion failed
#
#   紧接着前端拿不到可用的渲染管线 —— 实测表现为 Tauri 应用 (aghub) 启动后
#   无限转圈 / 主内容区整块白, 而它的 Rocket 后端和前后端 API 通信完全正常
#   (已用真机日志确认: 前端只发出前两个请求就停住, 正是渲染失败的时刻)。
#   tauri-apps/tauri#4642 记录了这个日志组合, 并给出解法是补 gst-plugins-good。
#
# 两个缺失的 element 分别在:
#   appsink      -> gst-plugins-base 的 libgstapp.so
#   autoaudiosink -> gst-plugins-good 的 libgstautodetect.so
# 所以 base + good 都要。
#
# 为什么放在 platform 而不是 aghub 的切面:
#   缺插件不是 aghub 的问题, 是这台机器的会话事实。任何走 WebKitGTK 的应用
#   (obsidian、bottles 等) 都会踩同一个坑, 所以和 portal.nix 同级共享。
#
# 为什么用 `environment.variables` 的列表形式:
#   列表类型在模块系统里按拼接合并, 所以这里追加的路径不会覆盖别处写入的值
#   (同 fcitx5-rime-wanxiang.nix 对 QT_PLUGIN_PATH 的处理)。GStreamer 的
#   `GST_PLUGIN_PATH` 是**追加**而非覆盖系统路径, 所以也不会挤掉已有的
#   libgstpipewire.so。
#
# 为什么 gstreamer 要取 `.out` 并单独列:
#   默认输出 (`gstreamer`) 是 `-bin`, 装的是 gst-launch / gst-inspect 等工具;
#   含 /lib 插件目录的反而是 `.out`。只写包名会漏掉 core elements
#   (libgstcoreelements.so 等), 所以两个输出都列上。
{
  lossilk.desktop._.platform._.gstreamer.nixos = {pkgs, ...}: {
    environment.systemPackages = with pkgs.gst_all_1; [
      gstreamer
      gst-plugins-base
      gst-plugins-good
    ];

    environment.variables.GST_PLUGIN_PATH = with pkgs.gst_all_1; [
      "${gstreamer.out}/lib/gstreamer-1.0"
      "${gst-plugins-base}/lib/gstreamer-1.0"
      "${gst-plugins-good}/lib/gstreamer-1.0"
    ];
  };
}
