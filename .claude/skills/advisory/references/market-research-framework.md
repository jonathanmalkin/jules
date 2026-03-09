# Market Research Framework

Reference doc for `/advisory` sessions involving market positioning, competitive analysis, or trend validation. Not a skill. The agent reads this when market research questions come up.

Extracted from agency-agents Trend Researcher, adapted for solo founder context.

## Weak Signal Detection

When assessing whether a trend is real or hype, look for convergence across these indicators:

1. **Search volume trajectory** -- Google Trends over 5 years. Look for sustained upward slope, not spikes.
2. **Social mention acceleration** -- Is the rate of mentions increasing, not just the absolute count?
3. **Adjacent mainstream adoption** -- Related topics going mainstream is a leading indicator.
4. **Creator ecosystem** -- Are people building courses, apps, communities around this topic? Creator density signals demand.
5. **Language normalization** -- Is the vocabulary shifting from niche/subcultural to everyday?

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
- [Need 1] -- why nobody serves this yet
- [Need 2] -- ...
```

Your positioning thesis informs the competitive advantage. For many solo founders, the advantage is willingness to serve underserved audiences with quality that signals legitimacy.

## Market Sizing (Bottom-Up)

Skip top-down TAM calculations (analyst reports about "the $X billion Y industry"). They're directionally true but operationally useless for a solo founder.

Instead, size bottom-up from actual data:

1. **Current traffic:** Daily active users from analytics
2. **Organic growth rate:** Week-over-week trend
3. **Channel potential:** For each traffic source, estimate ceiling:
   - Reddit: Total subscribers in target subs x historical post CTR
   - Organic search: Monthly search volume for target keywords x expected CTR at rank position
   - Referral: K-factor x current completions
4. **Conversion ceiling:** Current email signup rate x traffic ceiling = addressable email list
5. **Revenue potential:** Email list x expected conversion to paid product x price point

This gives a grounded SOM (Serviceable Obtainable Market). More useful than broad market size estimates.

## Technology Adoption Curve

For emerging market theses, map where the target audience sits on Rogers' curve:

| Phase | % of Market | Signals | Your App's Relevance |
|-------|-------------|---------|---------------------|
| **Innovators** (2.5%) | Already participating, teaching, building | Active community members, workshop attendees | Your current audience |
| **Early Adopters** (13.5%) | Curious but haven't started, seeking entry points | "How do I start?" searches, lurkers in communities | Primary growth target |
| **Early Majority** (34%) | Will engage when it feels safe/normal | Mainstream media coverage, major platform features | Future market -- brand positioning matters now |
| **Late Majority** (34%) | Need social proof and low friction | Normalized in popular culture | Not addressable yet |
| **Laggards** (16%) | Won't engage unless unavoidable | N/A | Not a target |

The strategic question: is the target topic transitioning from Early Adopters to Early Majority? Key evidence:
- Mainstream media tone shifting from sensational to educational
- Major platforms adding related features
- Celebrities/influencers discussing openly
- Search volume entering sustained growth (not just spikes around events)

## When to Apply This Framework

- **Rebrand decisions:** Use competitive positioning + adoption curve to assess whether a new name/domain positions well for the Early Majority transition
- **New product ideas:** Use bottom-up market sizing to reality-check revenue potential before building
- **Content strategy:** Use weak signal detection to identify topics worth creating content about
- **Pricing decisions:** Use competitive positioning to understand price anchoring in the market
