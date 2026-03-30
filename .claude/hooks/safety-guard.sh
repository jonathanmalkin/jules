#!/bin/bash
# safety-guard.sh — Unified security, privacy, and domain guard (PreToolUse hook)
#
# Four sections:
#   1. Command blocking   — dangerous Bash patterns (rm, sudo, force-push, etc.)
#   2. Secret scanning     — credential literals in command strings
#   3. Financial guard     — blocks outbound content with financial data after sensitive reads
#   4. Domain blocking     — blocks WebFetch to login-walled domains (x.com, twitter.com)
#
# Exit 0 = allow, Exit 2 = block (stderr fed back to Claude as error)
#
# Performance: array-based loop with short-circuit on first match.

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty')

# ══════════════════════════════════════════════════════════════════════
# Section 4: Domain Blocking (WebFetch only)
# ══════════════════════════════════════════════════════════════════════
if [[ "$TOOL" == "WebFetch" ]]; then
  URL=$(echo "$INPUT" | jq -r '.tool_input.url // empty')
  [[ -z "$URL" ]] && exit 0

  # Anchored domain matching: catch x.com, twitter.com, and subdomains
  # Avoids false positives on flex.com, next.com, etc.
  if echo "$URL" | grep -qEi '(^https?://(www\.)?(x\.com|twitter\.com)|://(mobile|m)\.(x\.com|twitter\.com))'; then
    cat >&2 <<'EOF'
BLOCKED: WebFetch to x.com/twitter.com returns login walls. Use X API instead:
- Post/reply/thread: bash Scripts/x-post.sh "text" (--reply-to, --thread, --file)
- Search tweets: bash Scripts/x-search.sh
- Read a tweet by ID: curl with Bearer Token (extract ID from URL)
- Full workflow: invoke /replies skill
EOF
    exit 2
  fi

  exit 0
fi

# Only inspect Bash commands beyond this point
[[ "$TOOL" != "Bash" ]] && exit 0

COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
[[ -z "$COMMAND" ]] && exit 0

# Strip git commit message from pattern matching — keywords inside -m "..." are not executable
# e.g. "git commit -m 'fix: remove sudo calls'" should not trigger the sudo block
COMMAND_FOR_MATCHING=$(echo "$COMMAND" | sed "s/git commit.*-m ['\"][^'\"]*['\"]//g")

# ══════════════════════════════════════════════════════════════════════
# Section 1: Command Blocking
# ══════════════════════════════════════════════════════════════════════

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
  # 14: destructive SSH commands on siteground (cp allowed — not destructive)
  '\bssh\b.*\bsiteground\b.*\b(rm|mv)\b'
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
  "BLOCKED: production deploy detected. Run the command in a separate terminal, or tell [Agent Name] to proceed after explicit approval."
  "BLOCKED: production deploy via GitHub Actions detected. Run the command in a separate terminal, or tell [Agent Name] to proceed after explicit approval."
  "BLOCKED: destructive SSH command on siteground. Give the user the exact command to run in their terminal."
  "BLOCKED: broad git staging (git add . / git add -A). Stage specific files instead."
)

# Short-circuit loop: exit on first match
for i in "${!PATTERNS[@]}"; do
  if echo "$COMMAND_FOR_MATCHING" | grep -qE "${PATTERNS[$i]}"; then
    echo "${MESSAGES[$i]}" >&2
    exit 2
  fi
done

# ══════════════════════════════════════════════════════════════════════
# Section 2: Secret Scanning
# ══════════════════════════════════════════════════════════════════════
# Catches hardcoded credentials appearing literally in command strings.
# Note: `cat ~/.aws/credentials` contains no key literal — it passes.

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

# ══════════════════════════════════════════════════════════════════════
# Section 3: Financial Guard
# ══════════════════════════════════════════════════════════════════════
# Two-gate logic: only blocks when BOTH gates fire.
#   Gate 1: Was sensitive financial data read this session? (flag file)
#   Gate 2: Does the outbound content contain financial patterns?

FLAG_FILE="${CLAUDE_SENSITIVE_SESSION_FILE:-/tmp/claude-sensitive-session-$$}"
if [[ -f "$FLAG_FILE" ]]; then
  # Override: user explicitly confirmed the content is safe
  echo "$COMMAND" | grep -q '^# SAFE-OVERRIDE:' && exit 0

  # Only gate outbound Bash: clipboard writes, HTTP POSTs, X posting scripts
  if echo "$COMMAND" | grep -qE '(pbcopy|curl.*(--data|-d|-F|--upload-file)|wget.*--post|x-post\.sh|post-to-x\.py)'; then
    MATCH=""

    # Dollar amounts
    echo "$COMMAND" | grep -qE '\$[0-9,]+' && MATCH=1

    # Percentage in financial context
    if [[ -z "$MATCH" ]]; then
      echo "$COMMAND" | grep -qiE '[0-9]+%[^a-z]*\b(return|yield|rate|allocation|burn|interest|growth)\b' && MATCH=1
      echo "$COMMAND" | grep -qiE '\b(return|yield|rate|allocation|burn|interest|growth)\b[^a-z]*[0-9]+%' && MATCH=1
    fi

    # Account-related terms
    if [[ -z "$MATCH" ]]; then
      echo "$COMMAND" | grep -qiE '\b(account\s+number|routing\s+number|balance|portfolio|brokerage|checking|savings)\b' && MATCH=1
    fi

    # Specific financial terms
    if [[ -z "$MATCH" ]]; then
      echo "$COMMAND" | grep -qiE '\b(runway|burn\s+rate|net\s+worth|retirement|401k|roth|ira|dividend|drawdown|withdrawal|contribution|rebalance)\b' && MATCH=1
    fi

    # 8+ digit sequences that look like account numbers
    if [[ -z "$MATCH" ]]; then
      echo "$COMMAND" | grep -qE '\b[0-9]{8,}\b' && MATCH=1
    fi

    if [[ -n "$MATCH" ]]; then
      cat >&2 <<'EOF'
BLOCKED: Sensitive financial data was read this session.
This outbound action contains financial patterns.
Sanitize the content or confirm with: # SAFE-OVERRIDE: <command>
EOF
      exit 2
    fi
  fi
fi

# ── Passed all checks ────────────────────────────────────────────
exit 0
