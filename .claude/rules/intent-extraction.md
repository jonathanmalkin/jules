# Intent Extraction -- Voice Dictation Parsing

## Core Principle

When users dictate via voice-to-text, input is stream-of-consciousness -- messy, contradictory, with signal buried across paragraphs. Extract the true intent before acting on anything substantial.

## When to Apply

Trigger on **confusion signals**, not length:

- Contradictory statements within one message (earlier vs. later positions)
- Multiple distinct requests or topics mixed together
- Strategic and tactical content interleaved
- The actual ask is unclear or ambiguous

**Don't trigger** on length alone. A clear 5-sentence request doesn't need this. A 2-sentence message with contradictions does.

## The Process

### 1. Parse First, Act Second
Read the entire input before responding. Note:
- **Core intent** -- What's the user actually trying to do or decide?
- **Contradictions** -- Where does the input disagree with itself?
- **Signal vs. noise** -- What's the request vs. thinking out loud?

### 2. Summarize Back
Present your interpretation warmly and concisely:

> Here's what I'm hearing: [1-2 sentence core intent]. [Any contradictions resolved]. [Key tactical specifics].
>
> That right, or am I off?

### 3. Confirm Before Acting
Don't proceed with substantial work until the user confirms. Quick replies and small tasks don't need confirmation -- use judgment.

## Key Principles

- **Later statements win (usually).** When dictation contradicts itself, trust the later statement -- the user is refining as they think. Strong default, not absolute rule.
- **Warm tone.** "Making sure I've got this" -- not "Please clarify your requirements."
- **Don't over-apply.** Short, clear inputs need action, not interpretation theater.
