# Analysis Modules

Seven analysis domains for the financial advisor skill. Each module defines inputs, key calculations, and output format.

> **Live data rule:** For any module involving tax rates, contribution limits, or federal brackets, run WebSearch for current-year figures before computing. Stale data silently produces wrong advice.

---

## 1. Spending Analysis

**Purpose:** Understand where money goes, identify anomalies, measure against burn target.

**Inputs:**
- Bank statements (checking, savings) — last 3 months minimum, 12 months preferred
- Credit card statements — all active cards
- Prior-period data (if available) for trend comparison

**Key calculations:**
- Categorize every transaction (housing, food, transport, subscriptions, medical, entertainment, misc)
- Sum by category, current period vs prior period
- Identify recurring charges (subscriptions, fixed bills) — flag new ones
- Calculate monthly burn rate = total outflows excluding savings/investments
- Compare burn rate to $8,333/mo target ($100K/year from [Your Name]'s profile)
- Flag anomalies: charges > $200 in variable categories, duplicate merchants, one-time spikes

**Output format:**
```
| Category        | This Month | Last Month | 3-Mo Avg | % of Budget |
|-----------------|-----------|-----------|----------|-------------|
| Housing         | $X        | $X        | $X       | X%          |
| Food & Dining   | $X        | $X        | $X       | X%          |
| ...             |           |           |          |             |
| TOTAL           | $X        | $X        | $X       | X%          |
```
Plus: Top 3 observations (largest category, biggest month-over-month change, notable anomaly).

---

## 2. Net Worth Tracking

**Purpose:** Snapshot total financial position and track momentum.

**Inputs:**
- All account balances (checking, savings, brokerage, retirement, crypto)
- Outstanding debts (credit cards, loans)
- Balances verified within 45 days (flag stale data if older)

**Key calculations:**
- Total assets = sum of all account balances
- Total liabilities = sum of all outstanding debts
- Net worth = assets − liabilities
- Month-over-month delta (if prior snapshot exists)
- Asset composition percentages: liquid, retirement, crypto, other

**Output format:**
```
Assets
  Liquid (checking/savings): $X (X%)
  Brokerage:                 $X (X%)
  Retirement (IRA/401k):     $X (X%)
  Crypto:                    $X (X%)
  Total Assets:              $X

Liabilities:                 $X

NET WORTH:                   $X  (↑/↓ $X vs last month)
```

---

## 3. Runway Projection

**Purpose:** Answer "how long can I sustain this?" under multiple scenarios.

**Inputs:**
- Liquid assets (checking + savings + taxable brokerage — exclude retirement accounts unless forced)
- Current monthly burn rate (from Spending Analysis)
- Optimized burn rate (current burn minus identified savings from this session)
- Revenue onset scenario: hypothetical monthly revenue amount (ask [Your Name])

**Key calculations:**
- Runway (months) = liquid assets / monthly burn
- Run three scenarios:
  1. **Current burn:** no changes
  2. **Optimized burn:** apply identified savings opportunities
  3. **Revenue onset:** subtract monthly revenue from burn before dividing
- Convert months to years + months for readability

**Output format:**
```
Liquid assets available: $X

| Scenario               | Monthly Burn | Runway       |
|------------------------|-------------|--------------|
| Current burn           | $X          | X yrs X mo  |
| Optimized (saves $X/mo)| $X          | X yrs X mo  |
| With $X/mo revenue     | $X          | X yrs X mo  |
```
Note retirement account balances separately — not in runway calc, but context for total picture.

---

## 4. Retirement Projection

**Purpose:** Model whether [Your Name] is on track for financial independence at target ages.

**Inputs:**
- Current balances: Roth IRA, Traditional IRA, Solo 401(k), brokerage (taxable)
- Contribution capacity: IRA $7,000/year ($8,000 if 50+), Solo 401(k) up to $69,000 employee + 25% employer
- Annual contribution history (if available)
- Target ages: 55, 60, 65
- Social Security estimate (from SSA.gov statement if available — use placeholder if not)

**Key calculations:**
- ⚠️ WebSearch current-year IRA and 401(k) limits before computing
- Project balances at 6%, 8%, 10% annualized growth for each target age
- Assume contributions continue at current capacity until target age
- Calculate total projected income at each age (portfolio withdrawal + Social Security)
- Apply 4% safe withdrawal rule to estimate sustainable annual income from portfolio
- Note Roth vs traditional split (affects taxation in retirement)

**Output format:**
```
Current balances: Roth $X | Traditional $X | 401k $X | Taxable $X | Total $X

Projections at:
| Age | 6% Growth    | 8% Growth    | 10% Growth   |
|-----|-------------|-------------|-------------|
| 55  | $X ($X/yr)  | $X ($X/yr)  | $X ($X/yr)  |
| 60  | $X ($X/yr)  | $X ($X/yr)  | $X ($X/yr)  |
| 65  | $X ($X/yr)  | $X ($X/yr)  | $X ($X/yr)  |

($X/yr = 4% safe withdrawal. SS placeholder: +$X/yr at 65.)
```

---

## 5. Tax Optimization

**Purpose:** Identify legal tax reduction opportunities given [Your Name]'s specific situation.

**Inputs:**
- Income sources and estimated annual income
- Account types held (Roth, Traditional IRA, taxable brokerage, checking)
- Estimated realized capital gains/losses
- Business income (LLC pass-through from [Your Company])
- Prior-year tax return (if available)

**Key calculations:**
- ⚠️ WebSearch current federal tax brackets and standard deduction before computing
- Determine current bracket; identify headroom to next bracket
- Roth conversion opportunity: in zero/low-income years, convert Traditional IRA to Roth at 0-12% bracket (up to standard deduction = essentially free)
- Capital gains harvesting: 0% LTCG bracket applies up to ~$47,025 (2024 — verify current year)
- Self-employment tax: 15.3% on 92.35% of net SE income if business revenue starts
- Estimated quarterly payment schedule if revenue exceeds ~$1,000 federal liability
- Texas: no state income tax (franchise tax threshold $2.47M — not applicable at current scale)
- ACA premium tax credit: MAGI increases from Roth conversions can reduce or eliminate credits — model interaction

**Output format:**
Ranked table of opportunities:
```
| Opportunity                  | Est. Annual Savings | Complexity | Priority |
|------------------------------|---------------------|-----------|----------|
| Roth conversion ($X at 0%)   | $X tax avoided      | Low       | High     |
| LTCG harvesting              | $X tax avoided      | Medium    | High     |
| Max solo 401(k) if revenue   | $X deduction        | Medium    | Medium   |
| ...                          |                     |           |          |
```

---

## 6. Investment Allocation

**Purpose:** Confirm current portfolio is positioned intentionally relative to stated goals and risk tolerance.

**Inputs:**
- Portfolio positions across all accounts (brokerage, IRA, 401k)
- Target allocation (from Financial-Profile.md goals section; default if not set: 80/20 stocks/bonds for aggressive, 60/40 for moderate)
- Cost basis for taxable positions (tax-lot awareness)
- Risk tolerance from profile

**Key calculations:**
- Sum holdings by asset class: US stocks, international stocks, bonds, real estate (REITs), cash, alternatives, crypto
- Calculate current allocation percentages
- Compare to target allocation
- Flag drift >5% from any target category
- Identify concentration risk: any single holding >10% of total portfolio
- Note tax implications of rebalancing taxable positions (realize gains?)

**Output format:**
```
| Asset Class         | Current $  | Current % | Target % | Drift |
|---------------------|-----------|----------|----------|-------|
| US Stocks           | $X        | X%       | X%       | +X%   |
| International       | $X        | X%       | X%       | -X%   |
| Bonds               | $X        | X%       | X%       | +X%   |
| Crypto              | $X        | X%       | X%       | +X%   |
| Cash                | $X        | X%       | X%       | --    |
```
Drift alerts: [list categories with >5% drift and recommended action]

---

## 7. Debt Management

**Purpose:** Prioritize debt payoff, measure impact on runway.

**Inputs:**
- All debts: creditor, type, current balance, interest rate, minimum payment
- Available monthly surplus (income minus expenses, from Spending Analysis)

**Key calculations:**
- Rank debts by interest rate (avalanche method — highest rate first)
- Calculate payoff timeline at minimum payments vs accelerated payments
- Calculate total interest saved with avalanche approach
- Measure impact of debt elimination on monthly burn rate (runway improvement)
- Flag any debt > 15% APR as high priority

**Output format:**
```
| Creditor     | Balance | Rate  | Min Payment | Payoff Priority | Payoff (mo) |
|--------------|---------|-------|-------------|-----------------|-------------|
| [Card A]     | $X      | X%    | $X          | 1 (highest APR) | X           |
| [Card B]     | $X      | X%    | $X          | 2               | X           |
| ...          |         |       |             |                 |             |
```
Runway impact: "Eliminating all current debt frees $X/month, extending runway by X months."
