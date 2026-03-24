#!/bin/bash
# x-webfetch-guard.sh — PreToolUse hook for WebFetch
# Blocks WebFetch calls to x.com and twitter.com domains.
# Exit 0 = allow, Exit 2 = block (stderr fed back to Claude as error)

INPUT=$(cat)
URL=$(echo "$INPUT" | jq -r '.tool_input.url // empty')

[[ -z "$URL" ]] && exit 0

# Anchored domain matching: catch x.com, twitter.com, and subdomains
# Avoids false positives on flex.com, next.com, etc.
if echo "$URL" | grep -qEi '(^https?://(www\.)?(x\.com|twitter\.com)|://(mobile|m)\.(x\.com|twitter\.com))'; then
  cat >&2 <<'EOF'
BLOCKED: WebFetch to x.com/twitter.com returns login walls. Use X API instead:
- Read tweet by ID: curl with Bearer Token (see .claude/rules/x-api.md for template)
- Post tweet: bash Scripts/x-post.sh "text" or --file /tmp/tweet.txt
- FAQ search: bash Scripts/x-search-faq.sh
- Full reference: .claude/rules/x-api.md
EOF
  exit 2
fi

exit 0
