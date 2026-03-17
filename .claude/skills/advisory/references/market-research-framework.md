# Market Research Framework

Reference doc for `/advisory` sessions involving market positioning, competitive analysis, or trend validation. Not a skill. Jules reads this when market research questions come up.

Extracted from agency-agents Trend Researcher, adapted for solo founder context.

## Weak Signal Detection

When assessing whether a trend is real or hype, look for convergence across these indicators:

1. **Search volume trajectory** — Google Trends over 5 years. Look for sustained upward slope, not spikes.
2. **Social mention acceleration** — Is the rate of mentions increasing, not just the absolute count?
3. **Adjacent mainstream adoption** — Related topics going mainstream is a leading indicator (e.g., meditation → mindfulness → somatic therapy → kink education).
4. **Creator ecosystem** — Are people building courses, apps, communities around this topic? Creator density signals demand.
5. **Language normalization** — Is the vocabulary shifting from clinical/subcultural to everyday? (e.g., "BDSM" → "kink" → "spice up your relationship")

**Confidence levels:**
- **Strong signal:** 3+ indicators converging, sustained over 12+ months
- **Moderate signal:** 2 indicators, 6+ months
- **Weak signal:** 1 indicator or < 6 months of data. Worth monitoring, not worth building for.

## Competitive Positioning

When assessing market position, build this map:

```
## Market Map: [Topic]

### Direct competitors (same audience, same solution type)
| Name | What they offer | Pricing | Audience size | Differentiation |
|------|----------------|---------|---------------|-----------------|
| ...  | ...            | ...     | ...           | ...             |

### Indirect competitors (same audience, different approach)
| Name | Approach | Why users might choose them over us |
|------|----------|-------------------------------------|
| ...  | ...      | ...                                 |

### Adjacent players (different audience, similar tech/approach)
| Name | Their audience | What we could learn |
|------|---------------|---------------------|
| ...  | ...           | ...                 |

### White space (unserved needs)
- [Need 1] — why nobody serves this yet
- [Need 2] — ...
```

[Your Name]'s positioning thesis: "Build where mainstream tech won't." The competitive advantage is willingness to serve taboo/stigmatized audiences with quality that signals legitimacy.

## Market Sizing (Bottom-Up)

Skip top-down TAM calculations (analyst reports about "the $X billion wellness industry"). They're directionally true but operationally useless for a solo founder.

Instead, size bottom-up from actual data:

1. **Current traffic:** Quiz starts/day from analytics
2. **Organic growth rate:** Week-over-week trend from daily_summary
3. **Channel potential:** For each traffic source, estimate ceiling:
   - Reddit: Total subscribers in target subs × historical post CTR
   - Organic search: Monthly search volume for target keywords × expected CTR at rank position
   - Referral: K-factor × current completions
4. **Conversion ceiling:** Current email signup rate × traffic ceiling = addressable email list
5. **Revenue potential:** Email list × expected conversion to paid product × price point

This gives a grounded SOM (Serviceable Obtainable Market). More useful than "the global sexual wellness market is $30B."

## Technology Adoption Curve

For the taboo-to-mainstream thesis, map where the target audience sits on Rogers' curve:

| Phase | % of Market | Signals | Quiz App Relevance |
|-------|-------------|---------|-------------------|
| **Innovators** (2.5%) | Already participating, teaching, building | Active community members, workshop attendees | These are [Your Name]'s current audience |
| **Early Adopters** (13.5%) | Curious but haven't started, seeking entry points | "How do I start?" searches, lurkers in communities | Primary growth target — the quiz serves this exact need |
| **Early Majority** (34%) | Will engage when it feels safe/normal | Mainstream media coverage, dating app features | Future market — brand positioning matters now |
| **Late Majority** (34%) | Need social proof and low friction | Normalized in popular culture | Not addressable yet |
| **Laggards** (16%) | Won't engage unless unavoidable | N/A | Not a target |

The strategic question: is the target topic transitioning from Early Adopters to Early Majority? Key evidence:
- Mainstream media tone shifting from sensational to educational
- Major platforms adding related features (dating apps, wellness apps)
- Celebrities/influencers discussing openly
- Search volume entering sustained growth (not just spikes around events)

## When to Apply This Framework

- **Rebrand decisions:** Use competitive positioning + adoption curve to assess whether a new name/domain positions well for the Early Majority transition
- **New product ideas:** Use bottom-up market sizing to reality-check revenue potential before building
- **Content strategy:** Use weak signal detection to identify topics worth creating content about
- **Pricing decisions:** Use competitive positioning to understand price anchoring in the market
