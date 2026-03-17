# X / Twitter — All Interactions via X API

## Architecture

**All X interactions use the X API v2.** No browser automation, no CDP. Reddit stays manual clipboard.

| Operation | Method | Auth |
|-----------|--------|------|
| Reads (fetch tweet, search, lookup) | X API v2 | `X_BEARER_TOKEN` (Bearer) |
| Posts (tweets, replies, threads) | X API v2 | OAuth 1.0a (`X_API_KEY`, `X_API_SECRET`, `X_ACCESS_TOKEN`, `X_ACCESS_SECRET`) |

All credentials are in the container env via `/tmp/agent-secrets.env`.

## Reading

```bash
source /tmp/agent-secrets.env

# Fetch a single tweet
curl -s "https://api.twitter.com/2/tweets/<id>?tweet.fields=text,author_id,conversation_id,created_at" \
  -H "Authorization: Bearer $X_BEARER_TOKEN"

# Search recent tweets
curl -s "https://api.twitter.com/2/tweets/search/recent?query=<query>&tweet.fields=text,author_id" \
  -H "Authorization: Bearer $X_BEARER_TOKEN"
```

## Posting

Use OAuth 1.0a for write operations. Scripts in `Scripts/x-post.sh`.

```bash
source /tmp/agent-secrets.env
# POST https://api.twitter.com/2/tweets with OAuth 1.0a header
```

## Character Limit

X Premium active: **25,000 char limit**. Posts over 280 chars show "Show more" to non-Premium readers. Check with `wc -m` (not `wc -c`).

## Troubleshooting

- **402 on write endpoint:** Check OAuth 1.0a credentials — Bearer token only works for reads.
- **401 on read:** Verify `X_BEARER_TOKEN` is sourced from `/tmp/agent-secrets.env`.
- **Thread fetching:** Use `conversation_id` to pull replies; filter by `author_id` to get only author self-replies.
