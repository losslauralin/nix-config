# Context Map

This file is the routing document for project language and ownership. The existing `docs/` tree is reference material: use it as research input, but verify claims against `modules/`, `flake.nix`, and current framework behavior before treating them as project truth.

## Contexts

- [Den Configuration](https://den.denful.dev/explanation/core-principles/) - owns framework language, aspect composition rules, entity/class boundaries, policies, quirks, batteries, and namespace conventions. Upstream Den concepts are the semantic authority; this repo should use Den's model rather than wrap it in a parallel local model.
- [Entity Model](./modules/) - owns concrete host/user entities, host specs, schema attributes, and each entity's primary aspect route table.
- [Capability Catalog](./modules/) - owns reusable aspects delivered to hosts or users. Most `modules/` directory names are mutable category shelves, not stable bounded contexts.
- [Research Docs](./docs/) - preserves prior research, agent notes, and reference summaries; it does not own live configuration semantics.

## Relationships

- **Entity Model -> Den Configuration**: Hosts and users are declared and resolved using Den's entity/aspect/class model.
- **Entity Model -> Capability Catalog**: Entity primary aspects include reusable capabilities and supported Glue Aspects; host-specific hardware and scenario details stay in entity-owned specs.
- **Capability Catalog -> Den Configuration**: Reusable capabilities must still respect Den terminology, aspect composition rules, and class boundaries.
- **Den Configuration -> All Contexts**: Do not bypass Den's prescribed mechanisms with local substitutes; use entities for data, aspects for behavior, policies for topology, quirks/pipes for structured sharing, and `includes` for composition.
- **Research Docs -> All Contexts**: Research docs can inform decisions, but code and this map resolve conflicts.

## Language

**Context Map**: The root routing document for bounded contexts, relationships, and canonical project terms.
_Avoid_: context notes, research summary

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

**Module Category**: A mutable physical shelf under `modules/` used for discoverability, such as `desktop`, `dev`, or `networking`; it is not automatically a bounded context.
_Avoid_: domain boundary, namespace contract

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

**ADR Location**: Durable architecture decisions live under `docs/adr/` when a decision is hard to reverse, surprising without context, and has real alternatives.
_Avoid_: burying decisions in comments