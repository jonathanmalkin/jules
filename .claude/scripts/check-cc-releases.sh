#!/usr/bin/env bash
# check-cc-releases.sh — Check latest Claude Code release from GitHub
#
# Output: JSON object with version, date, body (release notes), url
# No auth needed (public repo). Used by overnight-batch.md.
#
# Usage:
#   ./check-cc-releases.sh              # Latest release
#   ./check-cc-releases.sh --compare    # Compare to installed version

set -euo pipefail

REPO="anthropics/claude-code"
API_URL="https://api.github.com/repos/$REPO/releases/latest"

RESPONSE=$(curl -s -H "Accept: application/vnd.github+json" "$API_URL" 2>/dev/null || echo '{"error":"fetch_failed"}')

# Check for API errors
if echo "$RESPONSE" | python3 -c "import sys,json; d=json.load(sys.stdin); sys.exit(0 if 'tag_name' in d else 1)" 2>/dev/null; then
    RELEASE_JSON=$(echo "$RESPONSE" | python3 -c "
import sys, json

r = json.load(sys.stdin)
out = {
    'version': r.get('tag_name', '').lstrip('v'),
    'date': r.get('published_at', '')[:10],
    'url': r.get('html_url', ''),
    'body': r.get('body', '')[:2000]  # Cap release notes at 2K chars
}

# Compare to installed version if requested
import subprocess
try:
    installed = subprocess.run(['claude', '--version'], capture_output=True, text=True, timeout=5)
    if installed.returncode == 0:
        out['installed_version'] = installed.stdout.strip().split()[-1] if installed.stdout.strip() else 'unknown'
        out['update_available'] = out['version'] != out.get('installed_version', '')
except Exception:
    out['installed_version'] = 'unknown'
    out['update_available'] = None

print(json.dumps(out, indent=2))
")
    echo "$RELEASE_JSON"
else
    echo '{"error":"github_api_failed","message":"Could not fetch release from GitHub API"}'
    exit 1
fi
