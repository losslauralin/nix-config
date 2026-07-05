---
name: github-issue-pr-operations
description: Issue/PR operations for GitHub-Multica work: use for non-migration issue/PR edits, metadata changes, PR-to-Multica links, and new dual GitHub+Multica issues.
---

# GitHub Issue And PR Operations

Use this skill for issue/PR work that is not migration and not an activity update. Load `../github-multica-protocol/SKILL.md` first.

## Workflow

1. Resolve the target repo and items. If the user gives a number, URL, or vague repo name, read enough with `gh` to identify the exact `owner/repo` and item type.
2. Read current state before any write:
   - `gh issue view <n> --repo <owner/repo> --json title,url,state,body,author,labels,assignees,comments`
   - `gh pr view <n> --repo <owner/repo> --json title,url,state,merged,body,author,commits,reviews,comments,linkedIssues`
   - Use `multica issue ...` commands to read the matching Multica issue when one exists.
3. State the write target and affected items. For destructive or bulk actions, preview exact commands and wait for confirmation.
4. Apply the requested GitHub operation with `gh`. Use `gh api` only if `gh` lacks a direct command.
5. Apply the corresponding Multica operation when the item is linked, mirrored, or the request affects both sides.
6. Post the final result to the relevant Multica issue with `multica issue comment add` when a Multica issue exists or was created.
7. Report command results as a table or linked list.
8. Finish only after every affected GitHub and Multica item has an outcome: changed, unchanged, skipped with reason, or awaiting confirmation.

## Creating New Issues From This Workspace

When a new issue originates from this workspace, such as a bug or feature reported in chat, and it is not migrating an existing GitHub item, create it on both GitHub and Multica by default.

Steps:

1. Create the GitHub issue first so its number exists:

```sh
gh issue create --repo <owner/repo> --title <title> --body-file <file>
```

2. Create or update the matching Multica issue, bound to the Multica project for that repo.
3. Prefix the Multica title with the GitHub number:

```text
#<github-number> <title>
```

4. Put the GitHub issue link at the top of the Multica body as a markdown hyperlink:

```markdown
[#<number> <original title>](https://github.com/owner/repo/issues/<number>)
```

5. Below that link, include the issue body exactly as authored for the GitHub issue.
6. Before setting an assignee, read `../github-multica-protocol/ASSIGNEES.md` and apply it.
7. Before setting initial status, read `../github-multica-protocol/STATUS.md` and apply it.
8. On later edits to title or body, keep both sides in sync unless the user explicitly asks to update only one side.
9. On later status or assignee edits, use the protocol references instead of creation defaults.

If the user says "add an issue" without naming a side, dual creation is the default.

## Editing Existing Items

- Read both GitHub and Multica state before editing when a Multica link exists.
- Preserve user-authored body text unless the task explicitly asks to rewrite it.
- For labels, assignees, milestones, and projects, list current metadata before applying changes.
- For status or assignee changes, read the protocol reference file before writing.
- For close/cancel/delete/merge or bulk edit, preview exact commands and wait.
- Do not delete Multica issues by default. Use `cancelled` only when retiring an obsolete item.

## Linking PRs To Multica Issues

When linking a PR to a Multica issue:

1. Read PR title, URL, author, state, merged state, linked GitHub issues, commits, reviews, and comments.
2. Read the target Multica issue title, status, body, assignee, and comments.
3. Add or update references in Multica without discarding existing body content.
4. Use `../github-multica-protocol/STATUS.md` before changing status.
5. Use `../github-multica-protocol/ASSIGNEES.md` before changing assignee.
6. Add a concise Multica comment with PR link, state, and any status/assignee changes.
