# Den Authority Map

Use this map to find the authoritative rule instead of memorizing or duplicating it in a skill.

## Terminology

- Read `CONTEXT.md` for canonical repo terms and avoid-words.
- Read `docs/frameworks/den.md#concept-boundaries` when reviewing language in plans, docs, or final answers.
- Key gate: if a change conflates Entity, Aspect, Includes, Class, Entity Kind, Context, Policy, Quirk, or Battery, stop and reread the authority before editing.

## Taxonomy

- Read the `Modules Taxonomy` term in `CONTEXT.md` for concern-first physical placement and `lossilk.*` ownership.
- Read `docs/frameworks/den.md#layout-and-ownership` before adding, moving, or renaming `modules/**/*.nix`.
- Key gate: path and Aspect path must share the same primary concern, even when they do not mechanically mirror.

## Authoring

- Read `docs/frameworks/den.md#authoring-rules-for-this-repository` for attrpath style, includes/defaults, parametric dispatch, class modules, policies, quirks, batteries, and namespaces.
- Read `docs/agents/adding-a-feature.md` for concrete Aspect shapes and `docs/agents/den-configuration-patterns.md` for common implementation patterns.
- Key gate: Den Context args belong at Aspect roots; Nix module args belong in class blocks with `...`.

## Delivery

- Read the `Cross-entity Delivery` term in `CONTEXT.md` before moving config between host, user, and home scopes.
- Read `docs/frameworks/den.md#batteries-in-this-repo` before touching `host-aspects`, `primary-user`, `user-shell`, WSL, or other den batteries.
- Key gate: normal user includes do not depend on `host-aspects`; host-selected companion config and multi-user delivery use different mechanisms.

## Validation

- Read `AGENTS.md#commands-must-use-just-wrappers` for command wrappers.
- Read `AGENTS.md#constraints` before modifying confirmation-required files.
- Read `docs/frameworks/den.md#implementation--review-checklist` for impact-based validation and import-tree tracking.
- Key gate: new `modules/**/*.nix` files must be git-tracked before evaluation, and raw `nix` / `nh` / `nixos-rebuild` commands are not the repo entry point.

## Red Flags

- Read `docs/frameworks/den.md#red-flags` during review or when a plan feels semantically muddy.
- Read `docs/agents/den-configuration-patterns.md#common-error-prevention` when debugging a change that evaluates but has no effect.
- Key gate: if a red flag appears, resolve it before writing more code.
