---
name: weekly-field-notes
description: >
  Generate weekly field notes from scout-techniques intelligence. Reads the week's CC-Intelligence
  reports, produces a weekly digest, and drafts individual spotlight posts (Reddit long-form +
  tweet thread) for the top 2-3 finds. Queues all drafts for approval. Use when the user says
  "weekly field notes", "weekly digest", "write up the week's finds", "field notes", or invokes
  /weekly-field-notes. Typically run on Fridays or at end of week.
user_invocable: true
---

# Weekly Field Notes

Turn the week's scout-techniques intelligence into publishable content.

**Output:** One weekly digest report + spotlight drafts for top items, all queued for approval.

## Phase 1: Gather the Week's Reports

```bash
INTEL_DIR="$HOME/workspace/Documents/Field-Notes/CC-Intelligence"
WEEK_AGO=$(date -d "7 days ago" +%Y-%m-%d 2>/dev/null || date -v-7d +%Y-%m-%d)
TODAY=$(date +%Y-%m-%d)

# List reports from the past 7 days
ls "$INTEL_DIR"/report-*.md 2>/dev/null | while read f; do
    fname=$(basename "$f")
    report_date="${fname#report-}"
    report_date="${report_date%.md}"
    [[ "$report_date" > "$WEEK_AGO" ]] && echo "$f"
done | sort
```

If no reports exist in the past 7 days: output "No reports found this week. Run /scout-techniques first." and stop.

Load all matching report files. Extract:
- **Key findings** sections from each report
- **Adoptability scores** (items scored 8+)
- **Setup comparison** notes (gaps identified)

## Phase 2: Identify Top Items

From all reports, rank by adoptability signal:
- Score 9-10: Spotlight candidate (deep draft)
- Score 7-8: Digest mention (summary only)
- Score 5-6: Listed (title + one line)
- Below 5: Skip

**Max spotlights:** 3 per week. If more than 3 score 9-10, pick by recency + novelty.

## Phase 3: Generate Weekly Digest

Write to `Documents/Field-Notes/CC-Intelligence/weekly-digest-{YYYY-WNN}.md`:

```markdown
# Claude Code Weekly Field Notes — Week {N}, {YYYY}
{date range}

## What Caught My Eye This Week

{For each item scoring 7+: 2-3 sentences. What it is, why it matters, whether we've already done something similar. No fluff.}

## Spotlight: {Top Item Title}

{100-200 words. The thing itself, why it's interesting to an AI builder audience, what we already do or plan to do with it.}

## In Our Setup

{One paragraph: how this week's findings connect to our actual .claude/ config. What we adopted, what we're considering, what we explicitly decided against.}

## Worth Watching

{Any emerging patterns or repeated themes that didn't hit individual threshold but are worth tracking.}
```

## Phase 4: Draft Spotlight Posts

For each item scoring 9-10, generate two drafts. Save to `Documents/Content-Pipeline/01-Drafts/Field-Notes-Spotlights/`:

**File:** `spotlight-{YYYY-MM-DD}-{slug}.md`

```markdown
# Spotlight: {Title}
Source: {URL}
Draft date: {TODAY}
Status: needs-review

---
## Reddit Long-Form Draft

{300-600 words in [Your Name]'s voice. Structure:
- Opening hook: the specific thing that caught attention
- What it is (brief, assume technical audience)
- The insight worth sharing (the "so what" for AI builders)
- Our experience / how it applies to the setup
- Open question or invitation for discussion

No marketing language. Specific over generic. Technical details welcome.}

---
## Tweet Thread Draft

{3-5 tweets. Each standalone-valuable.
Tweet 1: The hook — the specific insight, not a tease
Tweet 2-3: The substance — what it is, why it matters
Tweet 4: Application — how it applies to our setup or what we're doing with it
Tweet 5 (optional): Open question or CTA

Format: numbered, 280 char max each, [Your Name]'s voice.}
```

## Phase 5: Slack Notification

```bash
# NOTE: Requires container with Slack daemon. Remove or adapt if not using the container setup.
bash /home/claude/workspace/.claude/scripts/slack-send.sh --ops "📓 *Weekly Field Notes ready*

$(ls Documents/Field-Notes/CC-Intelligence/weekly-digest-*.md | tail -1)
Spotlights: $(ls Documents/Content-Pipeline/01-Drafts/Field-Notes-Spotlights/spotlight-$(date +%Y-%m-%d)*.md 2>/dev/null | wc -l) drafts queued for review."
```

## Output to User

After completing all phases, show a summary:

```
**Weekly Field Notes — {date range}**

Digest: Documents/Field-Notes/CC-Intelligence/weekly-digest-{slug}.md
Spotlights: {N} drafts in Documents/Content-Pipeline/01-Drafts/Field-Notes-Spotlights/

Top this week:
- {Item 1 title} (score X) → spotlight draft ready
- {Item 2 title} (score X) → spotlight draft ready
- {Item 3 title} (score X) → digest mention

Review drafts and approve to queue for posting.
```
