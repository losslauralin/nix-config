# 新增 / 修改 Feature 切面指南

> 给 agent 的机械流程。先读 `CONTEXT.md` 和 `docs/frameworks/den.md`。
> 上游语义以本地 `~/workspace/nix-ref/den/docs/src/content/docs/guides/configure-aspects.mdx`、`guides/mutual.mdx` 为准。

## 0. 先建立 Den 模型

Den 不是传统 “host imports modules” 模型。

- **Entity** 声明存在什么：host、user、home。
- **Aspect** 声明 feature 做什么：一个 attrset，包含不同 Nix **Class** 的 owned configs。
- **Owned config** 是 class 名下的普通 Nix module：`nixos`、`homeManager`、`darwin`、`user`、`wsl` 等。
- **includes** 声明 aspect DAG 依赖，不是 Nix `imports`。
- **provides** 声明命名子切面；特殊 `provides.to-users` / `to-hosts` 做跨 entity 交付。
- **den.default** 自动应用到所有 entity，只放框架默认，不放业务 feature。

示例：

```nix
{
  lossilk.desktop._.example = {
    nixos.services.example.enable = true;
    homeManager.programs.example.enable = true;
  };
}
```

这个 aspect 有两个 owned configs。host 直接接收 `nixos`；user 直接接收 `homeManager`；具体如何跨 entity 到达由 pipeline / `host-aspects` / `provides` 决定。

## 1. 分清两种函数参数

### Den context function（aspect/root 层）

用于按 context 激活。参数只能请求 Den pipeline 中存在的值，如 `host`、`user`、`home`、`class`、`aspect-chain`。

```nix
lossilk.gaming._.min = {host, ...}: {
  nixos = {pkgs, ...}: {
    # host 可在这里从外层闭包使用
  };
};
```

如果 root function 写了 `{pkgs, ...}:`，Den 会把 `pkgs` 当成 context arg，而不是 Nix module arg。多数 context 没有 `pkgs`，切面会不匹配或被跳过。

### Nix module function（class block 内）

用于 NixOS/Home Manager module args，必须带 `...`：

```nix
lossilk.cli._.tool.homeManager = {pkgs, lib, ...}: {
  home.packages = [pkgs.tool];
};
```

## 2. 判断语义类型

| 需求 | 类型 | 做法 |
|---|---|---|
| 单 host 硬件/一次性配置 | Host spec | 写进 `modules/hosts/<host>/default.nix` 的 `nixos` block，不建 aspect |
| 普通可复用功能 | Leaf Aspect | 新建/修改 `modules/<concern>/<name>.nix` |
| 同一选择轴候选（shell/compositor） | Selection Variant | 子切面 include family root 和必要 battery |
| 给 family/leaf 叠加能力 | Extension | 子切面，可单独 include |
| 稳定组合/route table | Profile / Bundle | 通常只写 `includes`，不拥有 leaf 实现 |
| 两个 concern 的 glue | Integration Edge | 只拥有接线配置，不拥有两端实现 |
| 无自定义配置的小工具 | 聚合项 | 放入现有聚合（如 `cli/utils.nix`、`dev/extras.nix`） |

先查 den batteries：如果上游已有 battery，优先 include battery。

## 3. 选路径与 aspect path

按主要功能意图选 concern，不按 daemon/GUI/systemd 技术形状。

| Concern | 路径 | Aspect path |
|---|---|---|
| CLI / shell / TUI | `modules/cli/` | `lossilk.cli._.*` |
| 开发工具 / 编辑器 / 语言 / git | `modules/dev/` | `lossilk.dev._.*` |
| 桌面会话 / compositor / shell / browser / terminal / appearance | `modules/desktop/` | `lossilk.desktop._.*` |
| 网络 / SSH / VPN / 防火墙 | `modules/networking/` | `lossilk.networking._.*` |
| OS substrate / boot / fs / power / peripherals | `modules/system/` | `lossilk.system._.*` |
| 虚拟化 / 容器 / WSL | `modules/virt/` | `lossilk.virt._.*` |
| 安全 / secrets / auth | `modules/security/` | `lossilk.security._.*` |
| AI 工具 | `modules/ai/` | `lossilk.ai._.*` |

规则：

- 新文件用 attrpath 风格：`{lossilk, ...}:` + `lossilk.x._.y`。
- 不在新文件使用 `<lossilk/...>`，尖括号只保留既有文件风格。
- 文件路径和 aspect path 必须落在同一主要 concern。
- 不创建空 namespace root；root 只有在拥有共享行为或 Profile / Bundle 时存在。
- include 父切面不会自动启用 children；需要子项就显式 include。

## 4. 写 owned configs

### T1: 单 class leaf

