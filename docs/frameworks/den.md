# Den framework baseline

Codifies architecture baseline for using `denful/den` in this repo. Not to replace den official docs, but merge official mental model, repo terminology, and ADR constraints into rules agents must follow before implementation.

## Scope

Applies to all work affecting den semantics:

- `den.hosts` / `den.homes` / user Entity declarations
- `den.aspects.*` or `lossilk.*` Aspect composition, `includes` DAG, `provides` / `_` sub-aspects
- `den.schema.*`, `den.policies.*`, `den.quirks.*`
- `den.batteries.*` / `den.provides.*` Battery usage
- `nixos`, `darwin`, `homeManager`, `user` etc Class module writing
- Den Aspect ownership, file paths, discoverability of `modules/**/*.nix`

Does NOT apply to ordinary Nixpkgs package overrides, non-den shell scripts, or README-only copy changes, unless these changes alter Den Aspect, Entity, Policy, Quirk, Battery, or Class behavior.

## Source priority

1. **Repo semantic authority**: Read root `CONTEXT.md` first, then `docs/frameworks/den.md` current rules; for `modules/**/*.nix` placement or `lossilk.*` Aspect path, follow `CONTEXT.md` Modules Taxonomy / Cross-entity Delivery terminology.
2. **den framework API / mental model**: Use the official upstream den documentation when repo docs are insufficient, especially:
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
3. **den source**: Only inspect the exact upstream source for the pinned den revision when official docs are missing, unclear, or conflict with current repo behavior. Do not use unpinned local mirrors as authority, and do not wander source for general "understanding".

## Must read before Den work

Before any Den-related implementation, read:

- `CONTEXT.md`: This repo's terminology, avoid-words, Modules Taxonomy, Cross-entity Delivery.
- Current section of this file + checklist below.
- Necessary upstream den docs when repo docs are insufficient (especially `guides/configure-aspects.mdx`, `guides/mutual.mdx`, `explanation/core-principles.mdx`, `explanation/context-pipeline.mdx`, `explanation/parametric.mdx`, `explanation/class-modules.mdx`).

If plan/implementation/review conflicts with these files, must explicitly note conflict and suggest `/grill-with-docs`; don't silently override existing terminology and decisions.

## Core mental model

Den splits config into four concerns:

| Concern | This repo term | Role |
| --- | --- | --- |
| Data | Entity / Entity Kind | Declares "what exists": host, user, home. |
| Behavior | Aspect | Declares "what it does": composable concern containing per-class owned configs. |
| Topology | Policy | Declares how entities relate and fan-out, e.g. host→users. |
| Data flow | Quirk | Shares structured data between aspects, aggregated/filtered/passed across scope by pipes. |

Class is Nix module eval domain (`nixos`, `darwin`, `homeManager`, `user`, etc.), NOT equal to Entity Kind. Context is Den pipeline data shape (e.g. `{ host }`, `{ host, user }`, `{ home }`), NOT equal to NixOS module args.

## Concept boundaries

| Do | Do not |
| --- | --- |
| Say Entity is typed data declaration carrying freeform attributes. | Don't call Entity resource, instance. |
| Say Aspect is composable config unit declaring "what it does". | Don't call Aspect NixOS module. |
| Say `includes` is Aspect dependency declaration and DAG edge. | Don't call `includes` import; `imports` is Nix module system concept. |
| Say Class is Nix module eval domain. | Don't treat Class as host/user/home type. |
| Say Entity Kind is host/user/home etc policy dispatch type. | Don't treat Entity Kind as `nixos` / `homeManager`. |
| Say Den Context is pipeline function arg. | Don't call `{ host }`, `{ user }` `_module.args` or `specialArgs`. |
| Say aspect-level `provides` / `_` is sub-aspect namespace. | Don't confuse it with `den.provides`; `den.provides` is `den.batteries` alias. |
| Explicitly include sub-aspects or use meta-aspect inside provides to aggregate. | Don't depend on `._` collecting Provides children; `._` doesn't collect provides children and is unpublished behavior. |
| First determine Family Root / Selection Variant / Extension / Profile / Bundle / Integration Edge. | Don't call arbitrary sub-aspects variants. |
| Write host-specific hardware/scenario config as Host spec. | Don't create Host opt-in for single-host single-line toggles. |

## Authoring rules for this repository

### Layout and ownership

