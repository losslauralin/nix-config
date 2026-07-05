# Activity Summary

Read this reference before deciding whether to post a PR or issue activity summary.

## Fetching Activity

For PRs, fetch all activity:

```sh
gh pr view <n> --repo <owner/repo> --json commits,reviews,comments
```

For issue-only items, fetch comments:

```sh
gh issue view <n> --repo <owner/repo> --json comments
```

Check existing Multica comments to identify what has already been summarized:

```sh
multica issue comment list <issue-id> --output json
```

Look for a prior `Activity Summary` or `Activity Update` comment posted by this agent. If one exists, identify the latest commit SHA and latest comment/review timestamp it covered. Only include items newer than that checkpoint. This is an incremental update, not a full re-summary.

If there is no prior activity summary, cover everything.

## Summary Format

Write the summary to a temp markdown file and post it with `--content-file`.

First summary heading:

```markdown
## Activity Summary
```

Incremental update heading:

```markdown
## Activity Update - <YYYY-MM-DD>
```

Use this structure:

```markdown
## Activity Summary

### Commits

| Commit | Message |
| --- | --- |
| [`abc1234`](https://github.com/owner/repo/commit/abc1234...) | Message headline |

### Reviews

- Reviewer: APPROVED / CHANGES_REQUESTED / COMMENTED
  - Actionable finding with file:line link when available.

### Comments

- Commenter at <timestamp>: concise summary with GitHub link.

### Summary

Two to four sentences synthesizing what is new and what review feedback remains outstanding.
```

Keep the final summary concise and source-linked. Do not paste large review templates.

## Activity Rules

- Always link commit SHAs to original GitHub commit URLs.
- Always link review findings to original GitHub URLs when available.
- Include only commits not covered by a prior summary.
- Include only reviews not covered by a prior summary.
- Include only comments not covered by a prior summary.
- Skip bot reviews with no real findings, such as empty bodies or generic template output.
- If a bot review such as CodeRabbit or Codex has no actionable findings, note one line: `No actionable findings`.
- Include non-bot comments and meaningful bot comments, especially Codex P2+ findings.
- If there is nothing new since the last summary, skip posting entirely.
- Post one summary comment per update run, not one per commit or review.

Completion criterion: every fetched commit, review, and comment is either included because it is newer than the checkpoint or excluded with the checkpoint/no-actionable-finding reason, and at most one Multica summary comment is posted.