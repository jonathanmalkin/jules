#!/usr/bin/env bash
# session-scan.sh — Daily batch scan for non-interactive (Slack) sessions
#
# Runs at 7 PM CST daily (1 hour before retro). Deterministic bash — no LLM calls.
#
# What it does:
#   1. Discovers container sessions from the past 24 hours (history.jsonl)
#   2. Cross-references slack-dispatch.log for queue context
#   3. Commits orphaned changes from known output directories only
#   4. Reports unexpected changes outside known dirs (doesn't commit them)
#   5. Writes structured session digest (consumed by daily-retro.sh)
#   6. Writes handoff YAML (consumed by morning-orchestrator.sh)
#   7. Reports start/success/failure to #ops
#
# Signal file: ~/.claude/job-state/session-scan.status
# Session digest: ~/.claude/job-state/session-digest-{date}.md
# Handoff YAML: ~/.claude/job-state/handoffs/session-scan-{date}.yaml

set -euo pipefail

# ── Configuration ─────────────────────────────────────────────
SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPTS_DIR/../.." && pwd)"
STATE_DIR="$HOME/.claude/job-state"
SIGNAL_FILE="$STATE_DIR/session-scan.status"
HANDOFF_DIR="$STATE_DIR/handoffs"
SLACK_DISPATCH_LOG="$HOME/.claude/agent-runner-state/slack-dispatch.log"

TODAY=$(date +%Y-%m-%d)

mkdir -p "$STATE_DIR" "$HANDOFF_DIR"

log() {
    echo "[session-scan] $(date '+%H:%M:%S') $*"
}

SCAN_THREAD_TS=""
notify_ops() {
    if [ ! -x "$SCRIPTS_DIR/slack-send.sh" ]; then return 0; fi
    if [ -z "$SCAN_THREAD_TS" ]; then
        SCAN_THREAD_TS=$("$SCRIPTS_DIR/slack-send.sh" --return-ts --ops "$1" 2>/dev/null || true)
    else
        "$SCRIPTS_DIR/slack-send.sh" --ops ${SCAN_THREAD_TS:+--thread "$SCAN_THREAD_TS"} "$1" 2>/dev/null || true
    fi
}

# Atomic signal file write
write_signal() {
    local status="$1"
    local sessions="${2:-0}"
    local committed="${3:-0}"
    local untracked="${4:-0}"
    local error="${5:-}"
    local tmp_signal
    tmp_signal=$(mktemp "$STATE_DIR/session-scan.status.XXXXXX")
    printf 'date=%s\nstatus=%s\ntimestamp=%s\nsessions_found=%s\nfiles_committed=%s\nuntracked_outside_scope=%s\nerror=%s\n' \
        "$TODAY" "$status" "$(date +%H:%M:%S)" "$sessions" "$committed" "$untracked" "$error" > "$tmp_signal"
    mv "$tmp_signal" "$SIGNAL_FILE"
}

# ── Step 0: Report start ─────────────────────────────────────
log "=== Session Scan — $TODAY ==="
notify_ops ":hourglass_flowing_sand: *Session scan starting* for $TODAY."
write_signal "running"

# ── Step 1: Find today's container sessions ───────────────────
log "Discovering sessions from past 24 hours..."

SESSIONS_FOUND=0
SESSION_DIGEST_BODY=""

# Primary source: slack-dispatch.log (Slack daemon dispatches only)
# This avoids noise from cron job sessions (retro, orchestrator, etc.)
# which already manage their own reporting.
#
# Log format: [slack-daemon] YYYY-MM-DD HH:MM:SS <message>
# Key lines:  "Received: ..." and "Dispatching [model/effort]: ..."

