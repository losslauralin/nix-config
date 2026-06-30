# Migration Format

Read this reference before creating or refreshing a Multica title/body that mirrors GitHub source material.

## Title Rules

Format:

```text
#<number> <original title>
```

If an item has both an issue and its fixing PR, or multiple linked PRs, prefix every relevant number in ascending order:

```text
#236 #261 <title>
#229 #249 <title>
```

Title preservation rules:

- Use the original title verbatim and preserve language.
- English stays English; Chinese stays Chinese.
- Keep Conventional Commits prefixes exactly as in the original, including `feat`, `fix`, `fix(api)`, and `refactor`.
- Only trim or simplify when a title is too long. Keep the result concise and language-preserving.

## Body Rules

Put GitHub links at the very top, one per line, as markdown hyperlinks. The visible text must be `#<number> <original title>` and the target must be the GitHub URL.

Example:

```markdown
[#261 fix(desktop): render UI before telemetry init](https://github.com/owner/repo/pull/261)
[#236 Original issue title](https://github.com/owner/repo/issues/236)
```

Below the links, reproduce the original GitHub issue or PR body verbatim:

- Fetch the original text with `gh`.
- Do not summarize.
- Do not reword.
- Do not translate.
- Do not normalize markdown except as needed to combine links above the original body.

For an item that has both a PR and an issue, link both at the top, one line each. Use the issue body as the primary body unless the user explicitly asks for PR body content instead; if the issue body is empty and the PR body has meaningful detail, preserve the PR body verbatim below the links.

Completion criterion: each mirrored Multica issue has a title and body that account for every linked GitHub source, preserve the selected original body verbatim, and keep the GitHub link block at the top.