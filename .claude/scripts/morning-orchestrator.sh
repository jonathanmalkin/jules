#!/usr/bin/env bash
# morning-orchestrator.sh — Unified morning job (EXCERPTED for reference)
#
# Full version: ~1390 lines. This excerpt shows the architectural patterns:
# parallel dispatch, signal file coordination, timeout wrappers, and phase structure.
#
# Runs at 5 AM daily. Executes:
#   Phase 0: Pre-checks (missed wrap-ups, inbox sweep, daily retro signal)
#   Phase 1: Parallel background tasks (monitor, memory synthesis, data fetches)
#   Phase 2: Wait for background tasks + auto-apply safe updates
#   Phase 3: Gather briefing inputs (session reports, Terrain, health signals)
#   Phase 4: Generate briefing (single claude -p call with all inputs)
#   Phase 5: Save outputs (file, email, Slack)
#   Phase 6: Cleanup
#
# Usage:
#   ./morning-orchestrator.sh                # Normal run
#   ./morning-orchestrator.sh --preview      # Preview briefing without saving
#   ./morning-orchestrator.sh --force        # Force regenerate everything
#   ./morning-orchestrator.sh --weekly       # Force weekly review format
#   ./morning-orchestrator.sh --skip-monitor # Skip monitor (if already ran)
#   ./morning-orchestrator.sh --skip-memory  # Skip memory synthesis

set -euo pipefail
trap 'echo "[morning] [error] Script failed at line $LINENO (exit $?)"' ERR

# Load credentials (self-sufficient regardless of how script is invoked)
[ -f /tmp/agent-secrets.env ] && set -a && . /tmp/agent-secrets.env && set +a || true

# ── Config ────────────────────────────────────────────────────

WORKSPACE_ROOT="$HOME/workspace"
BRIEFING_DIR="$WORKSPACE_ROOT/Documents/Field-Notes"
STATE_DIR="$HOME/.claude/good-morning-state"
MONITOR_STATE_DIR="$HOME/.claude/monitor-state"
HISTORY_FILE="$HOME/.claude/history.jsonl"
MEMORY_FILE=$(find "$HOME/.claude/projects/" -name "MEMORY.md" -path "*/memory/*" 2>/dev/null | head -1)
SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"

# ── Parse flags ───────────────────────────────────────────────

PREVIEW=false
FORCE=false
WEEKLY=false
SKIP_MONITOR=false
SKIP_MEMORY=false

for arg in "$@"; do
    case "$arg" in
        --preview)      PREVIEW=true ;;
        --force)        FORCE=true ;;
        --weekly)       WEEKLY=true ;;
        --skip-monitor) SKIP_MONITOR=true ;;
        --skip-memory)  SKIP_MEMORY=true ;;
    esac
done

# --weekly implies --force (existing daily briefing would block regeneration)
$WEEKLY && FORCE=true

# ── Setup ─────────────────────────────────────────────────────

mkdir -p "$STATE_DIR" "$BRIEFING_DIR" "$BRIEFING_DIR/Logs"

TODAY=$(date +%Y-%m-%d)
YESTERDAY=$(date -d "1 day ago" +%Y-%m-%d 2>/dev/null || date -v-1d +%Y-%m-%d)
BRIEFING_FILE="$BRIEFING_DIR/$TODAY-Briefing.md"
ROOT_BRIEFING="$WORKSPACE_ROOT/Briefing.md"
STATUS_FILE="$STATE_DIR/last-run-status.json"

log() { echo "[morning] $(date +%H:%M:%S) $*"; }

# Source shared notification helper (Slack + terminal-notifier fallback)
source "$SCRIPTS_DIR/notify.sh"

write_status() {
    local status="$1" detail="${2:-}"
    cat > "$STATUS_FILE" << STATUSEOF
{"date":"$TODAY","status":"$status","detail":"$detail","timestamp":"$(date +%H:%M:%S)"}
STATUSEOF
}

# Robust timeout wrapper — polls PID and kills the process tree.
# Previous timeout-inside-$() approach failed to kill claude -p when the
# API was down (hung for 21min, 104min in production). This poll-and-kill
# pattern reliably terminates runaway processes.
run_claude_with_timeout() {
    local timeout_secs="$1"
    shift
    local output_file="/tmp/claude-timeout-output-$$.txt"
    local input_file="/tmp/claude-timeout-input-$$.txt"
    : > "$output_file"

    # Save stdin to file — backgrounding with & disconnects stdin
    cat > "$input_file"

    # Run in background, capture output to file
    "$@" < "$input_file" > "$output_file" 2>/dev/null &
    local pid=$!

    # Poll with timeout
    local elapsed=0
    while kill -0 "$pid" 2>/dev/null; do
        sleep 5
        elapsed=$((elapsed + 5))
        if [ "$elapsed" -ge "$timeout_secs" ]; then
            log "  [timeout] claude -p killed after ${timeout_secs}s (pid $pid)"
            pkill -TERM -P "$pid" 2>/dev/null || true
            kill -TERM "$pid" 2>/dev/null || true
            sleep 5
            pkill -9 -P "$pid" 2>/dev/null || true
            kill -9 "$pid" 2>/dev/null || true
            wait "$pid" 2>/dev/null || true
            rm -f "$output_file" "$input_file"
            return
        fi
    done
    wait "$pid" 2>/dev/null || true

    cat "$output_file" 2>/dev/null || true
    rm -f "$output_file" "$input_file"
}

