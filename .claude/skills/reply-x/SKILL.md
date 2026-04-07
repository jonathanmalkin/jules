---
name: reply-x
effort: medium
description: "Find posts where @[your-handle] tags @builtwithjules, draft replies, post approved ones as @builtwithjules."
user-invocable: true
---

# Replies

Find posts where @[your-handle] tags @builtwithjules, draft a reply for each, post after approval.

**Voice:** Jules — warm, direct, opinionated. Practitioner, not guru. Specific, not generic.

## Step 1: Load State

Read the tracking file: `Documents/Content-Pipeline/X-Mentions-Jules.md`

Extract:
- `Last seen tweet ID` — for filtering (not used in query — see note below)
- Existing tweet IDs — to avoid re-presenting anything already shown

## Step 2: Search

### 2a. Text search

```bash
xurl search "@builtwithjules from:[your-handle]" -n 20 -u builtwithjules
```

Filter results against the tracking file (skip any tweet ID already present).

### 2b. Mentions fetch (catches quote tweets)

Text search misses quote reposts where @builtwithjules appears in the quoted tweet
but not in the quoting text. To catch these, fetch Jules's mentions directly:

```bash
xurl mentions -n 20 -u builtwithjules
```

If mentions doesn't surface quote tweets, fall back to raw API:
```bash
xurl /2/users/by/username/[your-handle] -u builtwithjules  # get user_id
xurl "/2/users/{user_id}/tweets?expansions=referenced_tweets.id&max_results=20" -u builtwithjules
```

Skip any tweet ID already in the tracking file.

### 2c. Merge and deduplicate

Combine results from 2a and 2b. Deduplicate by tweet ID.

**Reply + standalone pairs:** [Your Name] often posts the same content as both a reply
and a standalone/quote tweet. When detected (same text or near-identical), group them
and present as a single item. Default to replying to the conversational thread version.

If no new results after filtering, say so and stop. Do NOT update "Last processed" timestamp.

## Step 3: Draft

For each new tweet, draft a reply:

- **Check reply eligibility first.** Fetch the target post and inspect `reply_settings`:

```bash
xurl "/2/tweets/{tweet_id}?tweet.fields=reply_settings,conversation_id,author_id,created_at,public_metrics"
```

Do not assume "not tagged means blocked." If the post allows broad replies, Jules may be
able to reply even when not explicitly tagged. If the post is limited (followers/mentioned users)
and Jules is not eligible, then flag it: "Jules isn't eligible to reply here — tag Jules first or skip."
Don't draft a reply for truly ineligible tweets.
- Be specific and useful — no generic "great point!" responses
- Keep under 280 characters when possible
- Apply outbound sanitization (no sensitive data)

Present each for approval:

```
**Original** (@[your-handle]): [tweet text]
**Reply:** [draft]
**Action:** approve / edit / skip
```

Add all new tweets to the tracking file immediately with `presented: yes`, `action: pending`.

Wait for [Your Name]'s approval before posting anything.

## Step 4: Post

For each approved reply:

```bash
xurl reply [TWEET_ID] "[reply text]" -u builtwithjules
```

## Step 5: Update State

After [Your Name] responds with approve/skip decisions:

1. Update each tweet's `Action` and `Reply ID` in the tracking file
2. Update `Last seen tweet ID` to the highest tweet ID seen this run
3. Update `Last processed` timestamp to now (CT)

Report: N new found, N posted, N skipped.

---

## Auth Notes

Posts as **@builtwithjules** via `-u builtwithjules` using OAuth2 credentials stored in `~/.xurl`.

xurl has two OAuth2 users under the `[your-handle]` app:
- `builtwithjules` — used by /reply-x (`-u builtwithjules`)
- `[your-handle]` — used by /watch-contacts (default, no flag needed)

If posting fails with 401: run `xurl auth oauth2` outside the Claude session,
log in as @builtwithjules in the browser.

If posting fails with 403 "not engaged" or equivalent restrictions after the eligibility check:
the post is effectively closed to Jules. Ask [Your Name] to tag @builtwithjules on the tweet first,
then retry.
