# Platform Posting Config

## X/Twitter

- **Handle:** `@your-handle`
- **API keys:** Store in your secrets manager
- **Tier:** X Premium — 25,000 char posts, Articles, blue checkmark
- **Posting:** 500 posts/month, write-only (no read). Pay-per-use model makes light usage nearly free.
- **Automation:** Use **Tweepy** + Bearer Token for regular posts: `tweepy.Client(bearer_token=...).create_tweet(text=...)`. Articles are desktop-only, no API — manual creation at x.com.
- **Articles:** Long-form publishing (up to ~100K chars) with rich formatting. Appears in dedicated Articles tab on profile. Desktop composition only. Good for full articles that also go to Reddit.

## LinkedIn

- **No API path for individuals.** Posts API prohibits automated post creation. Partner Program required (companies only, 3-6 month approval, <10% acceptance).
- **Alternatives:** Buffer/Hootsuite (paid), Selenium/Playwright (ToS-grey), manual clipboard relay.
- **Current approach:** Manual via `/copy-for`. Revisit if publishing cadence exceeds 4/week.

## Reddit

- **Username:** `your-username`
- Reddit is your blog — X and LinkedIn link back to Reddit.
- **Referrer limitation:** Reddit sends `Referrer-Policy: origin`, stripping the URL path. UTM parameters are the only way to trace traffic to specific posts.