- Den's responsibility is semantic composition: Entity, Aspect, Policy, Quirk, Battery, Namespace.
- This repo's physical directory layout is project governance rule: local `lossilk.*` aspects continue using feature-first, concern-first ownership placed under `modules/<concern>/`; apply `CONTEXT.md` Modules Taxonomy before placement/rename.
- Don't migrate this repo to `modules/aspects/lossilk/` just because den examples or batteries source use `modules/aspects/...`.
- Logical Aspect path and physical file path are two contracts: e.g. `lossilk.desktop._.shell._.dms` is include/provides API, `modules/desktop/shell/dms.nix` is ownership / discoverability API; they needn't mechanically mirror, but must fall in same primary concern.
- After adding `modules/**/*.nix` must `git add` before eval; this repo's `vic/import-tree` defaults to scanning only git-tracked files.

### Aspect granularity

- First ask semantic type of new content:
  - **Family Root**: Capability family common invariants and base config; parent aspect isn't default variant.
  - **Selection Variant**: Mutually-exclusive or constrained candidates on same Selection Axis, e.g. shell implementation.
  - **Extension**: Stackable capability answering "add this or not".
  - **Profile / Bundle**: Stable route table, usually only writes `includes`.
  - **Integration Edge**: Glue when two concerns co-exist.
  - **Host spec**: Physical hardware or single-host scenario specific config.
- Reusable, complex, cross-class coordinating, or independently include/disable-able capabilities should have separate files.
- One-off, trivial config can inline or enter clear aggregate aspect; once becomes real choice or owns independent responsibility, split into file.

### Includes and defaults

- In `includes` prefer referencing named Aspect / Battery. Den docs allow anonymous parametric include, but this repo prioritizes named Aspect for debuggability; anonymous functions only for very small local glue.
- `den.default` only for framework-level defaults: stateVersion, allowUnfree, `define-user`, `hostname` etc pipeline. Business baseline via host opt-in or user aspect include; `host-aspects` by users needing to receive host preferences explicitly opt-in.
- Host should explicitly opt-in reusable recipes; don't hide business config in global defaults.
- Including parent aspect doesn't auto-emit children. When needing children explicitly include, or design explicit meta-aspect to aggregate.

### Parametric dispatch and class modules

- Aspect-level parametric function's arg shape IS condition: `{ host }` only activates in host context, `{ host, user }` only in host+user context. Don't wrap scope conditions with `mkIf` or `enable` flag.
- Don't use deprecated wrappers like `den.lib.parametric`, `den.lib.perHost`, `den.lib.take.exactly`.
- Den Context and Nix module args are layered:
  - Two-layer style: `{ host }: { nixos = { config, pkgs, ... }: { ... }; }`
  - flat-form class module: `{ nixos = { host, config, pkgs, ... }: { ... }; }`
- flat-form class module entering Nix module system must have `...` in arg pattern, because module system passes extra args.
- class module requesting entity arg current scope lacks gets skipped; if config doesn't work, first check if scope truly has `host`, `user`, `home`.
- If Den context arg collides with module system arg name, handle per `meta.collisionPolicy` / entity `collisionPolicy` / `den.config.classModuleCollisionPolicy` hierarchy, don't guess.

### Policies and Quirks

- Policy is entity topology, NOT resolution stage. Declaring policy only registers function, must be placed in `includes` to activate.
- `policy.resolve` with Entity Kind key creates child scope; with non-entity key only enriches current scope.
- `policy.include` lets Aspect continue in resolution tree; `policy.provide` directly sends raw module to class. When glue expressible with `include` prefer `include`.
- Quirk for structured data aggregation: producer emits registered quirk key at aspect top-level, consumer receives list via class module function arg.
- Simple same-scope aggregation doesn't need pipe; only cross-scope, filtering, renaming, or collect needs pipe policy.

### Batteries in this repo

