#!/usr/bin/env bash
# daily-retro.sh — Independent daily retrospective batch job
#
# Runs at 3 AM via container cron. Analyzes yesterday's session issues
# using per-issue iteration: each issue gets parallel analysis agents
# + per-issue synthesis + report assembly.
#
# Architecture: fully iterative — no single LLM call scales with issue count.
#   Phase 1: Setup, git pull, auth pre-flight
#   Phase 2: Parse issues into individual files (bash)
#   Phase 3: Independent agent loops (concurrent, each iterates at own pace)
#   Phase 4a: Per-issue synthesis (sequential, bounded input per call)
#   Phase 4b: Report assembly (lightweight formatting)
#   Phase 5: Quality check (bash)
#   Phase 6: Git commit/push
#   Phase 7: Signal file + notify
#
# System prompts: .claude/skills/retro-deep/references/*.md
# Input: Documents/Field-Notes/Logs/*-Session-Issues.md
# Output: Documents/Field-Notes/YYYY-MM-DD-Daily-Retro.md
# Signal: ~/.claude/job-state/daily-retro.status

set -euo pipefail

# ── Configuration ─────────────────────────────────────────────
SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPTS_DIR/../.." && pwd)"
PROMPTS_DIR="$WORKSPACE_ROOT/.claude/skills/retro-deep/references"
STATE_DIR="$HOME/.claude/job-state"
BRIEFING_DIR="$WORKSPACE_ROOT/Documents/Field-Notes"
ISSUES_DIR="$BRIEFING_DIR/Logs"
SIGNAL_FILE="$STATE_DIR/daily-retro.status"

TODAY=$(date +%Y-%m-%d)
YESTERDAY=$(date -d "yesterday" +%Y-%m-%d 2>/dev/null || date -v-1d +%Y-%m-%d)
RETRO_FILE="$BRIEFING_DIR/$TODAY-Daily-Retro.md"

mkdir -p "$STATE_DIR" "$ISSUES_DIR"

log() {
    echo "[$(date '+%H:%M:%S')] $*"
}

# Atomic signal file write — temp file + mv
write_signal() {
    local status="$1"
    local error="${2:-}"
    local tmp_signal
    tmp_signal=$(mktemp "$STATE_DIR/daily-retro.status.XXXXXX")
    printf 'date=%s\nstatus=%s\nretro_file=%s\ntimestamp=%s\nerror=%s\n' \
        "$TODAY" "$status" "$RETRO_FILE" "$(date +%H:%M:%S)" "$error" > "$tmp_signal"
    mv "$tmp_signal" "$SIGNAL_FILE"
}

notify_ops() {
    if [ -x "$SCRIPTS_DIR/slack-send.sh" ]; then
        "$SCRIPTS_DIR/slack-send.sh" --ops "$1" 2>/dev/null || true
    fi
}

# Robust timeout wrapper — polls PID and kills the process tree.
# Returns 124 on timeout, otherwise the process exit code.
# Logs [timeout] vs [exit:N] for diagnostic clarity.
run_claude_with_timeout() {
    local timeout_secs="$1"
    shift
    local output_file input_file
    output_file=$(mktemp /tmp/claude-retro-output-XXXXXX.txt)
    input_file=$(mktemp /tmp/claude-retro-input-XXXXXX.txt)
    : > "$output_file"

    # Save stdin to file — backgrounding disconnects stdin
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
            return 124
        fi
    done
    wait "$pid" 2>/dev/null
    local exit_code=$?

    if [ "$exit_code" -ne 0 ]; then
        log "  [exit:$exit_code] claude -p exited with code $exit_code after ${elapsed}s"
    fi

    if [ "$exit_code" -eq 0 ]; then
        cat "$output_file" 2>/dev/null || true
    fi
    rm -f "$output_file" "$input_file"
    return $exit_code
}

