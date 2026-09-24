# Claude Code CLI — Anthropic 官方编码 agent 命令行工具。
# nixpkgs 属性名是 claude-code, 主程序为 claude。
# 只装程序; 网关/密钥属于运行时配置, 见 docs/ai-axonhub-gateway.md。
_: {
  lossilk.ai._.claude-code.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.claude-code];
  };
}
