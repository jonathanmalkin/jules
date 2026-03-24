# Research Report Template

Standard structure for `/research` reports. The content agent uses this as a scaffold when drafting.

## Template

```markdown
# [Report Title]

*[One-sentence description: what this covers and why it matters right now]*

**TL;DR:** [3-4 sentences. The hook. What did we find, what does it mean, what should you do about it. This is what people share.]

## The Question

[1-2 paragraphs. What prompted this research. Use personal framing: "I noticed..." or "After running X for N months, I wanted to know..." This is the Production Veteran opener — credential + curiosity.]

## What I Found

### [Finding 1 Title]

[Finding with inline citations. Mix external sources and first-party data. For each finding: what the source says, what my experience confirms or contradicts. Use [Verified], [Single-source], or [Unverified] confidence tags on key claims per research-output-standards.md.]

### [Finding 2 Title]

[...]

### [Finding 3 Title]

[...]

## Where the Sources Disagree

[Contradicting viewpoints. What Reddit says vs. what the docs say vs. what actually happens in production. This section is the value-add — most content creators skip it. If there are no meaningful disagreements, replace with "## What's Missing" and cover the gaps in existing coverage.]

## What I Think

[[Your Name]'s original analysis. Grounded in production experience. Reference specific files, configs, or metrics from the setup. This is NOT a summary of the findings above — it's the take. The opinion. The thing that makes this [Your Name]'s report and not a Wikipedia article.]

## What to Do About It

[Actionable recommendations. Concrete steps. Commands to run, configs to change, patterns to adopt. The "so what" section. Number them if there are multiple.]

## Sources & Confidence

| Source | Tier | Accessed |
|--------|------|----------|
| [Source title](URL) | Verified | YYYY-MM-DD |
| [Source title](URL) | Single-source | YYYY-MM-DD |
| `path/to/file.ts:42` | Verified | YYYY-MM-DD |
```

## Guidance

- **Word count:** 600-1200 words for the body (excluding TL;DR and Sources table)
- **Voice:** Technical register from Voice-Profile.md. Problem-I-hit opener. Wry close. Insider knowledge drops (numbers, file paths, specific commands).
- **The "What I Think" section is mandatory and must be original.** If [Your Name] doesn't have a genuine take on this topic, the report isn't ready to publish. Park it.
- **The "Where the Sources Disagree" section is the differentiator.** Anyone can list findings. Showing contradictions and resolving them with production experience is what builds authority.
- **Every factual claim gets a source.** No bare claims. Follow `research-output-standards.md`.
