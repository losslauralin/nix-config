# Den framework baseline

本文件固化本仓库使用 `denful/den` 的架构基准。目标不是替代 den 官方文档，而是把官方心智模型、仓库术语和 ADR 约束合并成后续 agent 实现前必须执行的规则。

## Scope

适用于所有会影响 den 语义的工作：

- `den.hosts` / `den.homes` / user Entity 声明
- `den.aspects.*` 或 `lossilk.*` Aspect 组合、`includes` DAG、`provides` / `_` 子切面
- `den.schema.*`、`den.policies.*`、`den.quirks.*`
- `den.batteries.*` / `den.provides.*` Battery 使用
- `nixos`、`darwin`、`homeManager`、`user` 等 Class module 写法
- `modules/**/*.nix` 的 Den Aspect ownership、文件路径和可发现性

不适用于普通 Nixpkgs package override、非 den 的 shell 脚本或只改 README 的文案，除非这些改动会改变 Den Aspect、Entity、Policy、Quirk、Battery 或 Class 行为。

## Source priority

1. **仓库语义裁决**：先读根目录 `CONTEXT.md`，再读 `docs/frameworks/den.md` 当前规则；涉及 `modules/**/*.nix` placement 或 `lossilk.*` Aspect path 时以 `CONTEXT.md` 中的 Modules Taxonomy / Cross-entity Delivery 术语为准。
2. **den 框架 API / 心智模型**：优先读本地文档目录 `/home/loss/workspace/nix-ref/den/docs`，尤其是：
   - `src/content/docs/overview.mdx`
   - `src/content/docs/explanation/core-principles.mdx`
   - `src/content/docs/explanation/aspects.mdx`
   - `src/content/docs/explanation/entities.mdx`
   - `src/content/docs/explanation/context-pipeline.mdx`
   - `src/content/docs/explanation/parametric.mdx`
   - `src/content/docs/explanation/class-modules.mdx`
   - `src/content/docs/explanation/policies.mdx`
   - `src/content/docs/explanation/quirks-and-pipes.mdx`
   - `src/content/docs/guides/configure-aspects.mdx`
   - `src/content/docs/guides/namespaces.mdx`
   - `src/content/docs/guides/batteries.mdx`
   - `src/content/docs/guides/home-manager.mdx`
   - `src/content/docs/guides/debug.md`
   - `src/content/docs/reference/aspects.mdx`
   - `src/content/docs/reference/batteries.mdx`
   - `src/content/docs/reference/schema.mdx`
   - `src/content/docs/reference/glossary.mdx`
3. **den 源码**：只有当本地文档缺失、表述不明确、与当前仓库行为冲突或需要核对当前 lock rev 的实际实现时，才读取 `/home/loss/workspace/nix-ref/den` 源码。不要为了泛泛“理解一下”而漫游源码。

## Must read before Den work

在任何 Den 相关实现前，先读：

- `CONTEXT.md`：本仓库术语、avoid 词、Modules Taxonomy、Cross-entity Delivery。
- 本文件当前小节和下方 checklist。
- 必要的 den 本地 docs（尤其是 `guides/configure-aspects.mdx`、`guides/mutual.mdx`、`explanation/core-principles.mdx`、`explanation/context-pipeline.mdx`、`explanation/parametric.mdx`、`explanation/class-modules.mdx`）。

如果计划、实现或评审与这些文件冲突，必须显式指出冲突并建议 `/grill-with-docs`；不要静默覆盖既有术语和决策。

## Core mental model

Den 把配置拆成四个 concern：

| Concern | 本仓库术语 | 作用 |
| --- | --- | --- |
| Data | Entity / Entity Kind | 声明“什么东西存在”：host、user、home。 |
| Behavior | Aspect | 声明“它做什么”：一个可组合 concern，包含 per-class owned configs。 |
| Topology | Policy | 声明 entity 如何关联和 fan-out，例如 host→users。 |
| Data flow | Quirk | 在切面间共享结构化数据，由 pipe 聚合、过滤或跨 scope 传递。 |

