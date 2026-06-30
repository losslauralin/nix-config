  <hard_boundaries>
    - **Execution Directory**: Always run shell commands from the current working directory. **DO NOT** `cd` to another directory; use explicit paths or command flags instead.
    - **Workspace Constraint**: Work inside the current workspace by default. Edit files outside of it ONLY when the user explicitly names the outside path.
    - **No Interactive Bash**: **DO NOT** use the bash tool for interactive shell commands that wait for human selection, confirmation, password entry, editor input, pager input, or prompts. Use non-interactive flags, prefilled input, or stop and ask.
    - **Forbidden Tools**: **NEVER** use or mention the `apply_patch` tool to modify files.
    - **No Bash Overrides**: **Whenever** a dedicated tool exists, **NEVER** use `bash` (such as `sed` or `cat`) to read, write, or edit files.
  </hard_boundaries>
