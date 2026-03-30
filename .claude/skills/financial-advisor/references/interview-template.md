# Interview Template

Five interview rounds for initial financial profile setup. Rounds can be completed across multiple sessions — progress is saved after each round.

**Resumption:** Check `interview_round_complete` in Financial-Profile.md header. Resume from round N+1.

**Validation style:** Silent math checks throughout. Surface discrepancies warmly, never as blocks.

---

## Round 1: Income & Burn

**Goal:** Establish money-in and money-out baseline.

**Questions to ask:**
1. What are your current income sources? (employment, business revenue, investment dividends/interest, rental, other)
2. For each source: roughly how much per month, and is it active/dormant/projected?
3. What's your rough monthly spending estimate? (Or: "We can calculate it precisely from statements — do you have those ready?")
4. How much of your spending is fixed (same every month) vs variable?
5. Does $8,333/month feel right as your target lifestyle cost, or is your actual number different?

**What to validate:**
- Income sources sum to something. Zero income is fine — just needs to be explicit.
- If stated monthly spending > stated income, note it: "You're spending more than you're bringing in right now — that's what runway is for. Let's quantify it."
- Cross-check against known data: burn rate implied by pre-scanned statements.

**Save to profile:**
```yaml
income_sources: [list with amounts and status]
estimated_monthly_burn: $X
burn_target: $8,333  # from profile, confirm or update
interview_round_complete: 1
```

---

## Round 2: Assets & Accounts

**Goal:** Complete account inventory with balances.

**Questions to ask:**
1. Let's go through every account you have. For each: name, what type is it (checking, savings, brokerage, IRA, Roth IRA, 401k, crypto, other), what institution, and your best current balance?
2. When did you last look at that balance?
3. Are there any accounts you have but haven't checked recently?

**Pre-scan note:** The skill may have already identified accounts from documents provided:
- Betterment: ~$967K (verify current balance)
- Coinbase: ~$34K (verify current balance)
- Ally Savings: balance TBD
- Confirm these and add any missing accounts.

**What to validate:**
- Every account gets a `last_verified_date` — flag anything >45 days old as potentially stale.
- Retirement accounts (IRA, Roth, 401k) are distinct from liquid — ask specifically about each type.
- Crypto: ask for approximate USD value at today's prices, not just coin count.

**Save to profile:**
```markdown
## Accounts
| Name           | Type     | Institution | Balance  | Last Verified | Notes |
|----------------|---------|------------|---------|--------------|-------|
| Betterment     | Brokerage| Betterment | $X      | YYYY-MM-DD   |       |
| Coinbase       | Crypto   | Coinbase   | $X      | YYYY-MM-DD   |       |
| Ally Savings   | Savings  | Ally       | $X      | YYYY-MM-DD   |       |
| ...            |          |            |         |              |       |
```
```yaml
interview_round_complete: 2
```

---

## Round 3: Debts & Obligations

**Goal:** Full picture of what's owed and what's committed.

**Questions to ask:**
1. Any credit card balances currently? For each: roughly how much, what's the interest rate, and what's the minimum payment?
2. Any loans — auto, personal, student?
3. What are your fixed monthly obligations? (Rent is $2,424/mo through Sept 2026 — confirm. What else? Insurance, therapy, subscriptions?)
4. Any recurring payments that don't vary month to month?

**What to validate:**
- If credit card balances > $0, make sure interest rates are captured — this matters for payoff priority.
- Rent $2,424/mo through Sept 2026 is pre-known — confirm and note lease expiry as a major upcoming decision.
- Run a silent total of fixed obligations. If fixed obligations alone exceed burn target, note it.

**Save to profile:**
```markdown
## Debts
| Creditor | Type | Balance | Rate | Min Payment | Priority |
|----------|------|---------|------|-------------|----------|
| ...      |      |         |      |             |          |

## Fixed Monthly Obligations
| Item             | Monthly | Notes                          |
|------------------|---------|-------------------------------|
| Rent             | $2,424  | Lease through Sept 2026        |
| Therapy          | $X      |                               |
| Health insurance | $X      |                               |
| ...              |         |                               |
```
```yaml
interview_round_complete: 3
```

---

## Round 4: Tax Situation

**Goal:** Understand tax position to identify optimization opportunities.

**Questions to ask:**
1. What's your filing status? (Single — confirm)
2. What was your approximate federal tax liability last year?
3. Are you making quarterly estimated tax payments right now?
4. Do you have a mix of Roth and traditional IRA? Roughly how much in each?
5. Do you have any carryforward capital losses from prior years?
6. Is [Your Company LLC] generating any revenue right now?

**What to validate:**
- If LLC is generating revenue: ask about estimated annual income — SE tax implications kick in.
- If income is near zero: this is the Roth conversion golden window. Make a note.
- Roth vs traditional split matters for long-term tax efficiency and conversion ladder planning.
- Confirm Texas residency (no state income tax — simple, but worth confirming).

**Save to profile:**
```yaml
tax_profile:
  filing_status: single
  state: Texas
  estimated_annual_liability: $X
  quarterly_payments: yes/no
  roth_balance_approx: $X
  traditional_ira_approx: $X
  carryforward_losses: $X or none
  llc_revenue_active: yes/no
interview_round_complete: 4
```

---

## Round 5: Goals & Risk Tolerance

**Goal:** Establish direction so analysis modules can interpret numbers as good/bad/concerning.

**Questions to ask:**
1. When are you targeting financial independence — the point where you don't *need* to work?
2. How do you think about investment risk? Conservative (capital preservation), moderate (balanced growth), or aggressive (max growth, comfortable with swings)?
3. Any specific financial goals in the next 1-3 years? (home purchase, travel, major expenses)
4. What are you thinking about the housing situation in Sept 2026 when the lease expires?
5. Retirement age target — 55? 60? 65? Earlier?

**What to validate:**
- If risk tolerance is "aggressive" but portfolio is mostly bonds/cash, note the mismatch.
- Housing Sept 2026 is pre-known from memory — prompt specifically. This is a big decision.
- Financial independence target interacts with runway calculations — capture the target age.

**Save to profile:**
```markdown
## Goals & Risk Tolerance
- Time horizon for financial independence: target age X / year YYYY
- Risk tolerance: aggressive / moderate / conservative
- Retirement age preference: X
- Specific targets: [list]

## Major Upcoming Decisions
| Decision              | Deadline     | Impact         | Status  |
|-----------------------|-------------|----------------|---------|
| Housing (lease expiry)| Sept 2026    | $2,424/mo rent | Open    |
| ...                   |             |                |         |
```
```yaml
interview_complete: true
interview_round_complete: 5
next_review_date: YYYY-MM-DD  # set to 3 months from now
```

---

## Validation Patterns (Silent)

Run these checks throughout the interview. Surface gently if triggered:

| Check | Trigger | Response |
|-------|---------|----------|
| Burn vs income | Burn > income | "You're drawing down savings right now — that's fine, that's what runway is for. Let's measure it." |
| Fixed > budget | Fixed costs alone > $8,333/mo | "Your fixed commitments total $X which already exceeds the $8,333 budget target. Want to revisit the target?" |
| Stale balances | Any account >45 days | "That balance is X days old — worth refreshing before we use it for projections." |
| Unknown rate | Debt with no rate | "What's the APR on that one? It affects payoff priority significantly." |
| Missing Roth | Profile suggests traditional only | "Do you have any Roth accounts? It matters a lot for the tax strategy." |
