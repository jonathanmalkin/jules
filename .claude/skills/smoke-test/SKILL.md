---
name: smoke-test
description: >
  Run a browser-based smoke test of the web app against staging
  (staging.example.com) or production (app.example.com). Use before
  deployments or when verifying the live site works end-to-end. Triggers on
  "smoke test the app", "test staging", "test the live site", or
  "pre-deploy check".
allowed-tools:
  - Bash
  - Read
  - Write
  - Glob
  - Grep
---

# Smoke Test

Browser-automation smoke test for the web app, run via
`agent-browser`. This complements the project's Playwright CI suite
(`pnpm run test:smoke` in `~/your-workspace/Code/my-app/`) by doing a
human-like walkthrough of the live staging or production site.

## When to use

| Trigger | Target |
|---------|--------|
| Pre-deploy validation | `staging.example.com` |
| Post-deploy sanity check | `app.example.com` |
| User says "smoke test the app" | Ask which environment |

## Environment

| Env | URL |
|-----|-----|
| Staging | `https://staging.example.com` |
| Production | `https://app.example.com` |

Default to **staging** unless the user specifies production.

## Prerequisites

- `agent-browser` CLI installed and working
- No login or auth required (app is public)

## Test Plan

Run these phases in order. Take a screenshot at each phase for visual
verification. Stop and report on the first hard failure; note soft issues
(visual glitches, slow loads) but continue.

### Phase 0 -- Setup

```bash
agent-browser close 2>/dev/null
agent-browser open <TARGET_URL>
agent-browser wait --load networkidle
agent-browser screenshot /tmp/smoke-landing.png
```

Verify: page title loads correctly, hero section visible.

### Phase 1 -- Landing page

```bash
agent-browser snapshot -i
```

Verify these elements exist:
- Primary CTA button (e.g., "Start" or "Get Started")
- Content cards or feature sections
- Footer links: Privacy Policy, Terms of Service

**Test one content modal:**
- Click any "Learn more" button
- Verify modal opens with title, description, CTA
- Close the modal

### Phase 2 -- Consent/onboarding gate

```bash
agent-browser click @<start-button-ref>
agent-browser snapshot -i
```

Verify:
- Any required checkboxes are present and unchecked
- Continue button is **disabled** until requirements met
- After checking requirements, button enables

Click to proceed.

### Phase 3 -- Multi-step form/flow

The app has a **dynamic number of steps** determined by user choices.
Sections may have "Complete section" buttons at boundaries that advance
to the next section, not to results.

**Important:** Form controls may be custom-styled elements, not standard
`<button>` elements. Use `agent-browser eval` with
`document.querySelectorAll("[role=radio]")` or appropriate selectors to
click them reliably.

Do NOT rely on snapshot refs (`@eNN`) for form answers -- they shift
between steps. Use JS eval for the interaction loop.

**Click through all steps** with varied answers. After each interaction,
check the snapshot:
- If results/completion indicators appear, break out of the loop.
- If "Complete section" appears, click it (advances to next section).

Verify during the flow:
- Progress indicator updates
- Navigation buttons are present
- Accessibility skip-links exist

### Phase 4 -- Results page

```bash
agent-browser screenshot --full /tmp/smoke-results.png
agent-browser snapshot -i
```

Verify these elements are present:
- Result content card with computed output
- Score/data visualization
- Download button
- Email input field + submit button (disabled until email entered)
- "Start Over" or retake button

**Test Download button:**
```bash
agent-browser click @<download-ref>
sleep 2
agent-browser screenshot /tmp/smoke-download.png
```
Verify: download confirmation text appears.

**Test email capture:**
```bash
TEST_EMAIL="smoketest_$(date +%Y-%m-%d_%H%M%S)@example.com"
agent-browser fill @<email-ref> "$TEST_EMAIL"
agent-browser snapshot -i  # verify submit is now enabled
agent-browser click @<submit-ref>
sleep 2
agent-browser screenshot /tmp/smoke-email.png
```
Verify:
- Submit button enables after email entry
- After submit: confirmation message appears
- Email field is replaced by confirmation message

**Test Retake/Start Over button:**
```bash
agent-browser click @<retake-ref>
agent-browser wait 1000
agent-browser snapshot -i
```
Verify: returns to landing page.

### Phase 5 -- Footer links

From the landing page, test each footer link opens the correct URL:

| Link | Expected URL |
|------|-------------|
| Privacy Policy | `https://example.com/privacy-policy/` |
| Terms of Service | `https://example.com/terms-of-service/` |

After each link, navigate back to the app to test the next.

### Phase 6 -- Mobile viewport (optional but recommended)

```bash
agent-browser close
agent-browser open <TARGET_URL> --viewport 375x812
```

