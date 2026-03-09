---
name: report-latest
description: Pull latest app analytics from production and report changes since the last data sync. Use when user says "report latest", "pull latest data", "app update", "what's changed", "analytics update", or invokes /report-latest. Do NOT use for the daily HTML email report (use preview-report for that).
user_invocable: true
---

# Report Latest Analytics

Pull fresh production data and show what changed since the last sync.

## Steps

1. Run the report command (terminal output):

```bash
make report-latest
```

2. Or open the visual HTML dashboard in the browser:

```bash
make pulse
```

3. Present the output to the user with brief commentary on notable changes:
   - Significant session/completion spikes or drops
   - Email conversion rate trends
   - New referral activity
   - New feedback or survey responses
   - Traffic source shifts

Default to `make pulse` (visual dashboard) unless the user specifically asks for terminal output or is in a context where opening a browser isn't practical.

## Troubleshooting

- **SSH connection refused**: Production server SSH must be accessible. Check `~/.ssh/config` for host entry.
- **1Password prompt**: Touch ID may fire on first run per 24-hour window. The key caches after first auth.
- **Empty diff**: If rows haven't changed, the pull was a no-op. Data on production matches local.
