# Pixel Forge Studios LLC -- Business Identity

Canonical reference for who this company is, what it does, and how it operates. The business equivalent of `profiles/user-profile.md`.

> **Note:** This is a fictional example showing the business-identity template filled in for a hypothetical solo founder. Use it as a model for your own file.

---

## What It Is

A Texas LLC building AI-powered tools for indie game developers who can't afford full teams. The problems are real, the audience is underserved, and the tools that exist are either too expensive or built for studios, not solo devs.

- **Legal entity:** Pixel Forge Studios LLC (Texas, formed March 2024)
- **DBA:** "Pixel Forge" (the operating brand)
- **Sole member/manager:** Alex Chen
- **Structure:** Manager-managed, disregarded entity for federal tax purposes

---

## What It Does

Desktop and web tools for indie game development workflows. Everything is online-first -- account-based, browser accessible, no install required for the core tools.

**Current products:**

- **Pixel Forge Asset Generator** (pixelforge.dev/generate) -- AI-powered game asset creation for Unity and Godot. Input a style guide and a description, get sprites, tiles, and UI elements that match your game's visual language. Free tier: 20 assets/month. Pro tier: unlimited at $19/month.

- **Balance Analyzer** (pixelforge.dev/balance) -- Upload your game's weapon stats, enemy health pools, or economy curves. The tool runs simulations and flags balance outliers before your players do. Currently in beta, invite-only. Launching Q2.

**Website:** pixelforge.dev (Next.js on Vercel). Also hosting the marketing site and docs.

**Consulting:** Not actively pursued. Indie devs don't have budget; studios aren't the target market.

**Monetization model:** Freemium. Free tier drives discovery through game jam communities and word-of-mouth. Pro tier ($19/month) for devs who need volume. The hypothesis: devs who use the free tier on a jam project upgrade when they start their next serious project.

---

## Who It Serves

Indie game developers building in Unity or Godot who don't have a dedicated artist on the team. Typically solo devs or small teams (2-3 people) working on their first or second commercial game. They have programmer skills, a clear vision for their game, and the one thing blocking them is art assets that look cohesive.

- **Primary user:** Solo dev, side-project or early-stage indie studio, Unity or Godot. Has programming skills. Struggles with visual consistency across assets from different sources (itch.io packs, Fiverr artists, AI tools that don't match each other).
- **Scale signal:** 340 registered users in the first 60 days, 28% monthly retention, 8 paid conversions. Game jam communities on Discord are the top referral source.
- **Broader thesis:** The tools to make indie games have democratized everything except visual production. Unity and Godot are free. Sound libraries are cheap. Asset pipelines are the gap. AI bridges it -- if the tooling is built for devs, not designers.

---

## Operating Principles

### Value-First
Free tier is real value, not a gimped demo. 20 assets per month is enough to prototype an entire jam game. The bet is that devs who ship a jam game with Pixel Forge tools become loyal customers when they start commercial projects.

### Information Discovery
Every experiment reveals something. The beta Balance Analyzer has 40 active users who are providing feedback that's reshaping the roadmap. Monthly retros against the question: "What did we learn about what devs will pay for?" Direct Discord conversations outperform surveys -- devs will tell you exactly what's broken if you ask in their space.

### Target Market
Unity and Godot indie devs. Not mobile studios. Not AAA contractors. Not game artists (they're not our customer). The developer who needs to make their game look coherent without a dedicated art team.

### Brand Values
Accessible. Honest about limitations. Builder-friendly. No bloat. Ship things that work. The tone of a fellow dev, not a SaaS company. Jargon is fine when it's the right jargon.

---

## Brand

Alex IS the brand. Content is published on Alex's personal accounts. There is no separate "Pixel Forge" voice -- it's Alex talking about tools Alex built.

**Identity statement:** "I build AI tools that help indie devs ship games they couldn't build alone."

**The Three Stories** (every platform appearance tells one of these):

1. **"AI Tools That Ship Games"** -- The technical how-to. How the asset generator works, what the balance analyzer catches, how to get the most out of the free tier. Establishes authority. Primary on r/gamedev and r/indiegaming.

2. **"Build Where AAA Won't"** -- Why indie devs are underserved by the current AI tooling wave. The tools being built are for designers and studios with budgets. There's a huge gap at the solo-dev level. This is the differentiator story.

3. **"Solo Dev + AI = Unfair Advantage"** -- One person with good tooling can now do what used to require a team. Relatable to any solopreneur, not just game devs. Lives on r/SideProject and LinkedIn.

**Brand anchor:** AI builder who happens to know game dev. The tools are proof that the approach works. The game dev context is interesting because it's concrete and visual -- you can show the output.

Full social media strategy: `Documents/Social-Strategy.md`
Voice calibration: `Profiles/Voice-Profile.md`
Writing samples: `Profiles/Voice-Samples-Raw.md`

---

## Content Tracks

### Active

| Track | Description | Primary Platform |
|-------|-------------|-----------------|
| **Game Dev AI Tools** | How to use AI tools (including Pixel Forge) in a real indie dev workflow. Practical, specific, opinionated. | r/gamedev, r/godot |
| **Unity / Godot Automation** | Workflow automation for indie devs: asset pipelines, CI/CD for games, playtesting scripts. | r/Unity3D, r/godot |
| **Indie Dev Business** | What it actually costs to ship an indie game. Revenue, pricing, launch strategy, game jam leverage. | r/gamedev, r/SideProject |
| **Building Solo with AI** | The technical setup behind Pixel Forge: Claude Code, agent workflows, how one dev moves fast. | r/ClaudeCode, r/SideProject |

### Planned

| Track | Description | Status |
|-------|-------------|--------|
| **Balance Design Deep Dives** | Game balance theory applied to real indie titles. Uses Balance Analyzer output as examples. | Planned Q3 |
| **Asset Style Guides** | How to define a visual language for your game and maintain it across AI-generated assets. | Planned Q3 |

Tracks are not fixed. When engaging in game dev communities, watch for recurring questions that don't fit existing tracks and propose new ones.

---

## Content Platform Strategy

**Reddit** is the base. Long-form practical write-ups, published Reddit-native. Strong engagement on r/gamedev (up to 400+ upvotes on tutorial posts). 2x/week max across all subreddits to avoid spam filters. Daily comment engagement builds credibility.

**X/Twitter** is automated cross-posts from Reddit content. Experimental, low priority.

**YouTube** is planned but not active. Short-form dev logs are a natural fit once the Balance Analyzer launches publicly -- showing before/after on real games is compelling visual content.

**LinkedIn, Instagram, TikTok** are not active. To be evaluated if content starts finding broader audiences outside game dev communities.

---

## Reference Documents

| Document | Location |
|----------|----------|
| Operating Agreement | `Documents/Legal/Operating-Agreement/` |
| Privacy Policy | `Documents/Policies/Privacy-Policy.md` |
| Terms of Service | `Documents/Policies/Terms-of-Service.md` |
| Financials | `Documents/Financials/` |
| Voice Profile | `Profiles/Voice-Profile.md` |
| Voice Samples | `Profiles/Voice-Samples-Raw.md` |
| Content Pipeline | `Documents/Content-Pipeline/` |
| Asset Generator Codebase | `Code/pixel-forge-generator/` |
| Balance Analyzer Codebase | `Code/pixel-forge-balance/` |
