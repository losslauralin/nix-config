---
name: repo-flow
description: Repo flow for git/GitHub work. Use when the user wants branchable development, issue/PR work, push/PR/review/merge/cleanup, or origin/upstream base and target choices.
---

# Repo Flow

Repo flow makes git side effects predictable by separating four facts:

- **base**: where the work branch starts.
- **target**: where completed work lands.
- **consent**: the user's explicit permission for public or destructive side effects.
- **mainline**: `origin/main` or `origin/master`, used only for cleanup decisions.

`origin` is the ordinary base and target. `upstream` may be a read source, but is never a write target unless the user explicitly asks for an upstream operation.

## Steps

1. Resolve mode and consent. Identify whether the request is local work, issue work, PR work, review handling, push, merge, or cleanup. If given an issue or PR number/URL, read it with `gh` before editing. Completion: requested side effects are known, and push/PR/comment/review/merge/cleanup/upstream-write consent is explicit or the next action is a user question.
2. Inspect repo state. Run `git status --short --branch`, identify branch/upstream/remotes, and read repo-local instructions such as `AGENTS.md`, `CONTRIBUTING.md`, or PR templates when relevant. If unrelated local changes exist, stop before switching, staging, or committing. Completion: branch state, local changes, remotes, and relevant repo instructions are known.
3. Choose the base and branch. Small local edits can stay on the current branch. Feature-sized, risky, user-facing, or merge-bound work starts a branch from an up-to-date `origin/<default>` or user-named `origin/<branch>`. Fetch from `upstream` only as a source when needed. Completion: the current branch is intentionally used, or a feature branch exists at a fresh `origin/*` base.
4. Do scoped work and validation. Make only task-specific changes, follow repo conventions, and run targeted checks that match the change. For review handling, fix required findings unless factually wrong, fix recommended findings when clearly in scope, and ask before optional or context-dependent churn. Completion: intended files changed, review findings accounted for when present, and validation result or skipped-validation reason is known.
5. Commit and push only with consent. Review the diff, stage only intended files, commit with a concise outcome message, and push the work branch to `origin` when requested or clearly part of the requested flow. Multi-line issue/PR/comment bodies go through a temp markdown file and `gh ... --body-file`, never shell-escaped `\n` strings. Completion: committed/pushed side effects match consent, and no unrelated local changes were included.
6. Create, update, or review PRs only with consent. A PR body should state summary, validation, issue link (`Closes` only for full resolution; `Refs` for partial/related work), and useful risks or follow-ups. Request review only when asked. Completion: the PR/comment link is returned, or an unresolved base/target/review question is asked.
7. Merge and clean up through the table. Before any autonomous merge, verify CI exists and is passing through repo-defined local checks or remote status; if CI is absent, unknown, or failing, ask. Clean up branches only after a confirmed merge into mainline. Completion: merge/cleanup happens only when the table allows it and CI passed, otherwise the next action is a user question.

## Autonomous Merge Table

| Repo shape | Target | Agent action |
|---|---|---|
| Single-person project | Any `origin` branch | Autonomous merge/push when CI passed |
| Multi-person same repo | Protected branch such as `main` or `dev` | Do not merge; ask whether to open a PR |
| Multi-person same repo | Personal feature branch such as `feat/*` | Autonomous merge when CI passed |
| Fork mode | Local fork branch on `origin` | Autonomous merge when CI passed |
| Fork mode | Cross-repo target on `upstream` | Do not PR, merge, push, or clean up; ask first |

## Output Contract

Return the current branch, side effects performed, created or updated issue/PR/comment links, validation results or skipped-validation reason, and any user decision still needed.
