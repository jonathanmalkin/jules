# Profile Schema — Financial-Profile.md

## Header (YAML Frontmatter)

```yaml
---
last_updated: YYYY-MM-DD
interview_complete: true/false
interview_round_complete: 0-5
next_review_date: YYYY-MM-DD
data_staleness_warning: true/false
---
```

- `interview_round_complete`: 0 = not started, 1-5 = completed through that round
- `next_review_date`: auto-set to 30 days from last full review
- `data_staleness_warning`: set to true when any account has `data_last_verified` > 45 days old

## Sections

### 1. Accounts

| Account Name | Type | Institution | Balance | Last Verified | Notes |
|-------------|------|-------------|---------|---------------|-------|
| Individual Taxable | Brokerage | Betterment | $495,395 | 2026-03-23 | Primary runway source |
| Traditional IRA | Retirement | Betterment | $327,355 | 2026-03-23 | Rollover from prior 401(k). Penalty before 59.5 |
| Roth IRA | Retirement | Betterment | $144,815 | 2026-03-23 | Contributions accessible penalty-free |
| Savings | Savings | Ally | TBD | — | ~$200/mo interest |
| Crypto | Crypto | Coinbase | $34,064 | 2026-03-23 | 0.43 BTC + 1.57 ETH |

**Types:** checking, savings, brokerage, traditional_ira, roth_ira, solo_401k, crypto, other

### 2. Income Sources

| Source | Type | Monthly Amount | Status |
|--------|------|---------------|--------|
| Investments (dividends/interest) | investment | ~$200 | active |
| [Your Company LLC] | business | $0 | dormant |

**Status:** active, dormant, projected

### 3. Monthly Budget

**Fixed:**
| Item | Monthly | Annual |
|------|---------|--------|
| Rent (TA Associates) | $2,424 | $29,088 |
| Health Insurance (Peak One) | $1,081 | $12,972 |
| Therapy | $740 | $8,880 |

**Variable:**
| Category | Monthly Avg | Annual |
|----------|------------|--------|
| Groceries | $740 | $8,880 |
| Amazon | $402 | $4,824 |
| Dining | $282 | $3,384 |
| Transport | $116 | $1,392 |
| Health/Medical | $319 | $3,828 |
| Other | $107 | $1,286 |

**Subscriptions:**
| Service | Monthly | Category |
|---------|---------|----------|
| Claude Max | $195 | AI tools |
| Google Fiber | $72 | Internet |
| Google Fi | $57 | Phone |
| YMCA | $75 | Fitness |
| OpenAI | $21 | AI tools |
| Wispr | $15 | AI tools |
| YouTube Premium | $15 | Entertainment |
| Spotify | $13 | Entertainment |
| Proton | $8 | Security |
| DigitalOcean | $7 | Infrastructure |
| Amazon Prime | $5 | Shopping |
| Amazon Digital | $3 | Entertainment |

### 4. Debts

| Creditor | Type | Balance | Interest Rate | Min Payment | Payoff Priority |
|----------|------|---------|---------------|-------------|----------------|

(Currently no debts — populate as applicable)

### 5. Tax Profile

- **Filing status:** Single
- **State:** Texas (no state income tax)
- **Estimated annual liability:** [from last return]
- **Roth/Traditional split:** [from accounts section]
- **Carryforward losses:** [from tax return]
- **Special situations:** Zero-income years = Roth conversion opportunity (0% bracket up to standard deduction)
- **Self-employment:** LLC pass-through, no active SE income currently

### 6. Goals & Risk Tolerance

- **Time horizon:** [from interview]
- **Risk comfort:** [conservative / moderate / aggressive]
- **Retirement target ages:** 55 / 60 / 65 (model all three)
- **Specific targets:** [from interview]
- **Financial independence definition:** [from interview]

### 7. Assumptions

| Parameter | Value | Notes |
|-----------|-------|-------|
| Inflation rate | 3% | Historical average |
| Conservative return | 6% | Bond-heavy portfolio |
| Moderate return | 8% | Balanced portfolio |
| Aggressive return | 10% | Equity-heavy portfolio |
| Social Security start age | 67 | Full retirement age for birth year |
| Life expectancy | 85 | Planning horizon |

### 8. Major Upcoming Decisions

| Decision | Deadline | Impact | Status |
|----------|----------|--------|--------|
| Housing (lease expiry) | Sept 2026 | $2,424/mo rent, biggest expense line | pending |
| Roth conversion ladder | Before revenue starts | 0% bracket opportunity while zero income | pending |
| Subscription audit | Quarterly | $522/mo, already cut Skool + Supermemory | last reviewed 2026-03-23 |
