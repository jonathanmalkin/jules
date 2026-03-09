---
name: post-article
description: Post a queued article to Reddit and X. Use when user says "post article", "publish article", "post next article", or invokes /post-article. Orchestrates the full cross-platform posting flow for a single article from Content-Queue.md. Posting schedule is Tue/Thu.
user_invocable: true
---

# Post Article

Orchestrate posting a queued article across Reddit and X. Posting schedule: Tue/Thu (may increase).

## Inputs

The user specifies the article by number, title, or "next" (first READY item in queue).

## Step 1: Find the Article

1. Read `Documents/Content-Pipeline/Content-Queue.md`
2. Locate the article (by number, title, or first READY item)
3. Read the Reddit draft from `Documents/Content-Pipeline/03-Pending-Human-Review/{slug}/Reddit.md`
4. Confirm the article with the user before proceeding

## Step 2: Reddit Posting (Tue + Thu, 7:30-10 AM CT)

1. Read the Reddit draft from the article's folder
2. Run publish voice check:
   - No em-dashes (use regular dashes)
   - No AI preamble ("As an AI...", "Great question!", "I'd be happy to...")
   - Hook-first opening (no throat-clearing)
   - CTA present (app link, follow, or engagement ask)
3. Present formatted content to user for final review
4. After approval, run the prep script:
   ```bash
   Scripts/post-to-reddit.sh <subreddit> /tmp/reddit-post-title.txt /tmp/reddit-post-body.txt "<flair>"
   ```
5. Copy title to clipboard (`printf '%s' "$(cat /tmp/reddit-post-title.txt)" | pbcopy`), tell user to paste
6. Copy body to clipboard, tell user to paste (remind: markdown mode, select flair)
7. **Post to target subreddits** — same content, standalone posts (not crosspost)
8. User provides post URLs after submission

## Step 3: X Posting (Same Day)

**Requires:** Chrome running with debug profile and remote debugging port, logged into X.

1. Read X draft from `Documents/Content-Pipeline/03-Pending-Human-Review/{slug}/X.md`
2. If no draft, generate X teaser (280 chars max)
3. Include Reddit link in the tweet body (not as a reply — simpler, more visible)
4. Write tweet text to `/tmp/x-post.txt`
5. Dry-run first:
   ```bash
   Scripts/post-to-x-auto.sh /tmp/x-post.txt
   ```
6. Review screenshot at `/tmp/x-pre-post.png`
7. If approved, post for real:
   ```bash
   Scripts/post-to-x-auto.sh /tmp/x-post.txt --post
   ```
8. Add Reddit link as reply:
   ```bash
   Scripts/post-to-x-auto.sh /tmp/x-reply.txt --reply-to <tweet_url> --post
   ```

## Step 4: Update Tracking

1. Move article to Posted table in `Documents/Content-Pipeline/Content-Queue.md` with date, URLs, platform
2. Update `Documents/Content-Pipeline/Published-URLs.md` with new URLs for each platform
3. Move folder from `04-Approved/` to `05-Published/` if all platforms are done

## Step 5: Engagement Reminders

After posting, remind the user:

- **Reddit:** Reply to comments within 4 hours (critical engagement window). Set a reminder.
- **X:** Reply-guy engagement throughout the day. Quote-tweet with additional context.

## Error Handling

- If Reddit login is required, prompt user to log in via agent-browser before continuing
- If a platform post fails, continue with remaining platforms and note the failure
- If Content-Queue.md has no READY articles, tell the user and suggest running content enrichment
- Always dry-run X posts first before actual posting
