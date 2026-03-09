#!/usr/bin/env bash
# run-smoke-test.sh — Full end-to-end smoke test of the web app.
#
# Usage: ./run-smoke-test.sh [staging|production]
#   Default: staging
#
# Runs all phases: landing -> consent -> form -> results -> footer -> mobile
# Outputs a PASS/FAIL summary table at the end.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV="${1:-staging}"
SCREENSHOT_DIR="/tmp/smoke"
mkdir -p "$SCREENSHOT_DIR"

case "$ENV" in
    staging)    URL="https://staging.example.com" ;;
    production) URL="https://app.example.com" ;;
    *)          echo "Usage: $0 [staging|production]"; exit 1 ;;
esac

echo "========================================"
echo "  App Smoke Test — $ENV"
echo "  URL: $URL"
echo "  $(date)"
echo "========================================"
echo ""

# Track results
declare -a TEST_NAMES=()
declare -a TEST_RESULTS=()
declare -a TEST_NOTES=()

record() {
    TEST_NAMES+=("$1")
    TEST_RESULTS+=("$2")
    TEST_NOTES+=("${3:-}")
}

# --- Phase 0: Setup ---

echo "Phase 0: Setup"
agent-browser close 2>/dev/null
agent-browser open "$URL" 2>/dev/null
agent-browser wait --load networkidle 2>/dev/null
sleep 3  # React SPA hydration
TITLE=$(agent-browser get title 2>/dev/null)
agent-browser screenshot "$SCREENSHOT_DIR/00-landing.png" 2>/dev/null

if echo "$TITLE" | grep -qiE "your-app-title"; then
    echo "  Page loaded: $TITLE"
    record "Page load" "PASS" "$TITLE"
else
    echo "  FAIL: Unexpected title: $TITLE"
    record "Page load" "FAIL" "Title: $TITLE"
fi
echo ""

# --- Phase 1: Landing page elements ---

echo "Phase 1: Landing page"
SNAP=$(agent-browser snapshot -i 2>/dev/null)

LANDING_OK=true
for ELEM in "Get Started" "Privacy Policy" "Terms of Service"; do
    if ! echo "$SNAP" | grep -q "$ELEM"; then
        echo "  MISSING: $ELEM"
        LANDING_OK=false
    fi
done

# Check content cards
CARDS=("Card A" "Card B" "Card C" "Card D" "Card E")
MISSING_CARDS=()
for A in "${CARDS[@]}"; do
    echo "$SNAP" | grep -q "$A" || MISSING_CARDS+=("$A")
done

