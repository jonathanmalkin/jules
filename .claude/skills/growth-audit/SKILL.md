---
name: growth-audit
description: "Structured growth analysis and experiment design for a web app. Pulls funnel metrics, identifies bottlenecks, optionally deep-dives into cohorts and behavioral patterns, and designs deploy-and-compare experiments with honest traffic reality checks. Use when user says 'growth audit', 'conversion analysis', 'experiment design', 'funnel analysis', 'what should we test next', 'A/B test', 'deep dive into data', 'cohort analysis', 'drop-off analysis', or invokes /growth-audit. Do NOT use for daily metrics snapshots (use /report-latest) or the HTML email report (use /preview-report)."
---

# Growth Audit

Structured growth experimentation for a web app. Combines funnel analysis, bottleneck identification, behavioral deep-dives, and experiment design into one workflow.

Experiments involve user-visible changes, so present recommendations as Decision Cards (Ask First).

## Constraints You Must Know

- **No feature flag system.** The app has no concurrent A/B testing infrastructure. All experiments are **deploy-and-compare**: ship a change, measure before/after using date cutoffs. Not ideal, but it's what we have.
- **No time-on-step data.** The analytics schema tracks sessions and events but not per-step duration. Drop-off analysis uses completion counts, not timing.
- **Low traffic reality.** ~[N] starts/day. At this volume, only bold changes (>30% relative effect) are measurable within a month. Be honest about this. Don't pretend subtle tweaks are testable.
- **Query path.** Use your analytics script with Python heredocs for complex queries.

## Phase 1: Funnel Snapshot

Pull current metrics using your analytics helper:

```bash
bash .claude/scripts/your-analytics-script.sh << 'PYEOF'
from your_queries import YourAnalytics

with YourAnalytics() as qa:
    # Core funnel (7-day and 30-day)
    for days in [7, 30]:
        print(f"\n=== {days}-Day Funnel ===")
        for r in qa.funnel(days): print(r)

    # Traffic sources
    print("\n=== UTM Sources (30d) ===")
    for r in qa.traffic_sources(days=30, by='utm'): print(r)

    # Daily trend (last 14 days)
    print("\n=== Daily Summary (14d) ===")
    for r in qa.daily_summary(days=14): print(r)
PYEOF
```

Calculate and present:
- **Stage conversion rates:** sessions -> started -> completed -> email signup -> referral
- **7-day vs 30-day comparison** to spot trends
- **Top traffic sources** by volume and completion rate
- **K-factor estimate** if referral data is available

Present as a clean table. No walls of JSON.

## Phase 2: Bottleneck Identification

For each funnel stage, calculate absolute drop-off count and percentage. The stage with the **biggest absolute loss** is the primary bottleneck.

For the completion stage specifically, query which steps are associated with drop-off:

```bash
bash .claude/scripts/your-analytics-script.sh << 'PYEOF'
from your_queries import YourAnalytics

with YourAnalytics() as qa:
    # Find the last step completed by users who didn't finish
    # Adapt this query to your schema (tables, columns, event types)
    rows = qa.query("""
        SELECT
            e.event_data,
            COUNT(*) as drop_count
        FROM your_events e
        JOIN your_users u ON e.user_id = u.id
        WHERE u.completed_at IS NULL
          AND u.created_at >= datetime('now', '-30 days')
          AND e.event_type = 'step_completed'
          AND e.id = (
              SELECT MAX(e2.id) FROM your_events e2
              WHERE e2.user_id = u.id AND e2.event_type = 'step_completed'
          )
        GROUP BY e.event_data
        ORDER BY drop_count DESC
        LIMIT 15
    """)
    for r in rows: print(r)
PYEOF
```

Present bottlenecks ranked by impact. Apply **RICE scoring** (Reach, Impact, Confidence, Effort) to help prioritize which to tackle:
- **Reach:** What % of users hit this stage?
- **Impact:** How large could the improvement be? (Use funnel math.)
- **Confidence:** How sure are we about the cause? (Data-backed vs. speculative.)
- **Effort:** How many files/changes to implement a fix?

## Phase 3: Deep Dive (Optional, On Request)

