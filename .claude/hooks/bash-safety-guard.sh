#!/bin/bash
# bash-safety-guard.sh — PreToolUse hook for Bash commands
# Blocks dangerous commands that slip past the deny list's glob patterns.
# Exit 0 = allow, Exit 2 = block (stderr fed back to Claude as error)
#
# Performance: array-based loop with short-circuit on first match.
# Original had 15 separate echo|grep calls (~30 subprocesses per Bash call).
# This version: 16 patterns, exits on first hit.

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty')

# ── Container-specific: Read tool path protection ─────────────────────
# Blocks Read tool access to credentials — fires only inside Docker (/.dockerenv)
if [ -f "/.dockerenv" ] && [[ "$TOOL" == "Read" ]]; then
  FILEPATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
  if [[ -n "$FILEPATH" ]] && echo "$FILEPATH" | grep -qE '(\.ssh/id_|\.env\.jules|\.claude/.*(credential|token|auth))'; then
    echo "BLOCKED [container]: direct read of sensitive credential path not permitted inside container." >&2
    exit 2
  fi
fi

# Only inspect Bash commands beyond this point
[[ "$TOOL" != "Bash" ]] && exit 0

COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
[[ -z "$COMMAND" ]] && exit 0

# Strip git commit message from pattern matching — keywords inside -m "..." are not executable
# e.g. "git commit -m 'fix: remove sudo calls'" should not trigger the sudo block
COMMAND_FOR_MATCHING=$(echo "$COMMAND" | sed "s/git commit.*-m ['\"][^'\"]*['\"]//g")

# ── Pattern arrays ────────────────────────────────────────────────
# FLAGS: -qE = case-sensitive extended regex
# Pattern 0 uses command-position matching to avoid false positives in strings

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
  "-qE"   # 12: git push to production
  "-qE"   # 13: gh workflow run production
  "-qE"   # 14: destructive SSH to your-hosting-provider
  "-qE"   # 15: broad git staging
)

PATTERNS=(
  # 0: rm in command position (after ^, ;, &, |) — avoids false positives in strings
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
  # 8: redirect overwriting .env files (require .env as direct redirect target)
  '[12]?>>?\s*\S*\.env\b'
  # 9: git force push
  '\bgit\b.*\bpush\b.*(-f\b|--force-with-lease)'
  # 10: git checkout ., restore ., clean -f
  '\bgit\b.*(checkout\s+\.\s*$|restore\s+\.\s*$|clean\s+-[a-zA-Z]*f)'
  # 11: kill -9 1, killall, shutdown, reboot, halt
  '\b(kill\s+-9\s+1\b|killall|shutdown|reboot|halt)\b'
  # 12: git push to production branch
  '\bgit\b.*\bpush\b.*(:production\b|origin\s+production\b)'
  # 13: gh workflow run with production environment
  '\bgh\b.*\bworkflow\b.*\brun\b.*environment=production'
  # 14: destructive SSH commands on your-hosting-provider (cp allowed — not destructive)
  '\bssh\b.*\byour-hosting-provider\b.*\b(rm|mv)\b'
  # 15: broad git staging (git add . or git add -A)
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
  "BLOCKED: destructive git operation (checkout ., restore ., clean -f). Too broad — specify files."
  "BLOCKED: system process/power management not permitted."
  "BLOCKED: production deploy detected. Run the command in a separate terminal, or tell Jules to proceed after explicit approval."
  "BLOCKED: production deploy via GitHub Actions detected. Run the command in a separate terminal, or tell Jules to proceed after explicit approval."
  "BLOCKED: destructive SSH command on your-hosting-provider. Give the user the exact command to run in their terminal."
  "BLOCKED: broad git staging (git add . / git add -A). Stage specific files instead."
)

# ── Short-circuit loop: exit on first match ───────────────────────
for i in "${!PATTERNS[@]}"; do
  if echo "$COMMAND_FOR_MATCHING" | grep ${FLAGS[$i]} "${PATTERNS[$i]}"; then
    echo "${MESSAGES[$i]}" >&2
    exit 2
  fi
