# Documentation Update Summary

## Context

The den framework has limited public corpus, making it difficult for agents to understand correct usage patterns. This update consolidates authoritative local documentation with verified web research to provide comprehensive guidance.

## Changes Made

### 1. New: `docs/agents/den-configuration-patterns.md`

**Purpose**: Quick reference for agents implementing den-based features.

**Content** (compressed English for token efficiency):
- Pre-modification checklist (governance docs, tool verification, git tracking)
- 6 common configuration patterns with concrete examples:
  - Single-class leaf aspect
  - Multi-class feature coordination
  - Family Root + Selection Variants
  - Profile/Bundle composition
  - Parametric aspect (conditional activation)
  - Host Spec (hardware-specific config)
- Cross-entity delivery (3 methods: user self-declared, host-aspects opt-in, explicit provides)
- File organization decision tree
- Reference style standard (attrpath vs angle brackets)
- Validation workflow (just fmt → just check → just build-vm)
- 8 common error prevention patterns with symptoms/causes/fixes
- Debugging tips (context scope, REPL query)
- Quick reference card

**Key improvement**: Practical patterns agents can copy/adapt, not just theory.

### 2. New: `docs/reference/den-web-search.md`

**Purpose**: Supplementary web-sourced overview with strong caveats.

**Content**:
- Core concepts from official docs + community examples
- Composition/inheritance rules
- Integration with flake-parts/NixOS
- Configuration patterns and best practices
- vic/import-tree integration
- Batteries used in this repo
- Links to additional resources

**Key safeguard**: Clearly marked as web-sourced, requires verification, not authoritative.

### 3. Updated: `CLAUDE.md` (via `AGENTS.md` symlink)

**Change**: Added `den-configuration-patterns.md` to documentation map.

**New entry**:
```
| 快速参考配置模式 | docs/agents/den-configuration-patterns.md (实用模式、验证检查点、错误预防) |
```

### 4. Updated: `docs/agents/adding-a-feature.md`

**Change**: Added cross-reference to new pattern guide.

**Addition**:
```
> **另见**: `den-configuration-patterns.md` — 实用配置模式、验证检查点、常见错误预防的快速参考。
```

## Verification Performed

1. ✅ **Cross-checked against local authoritative sources**:
   - `CONTEXT.md` (terminology)
   - `docs/frameworks/den.md` (baseline rules)
   - `~/workspace/nix-ref/den/docs/` (den framework docs)
   - Current project code structure

2. ✅ **Validated consistency**:
   - Terminology aligns with `CONTEXT.md` glossary
   - Rules don't contradict `docs/frameworks/den.md`
   - Examples match actual project structure
   - flake.lock den revision (590e20a84c, 2026-06-09) vs local den repo (fe63b4b, current)

3. ✅ **Format check passed**:
   ```
   just fmt-check
   traversed 128 files
   formatted 6 files (0 changed)
   ```

4. ✅ **Git tracking**:
   ```
   git add docs/agents/den-configuration-patterns.md docs/reference/den-web-search.md
   ```

## Rationale

### Why compress to English?

Token efficiency. The generated pattern guide is for agent consumption, not human reading. English allows more information in fewer tokens while remaining clear to models.

### Why separate web-search results?

Defensive accuracy. Web sources may contain outdated or incorrect information for low-corpus frameworks. By isolating web-sourced content:
- Agents see clear authority hierarchy
- Accidental reliance on unverified info is prevented
- Future updates can replace/remove web content without touching verified patterns

### Why focus on patterns vs theory?

Agents implementing features need "show me how" not "explain why". The existing `CONTEXT.md` and `docs/frameworks/den.md` already provide excellent theory and terminology. The gap was practical examples.

## Usage for Agents

**Before implementing any den-based feature**:

1. Read `CONTEXT.md` (terminology)
2. Read `docs/frameworks/den.md` (baseline rules + 15-question checklist)
3. Read `docs/agents/den-configuration-patterns.md` (practical patterns)
4. Consult `~/workspace/nix-ref/den/docs/` for specific API questions
5. Use `docs/reference/den-web-search.md` only as supplementary context

**During implementation**:
- Follow pre-modification checklist
- Choose appropriate pattern from the 6 examples
- Apply validation workflow (git add → just fmt → just check → just build-vm)
- Check common error prevention list

**After implementation**:
- Verify against quick reference card
- Run full validation sequence

## Files Modified

```
M  CLAUDE.md (via AGENTS.md symlink)
M  docs/agents/adding-a-feature.md
A  docs/agents/den-configuration-patterns.md
A  docs/reference/den-web-search.md
```

## Next Steps

These docs are now in the repo but not committed. Ready for commit with message:

```
docs: add den configuration patterns reference for agents

- Add docs/agents/den-configuration-patterns.md with practical patterns,
  validation checkpoints, and common error prevention
- Add docs/reference/den-web-search.md with web-sourced supplementary info
  (clearly marked as requiring verification)
- Update CLAUDE.md documentation map
- Cross-reference from docs/agents/adding-a-feature.md

Addresses low-corpus framework documentation gap. Provides agents with
concrete examples and validation workflows for den-based feature implementation.
```

Would you like me to commit these changes?
