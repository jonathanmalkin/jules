---
name: post-article
description: Post a queued article to Reddit and X (single tweet). Use when user says "post article", "publish article", "post next article", or invokes /post-article. Orchestrates the full cross-platform posting flow for a single article from Content-Queue.md. Posting schedule is Tue/Thu. For the full write-once distribute-twice workflow with X Articles and tweet threads, use /long-form-publish instead.
user_invocable: true
---

# Post Article

Orchestrate posting a queued article across Reddit and X. Posting schedule: Tue/Thu (may increase).

## Inputs

The user specifies the article by number, title, or "next" (first READY item in queue).

## Step 1: Find the Article

1. Read `Documents/Content-Pipeline/Content-Queue.md`
2. Locate the article (by number, title, or first READY item)
3. Read the Reddit draft from `Documents/Content-Pipeline/03-Pending-Human-Review/{slug}/Reddit-ClaudeCode.md`
4. Confirm the article with the user before proceeding

## Step 2: Reddit Posting (Manual Clipboard Relay)

Reddit API access request submitted 2026-03-15, pending approval. Until approved, use manual workflow.
When API access is granted, switch to automated posting via `Scripts/post-to-reddit-api.py`.

1. Read the Reddit draft from the article's folder
2. Run publish voice check:
   - No em-dashes (use regular dashes)
   - No AI preamble ("As an AI...", "Great question!", "I'd be happy to...")
   - Hook-first opening (no throat-clearing)
   - CTA present (quiz link, follow, or engagement ask)
3. Format for Reddit using `/copy-for reddit`
4. Tell the user: "Reddit post copied to clipboard. Paste into r/ClaudeCode, then r/ClaudeAI."
5. **Post to both r/ClaudeCode (138K) and r/ClaudeAI (566K)** -- same content, standalone posts (not crosspost). Both subs are on-topic for Claude Code content.
6. After user confirms posting, ask for the Reddit URLs

## Step 3: X Posting (Same Day)

1. Read X draft from `Documents/Content-Pipeline/03-Pending-Human-Review/{slug}/X.md`
2. If no draft, generate X teaser (280 chars max)
3. Include Reddit link in the tweet body (not as a reply -- simpler, more visible)
4. Write tweet text to `/tmp/x-post.txt`
5. Dry-run first:
   ```bash
   Scripts/x-post.sh --dry-run --file /tmp/x-post.txt
   ```
6. Review the dry-run output (shows exact text that will post)
7. If approved, post for real:
   ```bash
   Scripts/x-post.sh --file /tmp/x-post.txt
   ```
8. Add Reddit link as reply (get tweet ID from post output):
   ```bash
   Scripts/x-post.sh --file /tmp/x-reply.txt --reply-to <tweet_id>
   ```

## Step 3.5: LinkedIn Posting (Not Yet Configured)

LinkedIn API not yet set up. Skip this step until configured.

## Step 4: Update Tracking

1. Move article to Posted table in `Documents/Content-Pipeline/Content-Queue.md` with date, URLs, platform
2. Update `Documents/Content-Pipeline/Published-URLs.md` with new URLs for each platform
3. Move folder from `04-Approved/` to `05-Published/` if all platforms are done

## Step 5: Engagement Reminders

After posting, remind the user:

- **Reddit:** Reply to comments within 4 hours (critical engagement window). Set a reminder.
- **X:** Reply-guy engagement throughout the day. Quote-tweet with additional context.

## Error Handling

- Reddit posting is manual (clipboard relay) until API access is approved
- If a platform post fails, continue with remaining platforms and note the failure
- If Content-Queue.md has no READY articles, tell the user and suggest running content enrichment
- Always dry-run X posts first before actual posting
