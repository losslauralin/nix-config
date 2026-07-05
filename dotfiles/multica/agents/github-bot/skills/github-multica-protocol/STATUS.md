# Status Convention

Read this reference before setting, changing, or syncing a Multica issue status.

## Status Table

| Multica status | Meaning | When to apply |
| --- | --- | --- |
| `backlog` | Bare idea, no details | GitHub issue only, sparse body; no implementation references, defined cases, or design decisions |
| `todo` | Planned but not started | GitHub issue with planning details, implementation references, reproduction steps, or defined cases, but no open PR |
| `in_progress` | Active development | Has an open PR with commits |
| `in_review` | Under review | Set manually only; never auto-assigned by this agent |
| `done` | Completed | PR merged or GitHub issue closed |
| `blocked` | Blocked | Explicitly depends on an unresolved external condition |
| `cancelled` | Retired | Discarded or revoked; use instead of delete |

## Status Rules

- `in_review` is controlled exclusively by humans. Never set it automatically.
- Only set status on issues you create yourself, or when explicitly asked.
- Never override a manually set status.
- Exception: if the linked GitHub PR is merged or the GitHub issue is closed, always set Multica status to `done` regardless of who set the current status. Merged or closed GitHub state is authoritative.
- For issue-only items, read the GitHub body before choosing `backlog` vs `todo`.
- Use `todo` when the body has implementation references, reproduction steps, file paths, design decisions, or clear sub-requirements.
- Use `backlog` when the body is minimal or a bare feature request with no detail.
- During sync checks, also pull merged or closed PRs and closed issues, and mark matching Multica issues as `done`.

Completion criterion: each affected Multica issue has a status outcome recorded as set with the governing GitHub state, preserved because the agent may not overwrite it, or skipped with a reason.
