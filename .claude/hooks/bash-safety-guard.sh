#!/bin/bash
# bash-safety-guard.sh -- PreToolUse hook for Bash commands
# Blocks dangerous commands that slip past the deny list's glob patterns.
# Exit 0 = allow, Exit 2 = block (stderr fed back to Claude as error)
#
# Performance: array-based loop with short-circuit on first match.

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty')

# Only inspect Bash commands
[[ "$TOOL" != "Bash" ]] && exit 0

COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
[[ -z "$COMMAND" ]] && exit 0

# -- Pattern arrays --
FLAGS=(
  "-qE"   # 0: rm (all forms)
  "-qE"   # 1: find -delete
  "-qE"   # 2: file truncation
  "-qE"   # 3: privilege escalation
  "-qE"   # 4: disk destruction
  "-qE"   # 5: pipe-to-shell
  "-qE"   # 6: network exfiltration
  "-qE"   # 7: protected paths
  "-qE"   # 8: .env overwrite
  "-qE"   # 9: git force push
  "-qE"   # 10: destructive git ops
  "-qE"   # 11: process manipulation
  "-qE"   # 12: broad git staging
)

PATTERNS=(
  # 0: rm in command position (after ^, ;, &, |) -- avoids false positives in strings
  '(^|[;&|])\s*rm\b'
  # 1: find -delete or find -exec rm
  '\bfind\b.*(-delete|-exec\s+rm)'
  # 2: file truncation via redirect to absolute path
  '^\s*>\s*/|;\s*>\s*/|\|\s*>\s*/'
  # 3: sudo/doas
  '\bsudo\b|\bdoas\b'
  # 4: mkfs, dd of=, fdisk, parted, diskutil erase
  '\b(mkfs|dd\b.*of=|fdisk|parted|diskutil\s+erase)'
  # 5: curl/wget piped to shell
  '(curl|wget|fetch)\s.*\|\s*(bash|sh|zsh|source)'
  # 6: curl/wget uploading local files
  '(curl|wget)\s.*(-d\s*@|-F\s.*=@|--data-binary\s*@|--upload-file)'
  # 7: writes to system directories
  '(mv|cp|ln|chmod|chown)\s.*\s/(etc|usr|System|Library)/'
  # 8: redirect overwriting .env files
  '[12]?>>?\s*\S*\.env\b'
  # 9: git force push
  '\bgit\b.*\bpush\b.*(-f\b|--force-with-lease)'
  # 10: git checkout ., restore ., clean -f
  '\bgit\b.*(checkout\s+\.\s*$|restore\s+\.\s*$|clean\s+-[a-zA-Z]*f)'
  # 11: kill -9 1, killall, shutdown, reboot, halt
  '\b(kill\s+-9\s+1\b|killall|shutdown|reboot|halt)\b'
  # 12: broad git staging (git add . or git add -A)
  '\bgit\b\s+add\s+(-A\b|\.(\s|$))'
)

MESSAGES=(
  "BLOCKED: rm is not permitted. Use mv <target> ~/.Trash/ instead."
  "BLOCKED: find with -delete or -exec rm is destructive. List files first with find alone."
  "BLOCKED: file truncation via redirect to absolute path."
  "BLOCKED: privilege escalation (sudo/doas) not permitted."
  "BLOCKED: disk/filesystem modification not permitted."
  "BLOCKED: piping remote content to shell is not permitted."
  "BLOCKED: uploading local files via curl/wget. Ask user first."
  "BLOCKED: modification of system directories not permitted."
  "BLOCKED: overwriting .env files via redirect. Use Edit tool instead."
  "BLOCKED: force push detected. Only regular push is permitted."
  "BLOCKED: destructive git operation (checkout ., restore ., clean -f). Too broad -- specify files."
  "BLOCKED: system process/power management not permitted."
  "BLOCKED: broad git staging (git add . / git add -A). Stage specific files instead."
)

# -- Short-circuit loop: exit on first match --
for i in "${!PATTERNS[@]}"; do
  if echo "$COMMAND" | grep ${FLAGS[$i]} "${PATTERNS[$i]}"; then
    echo "${MESSAGES[$i]}" >&2
    exit 2
  fi
done

# -- Passed all checks --
exit 0
