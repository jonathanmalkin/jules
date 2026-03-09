#!/usr/bin/env bash
# verify-footer-links.sh — Verify footer links navigate to correct URLs.
#
# Requires: agent-browser session on the app landing page.
#
# Usage: ./verify-footer-links.sh <app_url>
#   app_url: base URL to navigate back to between tests

set -uo pipefail

APP_URL="${1:?Usage: verify-footer-links.sh <app_url>}"
FAILURES=0

pass() { echo "  PASS: $1"; }
fail() { echo "  FAIL: $1"; FAILURES=$((FAILURES + 1)); }

echo "=== Footer Links Verification ==="

declare -A EXPECTED_URLS=(
    ["Privacy Policy"]="https://example.com/privacy-policy"
    ["Terms of Service"]="https://example.com/terms-of-service"
)

# Links have target="_blank" — check href attributes via JS instead of clicking
# This avoids opening new tabs that agent-browser can't track
for LINK_TEXT in "Privacy Policy" "Terms of Service"; do
    EXPECTED="${EXPECTED_URLS[$LINK_TEXT]}"

    RAW_URL=$(agent-browser eval "Array.from(document.querySelectorAll('a')).find(a => a.textContent.trim() === '$LINK_TEXT')?.href || 'NOT_FOUND'" 2>/dev/null)
    # Strip quotes from eval output and trailing slash
    ACTUAL_URL=$(echo "$RAW_URL" | tr -d '"' | sed 's:/$::')

    if [ "$ACTUAL_URL" = "$EXPECTED" ]; then
        pass "$LINK_TEXT -> $ACTUAL_URL"
    elif [ "$ACTUAL_URL" = "NOT_FOUND" ]; then
        fail "$LINK_TEXT link not found in DOM"
    else
        fail "$LINK_TEXT expected $EXPECTED, got $ACTUAL_URL"
    fi
done

echo ""
if [ "$FAILURES" -eq 0 ]; then
    echo "ALL PASSED"
    exit 0
else
    echo "$FAILURES FAILURE(S)"
    exit 1
fi
