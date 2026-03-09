#!/usr/bin/env bash
# app-blast.sh — Fast form + survey traversal via phased JS evals
#
# Uses separate eval calls per phase to avoid:
# 1. Execution context destruction on page transitions
# 2. Shell quoting issues with inline JS in loops
#
# Each JS file is read via $(cat) — shell-safe (no ", $, `, !)
# Note: agent-browser eval wraps return values in JSON quotes ("value").
# All results are stripped of quotes before pattern matching.
#
# Requires: agent-browser session open on the first form step
# Usage: ./app-blast.sh
# Output: RESULTS_REACHED / FORM_INCOMPLETE / etc.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

FORM_JS="$SCRIPT_DIR/form-click-batch.js"
SURVEY_JS="$SCRIPT_DIR/survey-click.js"
CHECK_JS="$SCRIPT_DIR/check-state.js"

for f in "$FORM_JS" "$SURVEY_JS" "$CHECK_JS"; do
    if [ ! -f "$f" ]; then
        echo "ERROR: Missing $f"
        exit 1
    fi
done

# agent-browser eval returns JSON-quoted strings ("value"). Strip them.
strip_quotes() { tr -d '"'; }

TOTAL_Q=0
MAX_BATCHES=8

# Phase 1: Form steps in batches of 15
for BATCH in $(seq 1 $MAX_BATCHES); do
    RESULT=$(agent-browser eval "$(cat "$FORM_JS")" 2>/dev/null | strip_quotes || echo "EVAL_ERROR")

    # Extract step count from result string
    COUNT=$(echo "$RESULT" | grep -oE '[0-9]+' | tail -1)
    [ -n "$COUNT" ] && TOTAL_Q=$((TOTAL_Q + COUNT))

    case "$RESULT" in
        RESULTS_FOUND*)
            echo "RESULTS_REACHED: $TOTAL_Q steps, 0 survey"
            exit 0
            ;;
        SURVEY_FOUND*)
            break
            ;;
        NO_OPTIONS*)
            break
            ;;
        BATCH_DONE*)
            sleep 0.3
            ;;
        *)
            # Eval error or unexpected — check page state and recover
            sleep 1
            STATE=$(agent-browser eval "$(cat "$CHECK_JS")" 2>/dev/null | strip_quotes || echo "UNKNOWN")
            case "$STATE" in
                RESULTS)
                    echo "RESULTS_REACHED: $TOTAL_Q steps, 0 survey"
                    exit 0
                    ;;
                SURVEY)
                    break
                    ;;
                *)
                    ;; # continue with next batch
            esac
            ;;
    esac
done

# Phase 2: Survey interstitial
SURVEY_RESULT=$(agent-browser eval "$(cat "$SURVEY_JS")" 2>/dev/null | strip_quotes || echo "NO_SURVEY:0")
SURVEYED=$(echo "$SURVEY_RESULT" | grep -oE '[0-9]+' | tail -1)
[ -z "$SURVEYED" ] && SURVEYED=0

# Phase 3: Wait for calculating animation -> results
# The transition has a brief UNKNOWN state between calculating and results.
# Don't break early — always exhaust all wait attempts.
STATE="UNKNOWN"
for WAIT in 1 2 3 4 5 6 7 8; do
    sleep 2
    STATE=$(agent-browser eval "$(cat "$CHECK_JS")" 2>/dev/null | strip_quotes || echo "UNKNOWN")
    if [ "$STATE" = "RESULTS" ]; then
        echo "RESULTS_REACHED: $TOTAL_Q steps, $SURVEYED survey"
        exit 0
    fi
done

if [ "$SURVEYED" -gt 0 ]; then
    echo "SURVEY_DONE_NO_RESULTS: $TOTAL_Q steps, $SURVEYED survey"
    exit 1
fi

echo "FORM_INCOMPLETE: $TOTAL_Q steps, state=$STATE"
exit 1
