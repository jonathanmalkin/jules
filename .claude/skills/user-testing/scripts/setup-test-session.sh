#!/usr/bin/env bash
# setup-test-session.sh -- Prepare mobile browser session for user testing
#
# Creates directories, opens target URL at mobile viewport (375x812),
# navigates through any onboarding/consent gates, fast-forwards through
# the main flow to reach results, saves baseline screenshots.
#
# Usage: ./setup-test-session.sh <target-url>
#   e.g.: ./setup-test-session.sh https://staging.example.com
#
# Output: SETUP_COMPLETE on success, error message on failure
# Screenshots saved to /tmp/user-test/screenshots/

set -euo pipefail

TARGET_URL="${1:-https://staging.example.com}"
SCREENSHOT_DIR="/tmp/user-test/screenshots"

# --- Phase 1: Create directories ---
mkdir -p "$SCREENSHOT_DIR"
echo "Created /tmp/user-test/ and screenshots dir"

# --- Phase 2: Close existing sessions, open fresh mobile browser ---
agent-browser close 2>/dev/null || true
echo "Closed existing browser sessions"

agent-browser open "$TARGET_URL" --viewport 375x812
agent-browser wait --load networkidle
echo "Opened $TARGET_URL at 375x812"

# Baseline landing screenshot
agent-browser screenshot "$SCREENSHOT_DIR/setup-landing.png"
echo "Saved landing screenshot"

# --- Phase 3: Navigate through consent/onboarding gate ---
# Click the start/begin button (customize selectors for your app)
START_RESULT=$(agent-browser eval "var btn = Array.from(document.querySelectorAll('button, a')).find(function(el) { return /start|begin|take/i.test(el.textContent); }); if(btn) { btn.click(); 'CLICKED'; } else { 'NOT_FOUND'; }")

if [ "$START_RESULT" = "NOT_FOUND" ]; then
    echo "ERROR: Could not find start button on landing page"
    exit 1
fi
echo "Clicked start button"
sleep 2

# Handle any consent checkboxes
agent-browser eval "var cb = document.querySelector('input[type=checkbox]'); if(cb && cb.checked === false) { cb.click(); cb.dispatchEvent(new Event('change', {bubbles:true})); }"
sleep 1

# Click the continue/begin button
agent-browser eval "var btn = Array.from(document.querySelectorAll('button')).find(function(el) { return /begin|continue|next/i.test(el.textContent) && el.disabled === false; }); if(btn) btn.click();"
sleep 2

agent-browser screenshot "$SCREENSHOT_DIR/setup-first-step.png"
echo "Navigated through onboarding gate"

# --- Phase 4: Fast-forward through main flow to results ---
# CUSTOMIZE: Replace this section with your app's skip/fast-forward mechanism.
# For form-based apps, this might be a blast script. For other apps, click through steps quickly.
echo "NOTE: Customize Phase 4 to fast-forward through your app's main flow"
echo "Add your app's skip mechanism or rapid click-through logic here"

# Wait for results page to render
sleep 5

# --- Phase 5: Verify results page and save screenshots ---
agent-browser screenshot "$SCREENSHOT_DIR/setup-results-top.png"
agent-browser screenshot --full "$SCREENSHOT_DIR/setup-results-full.png"

# CUSTOMIZE: Update this check for your app's results page indicator
RESULTS_CHECK=$(agent-browser eval "document.querySelector('[data-testid=results], .results, #results') ? 'RESULTS_PAGE' : 'NOT_RESULTS'")

if [ "$RESULTS_CHECK" = "RESULTS_PAGE" ]; then
    echo "SETUP_COMPLETE: Results page reached at 375x812 mobile viewport"
    echo "Screenshots saved to $SCREENSHOT_DIR/"
    echo "Target: $TARGET_URL"
    exit 0
else
    echo "WARNING: Results page not auto-detected (customize the selector check)"
    echo "Screenshots saved to $SCREENSHOT_DIR/ for manual verification"
    echo "Target: $TARGET_URL"
    exit 0
fi