# ── Issue Parser ──────────────────────────────────────────────
# Splits concatenated session issues into individual issue files.
# Returns the count of issues parsed.
parse_issues() {
    local input="$1"
    local output_dir="$2"
    local start_offset="${3:-0}"   # number of issues already parsed in prior runs
    local issue_num="$start_offset"
    local current_file=""
    local in_issue=false
    local new_count=0

    mkdir -p "$output_dir"

    while IFS= read -r line || [ -n "$line" ]; do
        # New issue starts with ### N. [
        if echo "$line" | grep -qE '^### [0-9]+\. \['; then
            issue_num=$((issue_num + 1))
            new_count=$((new_count + 1))
            current_file="$output_dir/issue-$(printf '%03d' $issue_num).md"
            in_issue=true
            echo "$line" > "$current_file"
        elif $in_issue; then
            # Issue ends at next issue header, session boundary, or determinism section
            if echo "$line" | grep -qE '^### [0-9]+\. \['; then
                # New issue
                issue_num=$((issue_num + 1))
                new_count=$((new_count + 1))
                current_file="$output_dir/issue-$(printf '%03d' $issue_num).md"
                echo "$line" > "$current_file"
            elif echo "$line" | grep -qE '^---|^# Session|^## Determinism'; then
                in_issue=false
            else
                echo "$line" >> "$current_file"
            fi
        fi
    done <<< "$input"

    echo "$new_count"
}

# ── Per-Issue Agent Call ──────────────────────────────────────
analyze_issue() {
    local issue_file="$1"
    local issue_dir="$2"
    local agent_name="$3"
    local prompt_file="$4"
    local allowed_tools="$5"
    local max_turns="${6:-5}"
    local timeout=300

    local output_file="$issue_dir/${agent_name}.md"

    # Skip if already completed (resume support)
    if [ -f "$output_file" ] && [ -s "$output_file" ]; then
        return 0
    fi

    # Build input: issue + config context
    local input_file
    input_file=$(mktemp)
    cat > "$input_file" << EOF
# Issue to Analyze

$(cat "$issue_file")

# Current Configuration (reference)

$CONFIG_CONTENT
EOF

    local attempt=1
    while [ "$attempt" -le 2 ]; do
        local result
        if result=$(run_claude_with_timeout "$timeout" claude -p \
            --model sonnet --effort medium \
            --system-prompt "$(cat "$prompt_file")" \
            --allowedTools "$allowed_tools" \
            --max-turns "$max_turns" \
            --output-format text \
            < "$input_file" 2>/dev/null); then
            if [ -n "$result" ]; then
                echo "$result" > "$output_file"
                rm -f "$input_file"
                return 0
            fi
        fi
        log "  [$agent_name] attempt $attempt failed for $(basename "$issue_dir")."
        attempt=$((attempt + 1))
    done

    # Failed — write skip marker
    echo "(Analysis skipped — $agent_name failed after 2 attempts)" > "$output_file"
    rm -f "$input_file"
    return 0
}

# ── Phase 1: Setup + Signal + Auth ───────────────────────────
log "=== Daily Retro Batch — $TODAY ==="

# Git pull to get latest issue files
# Use container SSH config if present, otherwise fall back to native SSH (Mac)
GIT_SSH_CMD=""
[[ -f /tmp/ssh-state/ssh_config ]] && GIT_SSH_CMD="ssh -F /tmp/ssh-state/ssh_config"
(cd "$WORKSPACE_ROOT" && GIT_SSH_COMMAND="$GIT_SSH_CMD" git pull --ff-only --autostash 2>/dev/null && log "Git pull complete.") || log "[warn] Git pull failed — using current state."

# Write running signal immediately
write_signal "running"
notify_ops ":hourglass_flowing_sand: *Daily retro starting* for $TODAY — analyzing session issues."

# Check if any issue files exist at all (for early exit before work dir is set up)
ANY_ISSUES=false
for check_date in "$YESTERDAY" "$TODAY"; do
    ISSUE_FILE="$ISSUES_DIR/${check_date}-Session-Issues.md"
    [ -f "$ISSUE_FILE" ] && [ -s "$ISSUE_FILE" ] && ANY_ISSUES=true
done

if ! $ANY_ISSUES; then
    log "No session issues found — clean exit."
    write_signal "success" "no issues"
    exit 0
fi

