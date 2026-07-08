# Project Context

This repo is a personal NixOS and Home Manager configuration built on `denful/den` and `flake-parts`. Its project language is configuration semantics: hosts, users, aspects, supported routes, validation, and agent-safe maintenance.

This is not a product codebase with front-end/back-end layers, product requirements, or a product issue workflow. Use this file as the single project context and glossary for placement decisions and terminology.

## Sources Of Truth

- Upstream Den docs own framework semantics: entities, aspects, classes, policies, quirks, batteries, namespace conventions, and `includes` composition.
- `modules/`, `flake.nix`, and current evaluation behavior own live configuration truth.
- `docs/` preserves research, reference material, and agent notes. It can inform decisions, but it is not authoritative until verified against live code.
- Durable architecture decisions belong under `docs/adr/` when a decision is surprising, hard to reverse, and has real alternatives.

## Placement Rules

- Use Den's model directly. Do not wrap entities, aspects, policies, quirks, pipes, or batteries in a parallel local architecture model.
- Hosts and users are declared as entities. Their generated aspects define their route through reusable configuration.
- Host-specific hardware, disk, VM, WSL, image, and one-off scenario details stay in host specs.
- Reusable behavior belongs in capability aspects.
- Route-specific coordination belongs in ordinary glue aspects.
- Prefer ordinary class modules and `den.schema` before reaching for quirks, pipes, or fleet patterns.
- Most `modules/` directory names are mutable category shelves for discoverability, not stable ownership boundaries or namespace contracts.
- The supported desktop route is explicit. Do not infer that compositor, shell, launcher, portal, greeter, search, and IPC bindings are freely swappable unless a verified glue aspect proves that route.

## Validation

- Prefer `just` recipes over raw `nix`, `nh`, or `nixos-rebuild` commands when a recipe exists.
- Use `just fmt-check` for formatting and static lint checks.
- Use `just check` or `just check-all` when changes affect Nix evaluation, Den wiring, flake outputs, or shared configuration behavior.
- Use targeted builds such as `just build-vm <host>`, `just os-build .#<host>`, or `just diff <host>` when a change has host-specific risk.

## Language

### Daily Den Model

**Attrset**: A Nix attribute set, written `{ ... }`, containing named values. Most Den configuration values are attrsets with Den-recognized fields.
_Avoid_: object, dictionary unless speaking informally

**Entity**: A typed Den data record declaring what exists, such as a host or user.
_Avoid_: resource, instance, configuration module

**Host**: A concrete machine or VM declared as a Den host entity under `modules/hosts/`.
_Avoid_: system, node, box

**User**: A Den user entity and its generated personal aspect, currently centered on `loss`.
_Avoid_: account, person

**Generated Aspect**: The same-named aspect Den creates from a host or user entity. Writing `den.aspects.<name>` enhances that generated aspect.
_Avoid_: separate profile, manual import

**Aspect**: An attrset that contains modules for one or more Nix classes, usually organized around one configuration concern. It may also include other aspects.
_Avoid_: NixOS module, import, profile

**Class**: A Nix module evaluation domain such as `nixos`, `homeManager`, `darwin`, `hjem`, `maid`, or `user`.
_Avoid_: entity type, host/user kind

**Class Module**: The module value under a class key inside an aspect, such as `nixos = { ... };` or `homeManager = { pkgs, ... }: { ... };`.
_Avoid_: aspect, entity, imported file

**Includes**: The Den field an aspect uses to include other aspects or batteries.
_Avoid_: imports, module imports

**Host Spec**: Host-specific configuration for hardware, image/runtime facts, disk layout, or one-off scenario details.
_Avoid_: reusable module, profile

**Schema**: A `den.schema.*` declaration for typed metadata shared by entities of a kind, such as `den.schema.host.displays`.
_Avoid_: quirk, option hack, freeform convention