- `den.batteries.define-user`: Creates OS / Home user baseline in `den.default.includes`.
- `den.batteries.hostname`: Sets hostname in `den.default.includes`.
- `den.batteries.host-aspects`: Explicitly included by user primary aspect (e.g. `den.aspects.loss.includes`), means that user receives `homeManager`/`hjem` etc `user.classes` configs from host aspect tree. Doesn't make user includes work; user includes handled by built-in host-to-users pipeline. Transitional; verify den rev and upstream notes before modifying.
- `den.batteries.primary-user`: Placed in user primary aspect, e.g. `den.aspects.loss.includes`.
- `den.batteries.user-shell` / `den.provides.user-shell`: Included by shell Selection Variant, don't select specific shell in Family Root.
- Home Manager battery auto-activates when user `classes` include `homeManager` and host supports it; this repo uses `den.schema.user.classes = lib.mkDefault ["user" "homeManager"]`.
- WSL battery auto-activates when host entity sets `wsl.enable = true`; don't manually write duplicate import.
- `den.batteries.import-tree` is special format for migrating traditional non-Den plain modules, class directory must be `_<class>` (like `_nixos`, `_darwin`, `_homeManager`). This is NOT general directory standard for all Den modules in this repo.

### Namespaces

- This repo's registered local namespace is `lossilk`, via `inputs.den.namespace "lossilk" true`.
- `lossilk.cli._.shell` is ergonomic access form equivalent to `den.ful.lossilk.cli.provides.shell`.
- Only create namespace-shaped physical directory when adding another local/exported namespace, vendoring reusable aspects, or explicitly maintaining shared library.

## Implementation / review checklist

Before each Den-related implementation answer these questions:

1. Which files read? At minimum include `CONTEXT.md`, relevant ADR, this baseline, necessary den local docs.
2. What semantic type for this addition/modification: Family Root, Selection Variant, Extension, Profile / Bundle, Integration Edge, Host opt-in, Host spec, Policy, Quirk, Battery usage, or ordinary class config?
3. Which Entity Kind affected: host, user, home, or custom kind?
4. Which Class affected: `nixos`, `darwin`, `homeManager`, `user`, `os`, `wsl`, etc?
5. What physical file path owns it? Does it follow `CONTEXT.md` feature-first / concern-first ownership?
6. What logical Aspect path? Need `provides` children, or freeform sub-aspect?
7. What `includes` DAG edge needed? Included by host primary aspect, user primary aspect, Profile / Bundle, Family Root, Selection Variant, or Extension?
8. Involves cross-entity delivery? If user's own environment, put in user primary aspect includes; if primary user receives host aspect tree's companion config, user includes `host-aspects`; if multi-user or conditional host→user delivery, explicit `provides.to-users` / `provides.<user>`.
9. Need Entity freeform attribute or `den.schema.*` option? If all Entities should have default/type, prefer `den.schema`.
10. Need Quirk, rather than multiple producers writing same consumer's NixOS option?
11. Using Battery? Clear on its opt-in / auto-activated conditions?
12. Misusing `den.default` for business config?
13. Using deprecated wrapper or depending on `._` collecting provides? If so, fix.
14. Added `modules/**/*.nix`? If so, already `git add`ed to ensure import-tree can scan?
15. What validation command?
    - Doc/agent entry changes: `git diff --check`, declare no Nix evaluation-impacting files.
    - Den module changes: at minimum `just fmt` and `just check`; build or run a VM only when VM outputs/runtime behavior or a shared desktop VM profile specifically needs verification. Host-only binding changes are sufficiently covered by evaluation.
    - Non-NixOS dev host: first `command -v just nh nix`, when lacking tools follow `CLAUDE.md` using `nix shell`.

## Red flags

Pause and review when seeing:

- "import an Aspect" — should say `includes`, unless truly writing Nix module `imports`.
- Calling `homeManager` Entity Kind, or conflating `user` Entity Kind with `user` Class.
- Moving this repo's `modules/` layout because of den upstream examples.
- Adding business/desktop/dev-tool baseline in `den.default`.
- Blindly relying on global `host-aspects` for multi-user/conditional host→user config, instead of user opt-in or explicit `provides.to-users`.
- Writing Family Root as `_.base` or calling parent aspect default variant.
- Depending on `lossilk.foo._` auto-collecting provides children.
- Using `den.lib.parametric`, `den.lib.perHost`, `den.lib.take.exactly` old APIs.
- Trusting `nix flake check` after adding `modules/**/*.nix` without `git add`.
- Casually modifying `flake.nix`, `flake.lock`, `pkgs/*`.

## Debug pointers

- First check scope: does current context have your requested `host`, `user`, `home`?
- When needing to see policy hits, use `den.lib.policyInspect.inspect` from den docs `guides/debug.md`.
- When needing to see aspect include graph, use `den.lib.capture` / den-diagram.
- After temporarily exposing `flake.den = den` for REPL must remove; don't make debug output long-term flake API.