# Auth pre-flight
log "Auth pre-flight..."
unset CLAUDECODE 2>/dev/null || true
unset ANTHROPIC_API_KEY 2>/dev/null || true

if ! echo "ping" | timeout 30 claude -p --model haiku --max-turns 1 --output-format text >/dev/null 2>&1; then
    log "[error] Claude CLI auth failed."
    write_signal "failed" "auth_expired"
    notify_ops ":rotating_light: *Daily retro auth failed.* Re-auth the container."
    exit 1
fi
log "Auth OK."

# ── Phase 2: Pre-read config + parse issues ──────────────────
log "Pre-reading config files..."

CONFIG_CONTENT=""

# CLAUDE.md
if [ -f "$WORKSPACE_ROOT/CLAUDE.md" ]; then
    CONFIG_CONTENT="${CONFIG_CONTENT}
## CLAUDE.md (main project config)
$(cat "$WORKSPACE_ROOT/CLAUDE.md")
"
fi

# MEMORY.md — find dynamically (path varies by project)
MEMORY_FILE=$(find "$HOME/.claude/projects/" -name "MEMORY.md" -path "*/memory/*" 2>/dev/null | head -1)
if [ -n "$MEMORY_FILE" ] && [ -f "$MEMORY_FILE" ]; then
    CONFIG_CONTENT="${CONFIG_CONTENT}
## MEMORY.md
$(cat "$MEMORY_FILE")
"
fi

# All rules
for rule_file in "$WORKSPACE_ROOT/.claude/rules/"*.md; do
    if [ -f "$rule_file" ]; then
        CONFIG_CONTENT="${CONFIG_CONTENT}
## Rule: $(basename "$rule_file")
$(cat "$rule_file")
"
    fi
done

log "Config pre-read complete ($(echo "$CONFIG_CONTENT" | wc -l | tr -d ' ') lines)."

# Stable work dir — date-based so resume works across runs
WORK_DIR="/tmp/retro-work-$TODAY"
mkdir -p "$WORK_DIR/issues" "$WORK_DIR/results"

# Persistent registry — tracks which issue files have been successfully retro'd across all runs.
# Lives in job-state (survives /tmp cleanup). Per-run registry stays for same-day resume.
PERSISTENT_REGISTRY="$HOME/.claude/job-state/retro-processed-files.txt"
touch "$PERSISTENT_REGISTRY"
PARSED_REGISTRY="$WORK_DIR/parsed-files.txt"
touch "$PARSED_REGISTRY"

# Only parse issue files not already processed (check both persistent and per-run registries)
NEW_ISSUES=""
for check_date in "$YESTERDAY" "$TODAY"; do
    ISSUE_FILE="$ISSUES_DIR/${check_date}-Session-Issues.md"
    if [ -f "$ISSUE_FILE" ] && [ -s "$ISSUE_FILE" ]; then
        if grep -qxF "$ISSUE_FILE" "$PERSISTENT_REGISTRY" 2>/dev/null; then
            log "Already retro'd: $(basename "$ISSUE_FILE") — skipping (persistent registry)"
        elif grep -qxF "$ISSUE_FILE" "$PARSED_REGISTRY" 2>/dev/null; then
            log "Already parsed this run: $(basename "$ISSUE_FILE") — skipping"
        else
            NEW_ISSUES="${NEW_ISSUES}$(cat "$ISSUE_FILE")
---
"
            echo "$ISSUE_FILE" >> "$PARSED_REGISTRY"
            log "Queued for parsing: $(basename "$ISSUE_FILE")"
        fi
    fi
done

# Count existing issues (from prior runs)
EXISTING_COUNT=$(find "$WORK_DIR/issues" -name 'issue-*.md' 2>/dev/null | wc -l | tr -d ' ')

# Parse any new issues, appending to existing set
NEW_COUNT=0
if [ -n "$NEW_ISSUES" ]; then
    NEW_COUNT=$(parse_issues "$NEW_ISSUES" "$WORK_DIR/issues" "$EXISTING_COUNT")
    log "Parsed $NEW_COUNT new issues (${EXISTING_COUNT} already existed)."
else
    log "No new issue files to parse."
