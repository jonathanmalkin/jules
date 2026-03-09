#!/usr/bin/env bash
# answer-all-steps.sh — Click through all form steps with varied answers.
#
# Handles dynamic step counts and section boundaries ("Complete section" buttons).
# Requires: agent-browser session already open on the first form step.
#
# Usage: ./answer-all-steps.sh [max_steps]
#   max_steps: safety limit to prevent infinite loops (default: 50)
#
# Answer pattern cycles: 4, 2, 5, 1, 3 (varied across the full Likert range)
# Exit: prints "RESULTS_REACHED" on success, "MAX_STEPS_HIT" on safety limit.

set -euo pipefail

MAX_Q="${1:-50}"
ANSWER_REFS=("@e25" "@e17" "@e29" "@e13" "@e21")  # 4, 2, 5, 1, 3
STEP=0

while [ "$STEP" -lt "$MAX_Q" ]; do
    # Snapshot to determine page state
    SNAP=$(agent-browser snapshot -i -C 2>/dev/null)

    # Check if we've reached the results page
    if echo "$SNAP" | grep -q '"Download"'; then
        echo "RESULTS_REACHED after $STEP steps"
        exit 0
    fi

    # Check if answer buttons are present (Likert scale)
    if ! echo "$SNAP" | grep -q 'StronglyDisagree'; then
        # Not on a question page — might be a transition or loading state
        sleep 1
        continue
    fi

    # Pick answer from cycle
    IDX=$((STEP % 5))
    ANSWER_REF="${ANSWER_REFS[$IDX]}"

    # Click the answer
    agent-browser click "$ANSWER_REF" 2>/dev/null

    sleep 0.3

    # Re-snapshot to find the correct next/complete button
    SNAP2=$(agent-browser snapshot -i 2>/dev/null)

    # Determine which button to click: "Complete section" or "Go to next question"
    if echo "$SNAP2" | grep -q '"Complete section"'; then
        # Section boundary — advances to next section
        COMPLETE_REF=$(echo "$SNAP2" | grep '"Complete section"' | grep -o '\[ref=e[0-9]*\]' | sed 's/\[ref=/@/;s/\]//' | head -1)
        agent-browser click "$COMPLETE_REF" 2>/dev/null
    elif echo "$SNAP2" | grep -q '"Go to next question"'; then
        NEXT_REF=$(echo "$SNAP2" | grep '"Go to next question"' | grep -o '\[ref=e[0-9]*\]' | sed 's/\[ref=/@/;s/\]//' | head -1)
        agent-browser click "$NEXT_REF" 2>/dev/null
    else
        echo "WARNING: No next/complete button found at step $((STEP + 1))"
        agent-browser click @e5 2>/dev/null  # fallback to typical ref
    fi

    STEP=$((STEP + 1))
    sleep 0.5
done

echo "MAX_STEPS_HIT ($MAX_Q)"
exit 1