Class 是 Nix module 求值域（`nixos`、`darwin`、`homeManager`、`user` 等），不等于 Entity Kind。Context 是 Den pipeline 数据形状（例如 `{ host }`、`{ host, user }`、`{ home }`），不等于 NixOS module args。

## Concept boundaries

| Do | Do not |
| --- | --- |
| 说 Entity 是类型化数据声明，携带 freeform 属性。 | 不把 Entity 叫资源、实例。 |
| 说 Aspect 是可组合配置单元，声明“它做什么”。 | 不把 Aspect 叫 NixOS module。 |
| 说 `includes` 是 Aspect 依赖声明和 DAG edge。 | 不把 `includes` 叫 import；`imports` 是 Nix module 系统概念。 |
| 说 Class 是 Nix module 求值域。 | 不把 Class 当成 host/user/home 类型。 |
| 说 Entity Kind 是 host/user/home 等 policy dispatch 种类。 | 不把 Entity Kind 当成 `nixos` / `homeManager`。 |
| 说 Den Context 是 pipeline function arg。 | 不把 `{ host }`、`{ user }` 说成 `_module.args` 或 `specialArgs`。 |
| 说 aspect-level `provides` / `_` 是子切面命名空间。 | 不把它和 `den.provides` 混淆；`den.provides` 是 `den.batteries` alias。 |
| 显式 include 子切面或用 provides 内部 meta-aspect 聚合。 | 不依赖 `._` 收集 Provides 子项；`._` 不收集 provides 子项且是未公开行为。 |
| 先判断 Family Root / Selection Variant / Extension / Profile / Bundle / Integration Edge。 | 不把任意子切面都叫 variant。 |
| 把 host 专属硬件/场景配置写成 Host spec。 | 不为单机单行 toggle 新建 Host opt-in。 |

## Authoring rules for this repository

### Layout and ownership

- Den 的职责是语义组合：Entity、Aspect、Policy、Quirk、Battery、Namespace。
- 本仓库的物理目录布局是项目治理规则：本地 `lossilk.*` aspects 继续按 feature-first、concern-first ownership 放在 `modules/<concern>/` 下；placement/rename 前先应用 `CONTEXT.md` 的 Modules Taxonomy。
- 不要因为 den 示例或 batteries 源码使用 `modules/aspects/...` 就把本仓库迁移到 `modules/aspects/lossilk/`。
- 逻辑 Aspect path 和物理 file path 是两个契约：例如 `lossilk.desktop._.shell._.dms` 是 include/provides API，`modules/desktop/shell/dms.nix` 是 ownership / 可发现性 API；二者可以不机械镜像，但必须落在同一主要 concern。
- 新增 `modules/**/*.nix` 后必须 `git add` 再评估；本仓库的 `vic/import-tree` 默认只扫描 git-tracked 文件。

### Aspect granularity

- 先问新增内容的语义类型：
  - **Family Root**：能力族共同不变量和基础配置；父切面不是 default variant。
  - **Selection Variant**：同一 Selection Axis 上的互斥或受约束候选，例如 shell implementation。
  - **Extension**：可叠加能力，回答“要不要加”。
  - **Profile / Bundle**：稳定 route table，通常只写 `includes`。
  - **Integration Edge**：两个 concern 同时存在时的 glue。
  - **Host spec**：物理硬件或单 host 场景专属配置。
- 可复用、复杂、跨 class 协调或会被独立 include/disable 的能力应有独立文件。
- 一次性、平凡配置可以 inline 或进入清晰聚合切面；一旦成为真实选择或拥有独立 ownership，就拆出文件。

### Includes and defaults