if [ ${#MISSING_CARDS[@]} -gt 0 ]; then
    echo "  MISSING cards: ${MISSING_CARDS[*]}"
    LANDING_OK=false
fi

if $LANDING_OK; then
    record "Landing page elements" "PASS" ""
else
    record "Landing page elements" "FAIL" "Missing: ${MISSING_CARDS[*]:-elements}"
fi

# Test one content modal
MODAL_REF=$(echo "$SNAP" | grep '"Learn more about' | grep -o '\[ref=e[0-9]*\]' | sed 's/\[ref=/@/;s/\]//' | head -1)
if [ -n "$MODAL_REF" ]; then
    agent-browser click "$MODAL_REF" 2>/dev/null
    sleep 1
    MODAL_SNAP=$(agent-browser snapshot -i 2>/dev/null)
    agent-browser screenshot "$SCREENSHOT_DIR/01-modal.png" 2>/dev/null
    if echo "$MODAL_SNAP" | grep -q "Close"; then
        record "Content modal" "PASS" ""
        CLOSE_REF=$(echo "$MODAL_SNAP" | grep '"Close"' | grep -o '\[ref=e[0-9]*\]' | sed 's/\[ref=/@/;s/\]//' | head -1)
        agent-browser click "$CLOSE_REF" 2>/dev/null
        sleep 0.5
    else
        record "Content modal" "FAIL" "No Close button found"
    fi
else
    record "Content modal" "FAIL" "No Learn more button found"
fi
echo ""

# --- Phase 2: Consent gate ---

echo "Phase 2: Consent gate"
SNAP=$(agent-browser snapshot -i 2>/dev/null)
START_REF=$(echo "$SNAP" | grep -i 'Get Started' | grep -o '\[ref=e[0-9]*\]' | sed 's/\[ref=/@/;s/\]//' | head -1)
if [ -z "$START_REF" ]; then
    # Fallback: try alternate CTA button
    START_REF=$(echo "$SNAP" | grep -i 'Take the' | grep -o '\[ref=e[0-9]*\]' | sed 's/\[ref=/@/;s/\]//' | head -1)
fi
echo "  Clicking: $START_REF"
agent-browser click "$START_REF" 2>/dev/null
sleep 2  # Wait for React state transition

CONSENT_SNAP=$(agent-browser snapshot -i 2>/dev/null)
agent-browser screenshot "$SCREENSHOT_DIR/02-consent.png" 2>/dev/null

CONSENT_OK=true
# Check disabled state
if ! echo "$CONSENT_SNAP" | grep -q 'disabled'; then
    echo "  WARNING: Continue button not disabled before checkbox"
    CONSENT_OK=false
fi

# Check and agree
CHECKBOX_REF=$(echo "$CONSENT_SNAP" | grep 'checkbox' | grep -o '\[ref=e[0-9]*\]' | sed 's/\[ref=/@/;s/\]//' | head -1)
if [ -n "$CHECKBOX_REF" ]; then
    agent-browser check "$CHECKBOX_REF" 2>/dev/null
    sleep 0.3
    AFTER_CHECK=$(agent-browser snapshot -i 2>/dev/null)
    if echo "$AFTER_CHECK" | grep -q '"Begin"'; then
        echo "  Button enabled: Begin"
    else
        echo "  WARNING: Button text did not change to Begin"
        CONSENT_OK=false
    fi
    # Click to proceed
    BEGIN_REF=$(echo "$AFTER_CHECK" | grep '"Begin"' | grep -o '\[ref=e[0-9]*\]' | sed 's/\[ref=/@/;s/\]//' | head -1)
    agent-browser click "$BEGIN_REF" 2>/dev/null
    sleep 0.5
else
    echo "  FAIL: No checkbox found"
    CONSENT_OK=false
fi

$CONSENT_OK && record "Consent gate" "PASS" "" || record "Consent gate" "FAIL" ""
echo ""

# --- Phase 3: Form flow ---

echo "Phase 3: Form + survey (fast path)"
agent-browser screenshot "$SCREENSHOT_DIR/03-first-question.png" 2>/dev/null

FORM_OUTPUT=$("$SCRIPT_DIR/app-blast.sh" 2>&1)
echo "$FORM_OUTPUT" | tail -1

if echo "$FORM_OUTPUT" | grep -q "RESULTS_REACHED"; then
    Q_INFO=$(echo "$FORM_OUTPUT" | grep -o '[0-9]* steps, [0-9]* survey')
    record "Form flow" "PASS" "$Q_INFO"
else
    record "Form flow" "FAIL" "Did not reach results"
    echo "  FAIL — aborting remaining tests"
    # Print summary and exit
    echo ""
    echo "========================================"
    echo "  RESULTS SUMMARY"
    echo "========================================"
    printf "| %-25s | %-6s | %s\n" "Test" "Status" "Notes"
    printf "| %-25s | %-6s | %s\n" "-------------------------" "------" "-----"
    for i in "${!TEST_NAMES[@]}"; do
        printf "| %-25s | %-6s | %s\n" "${TEST_NAMES[$i]}" "${TEST_RESULTS[$i]}" "${TEST_NOTES[$i]}"
    done
    exit 1
fi
echo ""

# --- Phase 4: Results page ---

echo "Phase 4: Results page"
agent-browser screenshot --full "$SCREENSHOT_DIR/04-results.png" 2>/dev/null

TEST_EMAIL="smoketest_$(date +%Y-%m-%d_%H%M%S)@example.com"
RESULTS_OUTPUT=$("$SCRIPT_DIR/verify-results-page.sh" "$TEST_EMAIL" 2>&1)
echo "$RESULTS_OUTPUT"

# Parse individual results from the verify script
echo "$RESULTS_OUTPUT" | grep -q "FAIL:" && RESULTS_FAILED=true || RESULTS_FAILED=false

# Record individual sub-tests by matching PASS/FAIL lines directly
for SUBTEST in "Download" "Email" "Retake"; do
    LINES=$(echo "$RESULTS_OUTPUT" | grep -E "(PASS|FAIL):.*$SUBTEST")
    if echo "$LINES" | grep -q "FAIL"; then
        record "Results - $SUBTEST" "FAIL" ""
    elif echo "$LINES" | grep -q "PASS"; then
        record "Results - $SUBTEST" "PASS" ""
    else
        record "Results - $SUBTEST" "SKIP" "Could not determine"
    fi
done
echo ""

# --- Phase 5: Footer links ---

echo "Phase 5: Footer links"
# Navigate back to landing (retake button should have done this)
agent-browser open "$URL" 2>/dev/null
agent-browser wait --load networkidle 2>/dev/null
sleep 3

FOOTER_OUTPUT=$("$SCRIPT_DIR/verify-footer-links.sh" "$URL" 2>&1)
echo "$FOOTER_OUTPUT"
echo "$FOOTER_OUTPUT" | grep -q "ALL PASSED" && record "Footer links" "PASS" "" || record "Footer links" "FAIL" ""
echo ""

# --- Phase 6: Mobile viewport ---

echo "Phase 6: Mobile viewport (375x812)"
agent-browser close 2>/dev/null
agent-browser open "$URL" --viewport 375x812 2>/dev/null
agent-browser wait --load networkidle 2>/dev/null
agent-browser screenshot "$SCREENSHOT_DIR/06-mobile-landing.png" 2>/dev/null

MOBILE_SNAP=$(agent-browser snapshot -i 2>/dev/null)
if echo "$MOBILE_SNAP" | grep -q "Get Started"; then
    record "Mobile layout" "PASS" ""
else
    record "Mobile layout" "FAIL" "Landing page elements missing"
fi
echo ""

# --- Phase 7: Cleanup & Summary ---

agent-browser close 2>/dev/null

echo "========================================"
echo "  RESULTS SUMMARY — $ENV"
echo "  $(date)"
echo "========================================"
printf "| %-25s | %-6s | %s\n" "Test" "Status" "Notes"
printf "| %-25s | %-6s | %s\n" "-------------------------" "------" "-----"

TOTAL_FAIL=0
for i in "${!TEST_NAMES[@]}"; do
    printf "| %-25s | %-6s | %s\n" "${TEST_NAMES[$i]}" "${TEST_RESULTS[$i]}" "${TEST_NOTES[$i]}"
    [ "${TEST_RESULTS[$i]}" = "FAIL" ] && TOTAL_FAIL=$((TOTAL_FAIL + 1))
done

echo ""
echo "Screenshots: $SCREENSHOT_DIR/"

if [ "$TOTAL_FAIL" -eq 0 ]; then
    echo "ALL TESTS PASSED"
    exit 0
else
    echo "$TOTAL_FAIL TEST(S) FAILED"
    exit 1
fi
