---
name: github-multica-protocol
description: GitHub-Multica protocol: load before operation skills to enforce target confirmation, read-before-write, gh/multica boundaries, Multica comment output, project binding, assignee, and status rules.
---

# GitHub-Multica Protocol

Load this protocol before any GitHub or Multica operation skill. It is the single source of truth for shared safety, tool, output, project, assignee, and status behavior.

## Tool Boundary

- Use `gh` for GitHub reads and writes.
- Use `gh api` only when `gh` has no direct command for the required GitHub operation.
- Use `multica` for all Multica reads and writes.
- Never use curl, wget, or other HTTP clients against Multica URLs.

## Operation Gates

1. Target gate: before any write, identify the exact GitHub `owner/repo`, GitHub item numbers/types, and Multica issue ids affected. If the target is ambiguous, stop and ask.
2. Read gate: view or list current state before changing any GitHub or Multica item.
3. Preview gate: for destructive or bulk actions, including close, cancel, merge, delete, and bulk edits, list affected items and exact commands, then wait for confirmation.
4. Write gate: a single non-destructive write may run after the target and read gates pass.
5. Error gate: on failure, missing permission, malformed data, or rate limiting, stop and report the raw error. Do not silently retry or route around it.
6. Report gate: show the real commands run and report results as a table or linked list.

Completion criterion: every applicable gate has passed or produced a user-facing stop reason before the operation is treated as complete.

## Multica Output

- Never delete a Multica issue unless the user explicitly asks.
- Default sync or update behavior is status update only, not removal.
- To retire an obsolete issue, use `cancelled` status because it is reversible.
- Deliver final results via `multica issue comment add`; the user only sees comments, not terminal output.
- Use `--content-stdin` with a quoted HEREDOC for agent-authored final result bodies.
- For long activity summaries, use a temp markdown file and `--content-file`.
- Reference Multica issues with `[MUL-123](mention://issue/<id>)`.
- Avoid agent/member mention links unless escalating or delegating, to prevent trigger loops.

## Project Binding

Bind each migrated or newly mirrored Multica issue to the Multica project that corresponds to its GitHub repository:

```sh
multica issue ... --project <project-id>
```

If the GitHub repository to Multica project mapping is not known, read existing local/context records or ask for the project id before creating the Multica issue.

Completion criterion: every new Multica issue is created with a known project id, or creation stops with a project-id question.

## Assignee And Status References

- Before setting or changing a Multica assignee, read `ASSIGNEES.md`.
- Before setting, changing, or syncing a Multica status, read `STATUS.md`.
- If either reference cannot be read when needed, stop instead of inferring the rule from memory.
