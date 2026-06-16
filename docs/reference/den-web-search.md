# Den Framework Web Search Results

> **WARNING**: This document contains web-sourced information about the den framework.
> It was generated via automated search and may contain inaccuracies.
> 
> **Authoritative sources**:
> - Local den docs: `~/workspace/nix-ref/den/docs/`
> - Project terminology: `CONTEXT.md`
> - Project baseline: `docs/frameworks/den.md`
> - Practical patterns: `docs/agents/den-configuration-patterns.md`
>
> **Use this document only for**:
> - Quick overview when den docs are unavailable
> - Cross-referencing web examples
> - Understanding community usage patterns
>
> **Do NOT use for**:
> - Authoritative API reference
> - Terminology decisions
> - Implementation guidance without verification

## Search Summary

Comprehensive den framework information compiled from:
- Official documentation (den.denful.dev)
- GitHub repository (denful/den)
- Community discussions (Discourse, Reddit)
- Example configurations

### Core Concepts

**Aspects/Features**: Central primitive. Context-aware function (or functor via `__functor`) receiving entity context (`{ host, user, ... }`) and returning configuration for multiple Nix **classes** (`nixos`, `darwin`, `homeManager`, custom). One logical concern lives in one place across platforms.

```nix
den.aspects.gaming = { host, user }: {
  nixos = { pkgs, ... }: { programs.steam.enable = true; };
  homeManager = { pkgs, ... }: { programs.mangohud.enable = true; };
  includes = [ den.aspects.performance den.batteries.unfree ];
  provides.emulation = { nixos = { ... }; };  # nested sub-aspect
};
```

**Parametric/Context-Driven Dispatch**: Argument pattern = condition. Aspect requesting `{host, user}` only activates in user-on-host contexts; no `mkIf` or manual conditionals needed. Context flows automatically from schema via policies.

**Includes**: Forms **DAG** for composition. Recursive resolution walks graph, deduplicates, merges via Nix module system. Supports static modules, parametric functions, or namespaced references.

**Provides**: Creates nested/scoped sub-aspects (e.g., `den.aspects.workstation.gpu`) or mutual providers (`provides.to-users` for host→user config flow without tight coupling).

**Entities**: Declared in `den.hosts.<system>.<name> = { users = { ... }; includes = [...]; }` or `den.homes`. Typed via `den.schema`.

**Policies**: Pure functions (`ctx: [ effects... ]`) defining topology, routing, fan-out (host → users → homes), and context enrichment. Drive resolution pipeline. Extensible with algebraic effects.

**Quirks**: Structured data emitted by aspects and aggregated via pipeline pipes (decouples aspects, e.g., for firewall rules).

**Batteries**: Reusable built-in aspects/policies under `den.batteries.*` (aliases `den.provides.*`, `den._.*`): `hostname`, `primary-user`, `define-user`, `user-shell "fish"`, `unfree`, `import-tree`, `forward` (for custom classes). Include globally (`den.default.includes`) or per-aspect.

**Namespaces**: Scoped aspect libraries (`den.ful.<name>`). Created via `inputs.den.namespace "name" (exportBool or listOfSources)`. Populate modules defining aspects under the namespace. Export via `flake.denful.<name>`. Consume with `includes = [ eg.desktop ];` or terse `<eg/desktop>` syntax (requires `__findFile = den.lib.__findFile;`). Enables sharing aspect libraries across flakes/non-flakes without forcing full input graphs.

### Composition/Inheritance Rules

Purely compositional via DAG of `includes` + `provides` tree. No classical OOP inheritance. Resolution walks includes recursively; context pattern matching determines activation at each entity/policy stage; module-system merging applies (later definitions can override/merge). Policies control activation points and fan-out. DAG must be acyclic; `excludes`/`when` combinators for fine control. Deduplication prevents duplicate application.

### Integration with flake-parts and NixOS Module System

**den.lib**: Pure, zero-dependency AOP library. `den.lib.aspects.resolve "nixos" aspect` (or equivalent framework resolution) produces `deferredModule`s or lists compatible with `nixosSystem`, `homeManagerConfiguration`, etc. Class functions receive **both** Den context *and* standard module args (`{ config, pkgs, ... }`).

**Framework**: Provides `den.flakeModule`, schemas (`den.hosts`, `den.homes`, `den.schema`), batteries, policies pipeline, and automatic outputs (`nixosConfigurations.*`, `homeConfigurations.*`, etc.). Resolution pipeline: schema/entities → policies (topology/routing) → aspects/batteries (config collection) → quirks → outputs.

