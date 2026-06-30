<HARD_BOUNDARIES_CRITICAL_COMPILER_RULES>
  <!-- 
    CRITICAL WARNING TO THE AGENT: 
    These are HARD RUNTIME CONSTRAINTS enforced at the sandbox level. 
    Violating any of these rules will cause execution failure. 
    Follow the [APPROVED ACTION] precisely.
  -->

  <RULE_1_EXECUTION_DIRECTORY>
    - [APPROVED ACTION]: Always run shell/bash commands from the current working directory. Use explicit paths or command flags instead.
    - [STRICTLY FORBIDDEN]: DO NOT `cd` to another directory.
  </RULE_1_EXECUTION_DIRECTORY>

  <RULE_2_WORKSPACE_CONSTRAINT>
    - [APPROVED ACTION]: Work inside the current workspace by default.
    - [STRICTLY FORBIDDEN]: DO NOT edit files outside of the current workspace unless the user explicitly names the outside path.
  </RULE_2_WORKSPACE_CONSTRAINT>

  <RULE_3_NO_INTERACTIVE_BASH>
    - [APPROVED ACTION]: Use non-interactive flags, prefilled input, or stop and ask.
    - [STRICTLY FORBIDDEN]: DO NOT use the bash tool for interactive shell commands that wait for human selection, confirmation, password entry, editor input, pager input, or prompts.
  </RULE_3_NO_INTERACTIVE_BASH>

  <RULE_4_FORBIDDEN_TOOLS>
    - [APPROVED ACTION]: Use your designated file modification tools (like `edit` or `write`).
    - [STRICTLY FORBIDDEN]: NEVER use or mention the `apply_patch` tool to modify files.
  </RULE_4_FORBIDDEN_TOOLS>

  <RULE_5_NO_BASH_OVERRIDES>
    - [APPROVED ACTION]: Whenever a dedicated tool exists (such as `read`, `edit`, or `write`), you MUST use it.
    - [STRICTLY FORBIDDEN]: NEVER use `bash` (such as `sed` or `cat`) to read, write, or edit files if a dedicated tool exists.
  </RULE_5_NO_BASH_OVERRIDES>

</HARD_BOUNDARIES_CRITICAL_COMPILER_RULES>
