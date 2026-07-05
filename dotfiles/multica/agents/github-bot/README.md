# GitHub Bot Agent

This directory keeps the GitHub bot prompt small by splitting reusable guidance into skills.

- `AGENT.md` is the main agent definition.
- `skills/github-multica-protocol/SKILL.md` contains shared safety, tool, output, and project rules.
- `skills/github-multica-protocol/ASSIGNEES.md` and `skills/github-multica-protocol/STATUS.md` contain assignee and status references loaded only when needed.
- `skills/issue-pr-operations/SKILL.md` covers normal issue/PR operations and new dual GitHub+Multica issue creation.
- `skills/migrate-to-multica/SKILL.md` covers migration of existing GitHub items into Multica.
- `skills/migrate-to-multica/FORMAT.md` contains mirrored title/body conventions shared by migration and sync.
- `skills/sync-activity-update/SKILL.md` covers update/sync refreshes and incremental activity summaries.
- `skills/sync-activity-update/ACTIVITY_SUMMARY.md` contains activity fetching, checkpoint, and summary formatting rules.
