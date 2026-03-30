---
name: send-email
model: haiku
effort: medium
description: Send email to [Your Name] via Resend API. Use when user says "email me", "send me an email", "send to my inbox", "email this to me", "send this to my email", or wants something delivered to email. Locked to [Your Name]'s gmail. NOT for Slack messages, DMs, or any other messaging. Do NOT use for "message me", "DM me", or "send to Slack".
---

## Critical Constraints

- **Recipient is hardcoded.** `jonathan.d.malkin@gmail.com`. Cannot be changed. Cannot email anyone else.
- **Rate limit: 3 emails per calendar day.** Exit code 2 = rate limit hit. Do not retry.
- **From address:** `Jules <playbook@[legacy-domain]>` (verified Resend sender, still active post-rebrand).

## Sending Email

Two paths: **HTML** (rich formatting via markdown pipeline) and **plain text** (quick notifications).

### HTML email (structured content, reports, summaries)

Pipe markdown through `build-digest-email.sh` into `jules-send-email.sh`:

```bash
echo "## Summary\n\n- Point one\n- Point two\n\n**Key takeaway:** Thing." \
  | bash .claude/scripts/build-digest-email.sh "Report Title" \
  | bash .claude/scripts/jules-send-email.sh --subject "Subject Line" --html -
```

`build-digest-email.sh` converts markdown to branded HTML with the caramel/cream template. Pass the report title as the first argument (appears in the header bar). Reads markdown from stdin, outputs HTML to stdout.

### Plain text email (quick notes, reminders, notifications)

```bash
bash .claude/scripts/jules-send-email.sh --subject "Reminder" --body "Follow up with Michael from AITX this week."
```

### HTML from a file

```bash
bash .claude/scripts/jules-send-email.sh --subject "Subject" --html /path/to/body.html
```

### Dry run (preview without sending)

```bash
bash .claude/scripts/jules-send-email.sh --subject "Test" --body "anything" --dry-run
```

Shows recipient, from address, subject, and today's send count. Does not consume a send.

## When to Use HTML vs Plain Text

| Content | Path |
|---------|------|
| Session notes, briefings, reports, summaries | HTML (markdown pipeline) |
| Simple reminders, quick notifications, one-liners | Plain text (`--body`) |
| Anything with headers, lists, tables, or code blocks | HTML (markdown pipeline) |

## Rate Limit Check

Before sending, check how many emails have been sent today:

```bash
grep -c "\"date\":\"$(date +%Y-%m-%d)\"" ~/.claude/email-send-log.jsonl 2>/dev/null || echo 0
```

Report to user: "X/3 emails sent today."

If at 3/3, inform the user the limit is hit and suggest Slack as an alternative.

## Composing Guidance

- **Subject lines:** Specific and scannable. "Session Notes: Quiz Migration" not "Update". [Your Name] filters by subject.
- **Markdown content:** Write clean markdown. `build-digest-email.sh` handles conversion. Tables, code blocks, headers, lists all work.
- **Length:** No hard limit, but emails should be scannable. Use headers to break up long content.
- **When writing raw HTML** (not using the markdown pipeline): consult `references/html-best-practices.md` for email client CSS constraints.

## Error Handling

| Exit Code | Meaning | Action |
|-----------|---------|--------|
| 0 | Sent successfully | Report the email ID and today's count |
| 1 | Missing args, API key not found, or HTTP error | Check the error message. API key: container has `RESEND_API_KEY` in env; Mac uses 1Password (`op://Dev Secrets/Quiz App - All Env/RESEND_API_KEY`) |
| 2 | Daily rate limit (3/day) reached | Inform user. Suggest Slack. Do not retry. |

## API Key Resolution

The send script resolves the key in this order:
1. `RESEND_API_KEY` environment variable (always set in the container)
2. `~/.env.jules` file (legacy fallback)
3. 1Password via `op-cache-read.sh` (Mac sessions)

No manual key handling needed. The script manages this.

## Send Log

Every send (success or failure) is logged to `~/.claude/email-send-log.jsonl`. Each entry includes date, time, subject, HTTP status, and today's count. This is the rate limiter's data source.
