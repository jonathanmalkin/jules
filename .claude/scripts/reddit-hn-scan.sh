#!/usr/bin/env bash
# reddit-hn-scan.sh — Fetch top posts from AI subreddits + Hacker News
#
# Output: JSON array of {title, url, score, source, comments, created}
# Uses public Reddit JSON API (*.json suffix) and HN Algolia API.
# No auth needed. Used by overnight-batch.md.
#
# Usage:
#   ./reddit-hn-scan.sh           # All sources
#   ./reddit-hn-scan.sh --reddit  # Reddit only
#   ./reddit-hn-scan.sh --hn      # HN only

set -euo pipefail

UA="overnight-batch/1.0 (briefing scanner)"
REDDIT_LIMIT=5
HN_LIMIT=10

DO_REDDIT=true
DO_HN=true
for arg in "$@"; do
    case "$arg" in
        --reddit) DO_HN=false ;;
        --hn)     DO_REDDIT=false ;;
    esac
done

RESULTS="[]"

# ── Reddit ───────────────────────────────────────────────────
if $DO_REDDIT; then
    # Customize these subreddits for your interests
    SUBS="LocalLLaMA MachineLearning ClaudeCode AI_Agents openclaw"
    for sub in $SUBS; do
        REDDIT_JSON=$(curl -s -H "User-Agent: $UA" \
            "https://www.reddit.com/r/$sub/hot.json?limit=$REDDIT_LIMIT" 2>/dev/null || echo '{}')

        SUB_POSTS=$(echo "$REDDIT_JSON" | python3 -c "
import sys, json, os
sub = '$sub'
try:
    data = json.load(sys.stdin)
    posts = data.get('data', {}).get('children', [])
    results = []
    for p in posts:
        d = p.get('data', {})
        if d.get('stickied'):
            continue
        results.append({
            'title': d.get('title', '')[:200],
            'url': 'https://reddit.com' + d.get('permalink', ''),
            'score': d.get('score', 0),
            'comments': d.get('num_comments', 0),
            'source': f'r/{sub}',
            'created': d.get('created_utc', 0)
        })
    print(json.dumps(results))
except Exception:
    print('[]')
" 2>/dev/null || echo '[]')

        # Merge via temp file to avoid quoting issues
        RESULTS=$(python3 -c "
import json, sys
existing = json.loads(sys.argv[1]) if sys.argv[1] != '[]' else []
new = json.loads(sys.stdin.read())
print(json.dumps(existing + new))
" "$RESULTS" <<< "$SUB_POSTS" 2>/dev/null || echo "$RESULTS")
    done
fi

# ── Hacker News ──────────────────────────────────────────────
if $DO_HN; then
    # Search HN for AI-related stories from the last 24 hours
    SINCE_TS=$(python3 -c 'import time; print(int(time.time()-86400))')
    HN_JSON=$(curl -s "https://hn.algolia.com/api/v1/search?query=AI&tags=story&numericFilters=created_at_i%3E${SINCE_TS}&hitsPerPage=$HN_LIMIT" 2>/dev/null || echo '{}')

    HN_POSTS=$(echo "$HN_JSON" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    results = []
    for hit in data.get('hits', []):
        results.append({
            'title': hit.get('title', '')[:200],
            'url': hit.get('url') or f\"https://news.ycombinator.com/item?id={hit.get('objectID', '')}\",
            'score': hit.get('points', 0),
            'comments': hit.get('num_comments', 0),
            'source': 'HN',
            'created': hit.get('created_at_i', 0)
        })
    print(json.dumps(results))
except Exception:
    print('[]')
" 2>/dev/null || echo '[]')

    RESULTS=$(python3 -c "
import json, sys
existing = json.loads(sys.argv[1]) if sys.argv[1] != '[]' else []
new = json.loads(sys.stdin.read())
combined = existing + new
combined.sort(key=lambda x: x.get('score', 0), reverse=True)
print(json.dumps(combined, indent=2))
" "$RESULTS" <<< "$HN_POSTS" 2>/dev/null || echo "$RESULTS")
fi

echo "$RESULTS"
