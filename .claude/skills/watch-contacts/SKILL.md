---
name: watch-contacts
effort: light
description: "Check what watched contacts are posting on X, surface engagement opportunities. Reads Profiles/Contacts.md for handles."
user-invocable: true
---

# Watch Contacts

Monitor X/Twitter activity from contacts in the network. Surface posts worth engaging with, batch reply decisions via AskUserQuestion.

## Step 1: Load Contacts

Read `Profiles/Contacts.md`. Extract X/Twitter handles from ALL sections:
- "Active — Following Up" table (personal contacts)
- "X Watch List" tables (public figures, product leaders)

For each handle, also check the **Filter** column. If a filter string exists, that handle requires keyword-filtered search (see Step 2).

Build a handle list. Skip contacts with no X handle. Report how many handles found.

If no handles found, say so and stop.

## Step 1.5: Determine Floor Timestamp (Dedup Across Runs)

Before searching contacts, check whether this skill already ran earlier today:

```bash
xurl search "from:[your-handle]" -n 20
```

Look at the reply timestamps. If there's a cluster of replies today (indicating an earlier watch-contacts session or manual engagement), use the **end of the most recent cluster** as the floor timestamp. Only surface tweets posted AFTER this floor.

- If no earlier activity today → floor = 24 hours ago (default behavior).
- If earlier cluster found → floor = timestamp of last reply in that cluster.
- Report: "Last engagement session ended ~Xh ago. Filtering to tweets posted after [time]."

If the floor is very recent (< 2 hours ago), warn: "Ran recently — there may be few new posts." and proceed anyway.

## Step 2: Search Recent Posts

For each handle, search for the **3 most recent tweets**:

```bash
# Standard (no filter):
xurl search "from:{handle}" -n 10

# Filtered (high-volume posters — use separate queries, not OR):
xurl search "from:{handle} claude" -n 10
xurl search "from:{handle} openclaw" -n 10
xurl search "from:{handle} agent" -n 10
# Deduplicate by tweet ID across filter queries.
```

**Filter syntax note:** The X search API does not scope `OR` to the `from:` clause. `from:X foo OR bar` returns `(from:X foo) OR (bar globally)`. For filtered handles, run **one search per keyword** and deduplicate results by tweet ID.

From each handle's results, keep only the **3 most recent** tweets.

**Floor timestamp cutoff:** Discard any tweet older than the floor timestamp from Step 1.5. If a handle has no tweets after the floor, skip it entirely.

Run searches in parallel where possible.

## Step 3: Filter and Rank

From all remaining tweets (max 3 per handle, last 24h only), identify posts worth engaging with. Prioritize:

1. **Topic overlap** — AI agents, Claude Code, solo founder, building in public, Applied AI, open source
2. **Engagement opportunity** — questions asked, opinions shared, event announcements
3. **Recency** — newer is better
4. **Relationship signal** — replying to someone you want to build a relationship with carries more weight than replying to a stranger

Skip: retweets without commentary, promotional/spam, posts with 0 relevance to [Your Name]'s work, short replies to other people with no standalone value.

## Step 4: Present and Batch Approve

Present results in **batches of up to 4** using AskUserQuestion (tool limit: 4 questions max). Each batch contains up to 4 questions, **one question per post**. Each question is a single yes/no decision for one reply.

**Question format:**
- **question:** Formatted with all decision context. Use this layout (newlines in the string):
  ```
  @handle | https://x.com/handle/status/tweet_id | Xh ago | N replies | N likes | N imp
  "[full tweet text, truncated at ~200 chars if needed]"
  Draft: [reply text]
  Post this reply?
  ```
- **header:** `@handle` (max 12 chars — truncate handle if needed)
- **options:** `[{"label": "Post it", "description": "Reply from @[your-handle]"}, {"label": "Skip", "description": "Don't reply to this one"}]`
- **multiSelect:** false

**Context fields:** Calculate hours since posted from `created_at`. Use `reply_count`, `like_count`, `impression_count` from `public_metrics`. Build the tweet link from `https://x.com/{handle}/status/{tweet_id}`.

[Your Name] decides each reply independently:
- **"Post it"** → Jules posts the draft via `xurl reply`.
- **"Skip"** or **question skipped** → do nothing, move on. [Your Name] may have clicked the link and posted directly — verification catches this.

Also classify each surfaced post internally as one of:

- `reply now`
- `save for later`
- `article seed`
- `not worth touching`

Only present `reply now` items in the approval batch. Keep the others in the verbal summary.

If more than 4 actionable posts, present multiple batches sequentially (4 questions per batch).

If nothing worth engaging with: "Nothing actionable in the last 24h. [N] contacts checked, [M] posts scanned."

## Step 5: Post Approved Replies

For each "Post it" reply, check reply eligibility first:

```bash
xurl "/2/tweets/{tweet_id}?tweet.fields=reply_settings,conversation_id,author_id,created_at,public_metrics"
```

If `reply_settings` indicates the post is effectively public or otherwise open to reply, proceed.
Do not assume "not tagged" means blocked.

For each eligible "Post it" reply, attempt to post:

```bash
xurl reply [tweet_id] "[reply text]"
```

**If xurl reply fails** despite passing the eligibility check, fall back to copying the draft to clipboard and providing the link. One at a time — copy draft, show link, wait for [Your Name] to say "next" before copying the next one.

```bash
printf '%s' "draft reply text" | pbcopy
```

## Step 6: Verify All Posts

After ALL batches are complete, verify every post that was presented (both approved and skipped). For each original tweet, check whether a reply from @[your-handle] exists:

```bash
xurl search "from:[your-handle] to:handle" -n 5
```

Report results in a summary table:

| Post | Status | Reply |
|------|--------|-------|
| @handle — [short tweet ref] | Posted by Jules / Posted directly / No reply | [first ~80 chars of reply if found] |

**Voice sample capture:** For any reply [Your Name] posted directly (i.e., NOT posted by Jules but a reply from @[your-handle] exists on that tweet), read the full reply text and append it as a new sample to `Profiles/Voice-Samples-Raw.md`. Use this format:

```markdown
### X Reply — @handle ([date])
[full reply text]
```

These direct replies are authentic voice samples — [Your Name] wrote them manually, making them high-quality calibration data.

After verification: "Want to add or remove anyone from the watch list? I'll update `Profiles/Contacts.md`."

## Draft Reply Voice

[Your Name]'s voice — practitioner, not fan. Specific, not generic. References real experience building with AI agents, Claude Code, or shipping products. Never sycophantic. Short (1-3 sentences max).

## Notes

- This skill only covers X/Twitter. LinkedIn monitoring requires manual review (API doesn't support feed reading).
- To add someone to the watch list: add their X handle to `Profiles/Contacts.md`.
- Replies are posted from @[your-handle] unless [Your Name] specifies otherwise.
- Treat `@[your-handle]` as the authority account. `@builtwithjules` is for tagged or assistant-perspective replies, not default relationship building.
