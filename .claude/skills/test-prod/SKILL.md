---
name: test-prod
description: Use when smoke testing or verifying the web app on staging (staging.example.com) or production (app.example.com). Covers the full user flow without DevToolbar, admin login, and deployment verification.
---

## Purpose

Browser automation for smoke testing the web app on staging and production. No DevToolbar available -- must navigate the full user flow.

## When to Use

- Smoke testing after deployment
- Verifying production UI renders correctly
- Checking the full app flow end-to-end on live
- Verifying admin dashboard is accessible

**NOT for local dev testing** -- use `test-local-dev` skill instead.

## Environments

| Environment | URL | Notes |
|-------------|-----|-------|
| Production | `https://app.example.com` | Live user-facing |
| Staging | `https://staging.example.com` | Pre-production testing |

## Smoke Test Checklist

A standard production smoke test covers these pages:

1. **Landing page** -- hero loads, content cards render, CTAs work
2. **Consent page** -- checkbox enables "Begin"
3. **Form flow** -- steps load, scale works, navigation works
4. **Results page** -- result card renders, scores display, email signup form present, download button visible
5. **Admin dashboard** -- login gate loads at `/admin`

---

## Quick Start

```bash
agent-browser open "https://app.example.com" --headed
agent-browser snapshot -i
agent-browser screenshot --full
```

## Full Flow Walkthrough

### Landing Page

```bash
agent-browser open "https://app.example.com" --headed
agent-browser snapshot -i
# Verify: "Get Started" button, content cards, CTAs
agent-browser screenshot --full
```

### Consent Page

```bash
agent-browser click @e1                    # "Get Started"
agent-browser snapshot -i
agent-browser click @e1                    # Confirmation checkbox
agent-browser snapshot -i
# Verify: "Begin" is now enabled (not disabled)
agent-browser click @e4                    # "Begin"
```

### Form Flow (Answer + Advance)

**Likert buttons do NOT appear in `snapshot -i`.** Use `agent-browser eval`:

```bash
# Select an answer (values 1-5):
agent-browser eval "document.querySelector('[aria-label*=\"Agree: 4\"]')?.click()"

# Advance to next question:
agent-browser snapshot -i
agent-browser click @e5                    # "Go to next question"
```

### Skip All Steps (Fast Path to Results)

```bash
for i in $(seq 1 30); do
  agent-browser snapshot -i 2>/dev/null | grep -q "Skip this question" || break
  REF=$(agent-browser snapshot -i 2>/dev/null | grep 'Skip this question' | grep -o 'ref=e[0-9]*' | sed 's/ref=//' | head -1)
  agent-browser click "@$REF" 2>/dev/null
  sleep 0.3
done
```

### Results Page

```bash
agent-browser screenshot
# Verify: result card with type + subtype, score bars, "Download" button
agent-browser scroll down
agent-browser screenshot
# Verify: email signup form (input + submit), "Start Over"
```

### Admin Dashboard

```bash
agent-browser open "https://app.example.com/admin"
agent-browser screenshot
# Verify: login form renders with Username/Password fields and "Sign in" button
```

---

## Element Reference (Production)

Same elements as local dev, but **no DevToolbar** available.

| Page | Element | Match By Text |
|------|---------|---------------|
| Landing | Start (hero) | `"Get Started"` |
| Landing | Start (bottom) | `"Take the Assessment"` |
| Landing | Content cards | `"Learn more about {Name}"` |
| Consent | Checkbox | `"I confirm I meet the requirements..."` |
| Consent | Begin Button | `"Begin"` |
| Form | Next | `"Go to next question"` |
| Form | Skip | `"Skip this question and continue"` |
| Results | Download | `"Download"` |
| Results | Email Input | placeholder `"you@example.com"` |
| Results | Submit Email | `"Get My Results"` |
| Results | Retake | `"Start Over"` |
| Admin | Username | textbox labeled `"Username"` |
| Admin | Password | textbox labeled `"Password"` |
| Admin | Sign In | `"Sign in"` |

---

## Deployment Verification

After deploying code to the server, verify the new files exist:

```bash
ssh your-server "ls ~/www/app.example.com/public_html/api/lib/ | sort"
```

Then run the smoke test above.

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Likert buttons not in snapshot | Use `agent-browser eval` with JS click (see above) |
| Site not loading | Check DNS, verify deployment completed |
| Admin auth failing | Credentials are separate from app flow |
| Stale content after deploy | Hard refresh or clear CDN cache |
| Element not found | Use `agent-browser snapshot` (no `-i`) to see full DOM tree |
