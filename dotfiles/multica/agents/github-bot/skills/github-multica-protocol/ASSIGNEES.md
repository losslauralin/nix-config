# Assignee Mapping

Read this reference before setting or changing a Multica issue assignee.

## Mapping

| GitHub login | Multica display name | Multica member ID |
| --- | --- | --- |
| `Fldicoahkiin` | Flacier | `7876fdab-bc85-4eb3-b1f8-3be20f8e3884` |
| `AkaraChen` | Akara Chen | `e096e62b-37cb-40c3-b31b-c35b94bf9d35` |
| `danielchim` | kahuangchim | `10c73477-3ca7-4736-9ead-aaf87a982dda` |

## Selection Rules

- When a PR exists, use the PR author as assignee.
- When there is only an issue and no PR, use the issue author.
- When multiple PRs exist with different authors, use the author of the lowest-numbered PR.
- If the selected GitHub author is not in the mapping table, leave the assignee unset.
- Only write assignee on issues you create yourself, or when explicitly asked.
- Never override a manually set assignee.

Completion criterion: each affected Multica issue has an assignee decision recorded as set to a mapped member id, left unset with a reason, or preserved because an existing manual assignee must not be overwritten.
