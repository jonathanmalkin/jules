#!/usr/bin/env bash
# verify-results-page.sh — Test all interactive elements on the results page.
#
# Requires: agent-browser session on the results page (after flow completion).
#
# Usage: ./verify-results-page.sh [test_email]
#   test_email: email to use for capture test (default: auto-generated)
#
# Output: per-test PASS/FAIL lines, screenshot saved per step, exit code 0 if all pass.

set -uo pipefail

SCREENSHOT_DIR="/tmp/smoke"
mkdir -p "$SCREENSHOT_DIR"

TEST_EMAIL="${1:-smoketest_$(date +%Y-%m-%d_%H%M%S)@example.com}"
FAILURES=0

pass() { echo "  PASS: $1"; }
fail() { echo "  FAIL: $1"; FAILURES=$((FAILURES + 1)); }

echo "=== Results Page Verification ==="
echo "Test email: $TEST_EMAIL"
echo ""

# --- Step 1: Verify elements exist ---
echo "Step 1: Verify required elements"
SNAP=$(agent-browser snapshot -i 2>/dev/null)

echo "$SNAP" | grep -q '"Download"'            && pass "Download button present"           || fail "Download button missing"
echo "$SNAP" | grep -q '"Email address"'        && pass "Email field present"              || fail "Email field missing"
echo "$SNAP" | grep -q '"Send Me' && pass "Email submit button present" || fail "Email submit button missing"
echo "$SNAP" | grep -q 'Retake'                 && pass "Retake button present"            || fail "Retake button missing"

# Check that email submit is disabled before email entry
echo "$SNAP" | grep '"Send Me' | head -1 | grep -q 'disabled' && pass "Email submit disabled (no email)" || fail "Email submit should be disabled without email"

agent-browser screenshot --full "$SCREENSHOT_DIR/results-overview.png" 2>/dev/null
echo ""

# --- Step 2: Test Download button ---
echo "Step 2: Download scores button"
DL_REF=$(echo "$SNAP" | grep '"Download"' | grep -v 'Share' | grep -o '\[ref=e[0-9]*\]' | sed 's/\[ref=/@/;s/\]//' | head -1)
if [ -n "$DL_REF" ]; then
    agent-browser click "$DL_REF" 2>/dev/null
    sleep 2
    agent-browser screenshot "$SCREENSHOT_DIR/after-download.png" 2>/dev/null
    DL_TEXT=$(agent-browser get text body 2>/dev/null)
    echo "$DL_TEXT" | grep -qi 'downloaded' && pass "Download confirmation shown" || fail "No download confirmation text"
else
    fail "Could not find Download button ref"
fi
echo ""

# --- Step 3: Test email capture ---
echo "Step 3: Email capture"
SNAP=$(agent-browser snapshot -i 2>/dev/null)  # re-snapshot after previous click
EMAIL_REF=$(echo "$SNAP" | grep '"Email address"' | grep -o '\[ref=e[0-9]*\]' | sed 's/\[ref=/@/;s/\]//' | head -1)
SUBMIT_REF=$(echo "$SNAP" | grep '"Send Me' | grep -o '\[ref=e[0-9]*\]' | sed 's/\[ref=/@/;s/\]//' | head -1)

if [ -n "$EMAIL_REF" ] && [ -n "$SUBMIT_REF" ]; then
    agent-browser fill "$EMAIL_REF" "$TEST_EMAIL" 2>/dev/null

    # Verify button enables after email entry
    SNAP_AFTER=$(agent-browser snapshot -i 2>/dev/null)
    if echo "$SNAP_AFTER" | grep '"Send Me' | head -1 | grep -q 'disabled'; then
        fail "Email submit still disabled after email entry"
    else
        pass "Email submit enabled after email entry"
    fi

    # Submit
    agent-browser click "$SUBMIT_REF" 2>/dev/null
    sleep 3
    agent-browser screenshot "$SCREENSHOT_DIR/after-email.png" 2>/dev/null
    EMAIL_TEXT=$(agent-browser get text body 2>/dev/null)
    echo "$EMAIL_TEXT" | grep -qi 'check your inbox' && pass "Email confirmation message shown" || fail "No email confirmation message"

    # Verify email field is gone (replaced by confirmation)
    SNAP_POST=$(agent-browser snapshot -i 2>/dev/null)
    if echo "$SNAP_POST" | grep -q '"Email address"'; then
        fail "Email field still present after submission"
    else
        pass "Email field replaced by confirmation"
    fi
else
    fail "Could not find email field or submit button refs"
fi
echo ""

# --- Step 4: Test Retake button ---
echo "Step 4: Retake button"
SNAP=$(agent-browser snapshot -i 2>/dev/null)
RETAKE_REF=$(echo "$SNAP" | grep 'Retake' | grep -o '\[ref=e[0-9]*\]' | sed 's/\[ref=/@/;s/\]//' | head -1)
if [ -n "$RETAKE_REF" ]; then
    agent-browser click "$RETAKE_REF" 2>/dev/null
    sleep 1
    SNAP_LANDING=$(agent-browser snapshot -i 2>/dev/null)
    echo "$SNAP_LANDING" | grep -qi 'Get Started' && pass "Retake returns to landing page" || fail "Retake did not return to landing page"
    agent-browser screenshot "$SCREENSHOT_DIR/after-retake.png" 2>/dev/null
else
    fail "Could not find Retake button ref"
fi
echo ""

# --- Summary ---
echo "=== Results ==="
echo "Screenshots saved to: $SCREENSHOT_DIR/"
if [ "$FAILURES" -eq 0 ]; then
    echo "ALL PASSED"
    exit 0
else
    echo "$FAILURES FAILURE(S)"
    exit 1
fi