Quick-check:
- Landing page is responsive (no horizontal scroll, readable text,
  touch-friendly buttons)
- Start flow -> complete 2-3 steps -> verify layout
- No need to complete full flow on mobile unless desktop had issues

### Phase 7 -- Cleanup & report

```bash
agent-browser close
```

Present results as a pass/fail table:

```
| Test | Status | Notes |
|------|--------|-------|
| Landing page elements | PASS/FAIL | ... |
| Content modals | PASS/FAIL | ... |
| Consent gate | PASS/FAIL | ... |
| Multi-step flow | PASS/FAIL | ... |
| Results - Download | PASS/FAIL | ... |
| Results - Email capture | PASS/FAIL | ... |
| Results - Retake | PASS/FAIL | ... |
| Footer links | PASS/FAIL | ... |
| Mobile layout | PASS/FAIL | ... |
```

## Known quirks

- Custom form controls may be **divs with `cursor:pointer`**, not `<button>`.
  Always snapshot with `-C` flag.
- The app retains state via local storage. A retake may show
  pre-selected answers from the previous run.
- In headless Playwright (used by agent-browser), file downloads go to
  an internal path, not `~/Downloads`. Verify downloads by checking for
  visual confirmation text on the page, not by checking the filesystem.
- The clipboard API may not work in headless mode. Verify clipboard
  copy by checking the confirmation text, not by reading the clipboard.
- **Toast notifications block clicks.** The app may show encouragement
  toast notifications that overlay interactive elements. `agent-browser
  click @ref` will fail with "blocked by another element." Workaround:
  use JS eval to click through the overlay or dismiss the toast first.

## Scripts

The `scripts/` directory contains deterministic bash scripts that handle
the trickiest parts of the test. The skill can either run the full
orchestrator or call individual scripts.

### Full orchestrator

```bash
${CLAUDE_SKILL_DIR}/scripts/run-smoke-test.sh [staging|production]
```

Runs all phases end-to-end and prints a PASS/FAIL summary table.
Screenshots are saved to `/tmp/smoke/`. Default environment is staging.

### Individual scripts

| Script | Purpose |
|--------|---------|
| `app-blast.sh` | **Fast path.** Phased JS evals -- clicks through form (batches of 15), survey, and waits for results. Each phase is a separate `agent-browser eval` call to survive context destruction. Requires browser on first form step. Prints `RESULTS_REACHED: N steps, M survey`. |
| `form-click-batch.js` | Clicks up to 15 form steps per eval. Shell-safe. Returns `BATCH_DONE:N`, `RESULTS_FOUND:N`, `SURVEY_FOUND:N`, or `NO_OPTIONS:N`. |
| `survey-click.js` | Clicks through survey interstitial (up to 6 attempts). Shell-safe. Returns `SURVEY_DONE:N` or `NO_SURVEY:0`. |
| `check-state.js` | Detects current page state. Shell-safe. Returns `RESULTS`, `SURVEY`, `FORM`, `CALCULATING`, or `UNKNOWN`. |
| `app-blast.js` | **Legacy.** Original single-eval approach -- may fail on long flows due to context destruction or timeout. Kept for reference. |
| `answer-all-steps.sh [max]` | **Legacy slow path.** Per-click traversal (7+ min). Kept for debugging individual steps. Does NOT handle survey interstitial. |
| `verify-results-page.sh [email]` | Test all results page buttons (Download, email capture, Retake). Requires browser on results page. Prints per-test PASS/FAIL. |
| `verify-footer-links.sh <url>` | Verify all footer links navigate to correct URLs. Requires browser on landing page. |

### When to use scripts vs. manual steps

- **Use the orchestrator** (`run-smoke-test.sh`) for routine pre-deploy
  checks. Uses `app-blast.sh` (fast path) by default.
- **Use `app-blast.sh` directly** when you only need to traverse the
  form flow without the full orchestrator (landing, consent, results
  verification, footer links, mobile).
- **Use `answer-all-steps.sh`** only when debugging a specific
  step (e.g., need to see each snapshot between clicks).
- **Use manual agent-browser steps** (per the phases above) when you
  need to visually inspect something or test edge cases not covered by
  the scripts.

## Existing Playwright tests

The app project at `~/your-workspace/Code/my-app/` has its own
Playwright test suite:

```bash
cd ~/your-workspace/Code/my-app
pnpm run test:smoke        # Tagged @smoke specs (desktop + iOS Safari)
pnpm run test:playwright   # All E2E tests
pnpm run test:a11y:all     # Accessibility tests
```

These run against localhost and require the dev servers to be running.
This skill is for testing the **live deployed site** without needing
the local dev environment.