**flake-parts**: Fully supported (many templates). Common pattern: `flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);`. Den can contribute to outputs or be evaluated via `evalModules` + `den.flakeOutputs.flake`.

**NixOS Module System**: Den sits on top and produces standard modules. Works with/without flakes, home-manager, or even Nix entirely (npins + `lib.evalModules`). No lock-in; all parts optional/replaceable. Custom classes (MicroVMs, standalone Neovim/NVF, Terraform, etc.) are first-class.

### Configuration Patterns and Best Practices

**Feature-First / Dendritic**: Aspects define concerns; hosts/users select/include them (one line to add/remove capability). Avoid per-host piles. Organize `./modules/` tree (auto-loaded); `_nixos/` for legacy modules.

**Common Patterns**:
- Global defaults via `den.default.includes` and policies (e.g., stateVersion)
- Parametric host/user aspects (context provides `host.name`, `user.name`, etc.)
- Mutual configuration (host aspects provide to users' `homeManager`; users provide back to host `nixos`)
- Batteries for boilerplate; namespaces for public/shared vs private
- One aspect per logical cross-cutting concern (e.g., `bluetooth` handles NixOS hardware + HM applet + Darwin cask in one file)

**Best Practices**: Small, focused, composable aspects. Prefer context dispatch over conditionals. Use diagrams for debugging complex graphs. Test aspects in isolation. Incremental adoption. Publish reusable aspects via namespaces. Explicit policies for cardinality/ownership in multi-user or fleet scenarios.

**Pitfalls**: DAG cycles; context mismatches (aspect doesn't fire); option merge conflicts (esp. in 1:N host-user fanout — split aspects or use explicit `provides.to-users`); learning the effects/pipeline initially. Large graphs benefit from visualization. Avoid stringly-typed tags when real references are possible.

### vic/import-tree Integration

**What it is**: Companion zero-dependency library (`github:denful/import-tree` or `vic/import-tree`). Recursively walks directory tree, imports every `*.nix` file, returns unified list of modules or flake-parts-compatible structure. Sensible defaults (skips paths containing `/_` for helpers/legacy like `_nixos/hardware-configuration.nix`). Extensible builder API (`.filter pred`, `.match pattern`, `.map fn`, `.addAPI`, `.addPath`).

**Discovery in Den**: Core to most setups. In `flake.nix` or `default.nix`:
```nix
outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);
# or
modules = [ (inputs.import-tree ./modules) ];  # for evalModules
```

Each file in `./modules/` (or subdirs) can define `den.aspects.foo = ...`, `den.hosts...`, `den.policies...`, or plain modules. Path structure often informs namespacing. Turns a tree of small, focused files into complete configuration without manual `imports = [ ./foo ./bar ];` lists. Perfectly complements the dendritic pattern.

**In Practice**: Enables "den-dritic" layout — add new aspect file and it's auto-discovered. Used in all official templates, vic/vix (author's fleet config), and most community examples. Supports flake-parts, plain Nix, no-flake (npins), NixVim, etc.

### Batteries Used in This Repo

From web search + local doc verification:

- `den.batteries.define-user`: Creates OS/HM user baseline (in `den.default`)
- `den.batteries.hostname`: Sets hostname (in `den.default`)
- `den.batteries.primary-user`: Marks primary user (in `den.aspects.loss.includes`)
- `den.batteries.host-aspects`: User opt-in to receive host's user-class configs (in `den.aspects.loss.includes`)
- `den.provides.user-shell "fish"`: Shell selection battery (included by shell Selection Variants)

Auto-activated batteries:
- Home Manager battery: fires when user `classes` include `homeManager` and host supports it
- WSL battery: fires when `host.wsl.enable = true`

### Additional Resources

- **Official docs**: https://den.denful.dev/ — Start with *From Zero to Den*, *Core Principles*, *Namespaces*, *Batteries*, *Diagrams*, *Policies*
- **Examples**: vic/vix (author's fleet), community configs (Gwenodai/nixos, danielgafni/nixos)
- **Related**: https://import-tree.denful.dev/, NixOS Discourse, "Evaluating Den" blog
- **API/Schema**: `den.lib.aspects.resolve`, `den.schema.*`, `den.policies.*`, `den.batteries.*`

---

**REMINDER**: This document is supplementary and web-sourced. Always verify against:
1. `~/workspace/nix-ref/den/docs/` (authoritative local docs)
2. `CONTEXT.md` (project terminology)
3. `docs/frameworks/den.md` (project baseline)
4. `docs/agents/den-configuration-patterns.md` (practical patterns)

Do not cite this document as authoritative reference in implementation decisions.