# Skip if briefing already exists (unless --force or --preview)
if [ -f "$BRIEFING_FILE" ] && ! $FORCE && ! $PREVIEW; then
    log "Briefing already exists for $TODAY: $BRIEFING_FILE"
    exit 0
fi

START_TIME=$(date +%s)

# ── Auth pre-flight ───────────────────────────────────────────
check_claude_auth() {
    if ! echo "ping" | timeout 30 claude -p --model haiku --max-turns 1 --output-format text >/dev/null 2>&1; then
        log "[error] Claude CLI auth check failed."
        exit 1
    fi
    log "Claude auth OK."
}
check_claude_auth

# ── Phase 0: Check for missed wrap-ups ───────────────────────
# Compare git commit dates against session report dates.
# If commits exist with no corresponding session report, flag the gap.

log "Checking for missed wrap-ups..."
MISSED_WRAPUP=""
LOGS_DIR="$BRIEFING_DIR/Logs"

# Find dates with commits in the last 7 days
COMMIT_DATES=$(cd "$WORKSPACE_ROOT" && git log --format='%ad' --date=short --since="7 days ago" 2>/dev/null | sort -u)

if [ -n "$COMMIT_DATES" ]; then
    MISSED_DATES=""
    while IFS= read -r commit_date; do
        [ -z "$commit_date" ] && continue
        REPORT_FILE="$LOGS_DIR/${commit_date}-Session-Report.md"
        if [ ! -f "$REPORT_FILE" ]; then
            COMMIT_COUNT=$(cd "$WORKSPACE_ROOT" && git log --oneline --since="${commit_date} 00:00:00" --until="${commit_date} 23:59:59" 2>/dev/null | wc -l | tr -d ' ')
            MISSED_DATES="${MISSED_DATES}- **${commit_date}**: ${COMMIT_COUNT} commit(s), no session report\n"
        fi
    done <<< "$COMMIT_DATES"

    if [ -n "$MISSED_DATES" ]; then
        MISSED_WRAPUP="## Missed Wrap-Ups (Learning Pipeline Gap)

The following dates had git commits but no session report.

$(echo -e "$MISSED_DATES")"
        log "Found missed wrap-ups."
    fi
fi

# ── Phase 0b: Load daily retro results (from 3 AM daily-retro.sh) ──
# The retro batch runs independently at 3 AM. We just read the signal file
# and load the report if available. No retro execution here.

DAILY_RETRO_REPORT=""
RETRO_SIGNAL="$HOME/.claude/job-state/daily-retro.status"

if [ -f "$RETRO_SIGNAL" ]; then
    RETRO_DATE=$(grep '^date=' "$RETRO_SIGNAL" | cut -d= -f2)
    RETRO_STATUS=$(grep '^status=' "$RETRO_SIGNAL" | cut -d= -f2)
    RETRO_FILE_PATH=$(grep '^retro_file=' "$RETRO_SIGNAL" | cut -d= -f2)

    if [ "$RETRO_DATE" = "$TODAY" ] || [ "$RETRO_DATE" = "$YESTERDAY" ]; then
        case "$RETRO_STATUS" in
            success)
                if [ -f "$RETRO_FILE_PATH" ] && [ -s "$RETRO_FILE_PATH" ]; then
                    DAILY_RETRO_REPORT=$(cat "$RETRO_FILE_PATH")
                    log "Loaded daily retro report from $RETRO_FILE_PATH"
                fi
                ;;
            failed)
                log "[warn] Daily retro failed. Continuing without retro."
                ;;
            running)
                log "[warn] Daily retro still running. Continuing without retro."
                ;;
        esac
    fi
fi

# ── Phase 1: Parallel background tasks ───────────────────────
# Key pattern: spawn multiple independent tasks in background, wait for all in Phase 2.
# Each task writes its output to a temp file. The orchestrator collects them.

MONITOR_PID=""
MEMORY_SYNTHESIS_FILE="/tmp/memory-synthesis-${TODAY}.md"

