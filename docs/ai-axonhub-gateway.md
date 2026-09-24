# AxonHub 网关: 客户端配置指南

AxonHub 是服务端网关 (`modules/ai/axonhub.nix`, 容器监听 `:8090`)。客户端只需要
**base URL + 凭证**, 这些都是运行时配置, 不进 Nix —— 写进 Nix 会落进全局可读的
store, 密钥会泄漏。

本页是手动配置指南。Nix 只负责把程序装好; 配置由你在运行时写入。

## 前置: 网关是否在跑

```sh
curl -sS http://localhost:8090/health
```

网关由三个 host 引入 (`ai._.axonhub._.local`): 真机、GUI VM、headless VM。
在 AxonHub 的 Web UI 里创建 API key, 下面用它替换 `<AXONHUB_KEY>`。

---

## Codex CLI

配置文件 `~/.codex/config.toml`。注意 AxonHub 是**独立 provider**, 所以要写
`model_providers`; `openai_base_url` 只用来改内置 `openai` provider 的 URL, 不适用。

```toml
model = "<AxonHub 里的模型名>"
model_provider = "axonhub"

[model_providers.axonhub]
name = "AxonHub"
base_url = "http://localhost:8090/v1"
env_key = "AXONHUB_API_KEY"   # 从环境变量读 key, 不写死在文件里
```

密钥放环境变量 (shell profile 或 `~/.codex/` 外的 secret 工具):

```sh
export AXONHUB_API_KEY="<AXONHUB_KEY>"
```

校验时留意:

- `model` 必须是 AxonHub 实际提供的模型名, 否则请求会被拒。
- 若网关只支持 Anthropic 格式而非 OpenAI 格式, 改用 `wire_api` 显式声明。
- Codex 读用户级 `~/.codex/config.toml`; 项目级 `.codex/config.toml` **不能**
  设置 provider / base_url 等重定向凭证的键, 会被忽略并告警。

---

## Claude Code

配置文件 `~/.claude/settings.json`, 用 `env` 块。这是官方推荐做法: 它同时覆盖
前台 CLI 和后台 agent, 而只设 shell 变量覆盖不到后者。

```json
{
  "env": {
    "ANTHROPIC_BASE_URL": "http://localhost:8090",
    "ANTHROPIC_AUTH_TOKEN": "<AXONHUB_KEY>"
  }
}
```

凭证变量二选一, 取决于网关读哪个 header:

| 变量 | 发送的 header | 适用 |
|---|---|---|
| `ANTHROPIC_AUTH_TOKEN` | `Authorization: Bearer` | 网关说「bearer token」 |
| `ANTHROPIC_API_KEY` | `x-api-key` | 网关说「API key」 |

不确定就先试 `ANTHROPIC_AUTH_TOKEN`; 返回 `401` 说明 header 不匹配, 换另一个。

先验证连通性再持久化 (需要 shell 里已 export 上述变量):

```sh
curl -sS "$ANTHROPIC_BASE_URL/v1/messages" \
  -H "Authorization: Bearer $ANTHROPIC_AUTH_TOKEN" \
  -H "anthropic-version: 2023-06-01" \
  -H "content-type: application/json" \
  -d '{"model":"<任意模型名>","max_tokens":1,"messages":[{"role":"user","content":"hi"}]}'
```

返回以 `{"id":"msg_` 开头的 JSON 即通过。报「未知模型」也算通过 —— 请求已过认证。
`401` 才是凭证问题。

注意事项:

- **订阅不再生效**: 网关凭证变量一旦设置, 会取代 claude.ai 登录, 该会话按网关
  后面的账号计费。
- 用 `/status` 确认 `Anthropic base URL` 显示的是网关地址。
- 保存的 claude.ai 登录会保留但闲置; `claude /logout` 可清除。
- 设置网关后 **Remote Control 与语音听写不可用** (它们依赖 claude.ai 身份)。

---

## 各 AI 程序的 Nix 侧位置

| 程序 | 切面 | 说明 |
|---|---|---|
| pi | `ai._.pi` | user 主切面 |
| Codex CLI | `ai._.codex` | user 主切面 |
| Claude Code CLI | `ai._.claude-code` | user 主切面 |
| Codex 桌面版 | `ai._.codex-desktop` | GUI 应用, 只上有桌面的 host |
| AxonHub 网关 | `ai._.axonhub._.local` | 服务端, 各 host 显式 include |

密钥与 base URL 一律运行时配置, 不进以上任何切面。
