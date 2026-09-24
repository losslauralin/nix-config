# Codex Desktop — OpenAI 的 ChatGPT/Codex 桌面应用 (Linux 封装)。
# 上游 OpenAI 只发布 macOS 二进制; ilysenko/codex-desktop-linux 复用它并为
# NixOS 打好补丁, 属于非官方打包 (wrapper 为 MIT, 内含的桌面应用是专有软件)。
# 只装程序; 网关/密钥属于运行时配置, 见 docs/ai-axonhub-gateway.md。
{inputs, ...}: {
  lossilk.ai._.codex-desktop.homeManager = {pkgs, ...}: {
    home.packages = [
      inputs.codex-desktop-linux.packages.${pkgs.stdenv.hostPlatform.system}.codex-desktop
    ];

    # Wayland 四件套, 与 qq.nix / obsidian.nix 同一组标志、同一个理由 (本机
    # Wayland-only, Umbriel 是 client-side decoration 模型), 但不走全局
    # NIXOS_OZONE_WL —— 那会把所有 Chromium/Electron 程序一起切过去。
    #
    # 为什么必须用文件而不是环境变量: 上游 Nix wrapper 用
    # `--set-default CODEX_OZONE_PLATFORM x11` (flake.nix) 把默认钉在 XWayland,
    # 而 launcher 的 append_ozone_platform() 见到 CODEX_OZONE_PLATFORM=x11 就
    # 直接 return, 自动探测整段被跳过。electron-flags.conf 走的是更早的
    # load_user_electron_args(), 产出的参数让 ozone_switch_present() 命中,
    # 于是那条 pin 被绕过 —— 文档称显式 flag "always win"。
    #
    # 上游 launcher 自己也有一套 Wayland 标志, 但只在 NIXOS_OZONE_WL 非空时
    # 追加, 且不含 WaylandWindowDecorations —— Umbriel 缺了它窗口没有边框。
    xdg.configFile."codex-desktop/electron-flags.conf".text = ''
      --ozone-platform=wayland
      --enable-features=WaylandWindowDecorations
      --enable-wayland-ime=true
      --wayland-text-input-version=3
    '';
  };
}