```nix
# modules/cli/example.nix
{
  lossilk.cli._.example.homeManager = {pkgs, ...}: {
    home.packages = [pkgs.example];
    programs.example.enable = true;
  };
}
```

### T2: 多 class feature

```nix
# modules/desktop/apps/example.nix
{
  lossilk.desktop._.example = {
    nixos.services.example.enable = true;

    homeManager = {pkgs, ...}: {
      home.packages = [pkgs.example-client];
    };
  };
}
```

### T3: Parametric aspect

```nix
# 只有 user context 存在时激活
{
  lossilk.ai._.example = {user}: {
    nixos = _: {
      users.users.${user.name}.extraGroups = ["example"];
    };
  };
}
```

不要把 `pkgs`、`config`、`lib` 放到 aspect root function；它们属于 class module。

### T4: Selection Variant

```nix
# modules/cli/shell/example.nix
{
  den,
  lossilk,
  ...
}: {
  lossilk.cli._.shell._.example = {
    includes = [
      lossilk.cli._.shell
      (den.provides.user-shell "example")
    ];

    homeManager.programs.example.enable = true;
  };
}
```

### T5: Profile / Bundle

```nix
# modules/desktop/example-desktop.nix
{lossilk, ...}: {
  lossilk.desktop._.example-desktop.includes = with lossilk; [
    system
    networking
    desktop._.compositor._.example
    desktop._.terminals._.kitty
  ];
}
```

Profile / Bundle 只拥有稳定选择，不拥有 unrelated leaf 实现。

## 5. 决定接线位置

| 场景 | 接线 |
|---|---|
| 用户自己的通用环境（shell/dev/AI/dotfiles） | `modules/users/loss.nix` 的 `den.aspects.loss.includes` |
| Host 选择系统/桌面 profile | `modules/hosts/<host>/default.nix` 或 profile 的 `includes` |
| Feature 内部依赖 | feature 自己的 `includes` |
| Host 给所有/某些 users 发 companion config | `provides.to-users` / `provides.<user>` |
| User 给其 host 发补丁 | `provides.to-hosts` / `provides.<host>`，只用于用户特异性 host 补丁 |
| Primary user 接收 host aspect tree 中的 user classes | user include `den.batteries.host-aspects` |

### Cross-entity rules

- `loss.includes` 不依赖 `host-aspects`。它由内建 `host-to-users` policy 在 `{host, user}` context 下解析。
- `host-aspects` 表示 user opt-in 接收所在 host aspect tree 的 `homeManager`/`hjem` 等 user classes。
- 多用户或条件复杂时，优先显式 `provides.to-users` / `provides.<user>`。
- `provides.to-hosts` 只用于用户专属 host 补丁；不要写通用主机配置。

## 6. 新文件必须 git add

`vic/import-tree` 只扫描 git-tracked Nix 文件。新增 `modules/**/*.nix` 后立刻：

```bash
git add modules/<path>.nix
```

不 add，文件不参与 evaluation，`just check` 也可能仍然绿。

## 7. 验证

必须通过仓库 just 包装：

```bash
just fmt
just check
```

Host/desktop 改动再跑：

```bash
just build-vm nixos-niri-dms-vm
```

还要做 targeted eval / repl。`just check` 只证明能求值，不证明行为在最终配置里。

示例：

```bash
printf '%s\n' \
  ':p nixosConfigurations."nixos-niri-dms-vm".config."home-manager".users.loss.programs.kitty.enable' \
  ':q' | just repl
```

## 常见错误

| 症状 | 原因 | 修复 |
|---|---|---|
| 新文件完全不生效，check 仍绿 | 没 `git add` | `git add` 后重跑 |
| `undefined variable 'lossilk'` | 文件参数没声明 | `{lossilk, ...}:` |
| `undefined variable '__findFile'` | 新文件用了尖括号 | 改 attrpath 风格 |
| `function called with unexpected argument` | class module 参数没 `...` | `{pkgs, ...}:` |
| aspect 被跳过 | root function 请求了当前 context 没有的参数 | 检查 `{host}` / `{host, user}` / `{user}` |
| user includes 不生效 | 误以为靠 host-aspects，或没接到 user aspect | 检查 `den.aspects.loss.includes` 和 host user entity 声明 |
| host-selected HM companion 不到 user | user 没 opt-in `den.batteries.host-aspects`，或需显式 provides | 在 user includes 加 host-aspects，或写 `provides.to-users` |
| include 父切面后子项没生效 | 子切面不会自动 emit | 显式 include 子切面或建 meta-aspect |

## 红线

修改前必须问用户：

- `flake.nix`
- `flake.lock`
- `pkgs/*`

不要提交，除非用户明确要求。