# 1a. Claude Code change monitor — detects CC updates since last check
if ! $SKIP_MONITOR; then
    log "Starting monitor-claude-changes.sh in background..."
    MONITOR_FLAGS=""
    $FORCE && MONITOR_FLAGS="--force"
    "$SCRIPTS_DIR/monitor-claude-changes.sh" $MONITOR_FLAGS > /tmp/morning-monitor-$$.log 2>&1 &
    MONITOR_PID=$!
fi

# 1b. Memory synthesis — extracts session topics from history.jsonl
if ! $SKIP_MEMORY; then
    log "Starting memory synthesis in background..."
    # --- [Memory synthesis function — ~80 lines, reads history.jsonl, extracts
    #      session topics from last 7 days, sends to claude -p for synthesis] ---
    # Output: $MEMORY_SYNTHESIS_FILE
    : # placeholder — see production version for full implementation
fi

# --- [Additional parallel tasks omitted — ~200 lines total] ---
# Production version includes:
# - App analytics pulse (queries encrypted SQLite DB for key metrics)
# - Community intelligence (searches Reddit/social for relevant discussions)
# - Content mining (analyzes recent session history for publishable insights)
# - Content cadence check (tracks posting frequency across platforms)
# - System health check (disk, memory, process count, log errors)
# - File placement audit (flags misplaced files in workspace)
# - Security watch (checks for exposed credentials in recent commits)
# - Email inbox fetch (pulls unread emails via IMAP for briefing inclusion)
#
# Each follows the same pattern:
#   1. Write output to a temp file
#   2. Run in background (&)
#   3. Capture PID for Phase 2 wait

# ── Phase 2: Wait for background tasks ───────────────────────

if [ -n "$MONITOR_PID" ]; then
    log "Waiting for monitor..."
    wait "$MONITOR_PID" || log "[warn] Monitor exited with error (continuing anyway)."
fi

# --- [Wait for all other PIDs — same pattern as above] ---

PHASE1_ELAPSED=$(( $(date +%s) - START_TIME ))
log "Phase 1 complete in ${PHASE1_ELAPSED}s."

# ── Phase 3: Gather briefing inputs ──────────────────────────
# Reads all the temp files from Phase 1 + static files (Terrain, CLAUDE.md, etc.)
# into shell variables that get injected into the Phase 4 prompt.

# --- [~100 lines: reads session reports, Terrain.md, CLAUDE.md, memory,
#      retro results, monitor results, health signals, and assembles them
#      into a single BRIEFING_INPUT variable] ---

# ── Phase 4: Generate briefing ───────────────────────────────
# Single claude -p call with all gathered inputs. Uses the good-morning skill's
# system prompt. This is where the LLM synthesizes everything into a daily brief.

log "Generating briefing..."

# --- [~400 lines: constructs the prompt with all inputs, handles weekly vs daily
#      format, runs claude -p with timeout wrapper, parses output, handles
#      retry on failure with simplified prompt] ---

# ── Phase 5: Save outputs ────────────────────────────────────

FINAL_BRIEFING="# Good Morning — $TODAY $(date +%H:%M)

$BRIEFING_CONTENT

---

*Generated by morning-orchestrator.sh at $(date +%H:%M:%S)*"

if $PREVIEW; then
    log "Preview mode — showing briefing without saving:"
    echo "$FINAL_BRIEFING"
else
    mkdir -p "$BRIEFING_DIR" "$BRIEFING_DIR/Logs"
    echo "$FINAL_BRIEFING" > "$BRIEFING_FILE"
    cp "$BRIEFING_FILE" "$ROOT_BRIEFING"
    log "Briefing saved to: $BRIEFING_FILE (+ root copy)"

    # --- [~60 lines: email briefing via build-digest-email.sh + send-email.sh,
    #      post to Slack channel with bullet summary, include overnight activity] ---
fi

# ── Phase 6: Cleanup ─────────────────────────────────────────

# Clean up temp files from parallel tasks
rm -f "$MEMORY_SYNTHESIS_FILE"
# --- [clean up other temp files] ---

# Rotate old briefings, session reports, memory synthesis files
find "$BRIEFING_DIR" -name "*-Briefing.md" -mtime +60 -exec mv {} ~/.Trash/ \; 2>/dev/null || true
find "$BRIEFING_DIR/Logs" -name "*-Session-Report.md" -mtime +90 -exec mv {} ~/.Trash/ \; 2>/dev/null || true

TOTAL_ELAPSED=$(( $(date +%s) - START_TIME ))
log "Morning orchestrator complete in ${TOTAL_ELAPSED}s."

write_status "ok" "Briefing generated in ${TOTAL_ELAPSED}s"

exit 0