if [ -f "$SLACK_DISPATCH_LOG" ]; then
    CUTOFF_DATE=$(date -d "24 hours ago" +%Y-%m-%d 2>/dev/null || date -v-24H +%Y-%m-%d)

    # Parse dispatch log: extract Received + Dispatching lines from past 24h
    SESSION_LIST=$(python3 -c "
import sys, re
from datetime import datetime, timedelta

cutoff = datetime.now() - timedelta(hours=24)
dispatches = []
current_msg = None

for line in open('$SLACK_DISPATCH_LOG'):
    line = line.strip()
    if not line:
        continue

    # Parse timestamp: [slack-daemon] YYYY-MM-DD HH:MM:SS msg
    m = re.match(r'\[slack-daemon\] (\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}) (.*)', line)
    if not m:
        continue

    try:
        ts = datetime.strptime(m.group(1), '%Y-%m-%d %H:%M:%S')
    except ValueError:
        continue

    if ts < cutoff:
        continue

    msg = m.group(2)

    # Track received messages
    recv = re.match(r'Received: \"(.*)\"', msg)
    if recv:
        current_msg = recv.group(1)[:80]
        continue

    # Track dispatches (the actual claude -p calls)
    disp = re.match(r'Dispatching \[([^\]]+)\]: (.*)', msg)
    if disp:
        model_info = disp.group(1)
        prompt_text = current_msg or disp.group(2)[:80]
        dispatches.append({
            'time': ts.strftime('%H:%M'),
            'model': model_info,
            'prompt': prompt_text,
        })
        current_msg = None
        continue

    # Track queue processing
    queue = re.match(r'Queue: processing \"(.*)\" \((\d+) remaining\)', msg)
    if queue:
        dispatches.append({
            'time': ts.strftime('%H:%M'),
            'model': 'queued',
            'prompt': queue.group(1)[:80],
        })
        continue

for d in dispatches:
    prompt = d['prompt']
    if len(prompt) > 80:
        prompt = prompt[:77] + '...'
    print(f\"{d['time']}|{d['model']}|{prompt}\")
" 2>/dev/null || true)

    if [ -n "$SESSION_LIST" ]; then
        SESSIONS_FOUND=$(echo "$SESSION_LIST" | wc -l | tr -d ' ')

        while IFS='|' read -r time model prompt; do
            [ -z "$time" ] && continue
            SESSION_DIGEST_BODY="${SESSION_DIGEST_BODY}- **(${time}, Slack)** [${model}] — \"${prompt}\"
"
        done <<< "$SESSION_LIST"
    fi
else
    log "No slack-dispatch.log found — skipping session discovery."
fi

log "Found $SESSIONS_FOUND Slack dispatches in the past 24 hours."

# ── Step 2: Detect orphaned changes ──────────────────────────
log "Checking for uncommitted changes..."

cd "$WORKSPACE_ROOT"

# Git pull first to avoid false positives
GIT_SSH_CMD=""
[[ -f /tmp/ssh-state/ssh_config ]] && GIT_SSH_CMD="ssh -F /tmp/ssh-state/ssh_config"
(GIT_SSH_COMMAND="$GIT_SSH_CMD" git pull --ff-only --autostash 2>/dev/null && log "Git pull complete.") || log "[warn] Git pull failed — using current state."

PORCELAIN=$(git status --porcelain 2>/dev/null || true)

if [ -z "$PORCELAIN" ]; then
    log "Working tree clean — nothing to commit."
    FILES_COMMITTED=0
    UNTRACKED_OUTSIDE=0
    COMMITTED_FILES=""
    UNTRACKED_FILES=""
else
    # Known output directories (relative to workspace root)
    # These are safe to auto-commit from non-interactive sessions
    KNOWN_DIRS=(
        "Documents/"
        ".claude-memory/"
        ".claude/rules/"
        ".claude/skills/"
        ".claude/scripts/"
        "Briefing.md"
        "Terrain.md"
    )

    KNOWN_CHANGES=""
    OUTSIDE_CHANGES=""

    while IFS= read -r line; do
        [ -z "$line" ] && continue
        # git status --porcelain format: XY filename
        filepath=$(echo "$line" | sed 's/^...//')

        in_known=false
        for dir in "${KNOWN_DIRS[@]}"; do
            if [[ "$filepath" == "$dir"* ]]; then
                in_known=true
                break
            fi
        done

        if $in_known; then
            KNOWN_CHANGES="${KNOWN_CHANGES}${filepath}
"
        else
            OUTSIDE_CHANGES="${OUTSIDE_CHANGES}${filepath}
"
        fi
    done <<< "$PORCELAIN"

    # ── Step 3: Commit known-dir changes ──────────────────────
    FILES_COMMITTED=0
    COMMITTED_FILES=""
    if [ -n "$KNOWN_CHANGES" ]; then
        log "Staging changes from known directories..."

        # Use flock to prevent concurrent commits (e.g., if retro also runs)
        (
            flock -w 60 200 || { log "[error] Could not acquire flock — another commit in progress."; exit 1; }

            while IFS= read -r filepath; do
                [ -z "$filepath" ] && continue
                git add "$filepath" 2>/dev/null && COMMITTED_FILES="${COMMITTED_FILES}- ${filepath}
"
            done <<< "$KNOWN_CHANGES"

            FILES_COMMITTED=$(git diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')

            if [ "$FILES_COMMITTED" -gt 0 ]; then
                git commit -m "[session-scan] auto: ${FILES_COMMITTED} files from ${SESSIONS_FOUND} sessions" 2>/dev/null || true
                "$SCRIPTS_DIR/git-smart-push.sh" 2>/dev/null || log "[warn] Push failed — changes committed locally."
                log "Committed and pushed $FILES_COMMITTED files."
            else
                log "No staged changes after filtering."
            fi
        ) 200>/tmp/session-scan.flock
    fi

    # Count untracked outside scope
    UNTRACKED_OUTSIDE=0
    UNTRACKED_FILES=""
    if [ -n "$OUTSIDE_CHANGES" ]; then
        UNTRACKED_OUTSIDE=$(echo "$OUTSIDE_CHANGES" | grep -c . || true)
        UNTRACKED_FILES="$OUTSIDE_CHANGES"
        log "Found $UNTRACKED_OUTSIDE changes outside known directories."
    fi
fi

# ── Step 5: Write session digest ─────────────────────────────
DIGEST_FILE="$STATE_DIR/session-digest-${TODAY}.md"
log "Writing session digest..."

{
    echo "# Session Digest — $TODAY"
    echo ""

    echo "## Container Sessions (past 24h)"
    if [ -n "$SESSION_DIGEST_BODY" ]; then
        echo "$SESSION_DIGEST_BODY"
    else
        echo "(no sessions found)"
        echo ""
    fi

    echo "## Git Changes Committed"
    if [ -n "$COMMITTED_FILES" ]; then
        echo "$COMMITTED_FILES"
    else
        echo "(none)"
        echo ""
    fi

    echo "## Untracked Changes (outside scan scope)"
    if [ -n "$UNTRACKED_FILES" ]; then
        while IFS= read -r f; do
            [ -z "$f" ] && continue
            echo "- ${f} (NOT committed — review manually)"
        done <<< "$UNTRACKED_FILES"
        echo ""
    else
        echo "(none)"
        echo ""
    fi

    echo "## Errors"
    echo "(none)"
} > "$DIGEST_FILE"

log "Session digest written: $DIGEST_FILE"

# ── Step 6: Write handoff YAML ───────────────────────────────
HANDOFF_FILE="$HANDOFF_DIR/session-scan-${TODAY}.yaml"
log "Writing handoff YAML..."

TIMESTAMP=$(date -Iseconds 2>/dev/null || date +%Y-%m-%dT%H:%M:%S%z)
SUMMARY="${SESSIONS_FOUND} Slack sessions"
[ "$FILES_COMMITTED" -gt 0 ] && SUMMARY="${SUMMARY}, committed ${FILES_COMMITTED} files"
[ "$UNTRACKED_OUTSIDE" -gt 0 ] && SUMMARY="${SUMMARY}, ${UNTRACKED_OUTSIDE} untracked files flagged"

cat > "$HANDOFF_FILE" << YAMLEOF
job: session-scan
timestamp: "$TIMESTAMP"
status: success
sessions_found: $SESSIONS_FOUND
files_committed: $FILES_COMMITTED
untracked_outside_scope: $UNTRACKED_OUTSIDE
summary: "$SUMMARY"
errors: []
YAMLEOF

log "Handoff YAML written: $HANDOFF_FILE"

# ── Step 7: Cleanup old files ────────────────────────────────
log "Cleaning up old digests and handoffs..."
find "$STATE_DIR" -name "session-digest-*.md" -mtime +7 -delete 2>/dev/null || true
find "$HANDOFF_DIR" -name "session-scan-*.yaml" -mtime +7 -delete 2>/dev/null || true

# ── Step 8: Write signal file ────────────────────────────────
write_signal "success" "$SESSIONS_FOUND" "$FILES_COMMITTED" "$UNTRACKED_OUTSIDE"
log "Signal file written."

# ── Step 9: Report completion ────────────────────────────────
REPORT_MSG=":white_check_mark: *Session scan complete* — ${SESSIONS_FOUND} sessions"
[ "$FILES_COMMITTED" -gt 0 ] && REPORT_MSG="${REPORT_MSG}, ${FILES_COMMITTED} files committed"
[ "$UNTRACKED_OUTSIDE" -gt 0 ] && REPORT_MSG="${REPORT_MSG}, ${UNTRACKED_OUTSIDE} untracked files flagged"
REPORT_MSG="${REPORT_MSG}."
notify_ops "$REPORT_MSG"

log "=== Session Scan Complete ==="
