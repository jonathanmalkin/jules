# Pre-Flight Checklist

Deterministic checks that run before Stage 6 (Publish). All checks are automated. Failures block publishing.

## Website Article Checks

```bash
# 1. Build passes
cd Code/[your-site] && npm run build

# 2. Frontmatter complete
# Check that the article .md file has all required fields
```

**Required frontmatter fields:**
- `title` (string, non-empty)
- `date` (YYYY-MM-DD format)
- `description` (string, 50-160 chars for SEO)
- `story` (1, 2, or 3)
- `tags` (array, at least 1)
- `draft` (must be `false` for publishing)

**Optional but recommended:**
- `platforms` (object with reddit/x/linkedin URLs, populated post-publish)
- `image` (path to hero image)

## Content Quality Checks (all variants)

| Check | How | Fail condition |
|-------|-----|----------------|
| No em-dashes | `grep -n '—' {file}` | Any match |
| No en-dashes used as em-dashes | `grep -nP ' – ' {file}` | Any match (en-dashes in number ranges are fine) |
| Repo link footer present | `grep -l 'github.com/jonathanmalkin/jules' {canonical}` | Missing from canonical [your-site].md |
| First paragraph is AI-extractable summary | Manual check: first paragraph stands alone as a summary | Requires judgment (flag for author review if unclear) |
| No AI tells in opening/closing | `grep -niE 'certainly|I.d be happy|great question|let me break' {file}` | Any match in first or last 5 lines |

## X Thread Checks

| Check | How | Fail condition |
|-------|-----|----------------|
| All tweets under 280 chars | Count chars per tweet block (account for t.co 23-char URL compression) | Any tweet over 280 after URL compression |
| Hook tweet under 200 chars | Count chars of tweet 1 | Over 200 |
| Links only in final tweet | Check tweets 1 through N-1 for URLs | URL found outside final tweet |
| Thread structure | Verify: hook (1), body (2 to N-2), TL;DR (N-1), CTA (N) | Missing TL;DR or CTA |

## X Article Checks

| Check | How | Fail condition |
|-------|-----|----------------|
| No code blocks | `grep -c '^\`\`\`' {file}` | Any match |
| No bold/italic markers | `grep -nP '\*\*|\*[^*]' {file}` | Any match (asterisks paste as literal text) |
| No blank lines between paragraphs | Check for consecutive blank lines within body | Double blank lines in body text |
| Word count 800-2000 | `wc -w {file}` | Outside range |

## LinkedIn Checks

| Check | How | Fail condition |
|-------|-----|----------------|
| Word count 150-300 | `wc -w {file}` | Outside range |
| No URL in body | `grep -nE 'https?://' {file}` | URL found (LinkedIn penalizes links in body) |
| No code blocks | `grep -c '^\`\`\`' {file}` | Any match |

## Auth Checks

| Check | How | Fail condition |
|-------|-----|----------------|
| X API auth cached | `Scripts/x-post.sh --dry-run "test"` | Non-zero exit |
| LinkedIn token valid | `python3 Scripts/post-to-linkedin.py --check-auth` | Non-zero exit or "expired" in output |

## Editorial Quality Checks (Author Review)

These are flagged for [Your Name]'s review, not automated PASS/FAIL. Present alongside automated results.

### Blog ([your-domain])

- [ ] Contains at least one story only [Your Name] could tell (or a placeholder for one)
- [ ] Paragraph lengths vary (not all 3-4 sentences)
- [ ] Takes a genuine stance or recommendation (not just "here are the options")
- [ ] Headers are scannable and specific (not generic "Introduction" / "Conclusion")
- [ ] First-person claims are traceable to source material (no fabricated anecdotes)

### Reddit

- [ ] Reads like a real person sharing real experience, not a presentation
- [ ] Includes specific numbers where claims are made (times, percentages, counts)
- [ ] Admits at least one thing that didn't work or was harder than expected
- [ ] Closing question is genuine (invites discussion, not engagement bait)
- [ ] No credentials dump in the opening paragraph

### X Thread

- [ ] Each tweet has one clear idea (no "and also" tweets)
- [ ] Would you say each tweet at a dinner party? (natural, not performative)
- [ ] Takes a real stance (not hedged into meaninglessness)
- [ ] Hook tweet is compelling standalone (would you click if you saw just this?)
- [ ] No thread cliches ("A thread", "Here's what nobody tells you")

### X Article

- [ ] Narrative personal tone (not reformatted blog post)
- [ ] No code blocks or formatting markers visible as literal text
- [ ] Shorter paragraphs than blog version (2-3 sentences max)

### LinkedIn

- [ ] Under 300 words
- [ ] Personal angle leads (not abstract observation)
- [ ] No URL in body text
- [ ] Scannable (short paragraphs, line breaks, not dense prose)
- [ ] Genuine question close

## Execution

Run all checks before presenting the "ready to publish" prompt. Report:
- PASS: check passed
- FAIL: check failed with details
- SKIP: check not applicable (e.g., no X thread variant)

Block publishing if any FAIL on applicable checks. SKIP is fine.
