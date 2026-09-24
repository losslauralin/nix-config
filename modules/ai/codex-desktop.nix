# Codex Desktop — OpenAI 的 ChatGPT/Codex 桌面应用 (Linux 封装)。
# 上游 OpenAI 只发布 macOS 二进制; ilysenko/codex-desktop-linux 复用它并为
# NixOS 打好补丁, 属于非官方打包 (wrapper 为 MIT, 内含的桌面应用是专有软件)。
# 只装程序; 网关/密钥属于运行时配置, 见 docs/ai-axonhub-gateway.md。
{inputs, ...}: {
  lossilk.ai._.codex-desktop.homeManager = {pkgs, ...}: {
    home.packages = [
      inputs.codex-desktop-linux.packages.${pkgs.stdenv.hostPlatform.system}.codex-desktop
    ];
  };
}
