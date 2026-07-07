# Project Context

This repo is a personal NixOS and Home Manager configuration built on `denful/den` and `flake-parts`. Its project language is configuration semantics: hosts, users, aspects, supported routes, validation, and agent-safe maintenance.

This is not a product codebase with front-end/back-end layers, product requirements, or a product issue workflow. Use this file as the single project context and glossary for placement decisions and terminology.

## Sources Of Truth

- Upstream Den docs own framework semantics: entities, aspects, classes, policies, quirks, batteries, namespace conventions, and `includes` composition.
- `modules/`, `flake.nix`, and current evaluation behavior own live configuration truth.
- `docs/` preserves research, reference material, and agent notes. It can inform decisions, but it is not authoritative until verified against live code.
- Durable architecture decisions belong under `docs/adr/` when a decision is surprising, hard to reverse, and has real alternatives.

## Placement Rules

- Use Den's model directly. Do not wrap entities, aspects, policies, quirks, or batteries in a parallel local architecture model.
- Hosts and users are declared as entities. Their primary aspects define their route through reusable configuration.
- Host-specific hardware, disk, VM, WSL, image, and one-off scenario details stay in host specs.
- Reusable behavior belongs in capability aspects.
- Route-specific coordination belongs in ordinary glue aspects.
- Most `modules/` directory names are mutable category shelves for discoverability, not stable ownership boundaries or namespace contracts.
- The supported desktop route is explicit. Do not infer that compositor, shell, launcher, portal, greeter, search, and IPC bindings are freely swappable unless a verified glue aspect proves that route.

## Validation

- Prefer `just` recipes over raw `nix`, `nh`, or `nixos-rebuild` commands when a recipe exists.
- Use `just fmt-check` for formatting and static lint checks.
- Use `just check` or `just check-all` when changes affect Nix evaluation, Den wiring, flake outputs, or shared configuration behavior.
- Use targeted builds such as `just build-vm <host>`, `just os-build .#<host>`, or `just diff <host>` when a change has host-specific risk.

## Language

**Project Context**: This file: the single project context, terminology, and placement guide.
_Avoid_: context map, bounded context map, product context

**Research Docs**: Prior notes and references under `docs/` that are useful background but not authoritative by themselves.
_Avoid_: source of truth, live spec

**Host**: A concrete machine or VM declared as a Den host entity under `modules/hosts/`.
_Avoid_: system, node, box

**Entity**: A typed Den data record declaring what exists, such as a host or user.
_Avoid_: resource, instance, configuration module

**Host Spec**: Host-specific configuration for hardware, image/runtime facts, disk layout, or one-off scenario details.
_Avoid_: reusable module, profile

**User**: A Den user entity and its primary personal aspect, currently centered on `loss`.
_Avoid_: account, person

**Module Category**: A mutable physical shelf under `modules/` used for discoverability, such as `desktop`, `dev`, or `networking`; it is not automatically an ownership boundary.
_Avoid_: bounded context, domain boundary, namespace contract

**Aspect**: A composable Den configuration unit that declares behavior and may emit class modules.
_Avoid_: NixOS module, import

**Includes**: A Den aspect composition edge that adds another aspect or battery to the resolution graph.
_Avoid_: imports, module imports

**Glue Aspect**: An ordinary Aspect whose main job is to compose or coordinate other aspects for a concrete supported use case, especially when a generic abstraction would require too much explicit integration code. It is a usage pattern, not a Den concept alongside Entity, Aspect, Policy, or Quirk.
_Avoid_: profile primitive, default, preset

**niri-dms-desktop**: A Glue Aspect for the currently supported niri + DankMaterialShell desktop route. It is not evidence that compositor and shell modules form a free variant matrix, and it is allowed to remain route-specific until repeated integrations justify a more general abstraction.
_Avoid_: variant combination, desktop generator

**Supported Route**: A concrete aspect path that hosts may include because its integration behavior is known to work in this repo.
_Avoid_: theoretical combination, available module

**Niri-coupled Capability Aspect**: A capability aspect that assumes niri integration in its own configuration, such as contributing `programs.niri.settings` or selecting a niri greeter/compositor. This repo treats these as ad hoc supported routes unless enough Glue Aspect code exists to prove broader combinations.
_Avoid_: generic shell variant, freely composable desktop component

**Free Desktop Combination**: Arbitrary composition of compositor, shell, portal, launcher, greeter, search, and IPC bindings. This is not a supported model in the current repo because avoiding ad hoc coupling would require substantial explicit Glue Aspect code.
_Avoid_: supported default, simple variant swap

**Unsupported Candidate**: A support-status label for an aspect/module kept in-tree for possible future use but not exposed as a supported route until it has a stable Glue Aspect and verified integration behavior.
_Avoid_: supported variant, available option

**Noctalia**: An unsupported Niri-coupled Capability Aspect candidate; it is not stable or verified enough for this repo's supported desktop route.
_Avoid_: DMS alternative, niri shell variant

**Selection Variant**: A constrained alternative on one explicit choice axis, only valid where the surrounding stack supports that substitution.
_Avoid_: arbitrary combo, plugin, desktop shell swap

**Capability Aspect**: A reusable aspect that owns one capability or tightly related capability family.
_Avoid_: feature, snippet, package list

**Class**: A Nix module evaluation domain such as `nixos`, `homeManager`, or `user`.
_Avoid_: entity type, host/user kind

**Entity Kind**: The Den data kind of an entity, such as host or user.
_Avoid_: class

**Den Context**: The pipeline argument shape, such as `{ host }` or `{ host, user }`, used by Den to decide where an aspect function applies.
_Avoid_: NixOS module args, specialArgs

**Policy**: Den topology and routing logic that defines how entities relate, such as host-to-user fan-out.
_Avoid_: resolution stage, enable flag

**Quirk**: Structured data emitted by aspects and aggregated through pipes when contexts need to share data without direct coupling.
_Avoid_: shared option, global variable

**Battery**: A reusable Den-provided pattern such as `primary-user`, `user-shell`, `host-aspects`, or `hostname`.
_Avoid_: profile, feature aspect