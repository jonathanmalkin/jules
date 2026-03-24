# Research Output Standards — Specificity, Authenticity, Accuracy

Every factual claim gets a source. The overhead scales with the tier.

## Tier Matrix

| Tier | Source links | Confidence tags | Audit trail | Sources block |
|------|-------------|-----------------|-------------|---------------|
| **Quick** | Yes (inline) | No | No | No |
| **Debug** | Yes | Root-cause claims only | Debug trace = audit trail | Brief — key sources only |
| **Advisory/Scope/Content/Scout** | Yes | Inline on key claims | Full (queries + coverage) | Full `## Sources & Confidence` block |

## Source Citation Format

- **Web sources:** `[Title](URL)` — clickable markdown links, always
- **Local files:** `file_path:line_number`
- **Training data:** flag as `[training data — not live-verified]`
- **No bare claims.** Every factual statement gets a source. If you can't source it, say so.

## Confidence Tiers

Use inline tags on key claims (Advisory/Scope/Content/Scout only). Skip for Quick and Debug.

| Tag | Meaning | When to use |
|-----|---------|-------------|
| `[Verified]` | Read the live source, confirmed the claim | Official docs, API responses, WebFetch'd pages, multiple sources agreeing |
| `[Single-source]` | One source, not cross-checked | One SO answer, one blog post, one forum thread |
| `[Unverified]` | From training data or memory, not live-checked | General knowledge, no live lookup performed this session |

## End-of-Response Sources Block

For Advisory, Scope, Content, and Scout responses, append:

```
## Sources & Confidence
| Source | Tier | Accessed |
|--------|------|----------|
| [Source title](URL) | Verified | YYYY-MM-DD |
| `path/to/file.ts:42` | Verified | YYYY-MM-DD |
```

Skip this block for Quick and Debug tiers.

## Verification Handoff Format

Anytime the agent asks [Your Name] to take an action or verify something:

```
**Action:** [what to do]
**Command:** `exact command to copy-paste`
**URL:** [clickable link if applicable]
**Expected:** [what success looks like]
```

No "go check the docs." Always the exact command, URL, and expected result.

## Research Audit Trail

For non-trivial research (Advisory, Scope, Scout, Content), include:
- **Queries used:** exact search strings
- **Sources checked:** URLs visited, with outcome (useful / empty / contradicting)
- **Sources that returned nothing:** coverage transparency — [Your Name] evaluates search breadth, not just hits

Quick replies: audit trail optional. Debug: included naturally in the debug trace.

## Cross-Reference Rules

- Read full source context (comments, replies, updates) before citing — not just title/snippet
- Check for contradicting sources and flag them
- Date all findings (access date)
- Flag sources older than 6 months as potentially stale
- Never cite a source you haven't actually read in this session

## Examples

**Quick reply:**
> The auth middleware is at `Code/<your-app>/src/middleware/auth.ts:42`. It uses JWT validation via the `jose` library ([docs](https://github.com/panva/jose)).

**Advisory response (abbreviated):**
> Claude Code's auto-memory stores memories in `~/.claude/` project directories `[Verified]`. The feature was added in v1.0.8 `[Single-source]`.
>
> ## Sources & Confidence
> | Source | Tier | Accessed |
> |--------|------|----------|
> | [Claude Code docs — memory](https://docs.anthropic.com/...) | Verified | 2026-03-18 |
> | [Changelog v1.0.8](https://github.com/anthropics/claude-code/releases) | Single-source | 2026-03-18 |

**Verification handoff:**
> **Action:** Check container health
> **Command:** `ssh your-vps "docker ps --format 'table {{.Names}}\t{{.Status}}' | grep your-agent-dev"`
> **Expected:** Status shows "Up" with uptime duration (e.g., "Up 3 hours")
