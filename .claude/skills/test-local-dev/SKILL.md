---
name: test-local-dev
description: Use when testing a web app UI in the local development environment. Covers dev server startup, browser automation with agent-browser, navigating app flows, and verifying visual changes before deploying. Mobile-first (iPhone X dimensions).
---

## Purpose

Browser automation for testing your web app in local development. Uses `agent-browser` CLI for fast iteration.

## When to Use

- Testing front-end UI changes locally
- Navigating through the app flow in dev
- Using dev tools to skip to specific states or load test profiles
- Verifying visual changes before deploying

**NOT for production/staging** -- use `test-prod` skill instead.

## Instructions

### Step 1: Check Dev Server

```bash
# Check if your dev server is running
# Adapt these commands to your project's package manager and scripts
pnpm run dev:status    # or: npm run dev:status, yarn dev:status
```

If not running:

```bash
pnpm run dev:full  # run with run_in_background: true
```

Wait 8-10 seconds, then re-check to get the dev server port.

**Fallback** (if your dev script fails):
```bash
for port in 8080 8081 8082 8083 8084 8085; do
  lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1 && echo "DEV_PORT=$port" && break
done
```

### Step 2: Open Browser

```bash
agent-browser open "http://localhost:{DEV_PORT}" --headed
agent-browser snapshot -i
```

---

## App Flow Navigation

### General Pattern

```bash
# Take a snapshot to see interactive elements
agent-browser snapshot -i

# Click elements by reference
agent-browser click @e1                    # First interactive element

# Take another snapshot to see the new state
agent-browser snapshot -i
```

### Custom UI Elements

Some UI elements (custom radio buttons, styled inputs, etc.) may not appear in `snapshot -i`. Use JS evaluation to interact with them:

```bash
# Click by aria-label:
agent-browser eval "document.querySelector('[aria-label=\"Your Label\"]')?.click()"

# Click by data-testid:
agent-browser eval "document.querySelector('[data-testid=\"your-id\"]')?.click()"
```

### Skip Through a Multi-Step Flow

```bash
for i in $(seq 1 30); do
  agent-browser snapshot -i 2>/dev/null | grep -q "Skip" || break
  REF=$(agent-browser snapshot -i 2>/dev/null | grep 'Skip' | grep -o 'ref=e[0-9]*' | sed 's/ref=//' | head -1)
  agent-browser click "@$REF" 2>/dev/null
  sleep 0.3
done
```

---

## Dev Toolbar (If Available)

Many apps include a dev-only toolbar for testing. Common actions:

| Action | Description |
|--------|-------------|
| Skip to Results | Jump past the flow to see output |
| Load Test Profile | Pre-fill with known test data |
| Configure Output | Adjust result display settings |
| Start Over | Clear state and return to beginning |

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Port conflicts | Kill existing processes on the port |
| Dev toolbar not visible | Only available in development mode |
| Custom elements not in snapshot | Use `agent-browser eval` with JS click |
| API errors | Verify backend server is running |
| Element not found | Use `agent-browser snapshot` (no `-i`) to see full tree |
