# Nix Config — Den 切面架构

个人 NixOS/Home Manager 配置，使用 den 框架的切面（aspect-oriented）架构组织。

## Language

> 术语对齐 den 官方术语表：https://den.denful.dev/reference/glossary/
> 标注「上游未收录」的为本仓库自建术语。

**Entity** (实体):
类型化的数据声明 — host、user、home。Entity 声明"什么东西存在"，携带 freeform 属性。
_Avoid_: 资源、实例

**Aspect** (切面):
可组合的配置单元，包含 per-class owned configs。
切面通过 `includes` DAG 激活/组合；通过 `provides` 构建命名子切面层级（aspect-first 架构下表达切面树的唯一方式）。
Aspect 声明"它做什么"。den 对每个 entity 自动创建一个 parametric aspect（见 **Parametric Aspect**）。
粒度按「复用性 × 复杂度 × 可发现性」决定（依据 den `templates/example` 和本文件 **Modules Taxonomy**）：一次性/平凡配置 inline 或归 `lossilk.cli._.utils` 类聚合切面；可复用、复杂（跨 class 协调、自成 concern）或作为树状多选一变体被独立启停时，单开切面文件。
_Avoid_: 模块（易与 NixOS module 混淆）

**Modules Taxonomy** (模块分类规则, 上游未收录):
本仓库 `modules/` 物理路径和本地 `lossilk.*` Aspect path 的 concern-first ownership 规则。新增、移动或重命名 `modules/**/*.nix` 时先按主要功能意图分类，再考虑 systemd/daemon/GUI/TUI/CLI/Nix option 等技术形状。
_Avoid_: services 兜底分类、Den upstream 目录镜像、空 namespace root

**Includes** (依赖声明):
Aspect 的 `includes` 列表声明依赖——"本切面需要这些切面一起解析"。
多个切面通过 includes 形成 DAG，den 的 resolution 管道按图 walk。
每个 entity 的 parametric aspect 是 DAG 的根——entity 本身不声明 includes，它的 includes 由对应的 `den.aspects.<name>.includes` 承载。
_Avoid_: import（那是 Nix module 系统的 `imports`）

**Host opt-in** (host 按需引入):
可复用的 recipe，host 主动选择 include。多个 host 可共享同一配置组合。
判断标准：多个 host 需要同一组 NixOS option 的协调组合（不是单行 toggle）。
在 host 主切面 `includes` 中引入。
_Avoid_: host spec（那是 inline 的 host 专属配置）

**Host spec** (host 专属配置):
绑定物理硬件或特定场景的配置，不可复用。直接写在 host 的 `nixos = { ... }` block 里，不建切面。
判断标准：单行 NixOS option toggle，或只对一台 host 有意义的配置。
_Avoid_: host opt-in（那是可复用的切面）

**Freeform 子切面 vs Provides 子项**:
切面的子切面有两种存在形式，行为不同：
- **Freeform 子切面**: 直接 key（如 `lossilk.cli.shell`）。`._` 收集所有 immediate freeform 直接子切面，不收 grandchildren。
- **Provides 子项**: 通过 `provides`/`_` 声明（如 `lossilk.cli._.shell`）。`._` **不收集** provides 子项。
- include 父切面时，子切面不会自动 emit；需要显式 include 子切面，或用 `._` 收集 immediate freeform 子切面。
- `provides` 子项可通过 forwarding 直接访问（`lossilk.cli.shell` 即使定义为 `lossilk.cli._.shell` 也能解析）。
- 设计权衡：provides 提供组织层级；freeform keys 更扁平但无层级。
- 子切面只是可寻址的嵌套路径，不说明语义类型；具体语义要按 **Family Root**、**Selection Variant**、**Extension**、**Profile / Bundle** 或 **Integration Edge** 判断。
- **注意**：`._`（收集所有直接子切面）是未公开特性，可能被移除。不要依赖它。

**Family Root** (能力族根):
一个 feature family 的父切面，拥有共同不变量和基础配置。例如 `lossilk.cli._.shell` 是 shell family root；include 它表达启用 shell 基础层，不是在选择某个 shell variant。
_Avoid_: default variant, base sub-aspect

**Selection Axis** (选择轴):
一组互斥或受约束的同层选择槽位，回答同一个问题，例如 shell implementation axis。没有明确 axis 时，不要把子切面叫 variant。
_Avoid_: namespace level, child path

**Selection Variant** (选择变体):
某个 **Selection Axis** 上的具体候选实现，例如 `lossilk.cli._.shell._.fish`、`lossilk.cli._.shell._.zsh`、`lossilk.cli._.shell._.nushell`。Variant 是同层替代实现，不是父切面的默认内容，也不是任意额外扩展。
_Avoid_: sub-aspect, extension

**Extension** (叠加扩展):
给某个 family 或 leaf 增加可叠加能力的子切面，回答"要不要加这个"，不是"同一槽位选哪个"。
_Avoid_: variant

**Profile / Bundle** (组合切面):
拥有一组稳定选择的 route table，通常只写 `includes`。Profile 负责复用选择，不拥有 leaf 的配置实现。
_Avoid_: leaf, implementation

**Niri DMS Desktop Profile** (Niri + DankMaterialShell 桌面组合切面, 上游未收录):
`lossilk.desktop._.niri-dms-desktop`，供运行 niri compositor + DankMaterialShell 的 NixOS host opt-in。它只拥有稳定 route table（system/nix/networking/audio 与 desktop leaf 选择），不拥有 VM、磁盘、硬件、display 等 host spec。
_Avoid_: compositor variant, shell implementation

