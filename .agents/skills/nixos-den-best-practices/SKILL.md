---
name: nixos-den-best-practices
description: Den gate for planning, editing, or reviewing den Entities, Aspects, includes, policies, quirks, batteries, cross-entity delivery, or modules/**/*.nix ownership.
---

# NixOS Den Best Practices

Use this as the shared gate for Den semantic work. It is not a feature-authoring flow; call `add-aspect` or `declare-den-host` when the task has that narrower shape.

## Gate

1. Confirm scope. Apply this skill only when the change affects Den semantics: `den.hosts`, users/homes, `den.aspects.*`, `lossilk.*`, `includes`, `provides`, policies, quirks, batteries, class blocks, or `modules/**/*.nix` ownership. If it is ordinary shell/docs/package work, leave the gate.
2. Read authorities in order: `AGENTS.md`, `CONTEXT.md`, `docs/frameworks/den.md`, then the task-specific docs. Use official upstream den docs only when upstream semantics are needed or repo docs are unclear.
3. Name the semantic role before editing: Entity, Host spec, Host opt-in, Leaf Aspect, Family Root, Selection Variant, Extension, Profile / Bundle, Integration Edge, Policy, Quirk, Battery usage, or ordinary class config. Continue only when the role has a single owner.
4. Check ownership: physical path follows primary concern, logical path follows matching `lossilk.<concern>._.*`, and no business feature is hidden in `den.default`.
5. Check execution shape: Aspect root functions request Den Context args, class blocks request Nix module args with `...`, parent Aspects do not imply child Aspects, and deprecated wrappers are absent.
6. Check delivery: user-owned environment goes through user primary Aspect includes; host-selected companion config requires user opt-in to `host-aspects`; multi-user or conditional delivery uses explicit provides.
7. Check file/command safety: ask before `flake.nix`, `flake.lock`, or `pkgs/*`; `git add` new `modules/**/*.nix` files before eval; use repo `just` wrappers only.
8. Validate according to impact. Docs/skills-only edits need `git diff --check`; Den module edits need at least `just fmt` and `just check`; VM/image outputs need the relevant VM/image build. Host-only binding changes are sufficiently covered by evaluation.

## Reference Pointers

Open `.agents/skills/nixos-den-best-practices/REFERENCE.md` only for the branch you need:

- `#terminology` for repo words and avoid-words.
- `#taxonomy` for concern-to-path mapping.
- `#authoring` for attrpath, context, class, and include rules.
- `#delivery` for cross-entity delivery choices.
- `#validation` for command and tracking rules.
- `#red-flags` for review failure modes.

## Completion Check

- The semantic role, owner path, and include/delivery edge are coherent.
- No Den Context, Class, or Entity Kind terms are conflated.
- No new untracked Nix file is invisible to import-tree.
- Validation used the wrapper appropriate to the changed surface.
