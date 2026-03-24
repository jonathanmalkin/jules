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
- Add `--strict-mcp-config` -- prevents MCP server zombie children that block `$()` indefinitely. Required for all headless/scripted calls. (This is a scripting-layer guard -- the container-level zombie defense is `tini` as PID 1. See `rules/cron-status.md` Container Process Management.)
- Add `--max-turns 1` to prevent multi-turn loops
- Add `--output-format text` for raw output without JSON wrapping

## Known Issues
- **Slash commands don't work in `-p` mode.** `/engage`, `/wrap-up`, etc. return "Unknown skill." Skills are interactive-mode-only. Use natural language prompts instead.
- **`claude -p` swallows Bash tool output** -- when called as a subprocess, Bash tool shows empty output. Workaround: redirect to a file (`> /tmp/output.txt 2>&1`) and Read the file after.
- **Empty output on large stdin** -- inputs exceeding ~7000 chars can produce empty output (exit 0, no error). Workaround: write to temp file, reference path in a short prompt.
- **`run_claude_with_timeout` stdin bug** -- `&` inside `$()` disconnects stdin. Fix: save stdin to temp file before backgrounding, redirect explicitly.
- **`--output-format stream-json` requires `--verbose`.** Without it, claude -p exits with: `"When using --print, --output-format=stream-json requires --verbose"`. Always pair them: `--output-format stream-json --verbose`.
- **`--output-format text` silently drops output when session ends on a tool call.** With tools enabled, if the LLM's final turn is a tool call instead of text, stdout is completely empty (exit 0, no error). Fix: always add `--verbose` when tools are available. For pure text generation, also add `--tools "" --strict-mcp-config` to prevent tool calls entirely. Pattern: `claude -p --output-format text --verbose --tools "" --strict-mcp-config`.

## Shell Scripting Gotchas (bash/macOS vs Linux)

- **`grep` exits 1 on no match under `set -e`.** Any `VAR=$(grep ...)` call kills the script when the pattern isn't found. Always append `|| true`: `VAR=$(grep -E 'pattern' file 2>/dev/null || true)`.
- **`stat` is not cross-platform.** macOS: `stat -f %m file` (modification time as epoch). Linux: `stat -c %Y file`. Safe cross-platform form: `stat -c %Y "$f" 2>/dev/null || stat -f %m "$f" 2>/dev/null || date +%s`.
- **`wc -c` returns leading whitespace on macOS.** APIs expecting a bare integer will reject `" 8092"`. Always strip: `wc -c < "$file" | tr -d ' '`.
- **`grep` treats `--`-prefixed patterns as flags on macOS.** Any pattern starting with `--` (e.g., `-----BEGIN...`) causes `grep: invalid option`. Fix: include `--` before the pattern variable: `grep -qE -- "$pattern"`. Safe on both GNU and BSD grep.
- **`source .env` doesn't export to child processes.** `source` sets variables in the current shell without `export`. Child scripts called via `bash "$script"` don't inherit them. Fix: either `export VAR` after sourcing, or have each child script source the env file itself -- self-contained is cleaner.
- **Stale env vars survive re-sourcing.** Re-sourcing a file doesn't unset variables already in the environment. To test after a key change: `unset VARNAME && source ~/.env.file`.
- **`mktemp -d` breaks resume logic.** Random temp dirs are lost on restart. For scripts with multi-run resume support, use a stable date-scoped path: `WORK_DIR="/tmp/script-name-$(date +%Y-%m-%d)"`.

## Subagent Context Drift

Agents spawned via `claude -p` or the Agent tool start with a clean context. They don't inherit the parent session's conversation history, tool results, or accumulated understanding. This causes drift:

- **Stale assumptions:** Agent uses training-data knowledge instead of what was just discovered in the parent session. Fix: include all relevant findings in the agent's prompt, not just a summary.
- **Repeated work:** Agent re-researches what the parent already knows. Fix: pass research results as context in the prompt, or write findings to a temp file the agent reads.
- **Style/convention drift:** Agent doesn't follow project conventions unless its prompt includes them. Fix: for long-running agents, include key conventions or reference CLAUDE.md explicitly.
- **Tool discovery overhead:** Agent doesn't know which tools are available until it tries them. Deferred tools (ENABLE_TOOL_SEARCH) fire fresh per-agent. Fix: for short tasks, specify the exact tool in the prompt ("use Grep to find X") rather than letting the agent discover.

