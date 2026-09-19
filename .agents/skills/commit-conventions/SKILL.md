---
name: commit-conventions
description: Commit message conventions for this nix-config. Use when staging or committing changes, writing a commit message, or splitting work into commits.
---

# Commit Conventions

This repo uses a lightweight Conventional Commits style. Follow it for new
commits; do not rewrite existing history. Write in English. No tooling enforces
this — it is a habit, not a gate.

The style below is what the repo already uses. Pick type and scope by the
intent of the change, not by the file path.

## Types

- `feat` — new capability, host, aspect, or user-visible behavior.
- `fix` — a bug fix or a correction to wrong configuration.
- `refactor` — neither new capability nor defect fix.
- `chore` — non-user-visible maintenance (dependency/input bumps, cleanup).
- `docs` — documentation only (`*.md`, skills, comments).
- `ci` — CI or automation workflows.
- `style` — formatting or lint-only, no behavior change.
- `revert` — revert a previous commit.
- `perf` — purpose is performance.
- `test` — test-only changes.

A dependency bump that fixes broken evaluation is a `fix`, not a `chore`.

## Scope

Optional, and used to disambiguate. Natural scopes are this repo's Den shelves,
routes, entities, and infra, for example: `desktop`, `shell`, `terminals`,
`compositor`, `cli`, `dev`, `umbriel-noctalia-desktop`, `mechrevo`, `flake`,
`pkgs`, `just`, `agents`. Use it when the subject alone would be ambiguous or
the change is confined to one shelf; omit it for repo-wide changes. Do not
invent scopes that do not map to a real shelf, route, or entity.

## Subject and body

- Subject: imperative mood, lowercase, no trailing period, English, short
  enough to read in `git log --oneline`.
- Body: optional but encouraged; explain **why**, not **what**. Wrap at ~72
  chars. Use bullets when the change has distinct parts. Do not restate the diff.
- Footer: optional; use for `Refs:`, `Co-authored-by:`, or a follow-up limitation.

## Format

```
<type>[optional scope]: <subject>

[optional body]

[optional footer]
```

## Steps

1. Read the working tree before writing anything.

   Run `git status --short` and `git diff` (staged and unstaged). Every search
   command includes `--glob '!/nix/store/**'`.

   Completion: you can list exactly which files changed and why, and no command
   has touched `/nix/store/**`.

2. Decide the commit split.

   One commit = one intent. Separate unrelated changes (e.g. a config fix and a
   docs/skill addition) into distinct commits. Check recent style with
   `git log --oneline -10` before writing.

   Completion: the number of commits and the files in each are fixed. A mixed
   "config + docs" change is split, not bundled.

3. Stage exactly the files for this commit.

   Use explicit paths: `git add <file> ...`. Do not stage unrelated work, and do
   not use `git add -A` / `git add .` when the tree has other changes. New
   `modules/**/*.nix` files must be staged before any evaluation (import-tree
   only scans tracked files).

   Completion: `git status --short` shows only the intended files as staged.

4. Write the message.

   Apply the type, scope, subject, and body rules above. Put the reason in the
   body for non-obvious changes. English only.

   Completion: the message matches `<type>[scope]: <subject>` and the body, if
   any, explains why.

5. Commit and verify.

   Commit with the message. Then run `git log --oneline -3` and
   `git status --short`.

   Completion: the new commit appears with the intended message, and the
   working tree is clean or only holds intentionally uncommitted work.

## Good examples (from this repo)

```
fix: load the nvidia KMS stack in initrd on mechrevo

Wayland-only host (greetd), so services.xserver.enable is false and the
nixpkgs boot.kernelModules nvidia entries (gated on it) never apply.
... the window that made the compositor start glitched.
```

```
refactor: rename the Noctalia Greeter aspect to noctalia-greeter

Match the upstream package and nixpkgs module name
(services.displayManager.noctalia-greeter) instead of reusing the shell's
name under the greeter shelf.
```

## Avoid

- Sentence-style with no type: `Add fcitx5 rime wanxiang input aspect`.
- Missing space after the colon: `docs:update desc`.
- Vague fillers: `fixup`, `update stuff`.
- Restating the diff: `fix: change line 42 to true`.
- Bundling unrelated changes into one commit.

## Stop Rules

- Do not rewrite or amend existing history unless the user explicitly asks.
- Do not force-push.
- Do not introduce commitlint, a commit-msg hook, or any enforcement tooling
  unless the user explicitly asks; that would touch `flake.nix`/`pkgs` and needs
  confirmation.
- If you are about to bundle two unrelated changes because they are "close
  enough", stop and split them instead.
- If a commit needs `flake.nix`, `flake.lock`, or `pkgs/*`, get explicit
  confirmation before editing those files.