If the user asks to go deeper, or if the bottleneck cause isn't obvious, run targeted analysis:

**Cohort Comparison:**
- Segment by traffic source: do Reddit visitors complete at different rates than organic?
- Segment by device type (if trackable via user agent in sessions)
- Segment by time of day / day of week
- Which cohorts have highest email conversion?

**Behavioral Patterns:**
- Answer distribution analysis: are any steps heavily skewed toward one answer? (Possible confusion or social desirability.)
- Completion rate by result type: do users with certain results convert to email at higher rates?
- Survey response themes: what patterns emerge from free-text responses?

```bash
bash .claude/scripts/your-analytics-script.sh << 'PYEOF'
from your_queries import YourAnalytics

with YourAnalytics() as qa:
    # Survey feedback for qualitative signal
    print("=== Free-Text Responses ===")
    for r in qa.survey_freetext('your_field', days=30): print(r)

    # Full survey distributions
    print("\n=== Survey Distributions (30d) ===")
    import json
    data = qa.survey_all(days=30)
    for key, val in data.items():
        if key == 'your_field': continue
        print(f"\n{val['label']} (n={val['total']}):")
        for row in val['rows']:
            print(f"  {row.get('response_value', row.get('response_text', '?'))}: {row['count']}")
PYEOF
```

**Trend Analysis:**
- Week-over-week and month-over-month comparison
- Before/after analysis for specific deploy dates (check `git log --oneline -20` for recent changes)

## Phase 4: Experiment Design

For the top bottleneck, design a concrete change. Use this template:

```
## Experiment: [Name]

**Hypothesis:** If we [change], then [metric] will [improve by X%] because [reasoning].

**Change:** [Specific description of what changes]
- Control: [Current behavior]
- Variant: [New behavior]

**Primary metric:** [The one number that decides success/failure]
**Guardrail metrics:** [Metrics that must NOT degrade -- e.g., completion rate, page load time]

**Traffic reality check:**
- Current baseline: [metric value]
- Minimum detectable effect: [X% relative change]
- Required sample size: [N per variant]
- At ~[N] starts/day: [duration] days to reach 95% confidence
- Feasible? [Yes/No -- be honest]

**Implementation:**
- Method: Deploy-and-compare (before/after with date cutoff)
- Files to change: [list]
- Effort: [Trivial/Small/Medium]

**Decision criteria:**
- Success: [metric] improves by >=[X%] in [timeframe]
- Failure: No significant change after [timeframe], or guardrail metrics degrade
- Stop early if: [any catastrophic signal]
```

**Traffic math reference** (for email signup at [X]% baseline, 50/50 split):
- 50% relative lift: ~3,400/variant
- 30% relative lift: ~7,500/variant
- 20% relative lift: ~15,000/variant
- Calculate days needed: variant_size / daily_starts

Prefer testing **large, bold changes** over subtle ones. At this traffic, nuance is unmeasurable.

## Phase 5: Decision Card

Present the experiment as a Decision Card:

```
**[DECISION]** [Experiment name] | **Rec:** [recommendation] | **Risk:** [what could go wrong] | **Reversible?** Yes (deploy revert) -> Approve / Reject / Discuss
```

## Funnel Stage Taxonomy

Reference framework for categorizing metrics and experiments:

| Stage | App Equivalent | Key Metric |
|-------|---------------|------------|
| **Awareness** | Traffic / page visits | Sessions from UTM sources |
| **Activation** | Flow started | Start rate (sessions -> started) |
| **Engagement** | Flow completed | Completion rate (started -> completed) |
| **Conversion** | Email signup | Signup rate (completed -> email) |
| **Referral** | Invite sent | K-factor (invites x conversion) |
| **Retention** | Return visit | Repeat session rate |

## Error Handling

- **Encryption key missing:** 1Password Touch ID may prompt. If the key isn't cached, run the report command first to trigger auth.
- **Empty results:** If any query returns empty, note the gap and work with available data. Don't fabricate.
- **Schema changes:** If a query fails with "no such column/table," the schema may have changed. Check `sqlite_master` and adapt.