fi

ISSUE_COUNT=$((EXISTING_COUNT + NEW_COUNT))
log "Total issues to process: $ISSUE_COUNT."

# Validation: parser fallback
if [ "$ISSUE_COUNT" -eq 0 ]; then
    log "[warn] Parser produced 0 issues from non-empty input. Falling back to monolithic."
    cat "$PARSED_REGISTRY" | while IFS= read -r f; do cat "$f"; echo "---"; done > "$WORK_DIR/issues/issue-001.md"
    ISSUE_COUNT=1
fi

# ── Phase 3: Independent Agent Loops (concurrent) ────────────
log "Launching analysis agent loop across $ISSUE_COUNT issues..."

# Each agent type runs its own loop over all issues independently
run_agent_loop() {
    local agent_name="$1"
    local prompt_file="$2"
    local allowed_tools="$3"
    local max_turns="$4"
    local completed=0
    local failed=0

    for issue_file in "$WORK_DIR/issues"/issue-*.md; do
        local issue_name
        issue_name=$(basename "$issue_file" .md)
        local issue_dir="$WORK_DIR/results/$issue_name"
        mkdir -p "$issue_dir"
        if analyze_issue "$issue_file" "$issue_dir" "$agent_name" \
            "$prompt_file" "$allowed_tools" "$max_turns"; then
            completed=$((completed + 1))
        else
            failed=$((failed + 1))
        fi
    done
    log "[$agent_name] loop complete: $completed succeeded, $failed failed."
}

# Combined analyzer — config audit + research + pattern scanner in one agent call
# max-turns 12 to ensure all 3 analysis sections complete
run_agent_loop "analyzer" "$PROMPTS_DIR/analyzer.md" "WebSearch,Read,Glob,Grep" 12

log "All analysis loops complete."

# ── Phase 4a: Per-Issue Synthesis ─────────────────────────────
log "Running per-issue synthesis..."

SYNTH_SUCCEEDED=0
SYNTH_FAILED=0

for issue_file in "$WORK_DIR/issues"/issue-*.md; do
    issue_name=$(basename "$issue_file" .md)
    issue_dir="$WORK_DIR/results/$issue_name"
    synth_output="$issue_dir/synthesis.md"

    # Skip if already done (resume support)
    if [ -f "$synth_output" ] && [ -s "$synth_output" ]; then
        SYNTH_SUCCEEDED=$((SYNTH_SUCCEEDED + 1))
        continue
    fi

    # Build per-issue synthesis input (bounded: ~200-400 lines + config)
    synth_input=$(mktemp)
    cat > "$synth_input" << SYNTHEOF
# Issue to Synthesize

## Original Issue
$(cat "$issue_file")

## Analyzer Output (Config Audit + Research + Patterns)
$(cat "$issue_dir/analyzer.md" 2>/dev/null || echo "(unavailable)")

