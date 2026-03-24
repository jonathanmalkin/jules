# X/Twitter API — Always Use API, Never WebFetch

## The Rule

**Never use WebFetch on x.com or twitter.com URLs.** The hook (`x-webfetch-guard.sh`) blocks this deterministically. WebFetch returns login walls or partial HTML — useless.

**WebSearch for X content is low-value** (X posts are inconsistently indexed). Prefer the API. Not hook-enforced since WebSearch takes query strings, not URLs.

## Intent → Tool Map

| Intent | Tool | Example |
|--------|------|---------|
| **Post a tweet** | `Scripts/x-post.sh` (Mac) / `Scripts/post-to-x.py` (container) | `bash Scripts/x-post.sh "tweet text"` |
| **Post from file** | Same | `bash Scripts/x-post.sh --file /tmp/tweet.txt` |
| **Reply to a tweet** | Same, with `--reply-to` | `bash Scripts/x-post.sh --reply-to 1234567890 "reply text"` |
| **Post a thread** | Same, with `--thread` | `bash Scripts/x-post.sh --thread --file /tmp/thread.txt` |
| **FAQ category search** | `Scripts/x-search-faq.sh` | `bash Scripts/x-search-faq.sh > /tmp/results.json` |
| **Read a specific tweet** | curl (see template below) | Extract tweet ID from URL, use v2 endpoint |
| **General keyword search** | curl (see template below) | Bearer Token + search/recent endpoint |

## Curl Templates for Ad-Hoc Reads

### Read a specific tweet by ID

Extract the tweet ID from the URL (the numeric part after `/status/`), then:

```bash
# On Mac:
export X_BEARER_TOKEN=$(op item get "X" --vault "Your-Vault" --fields "Bearer Token" --reveal)

# In container: X_BEARER_TOKEN is already in env

curl -s -H "Authorization: Bearer $X_BEARER_TOKEN" \
  "https://api.x.com/2/tweets/TWEET_ID?tweet.fields=created_at,public_metrics,text&expansions=author_id&user.fields=username,name"
```

### Search recent tweets

```bash
curl -s -H "Authorization: Bearer $X_BEARER_TOKEN" \
  "https://api.x.com/2/tweets/search/recent?query=QUERY&tweet.fields=created_at,public_metrics,text&expansions=author_id&user.fields=username,name&max_results=10"
```

URL-encode the query. Free tier: search/recent only (last 7 days), 1 request/second, 10 requests/month on Basic.

## Auth Notes

- **Posting** uses OAuth 1.0a (consumer key + access token). Env vars: `X_API_KEY`, `X_API_SECRET`, `X_ACCESS_TOKEN`, `X_ACCESS_SECRET`.
- **Reading/searching** uses Bearer Token. Env var: `X_BEARER_TOKEN`.
- On Mac, scripts fetch from 1Password automatically. In container, env vars are pre-loaded.

## What Doesn't Exist Yet

- No dedicated tweet-lookup script (use curl template above)
- No general search script (x-search-faq.sh is FAQ-specific with hardcoded categories)
- No user profile lookup script
