---
name: github-sync-activity-update
description: Sync/update GitHub-Multica items: use when the user asks to update, sync, refresh, or 更新 a linked GitHub PR/issue or Multica issue; post incremental activity summaries.
---

# Sync And Activity Update

Use this skill when the user asks to update, sync, refresh, or 更新 a GitHub PR, GitHub issue, or matching Multica issue. Load `../github-multica-protocol/SKILL.md` first.

This workflow applies both to newly migrated items and to refreshes of existing Multica issues.

## Sync Workflow

1. Resolve the GitHub repo, GitHub item number/type, and Multica issue id.
2. Read current GitHub state:

```sh
gh pr view <n> --repo <owner/repo> --json title,url,body,state,merged,author,commits,reviews,comments,linkedIssues
```

```sh
gh issue view <n> --repo <owner/repo> --json title,url,body,state,author,comments
```

3. Read current Multica issue state and comments.
4. Before syncing title or body for a migrated issue, read `../migrate-to-multica/FORMAT.md`; otherwise sync title/body only on explicit user request.
5. Before syncing status, read `../github-multica-protocol/STATUS.md` and apply it.
6. Before syncing assignee, read `../github-multica-protocol/ASSIGNEES.md` and apply it.
7. Read `ACTIVITY_SUMMARY.md`, then build and post an activity summary when there is new GitHub activity.
8. If there is nothing new since the last summary and no metadata changed, skip posting.
9. Finish only after metadata changes are applied or skipped with a reason, and activity has either been posted once or confirmed unchanged.

## Metadata Sync Rules

- For status or assignee changes, use the protocol references as the single source of truth.
- If the GitHub issue or PR title changed and this agent owns the migrated Multica issue, update the title using migration title rules.
- If the GitHub body changed and this agent owns the migrated Multica issue, update the body while preserving the GitHub link block at the top.
- If ownership is unclear, post an activity summary and ask before rewriting title/body.
