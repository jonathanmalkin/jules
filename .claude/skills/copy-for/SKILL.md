---
name: copy-for
description: Format text for a target platform (Discord, Reddit, LinkedIn, X, or plain) and copy to clipboard. Use when the user says "copy for discord", "copy for reddit", "copy for linkedin", "copy for x", "copy for plain", "format for discord", or invokes /copy-for. Accepts optional inline text after the platform name; if omitted, reformats the last response.
user_invocable: true
---

# Copy For Platform

Format text for a target platform and copy it to the clipboard.

## Usage

```
/copy-for discord This is the text I want formatted for Discord
/copy-for plain Some text to strip formatting from
```

If **inline text is provided** after the platform name, use that text as the input.
If **no inline text** is provided, use the most recent substantive response in the conversation (skip tool calls, short confirmations, etc.).

```
/copy-for discord          ← reformats last response for Discord
```

If no platform is specified, ask which one.

## Platform Rules

### Discord

Discord uses a limited markdown subset. Apply these transformations:

- **Keep**: `**bold**`, `*italic*`, `` `inline code` ``, ` ```code blocks``` `, `> blockquotes`, `- unordered lists`, `1. ordered lists`, `# ## ###` headers, `~~strikethrough~~`, `||spoilers||`, `[text](url)` links
- **Remove**: Tables (convert to plain text or lists), horizontal rules (`---`), HTML tags
- **Line breaks**: Discord needs a blank line between paragraphs. Single newlines within a paragraph are fine. Do NOT insert hard line breaks mid-sentence.
- **Max length**: Discord messages cap at 2000 characters. Budget **1900 characters max** per message to leave margin for Unicode (emoji, special symbols like ✓ count as more bytes than ASCII). Count with `len()` in Python or `wc -c` in bash. If the reformatted text exceeds 1900 characters, split at natural break points (paragraphs, section dividers) and separate parts with `--- SPLIT HERE ---` markers. Tell the user how many messages to paste.

### Reddit

Reddit uses standard markdown. Most content can go through as-is:

- **Keep**: All standard markdown -- bold, italic, headers, lists, code blocks, tables, links, blockquotes, horizontal rules
- **Remove**: HTML tags, non-standard extensions
- **Code blocks**: Reddit loves inline code. Preserve all code fences. Use four-space indent as fallback.
- **Line breaks**: Reddit needs double newlines between paragraphs. Single newlines are ignored.
- **Flair**: If you know the target subreddit's available flairs, suggest one in a note after the content.
- **No character limit** for text posts. Keep under 40,000 characters (Reddit hard limit).

### LinkedIn

LinkedIn uses plain text with minimal formatting support:

- **Keep**: Line breaks (blank line = paragraph break), emoji (sparingly)
- **Remove**: ALL markdown syntax -- no bold, italic, headers, code blocks, tables, links in text
- **Links**: Do NOT include links in the post body. LinkedIn penalizes external links with 25-35% less reach. Put links in the first comment instead. Add a note: "Link in first comment."
- **Hashtags**: 3-5 at the end, PascalCase (e.g., `#ClaudeCode #AIAgents #DeveloperTools`)
- **Max length**: Target under 1300 characters (before the "see more" fold). If over, note the character count.
- **Engagement question**: End with a question to drive comments.

### X (Twitter) -- Post

X Premium is active on this account. Use the 25,000-char limit for posts:

- **Keep**: Plain text, emoji (sparingly), hashtags (1-2 max)
- **Remove**: ALL markdown syntax, all formatting
- **Max length**: 25,000 characters (X Premium). Posts over 280 chars show a "Show more" link to non-Premium readers.
- **Links**: X penalizes external links in tweets. For link posts, put the URL as a reply to your own tweet, not in the main tweet. Add a note: "Link as reply."
- **Thread format**: With Premium's 25,000-char limit, threads are rarely needed. Use a single long post instead. If content exceeds 25,000 chars, split into a thread. Each tweet should stand alone. Number them: "1/", "2/", etc.
- **No hashtag spam**: 1-2 relevant hashtags max. More than that reduces engagement on X.

### X (Twitter) -- Article

X Articles are a separate long-form publishing format (like a blog post on X). Use when content is article-length (1,000+ words) and benefits from rich formatting:

- **Formatting supported**: Headings, subheadings, bold, italic, strikethrough, indentation, numbered and bulleted lists
- **Media**: Images, video, GIFs, embedded X posts, and links can be embedded inline
- **Max length**: ~100,000 characters
- **Desktop only**: Articles can only be composed via x.com desktop -- no mobile composition
- **No API/automation**: Articles must be created manually in X's web editor. Cannot be automated via Tweepy or agent-browser.
- **Profile display**: Articles appear in a dedicated "Articles" tab on the user's profile
- **When to use**: Full articles that would otherwise go to Reddit or a blog. Especially good for content over 2,000 words with formatting needs.
- **Output format**: When formatting for X Article, keep markdown formatting (headings, bold, lists) since the Article editor supports it. Add a note: "Paste into X Article editor at x.com (desktop only)."

### Plain

Strip all formatting. Output clean prose:

- No markdown syntax characters
- Paragraphs separated by blank lines
- Lists as plain indented text with dashes
- No code fences -- just the code content

<HARD-GATE>
Do NOT regenerate or rewrite the content. Preserve the meaning and structure exactly. Only change formatting for the target platform. This is the entire contract of the skill.
</HARD-GATE>

## Procedure

### Step 1: Determine Input `[INPUT]`

- If the user provided inline text after the platform name, use that as-is.
- If no inline text, use your most recent substantive response in the conversation (skip tool calls, short confirmations, etc.).

### Step 2: Format `[FORMAT]`

Apply the platform rules above to the input text.

### Step 3: Copy `[COPY]`

Write the formatted text and platform sidecar, then copy to clipboard:

```bash
# Write platform name for the clipboard-validate hook
printf '%s' '<platform>' > /tmp/claude-copy-for-platform.txt
# Write content and copy
cat /tmp/claude-copy-for.txt | bash .claude/scripts/clipboard.sh
```

### Step 4: Confirm `[CONFIRM]`

Tell the user what was copied and for which platform. If the content was split (Discord), tell them how many parts.

## Example

**Input** (from a previous response):
> Claude Code skills use frontmatter for trigger matching. The `description` field is the **primary signal** for routing.

**Output** (`/copy-for linkedin`):
> Claude Code skills use frontmatter for trigger matching. The description field is the primary signal for routing.
>
> #ClaudeCode #AIAgents
>
> _Note: "Link in first comment" if linking to docs._

## Anti-Patterns

1. **Rewriting content.** Change formatting, not meaning. Don't improve prose, fix typos, or add commentary. The input text is sacred.
2. **Asking before copying.** Copy to clipboard immediately. Don't ask "shall I copy this?"
3. **Adding extras.** No headers, sign-offs, CTAs, or commentary that wasn't in the original.
4. **Skipping platform rules.** Don't output raw markdown for LinkedIn or X. Every platform has specific stripping/transformation rules above.

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Clipboard script not found | Show formatted text in a code fence for manual copy |
| Platform not recognized | Ask the user which platform. Supported: Discord, Reddit, LinkedIn, X, X Article, Plain |
| Content exceeds platform limit | Split at natural break points, note the split count |
