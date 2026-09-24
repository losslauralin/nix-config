---
name: commit-conventions
description: Commit message conventions for this nix-config. Use when staging or committing changes, writing a commit message, or splitting work into commits.
---

# Commit Conventions

This repo uses a lightweight Conventional Commits style. Follow it for new
commits; do not rewrite existing history. Write in English.

The style below is what the repo already uses. Pick type and scope by the
intent of the change, not by the file path.

Pre-commit runs a `treefmt` hook over the staged files (see
`modules/flake-parts/git-hooks.nix`), and it will reject your commit when it
finds something to fix. That hook is a gate, so a rejected commit means the
tree needs attention -- see [When a commit is rejected](#when-a-commit-is-rejected).
Read the hook config itself when it matters; this skill describes the
conventions, not the current state of the tooling.

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

   One commit carries one intent. When the tree holds a config fix and a
   docs addition, that is two commits, not one. Check recent style with
   `git log --oneline -10` before writing.

   A commit that grew past its intent is hard to review and hard to revert:
   reverting it drags the unrelated change out with it. The test is whether
   the commit can be described in one subject line without an "and".

   Completion: you can name each commit's intent in one sentence, and know
   which files belong to each.

3. Stage exactly the files for this commit.

   Use explicit paths: `git add <file> ...`. When the tree holds other changes,
   leave them out of the index.

   A new `modules/**/*.nix` file has to be tracked before anything that
   evaluates the flake will see it. `flake.nix` builds this repo's module tree
   with `import-tree ./modules`, which walks git-tracked files only, so an
   untracked module is not an error -- it is simply absent. `just check` and
   `just build` will pass while the aspect or host file you just wrote
   contributes nothing. Track the file in the same breath as creating it, and
   confirm with `git status --short` that it shows as `A` rather than `??`.

   The same silence applies to Den wiring: an aspect only takes effect through
   an `includes` entry. A staged, committed aspect file that no host or user
   `includes` is inert, and evaluation stays green. When the commit adds or
   renames an aspect, check that the include site moves with it.

   A previously failed attempt leaves its staged files in the index, and the
   next `git add` adds to that pile rather than starting over. Before staging,
   run `git status --short` and confirm the index matches this commit's file
   list; `git reset` clears it when it does not.

   Completion: `git status --short` shows only the intended files as staged,
   every new `modules/**/*.nix` file reads `A`, and any new aspect has its
   `includes` entry in the same commit.

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

## When a commit is rejected

The `treefmt` hook rejects a commit by rewriting the files it can format and
failing on the ones it cannot. Work out which of the two happened before
touching anything, because the responses differ:

- **The hook rewrote files.** Those rewrites are the fix. Re-stage them and
  commit again.
- **The hook reports a formatter it cannot apply.** That means the file and the
  formatter disagree about what this repo should look like. Decide whether the
  file needs editing or the formatter needs excluding, and change the one that
  is actually wrong.

A formatter pointed at vendored third-party code is the common case: lint rules
written for this repo's own sources will find fault with code the repo does not
own, and rewriting it silently diverges from upstream. Vendored directories are
excluded from the formatter instead -- and because the hook passes an explicit
file list, the exclusion has to be set both in `formatter.nix` (for a
directory walk) and in `git-hooks.nix` (for the staged-file list). When a
commit is rejected, read the hook's output rather than assuming it is wrong.

`--no-verify` skips the check for one commit. It is warranted when the commit
itself is the change that makes the hook pass -- a formatter or hook config fix
that the hook cannot yet see, because the hook reads the committed config. Reach
for it only there, and say why in the commit body, so the next reader does not
read it as a routine bypass.

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
- Subjects that restate the diff: `fix: change line 42 to true`.
- Commits holding two intents, which the subject line cannot honestly describe.

## Stop Rules

- Do not rewrite or amend existing history unless the user explicitly asks.
- Do not force-push.
- Do not introduce commitlint, a commit-msg hook, or any enforcement tooling
  unless the user explicitly asks; that would touch `flake.nix`/`pkgs` and needs
  confirmation.
- If two unrelated changes are tempting to bundle because they are "close
  enough", split them instead.
- If a commit needs `flake.nix`, `flake.lock`, or `pkgs/*`, get explicit
  confirmation before editing those files.
