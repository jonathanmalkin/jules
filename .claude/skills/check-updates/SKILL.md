---
name: check-updates
description: Display the latest Claude Code change monitor report. Use when the user says "check updates", "check for updates", "what's new in claude", or invokes /check-updates. Pass `run` to re-run the monitor on demand; default just shows the latest daily report.
user_invocable: true
---

# Check Updates

Show the latest Claude Code change monitor report. The monitor runs daily at 7 AM via launchd; this skill displays the result.

## Usage

```
/check-updates              Show the latest report (default)
/check-updates run          Run the monitor first, then show the report
/check-updates force        Force re-check all sources (ignore timestamps)
```

## Procedure

### 1. Determine the mode

- **No args, empty, or `latest`**: Show the latest report without running the monitor
- **`run`**: Run the monitor (checks for new changes since last run), then show the report
- **`force`**: Re-check everything ignoring last-check timestamps, then show the report

### 2. Run the monitor (only for `run` or `force` modes)

Skip this step if mode is show-latest (no args, empty, or `latest`).

Execute the monitor script:

```bash
# run mode
make monitor-claude

# force mode
make monitor-claude-force
```

The script takes 30-60 seconds (it fetches feeds and doc pages). Let the user know it's running.

If the script fails, show the error output and suggest:
- Check internet connectivity
- Try `make monitor-claude` from your workspace manually
- Check logs at `~/.claude/monitor-state/launchd.log`

### 3. Find and display the report

Reports live at `~/.claude/monitor-state/reports/report-YYYY-MM-DD.md`.

Find the most recent report:

```bash
ls -t ~/.claude/monitor-state/reports/report-*.md | head -1
```

Read the report file and display its full contents in the conversation. Do not summarize or truncate — show the complete report so the user can scan it naturally.

**Staleness check:** If the report date (from the filename) is more than 24 hours old, warn the user that the daily monitor may not be running and suggest `/check-updates run` to get a fresh report.

### 4. Clear the unread flag

If `~/.claude/monitor-state/unread` exists, remove it — the user has now seen the report:

```bash
mv ~/.claude/monitor-state/unread ~/.Trash/ 2>/dev/null || true
```

### 5. Offer next steps

After displaying the report, briefly note:
- How many infrastructure-relevant changes were found (count the `###` headers)
- If any have action items, offer to help implement them
- If no changes were found, just say so — no need to elaborate
