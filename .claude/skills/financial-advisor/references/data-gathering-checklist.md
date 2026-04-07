# Data Gathering Checklist

## Tier 1 — Minimum Viable (30-60 min gathering)

- [ ] Last 3 months bank/checking statements (PDF preferred for pdf skill compatibility)
- [ ] All investment account statements (brokerage, retirement — positions + cost basis)
- [ ] Most recent tax return (1040 + Schedule C if applicable)
- [ ] Social Security statement (ssa.gov — create account if needed)
- [ ] Current insurance policies (health, renter's, umbrella, life/disability if any)
- [ ] LLC operating agreement (already at `Documents/[Your-Company-LLC]/Legal/`)

## Tier 2 — Comprehensive (adds depth)

- [ ] 12 months bank/credit card statements (seasonal spending patterns)
- [ ] 3 years tax returns (trend analysis, carryforward losses)
- [ ] Cost basis detail for all brokerage positions (tax-lot level)
- [ ] Estate documents: will, trust, beneficiary designations on all accounts, POA
- [ ] Insurance declarations pages (coverage amounts, premiums, deductibles)

## Tier 3 — Nice to Have

- [ ] Property appraisals or Zillow estimates (if real estate owned)
- [ ] Employer benefits summary (if returning to employment)
- [ ] Digital asset inventory (crypto wallets, domain names with value)

## Statement Format Compatibility

| Format | Skill | Notes |
|--------|-------|-------|
| PDF | pdf skill | Best compatibility. Preferred for all statements. |
| XLSX/XLS | xlsx skill | Works well. Common from some brokerages. |
| CSV/TSV | Manual | No dedicated skill. Use `cat` + inline parsing. |
| OFX/QFX | Not supported | Quicken format from some brokerages. Export as PDF or CSV instead. |

**Recommendation:** When downloading statements, choose PDF. If CSV is the only export option, it can be parsed inline but won't get the full skill treatment. OFX/QFX should be re-exported as PDF.

## External Data (Fetched via WebSearch)

The skill automatically fetches these before tax calculations:

- Current federal tax brackets and standard deduction
- IRA/Roth/solo 401(k) contribution limits (current year)
- Social Security bend points and full retirement age
- Current CPI inflation rate
- Treasury yield curve (for conservative return assumptions)
- ACA marketplace premiums (if health insurance is through marketplace)

## Where to Drop Files

Place raw statements in: `Documents/Personal-Finance/Import-Data/`

The skill processes files from this directory during Full Review or when explicitly asked.
