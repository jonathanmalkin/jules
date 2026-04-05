# Data Sensitivity — Financial Data Security Rules

## File Storage

- All working financial files live in `Documents/Personal-Finance/` — **gitignored**
- Raw statement imports go in `Documents/Personal-Finance/Import-Data/`
- Dashboard is local-only (`Documents/Personal-Finance/Dashboard.html`), never committed
- Net worth history is local-only (`Documents/Personal-Finance/Net-Worth-History.json`)

## Terrain.md Rules

Use relative terms only. NEVER include dollar amounts, account numbers, or balances.

**Do:** "~73 months runway", "burn rate under target", "net worth stable month-over-month"
**Don't:** "$6,733/mo burn", "$1M net worth", "Betterment balance $495K"

## Memory Rules

Use generalized language. NEVER store specific balances, account numbers, or transaction details.

**Do:** "reviewed finances, runway healthy", "spending under target", "identified subscription savings"
**Don't:** "$967K in Betterment", "cut Skool ($9/mo)", "rent is $2,424"

Note: `Profiles/Personal-Finance-Health-Context.md` is an exception — it's a standing advisory file with specific numbers, but it's in a gitignored-adjacent profile directory and is never posted externally.

## External Content Rules

For Slack, clipboard, X, Reddit, or any external platform:

| Category | Placeholder |
|----------|------------|
| Dollar amounts | [AMOUNT] |
| Account names/numbers | [ACCOUNT] |
| Institution names (in financial context) | [INSTITUTION] |
| Percentages (in financial context) | [PERCENTAGE] |
| Tax details | [TAX-DETAIL] |

## Deterministic Enforcement (Hooks)

Three layers of protection:

1. **`sensitive-session-tracker.sh`** (PostToolUse on Read)
   - Detects when financial files are read
   - Writes session-scoped flag to `/tmp/claude-sensitive-session-$$`
   - Triggers: `Documents/Personal-Finance/*`, `Profiles/Personal-Finance-Health-Context.md`, `Documents/Open-Door-Learning-LLC/Financials/*`

2. **`sensitive-outbound-guard.sh`** (PreToolUse on Bash + Slack MCP)
   - Two-gate check: session flag exists AND outbound content has financial patterns
   - Blocks: Bash (pbcopy, curl POST, xurl post/reply/quote), Slack (send_message, schedule_message, create_canvas)
   - Override: `# SAFE-OVERRIDE:` prefix after user confirmation

3. **`check-sensitive-data.sh`** (called by clipboard-validate.sh)
   - Pattern-based content scanning (backstop for paraphrase gap)
   - Blocks: API keys, credit cards, SSNs, bank accounts, PEM keys
   - Advises: dollar amounts, emails, phones, health terms, legal details

## What's NOT Gated

- Writing to local files (`Documents/`, `Profiles/`, etc.) — always allowed
- Internal analysis and calculation — no restriction
- Conversation with [Your Name] in the terminal — not outbound

## Subagent Propagation

When delegating to subagents during financial work, set:
```bash
export CLAUDE_SENSITIVE_SESSION_FILE=/tmp/claude-sensitive-session-<parent-PID>
```
This ensures subagents inherit the session flag from the parent process.
