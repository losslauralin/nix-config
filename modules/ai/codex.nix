# Codex CLI — OpenAI 官方编码 agent 命令行工具。
# 只装程序; 网关/密钥属于运行时配置, 见 docs/ai-axonhub-gateway.md。
_: {
  lossilk.ai._.codex.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.codex];
  };
}