**Entity Kind**: The Den data kind of an entity, such as host or user.
_Avoid_: class

**Den Context**: The pipeline argument shape, such as `{ host }` or `{ host, user }`, used by Den to decide where an aspect function applies.
_Avoid_: NixOS module args, specialArgs

### Advanced Den Mechanisms

**Battery**: A reusable Den-provided pattern such as `primary-user`, `user-shell`, `host-aspects`, or `hostname`.
_Avoid_: profile, feature aspect

**Policy**: A Den rule that can route entities, enrich context, or pipe quirk data. Policies are advanced user mechanisms; most repo work should use existing policies through batteries or includes.
_Avoid_: ordinary config, enable flag

**Policy Activation**: A policy is inert when declared; it only runs when included by an aspect, schema, or other active configuration path.
_Avoid_: global automatic behavior

**Quirk**: Named structured data emitted by aspects for later consumption. Prefer direct class modules or `den.schema` unless multiple producers need to publish the same kind of project-specific fact.
_Avoid_: shared option, global variable, ordinary NixOS option merge

**Pipe**: A policy effect that routes, filters, transforms, renames, exposes, or collects quirk data across scopes.
_Avoid_: Nix pipe operator, module import

**Fleet**: The set of hosts resolved together in one Den run. Use fleet patterns only when hosts need to share or collect structured data across sibling host scopes.
_Avoid_: host list, inventory by default

### Repo Placement Terms

**Project Context**: This file: the single project context, terminology, and placement guide.
_Avoid_: context map, bounded context map, product context

**Research Docs**: Prior notes and references under `docs/` that are useful background but not authoritative by themselves.
_Avoid_: source of truth, live spec

**Module Category**: A mutable physical shelf under `modules/` used for discoverability, such as `desktop`, `dev`, or `networking`; it is not automatically an ownership boundary.
_Avoid_: bounded context, domain boundary, namespace contract

**Capability Aspect**: A reusable aspect for one capability or a small capability family.
_Avoid_: feature, snippet, package list

**Glue Aspect**: An ordinary Aspect whose main job is to include and coordinate several other aspects for a concrete supported use case. It is a local usage pattern, not a Den concept alongside Entity, Aspect, Policy, or Quirk.
_Avoid_: profile primitive, default, preset

**Supported Route**: A concrete aspect path that hosts may include because its integration behavior is known to work in this repo.
_Avoid_: theoretical combination, available module

**Selection Variant**: A constrained alternative on one explicit choice axis, only valid where the surrounding stack supports that substitution.
_Avoid_: arbitrary combo, plugin, desktop shell swap

### Desktop Route Terms

**niri-dms-desktop**: A Glue Aspect for the currently supported niri + DankMaterialShell desktop route. It is not evidence that compositor and shell modules form a free variant matrix, and it is allowed to remain route-specific until repeated integrations justify a more general abstraction.
_Avoid_: variant combination, desktop generator

**Niri-coupled Capability Aspect**: A capability aspect that assumes niri integration in its own configuration, such as contributing `programs.niri.settings` or selecting a niri greeter/compositor. This repo treats these as ad hoc supported routes unless enough Glue Aspect code exists to prove broader combinations.
_Avoid_: generic shell variant, freely composable desktop component

**Free Desktop Combination**: Arbitrary composition of compositor, shell, portal, launcher, greeter, search, and IPC bindings. This is not a supported model in the current repo because avoiding ad hoc coupling would require substantial explicit Glue Aspect code.
_Avoid_: supported default, simple variant swap

**Unsupported Candidate**: A support-status label for an aspect/module kept in-tree for possible future use but not exposed as a supported route until it has a stable Glue Aspect and verified integration behavior.
_Avoid_: supported variant, available option

**Noctalia**: An unsupported Niri-coupled Capability Aspect candidate; it is not stable or verified enough for this repo's supported desktop route.
_Avoid_: DMS alternative, niri shell variant