- `includes` 中优先引用命名 Aspect / Battery。den 文档允许匿名 parametric include，但本仓库为可调试性优先使用命名 Aspect；匿名函数只用于很小的局部 glue。
- `den.default` 只放框架级默认：stateVersion、allowUnfree、`define-user`、`hostname` 等管线。业务基线走 host opt-in 或 user aspect include；`host-aspects` 由需要接收 host 偏好的 user 显式 opt-in。
- Host 应显式 opt-in 可复用 recipe；不要把业务配置藏进全局默认。
- include 父切面不会自动 emit 子切面。需要子项时显式 include，或设计一个明确的 meta-aspect 来聚合。

### Parametric dispatch and class modules

- Aspect-level parametric function 的参数形状就是条件：`{ host }` 只在 host context 激活，`{ host, user }` 只在 host+user context 激活。不要为 scope 条件套 `mkIf` 或 `enable` flag。
- 不使用已废弃 wrapper，例如 `den.lib.parametric`、`den.lib.perHost`、`den.lib.take.exactly`。
- Den Context 和 Nix module args 分层：
  - 两层写法：`{ host }: { nixos = { config, pkgs, ... }: { ... }; }`
  - flat-form class module：`{ nixos = { host, config, pkgs, ... }: { ... }; }`
- flat-form class module 若会进入 Nix module system，参数模式必须带 `...`，因为 module system 会传入额外 args。
- class module 请求当前 scope 没有的 entity arg 会被跳过；如果配置没有生效，先检查 scope 中是否真的有 `host`、`user`、`home`。
- 如果 Den context arg 与 module system arg 名称冲突，按 `meta.collisionPolicy` / entity `collisionPolicy` / `den.config.classModuleCollisionPolicy` 的层级处理，不要猜。

### Policies and Quirks

- Policy 是 entity topology，不是 resolution stage。声明 policy 只注册函数，必须放入 `includes` 才激活。
- `policy.resolve` 带 Entity Kind key 时创建 child scope；带非 entity key 时只是 enrich 当前 scope。
- `policy.include` 让 Aspect 继续参与 resolution tree；`policy.provide` 直接把 raw module 送到 class。能用 `include` 表达的 glue 优先用 `include`。
- Quirk 用于 structured data aggregation：producer 在 aspect 顶层 emit 已注册的 quirk key，consumer 通过 class module function arg 接收 list。
- 简单 same-scope 聚合不需要 pipe；跨 scope、过滤、重命名或 collect 才需要 pipe policy。

### Batteries in this repo

- `den.batteries.define-user`：在 `den.default.includes` 中创建 OS / Home user 基线。
- `den.batteries.hostname`：在 `den.default.includes` 中设置 hostname。
- `den.batteries.host-aspects`：由 user 主切面显式 include（例如 `den.aspects.loss.includes`），表示该 user 接收所在 host aspect tree 中的 `homeManager`/`hjem` 等 `user.classes` 配置。它不让 user includes 生效；user includes 由内建 host-to-users pipeline 处理。它是过渡方案；改动前核对 den rev 和上游说明。
- `den.batteries.primary-user`：放在 user 主切面，例如 `den.aspects.loss.includes`。
- `den.batteries.user-shell` / `den.provides.user-shell`：由 shell Selection Variant include，不在 Family Root 里选择具体 shell。
- Home Manager battery 自动在用户 `classes` 包含 `homeManager` 且 host 支持时启用；本仓库用 `den.schema.user.classes = lib.mkDefault ["user" "homeManager"]`。
- WSL battery 在 host entity 设置 `wsl.enable = true` 时自动启用；不要再手写重复 import。
- `den.batteries.import-tree` 是迁移传统非 Den plain modules 的特殊格式，class 目录必须是 `_<class>`（如 `_nixos`、`_darwin`、`_homeManager`）。这不是本仓库所有 Den modules 的通用目录规范。

### Namespaces

- 本仓库注册的本地 namespace 是 `lossilk`，通过 `inputs.den.namespace "lossilk" true`。
- `lossilk.cli._.shell` 等价于 `den.ful.lossilk.cli.provides.shell` 的人体工程学访问形式。
- 只有当新增另一个本地/导出 namespace、vendoring reusable aspects，或明确维护共享库时，才创建 namespace-shaped 物理目录。

