---
name: github-migrate-to-multica
description: Migrate existing GitHub issues or PRs into Multica with skip rules, exact title/body preservation, project binding, assignee/status references, and source-to-target output.
---

# Migrate GitHub Items To Multica

Use this skill when existing GitHub issues or PRs need to become Multica issues. Load `../github-multica-protocol/SKILL.md` first.

## Skip Rules

Skip these GitHub items during migration unless the user explicitly overrides the rule:

- Closed PRs.
- Merged PRs.
- Dependency-update PRs, including deps/dependency bot PRs.

Closed GitHub issues are not skipped by this rule, but their Multica status must be `done`.

## Workflow

1. Resolve the exact `owner/repo`, item numbers, item types, and Multica project id.
2. Read each GitHub item with `gh` before creating anything:

```sh
gh issue view <n> --repo <owner/repo> --json title,url,body,state,author,closed
```

```sh
gh pr view <n> --repo <owner/repo> --json title,url,body,state,merged,author,commits,linkedIssues
```

3. Detect issue/PR pairs. If an issue has a fixing PR or multiple linked PRs, migrate them into one Multica issue when that represents one work item.
4. Apply skip rules and show skipped items with reasons.
5. Read `FORMAT.md`, then build the Multica title and body from every non-skipped source.
6. Create the Multica issue with project binding, after reading the assignee and status references when those fields are needed.
7. For newly migrated PRs or migrated refreshes, run the activity summary workflow from `../sync-activity-update/SKILL.md`.
8. Post final results via `multica issue comment add` and include a source -> target mapping table.
9. Finish only after every requested GitHub source appears in the mapping table as created, updated, already-linked, or skipped with a reason.

## Status And Assignee

- Before choosing assignee, read `../github-multica-protocol/ASSIGNEES.md`.
- Before choosing status, read `../github-multica-protocol/STATUS.md`.
- Pass all linked issue and PR authors, states, and commit presence into those references so their selection rules can be applied.
- Record the chosen project, assignee decision, and status outcome in the migration result.

## Migration Output

Use a source -> target mapping table like this:

| Source | Multica target | Status | Notes |
| --- | --- | --- | --- |
| `owner/repo#261` | `[MUL-123](mention://issue/<id>)` | `in_progress` | Created |
| `owner/repo#104` | skipped | - | Merged PR |

Post this mapping to the relevant Multica issue or project-level issue/comment target requested by the user. If there is no Multica destination for final reporting, return the table in the chat and mention that no Multica comment target was available.