done

# ── Layer 3: Secrets / credential detection ──────────────────────────
# Catches hardcoded credentials appearing literally in command strings.
# Note: `cat ~/.aws/credentials` contains no key literal — it passes.
# Note: COMMAND_FOR_MATCHING used (git commit messages already stripped).

SECRET_PATTERNS=(
  'AKIA[0-9A-Z]{16}|ASIA[0-9A-Z]{16}'
  'ghp_[0-9a-zA-Z]{36}'
  'github_pat_[a-zA-Z0-9_]{82}'
  'sk-ant-api03-[a-zA-Z0-9_\-]{93}AA'
  'sk-[a-zA-Z0-9]{20}T3BlbkFJ[a-zA-Z0-9]{20}'
  '-----BEGIN[ A-Z0-9_\-]{0,100}PRIVATE KEY'
)

SECRET_MESSAGES=(
  "BLOCKED: AWS access key literal in command. Use env vars or ~/.aws/credentials."
  "BLOCKED: GitHub PAT literal in command. Use gh auth login or GITHUB_TOKEN env var."
  "BLOCKED: GitHub fine-grained PAT literal in command. Use GITHUB_TOKEN env var."
  "BLOCKED: Anthropic API key literal in command. Use ANTHROPIC_API_KEY env var."
  "BLOCKED: OpenAI API key literal in command. Use OPENAI_API_KEY env var."
  "BLOCKED: Private key material in command. Do not embed key content in shell commands."
)

for i in "${!SECRET_PATTERNS[@]}"; do
  if echo "$COMMAND_FOR_MATCHING" | grep -qE -- "${SECRET_PATTERNS[$i]}"; then
    echo "${SECRET_MESSAGES[$i]}" >&2
    exit 2
  fi
done

# ── Container-specific Bash restrictions ──────────────────────────────
# Additional blocks for autonomous Claude inside Docker — fires only inside container
if [ -f "/.dockerenv" ]; then
  CPATTERNS=(
    # SSH private key reads via shell commands
    '(cat|head|tail|less|more|strings|grep)\s.*(\.ssh/id_|_rsa|_ecdsa|_ed25519)\b'
    # .env.jules reads via shell
    '(cat|head|tail|less|more)\s.*\.env\.jules\b'
    # Claude credential reads via shell
    '(cat|head|tail|less|more)\s.*\.claude/.*(credential|token|auth)'
    # Outbound curl/wget data upload or POST body (exfil pattern)
    '(curl|wget)\s.*((-X\s*(POST|PUT))|(-d\s)|(--data\b)|(--upload-file\b))'
    # Netcat/socat outbound connections (covert channel)
    '\b(nc|ncat|netcat|socat)\b'
    # scp/rsync to external hosts
    '\b(scp|rsync)\b.*@[a-zA-Z0-9.-]+:'
    # su / pkexec privilege escalation (sudo already blocked by main patterns)
    '\b(su|pkexec)\s'
  )
  CMESSAGES=(
    "BLOCKED [container]: SSH private key reads via shell not permitted inside container."
    "BLOCKED [container]: .env.jules reads via shell not permitted inside container."
    "BLOCKED [container]: credential file reads via shell not permitted inside container."
    "BLOCKED [container]: outbound data upload via curl/wget not permitted inside container."
    "BLOCKED [container]: netcat/socat connections not permitted inside container."
    "BLOCKED [container]: scp/rsync to external hosts not permitted inside container."
    "BLOCKED [container]: su/pkexec privilege escalation not permitted inside container."
  )
  for i in "${!CPATTERNS[@]}"; do
    if echo "$COMMAND" | grep -qE "${CPATTERNS[$i]}"; then
      echo "${CMESSAGES[$i]}" >&2
      exit 2
    fi
  done
fi

# ── Passed all checks ────────────────────────────────────────────
exit 0