## Implementation / review checklist

每次 Den 相关实现前回答这些问题：

1. 已读哪些文件？至少包括 `CONTEXT.md`、相关 ADR、本 baseline、必要的 den 本地 docs。
2. 这次新增/修改的语义类型是什么：Family Root、Selection Variant、Extension、Profile / Bundle、Integration Edge、Host opt-in、Host spec、Policy、Quirk、Battery usage，还是普通 class config？
3. 影响的 Entity Kind 是什么：host、user、home，或自定义 kind？
4. 影响的 Class 是什么：`nixos`、`darwin`、`homeManager`、`user`、`os`、`wsl` 等？
5. 拥有它的物理文件路径是什么？是否符合 `CONTEXT.md` 的 feature-first / concern-first ownership？
6. 逻辑 Aspect path 是什么？是否需要 `provides` 子项，还是 freeform 子切面？
7. 需要哪条 `includes` DAG edge？由 host 主切面、user 主切面、Profile / Bundle、Family Root、Selection Variant 还是 Extension include？
8. 是否涉及 cross-entity delivery？若是 user 自有环境，放 user 主切面 includes；若是 primary user 接收 host aspect tree 的 companion config，user include `host-aspects`；若是多用户或条件化 host→user 交付，显式 `provides.to-users` / `provides.<user>`。
9. 是否需要 Entity freeform 属性或 `den.schema.*` option？如果是所有 Entity 都应有默认/类型，优先 `den.schema`。
10. 是否需要 Quirk，而不是让多个 producer 写同一个 consumer 的 NixOS option？
11. 是否使用 Battery？是否明确其 opt-in / auto-activated 条件？
12. 是否误用了 `den.default` 放业务配置？
13. 是否用了 deprecated wrapper 或依赖 `._` 收集 provides？如果有，改掉。
14. 新增了 `modules/**/*.nix` 吗？如果有，是否已 `git add`，确保 import-tree 能扫描？
15. 验证命令是什么？
    - 文档/agent 入口改动：`git diff --check`，并声明无 Nix evaluation-impacting 文件。
    - Den module 改动：至少 `just check`；desktop/host 改动再跑 `just build-vm nixos-niri-dms-vm` 或 `just test-vm nixos-niri-dms-vm`。
    - 非 NixOS 开发 host：先 `command -v just nh nix`，缺工具时按 `CLAUDE.md` 使用 `nix shell`。

## Red flags

看到以下情况应暂停并复核：

- “import 一个 Aspect”——应说 `includes`，除非真的在写 Nix module `imports`。
- 把 `homeManager` 叫 Entity Kind，或把 `user` Entity Kind 和 `user` Class 混为一谈。
- 因为 den 上游示例而移动本仓库 `modules/` 布局。
- 在 `den.default` 中加入业务/桌面/开发工具基线。
- 为多用户/条件化 host→user 配置无脑依赖全局 `host-aspects`，而不是让 user opt-in 或使用显式 `provides.to-users`。
- 把 Family Root 写成 `_.base` 或把父切面叫 default variant。
- 依赖 `lossilk.foo._` 自动收集 provides 子项。
- 使用 `den.lib.parametric`、`den.lib.perHost`、`den.lib.take.exactly` 等旧 API。
- 新增 `modules/**/*.nix` 后没 `git add` 就相信 `nix flake check`。
- 随意修改 `flake.nix`、`flake.lock`、`pkgs/*`。

## Debug pointers

- 先检查 scope：当前 context 有没有你请求的 `host`、`user`、`home`？
- 需要看 policy 命中时，用 den docs `guides/debug.md` 中的 `den.lib.policyInspect.inspect`。
- 需要看 aspect include 图时，用 `den.lib.capture` / den-diagram。
- 临时 REPL 暴露 `flake.den = den` 后必须移除；不要把调试输出变成长期 flake API。