**Rule of thumb:** The more context an agent needs to get right, the more you should include in its prompt. One-shot research queries need minimal context. Multi-file edit tasks need full specifications.

## Autonomous Script Safeguards

Scripts that run unattended (`claude -p` in cron, dispatch, or Slack daemon) need defensive patterns:

1. **Always set `--max-turns`** -- prevents infinite loops. Use `--max-turns 1` for pure generation, `--max-turns 5-10` for tool-using tasks.
2. **Always set timeout** -- `timeout 300 claude -p ...` (5 min default). Long tasks get explicit higher limits.
3. **Check exit codes** -- `claude -p` can exit 0 with empty output (see Known Issues). Validate output exists: `[ -s "$OUTPUT_FILE" ] || echo "FAIL: empty output"`.
4. **Lock files for exclusive tasks** -- prevent overlapping runs: `flock -n /tmp/task.lock -c "claude -p ..."`.
5. **Structured output validation** -- when expecting JSON, validate with `jq . "$OUTPUT_FILE" > /dev/null 2>&1` before processing.
6. **Log everything** -- redirect stderr: `claude -p ... 2>> "$LOG_FILE"`. Include timestamps: `echo "[$(date -Iseconds)] Starting task" >> "$LOG_FILE"`.
7. **Auth pre-check** -- source `auth-check.sh` before any `claude -p` call. Exit early if auth is broken rather than burning time on a call that will fail.
8. **Temp file cleanup** -- use `trap 'rm -f "$TMPFILE"' EXIT` for temp files. Or use stable paths with date stamps for resume support.

## SSH Non-Interactive PATH

When running commands over SSH (`ssh your-vps "command"`), the remote shell is non-interactive. This means:

- **`.bashrc` is NOT sourced** (it guards with `[ -z "$PS1" ] && return`)
- **`.bash_profile` is NOT sourced** (only for login shells)
- **PATH is minimal:** typically `/usr/bin:/bin:/usr/sbin:/sbin`
- **Tools installed via `apt` are available** (`/usr/bin/`)
- **Tools installed per-user (pip, npm global, cargo)** may NOT be on PATH

**Workarounds:**
```bash
# Option 1: Use full paths
ssh your-vps "/usr/local/bin/node script.js"

# Option 2: Source profile explicitly
ssh your-vps "source ~/.profile && command"

# Option 3: For docker exec (most common in the container setup)
ssh your-vps "docker exec --user claude your-agent-dev bash -c 'source /tmp/agent-secrets.env && command'"
```

**In the container setup:** Most SSH commands target `docker exec --user claude your-agent-dev`, which inherits the container's env from `entrypoint.sh`. PATH issues are rare inside the container because env vars are set at startup. They're more likely on the VPS host itself.

## Additional Bash Gotchas

- **`set -e` + process substitution** -- `while read line; do ...; done < <(command)` does NOT propagate errors from `command` under `set -e`. The subshell runs independently. Fix: capture output first: `output=$(command)` (this WILL fail under `set -e`), then process it.
- **Heredoc quoting matters** -- `cat << 'EOF'` (quoted) = no variable expansion. `cat << EOF` (unquoted) = variables expand. Use quoted for template content that contains `$` characters.
- **`local` masks exit codes** -- `local VAR=$(failing_command)` always succeeds because `local` returns 0. Fix: declare first, then assign: `local VAR; VAR=$(failing_command)`.
- **Array gotchas in bash 3 (macOS default)** -- associative arrays (`declare -A`) require bash 4+. macOS ships bash 3.2. Either `brew install bash` or use plain variables/files.
- **`read` strips leading/trailing whitespace** -- `IFS= read -r line` preserves it. Always use `-r` to prevent backslash interpretation.
- **Subshell variable scope** -- pipes create subshells: `echo "x" | while read line; do VAR=$line; done` -- `$VAR` is empty after the loop. Fix: use process substitution or `<<<` instead.

## Input handling
- For large inputs, write to a temp file and pipe via stdin (`< "$INPUT_FILE"`)
- Shell argument length limits will reject large positional arguments
- Prepend an instruction header to the input file telling Claude exactly what format to output
