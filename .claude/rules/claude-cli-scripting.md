---
paths:
  - "**/scripts/**"
  - "**/*.sh"
---

# Claude CLI Scripting (`claude -p`)

When building shell scripts that call `claude -p` (pipe mode):

## Environment
- `unset CLAUDECODE` before the call -- Claude Code sets this env var to block nested sessions
- `unset ANTHROPIC_API_KEY` if using Max subscription (not API billing)

## Prompt control
- Use `--system-prompt "$(cat prompt.md)"` to **replace** the entire system prompt
- Do NOT use `--append-system-prompt-file` -- it appends to Claude Code's default system prompt, which includes conversational instructions that contaminate raw output
- Add `--tools ""` to disable all tools (forces pure text generation)
- Add `--strict-mcp-config` -- prevents MCP server zombie children that block `$()` indefinitely. Required for all headless/scripted calls.
- Add `--max-turns 1` to prevent multi-turn loops
- Add `--output-format text` for raw output without JSON wrapping

## Known Issues
- **`claude -p` swallows Bash tool output** -- when called as a subprocess, Bash tool shows empty output. Workaround: redirect to a file (`> /tmp/output.txt 2>&1`) and Read the file after.
- **`run_claude_with_timeout` stdin bug** -- `&` inside `$()` disconnects stdin. Fix: save stdin to temp file before backgrounding, redirect explicitly.

## Input handling
- For large inputs, write to a temp file and pipe via stdin (`< "$INPUT_FILE"`)
- Shell argument length limits will reject large positional arguments
- Prepend an instruction header to the input file telling Claude exactly what format to output
