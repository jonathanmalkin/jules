---
paths:
  - "**/your-website/**"
---

# WordPress / Elementor Updates

## Updating Elementor Page Content via CLI

Elementor pages store content in `_elementor_data` postmeta (JSON), NOT `post_content`. Updating `post_content` via `wp post update` does nothing visible.

### Correct procedure

1. **Pull current Elementor data:**
   ```bash
   ssh your-server "cd ~/www/app.example.com/public_html && wp post meta get [PAGE-ID] _elementor_data" > /tmp/elementor-data.json
   ```

2. **Edit the JSON locally** -- the HTML lives inside the `editor` field of `text-editor` widgets

3. **Upload and update the meta:**
   ```bash
   scp /tmp/elementor-data.json your-server:/tmp/elementor-data.json
   ssh your-server 'cd ~/www/app.example.com/public_html && wp post meta update [PAGE-ID] _elementor_data "$(cat /tmp/elementor-data.json)"'
   ```

4. **Also update `post_content`** to keep the fallback in sync:
   ```bash
   ssh your-server 'cd ~/www/app.example.com/public_html && wp post update [PAGE-ID] --post_content="$(cat /tmp/post-content.html)"'
   ```

5. **Flush caches (all three):**
   ```bash
   ssh your-server "cd ~/www/app.example.com/public_html && wp elementor flush-css && wp sg purge && wp cache flush"
   ```

6. **Verify with agent-browser, not WebFetch.** CDN caching can serve stale content even after purging. Always open the page in agent-browser and check the rendered text.

### Common mistakes

- Updating only `post_content` -- Elementor ignores it and renders from `_elementor_data`
- Using WebFetch to verify -- hits CDN cache, gives false results
- Forgetting `wp elementor flush-css` -- Elementor may cache rendered output separately from the hosting provider