## Current Configuration
$CONFIG_CONTENT
SYNTHEOF

    log "  Synthesizing $issue_name..."

    # 90s timeout — reduced from 180s (synthesis is focused per-issue)
    result=""
    if result=$(run_claude_with_timeout 90 claude -p \
        --model sonnet --effort high \
        --system-prompt "$(cat "$PROMPTS_DIR/synthesis.md")" \
        --allowedTools "Read,Edit,Write,Glob,Grep" \
        --max-turns 8 \
        --output-format text \
        < "$synth_input" 2>/dev/null); then
        if [ -n "$result" ]; then
            echo "$result" > "$synth_output"
        fi
    fi

    # Retry once on failure
    if [ ! -f "$synth_output" ] || [ ! -s "$synth_output" ]; then
        log "  [$issue_name] synthesis retry..."
        if result=$(run_claude_with_timeout 90 claude -p \
            --model sonnet --effort high \
            --system-prompt "$(cat "$PROMPTS_DIR/synthesis.md")

IMPORTANT: Previous attempt failed. Take a simpler approach. Apply only the most critical fix for this issue." \
            --allowedTools "Read,Edit,Write,Glob,Grep" \
            --max-turns 6 \
            --output-format text \
            < "$synth_input" 2>/dev/null); then
            if [ -n "$result" ]; then
                echo "$result" > "$synth_output"
            fi
        fi
    fi

    rm -f "$synth_input"

    if [ -f "$synth_output" ] && [ -s "$synth_output" ]; then
        SYNTH_SUCCEEDED=$((SYNTH_SUCCEEDED + 1))
        log "  $issue_name synthesized."
    else
        SYNTH_FAILED=$((SYNTH_FAILED + 1))
        log "  [warn] $issue_name synthesis failed."
    fi
done

log "Synthesis complete: $SYNTH_SUCCEEDED succeeded, $SYNTH_FAILED failed."

# Check if we have any synthesis results
if [ "$SYNTH_SUCCEEDED" -eq 0 ]; then
    log "[error] All synthesis attempts failed."
    write_signal "failed" "all_synthesis_failed"
    notify_ops ":x: *Daily retro: all $ISSUE_COUNT synthesis calls failed.* Issues preserved for manual review."
    exit 1
fi

# ── Phase 4b: Report Assembly ─────────────────────────────────
log "Assembling report from synthesis outputs..."
{
    echo "# Daily Retrospective — $TODAY"
    echo ""
    for issue_file in "$WORK_DIR/issues"/issue-*.md; do
        issue_name=$(basename "$issue_file" .md)
        synth_file="$WORK_DIR/results/$issue_name/synthesis.md"
        if [ -f "$synth_file" ] && [ -s "$synth_file" ]; then
            echo ""
            echo "---"
            echo ""
            cat "$synth_file"
        fi
    done
} > "$RETRO_FILE"

DAILY_RETRO_REPORT=$(cat "$RETRO_FILE")

# ── Phase 5: Quality check ───────────────────────────────────
# Relaxed check — per-issue synthesis means report format may vary
if [ "$(echo "$DAILY_RETRO_REPORT" | wc -c)" -lt 200 ]; then
    log "[error] Report too short ($(echo "$DAILY_RETRO_REPORT" | wc -c) chars)."
    write_signal "failed" "report_too_short"
    notify_ops ":x: *Daily retro: report too short.* Issues preserved for manual review."
    exit 1
fi

log "Report passed quality check."
log "Retro report saved: $RETRO_FILE"

# Work dir kept at $WORK_DIR for resume support (date-based, OS will clean /tmp eventually)

# ── Phase 6: Git commit/push ────────────────────────────────
log "Committing changes..."
(
    cd "$WORKSPACE_ROOT"
    if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
        git add "$RETRO_FILE" 2>/dev/null || true
        git add CLAUDE.md .claude/rules/ .claude/skills/ .claude/scripts/ 2>/dev/null || true
        # Also add memory files that synthesis may have edited
        MEMORY_DIR=$(find "$HOME/.claude/projects/" -name "memory" -type d 2>/dev/null | head -1)
        [ -n "$MEMORY_DIR" ] && git add "$MEMORY_DIR/" 2>/dev/null || true
        GIT_SSH_COMMAND="$GIT_SSH_CMD" git commit -m "retro: auto-apply config fixes $TODAY" && \
        GIT_SSH_COMMAND="$GIT_SSH_CMD" git push && \
        log "Changes committed and pushed."
    else
        log "No file changes to commit."
    fi
) || log "[warn] Git commit/push failed — changes pending next auto-pull."

# ── Phase 7: Final signal + notify ───────────────────────────
write_signal "success"

# Mark processed files in persistent registry so future runs skip them
if [ -f "$PARSED_REGISTRY" ]; then
    while IFS= read -r processed_file; do
        if ! grep -qxF "$processed_file" "$PERSISTENT_REGISTRY" 2>/dev/null; then
            echo "$processed_file" >> "$PERSISTENT_REGISTRY"
        fi
    done < "$PARSED_REGISTRY"
    log "Updated persistent registry with $(wc -l < "$PARSED_REGISTRY" | tr -d ' ') processed files."
fi

notify_ops ":white_check_mark: *Daily retro complete* for $TODAY. Report: $RETRO_FILE"
log "=== Daily Retro Complete ==="