**Integration Edge** (集成边):
两个 concern 同时存在时需要的接线配置，例如 shell 与某 CLI tool 的 shell integration。Integration edge 只拥有 glue，不拥有两端完整实现。
_Avoid_: variant, profile

**Parametric Aspect** (参数化切面):
两层含义：
1. **Auto-created**: den 为每个 entity 自动创建的切面，class blocks 为空，作为 `includes` 的组合目标。例如 `den.aspects.igloo = parametric { nixos = {}; };`。
2. **User-defined**: 用户定义的函数式切面，参数形状决定激活条件。`{ host }` 只在 host 上下文激活，`{ host, user }` 只在 host+user 上下文激活。不需要 `mkIf` 或 `enable` 标志——参数形状本身就是条件。

**Class** (类):
Nix 模块求值域 — `nixos`、`darwin`、`homeManager`、`user` 等。一个 aspect 可包含多个 class 的配置。
Class 决定"哪个模块系统求值"，不等于 entity kind。
_Avoid_: 类型（易与 Nix 类型系统混淆）

**Entity Kind** (实体种类):
entity 的类型：`host`、`user`、`home`。Entity kind 驱动 policy 分发。
_Avoid_: class（那是 Nix 模块求值域）

**Policy** (策略):
Entity 之间的有向边，声明 entity 如何关联。每个 policy 有 `from`（源 entity kind）、`to`（目标 entity kind）、`resolve`（fan-out context 的函数）。
`host-to-users` 从 host fan-out 到 user；user resolution 产出的 `homeManager` class 会包装成 host 的 NixOS module（如 `home-manager.users.<name>`）汇入 host 配置。
Policies 属于 entity topology，不属于 resolution stages。
_Avoid_: 规则、路由

**Cross-entity Delivery** (实体间交付, 上游未收录):
跨 entity 传递 class 配置的三种模式：
- **User 自有声明流**: user 主切面 `includes` 在 `{host, user}` context 下解析，产出的 `homeManager` class 包装进所在 host 的 NixOS 配置。它不依赖 `host-aspects`。
- **Host-aspects opt-in**: user 显式 include `den.batteries.host-aspects`，表示接收所在 host aspect tree 中的 `homeManager`/`hjem` 等 `user.classes` 配置。适合个人主用户接收 host 选择的 desktop/profile companion config；不放 `den.default` 全局启用。
- **Explicit Provides delivery**: `provides.to-users` / `provides.<user>` / `provides.to-hosts` 明确声明跨实体交付。多用户、条件化 host→user 策略优先用显式 provides；`provides.to-hosts` 仅用于纯用户特异性的 host 补丁，不写通用主机配置。
_Avoid_: 把 `host-aspects` 当成 user includes 生效前提、把 user→host 与 host→user 投影混为一谈

**Quirk** (特性):
切面间共享的结构化数据。生产者 emit（在 aspect 顶层写同名 key），消费者通过 function arg 接收（收集到的 list，自动去重/flatten）。
den 内置 API（`den.quirks`），上游术语表未收录。
_Avoid_: 信号、事件

**Battery** (电池):
den 内置的可复用 aspect，位于 `den.batteries.*`（也通过 `den.provides.*` 别名访问）。
解决常见配置任务：user 创建（`define-user`/`primary-user`）、hostname 设置（`hostname`）、host aspect tree 到 user 的 home 环境投影（`host-aspects`）、shell 选择（`user-shell`）等。
_Avoid_: 插件、扩展

**Provider** (提供者):
意图被复用的 aspect。所有 battery 都是 provider,但任何 aspect 都可以作为 provider 被 `includes` 引用。
_Avoid_: 库、包

**Context** (上下文):
Pipeline 数据形状 — `{ host }`、`{ host, user }`、`{ home }`。
是真正的函数参数，不是 NixOS module args（`config`、`pkgs`、`lib`）。
_Avoid_: 参数、args

**Namespace** (命名空间):
通过 `inputs.den.namespace "name" true` 注册的切面库。
`lossilk` 是本仓库的 namespace，`lossilk.cli._.shell` 等价于 `den.ful.lossilk.cli.provides.shell`。
`_` 是 `provides` 的人体工程学语法糖（`mkAliasOptionModule`），用于简化深层路径书写。
Freeform 子切面和 provides 子项均可被显式 include/解析，但不会因为父切面被 include 而自动启用（见 **Freeform 子切面 vs Provides 子项**）。
需要聚合多个子切面时，用 provides 内部的 meta-aspect，不依赖 `._`。

**`den.default`**:
特殊切面，自动应用到所有 entity，不需要显式 include。
只放框架级默认（stateVersion、allowUnfree、define-user/hostname 等管线）。简单静态属性直接 inline 在 class block 里。
业务基线（如 lossilk.base）不进 den.default —— 走 host opt-in，各 host 在 includes 里显式引入（依据 den `templates/example/defaults.nix`）。`host-aspects` 也不在本仓库全局启用；由需要接收 host 偏好的 user 显式 opt-in。

**Dendritic**:
将跨多个 Nix class 的配置按 concern 捆绑到一个 attrset 的结构模式。
一个 feature（如 niri 桌面）fan-out 到 `nixos`/`homeManager` 等多个 class，但对外是单一 include 点。
本仓库当前不 import `den.flakeModules.dendritic`；`modules/den.nix` 直接 import `inputs.den.flakeModule` 并注册 namespace。早期曾用 `vic/flake-file` 的 dendritic flakeModule 做输入声明，但 flake-file 的 input ↔ module 同步机制与 Nix module 严格求值冲突，因此已弃用 flake-file。

**Freeform 属性**:
Entity 携带的任意 key-value 数据，无需声明 option。通过 context 中的 entity 引用访问。
