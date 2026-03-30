# Dashboard Template — Self-Contained HTML

## Setup Requirement

First-time setup (run once, then embed):
```bash
curl -s https://cdn.jsdelivr.net/npm/chart.js/dist/chart.umd.min.js -o /tmp/chartjs-bundle.js
```

Embed the contents as an inline `<script>` block in the dashboard. Dashboard generation never needs network access after this. (~200KB inline, acceptable for a local file.)

**Check existence before generating:** `/tmp/chartjs-bundle.js` is cleared on reboot. If missing, re-fetch before building the HTML.

## Layout

| # | Section | Chart Type | Data Source |
|---|---------|-----------|-------------|
| 1 | Key Metrics | 4 HTML cards (top row) | Latest monthly summary |
| 2 | Net Worth Over Time | Line chart | `Net-Worth-History.json` |
| 3 | Monthly Spending Breakdown | Doughnut chart | Latest monthly summary categories |
| 4 | Runway Projection | Grouped bar chart | Liquid assets at 3 scenarios |
| 5 | Investment Allocation | Side-by-side doughnuts | Current vs target allocation |
| 6 | Spending Trend | Line chart | Last 6-12 monthly summaries |

## Key Metrics Cards

4 cards across the top row. Colored top border (4px) indicates health:

| Card | Green | Yellow | Red |
|------|-------|--------|-----|
| Monthly Burn Rate | < $8,333/mo | $8,333-$9,583 (+15%) | > $9,583 |
| Runway | > 36 months | 12-36 months | < 12 months |
| Net Worth | N/A (neutral blue) | — | — |
| Net Worth Delta | positive | 0 | negative |

## Data Shape

```javascript
const DATA = {
  metrics: {
    burnRate: 6733,
    runway: 73,            // months
    netWorth: 1000000,
    netWorthDelta: 15000   // month-over-month change
  },
  netWorthHistory: [
    { date: "2026-03", value: 1000000 }
  ],
  spendingBreakdown: {
    "Rent": 2424,
    "Health Insurance": 1081,
    "Therapy": 740,
    "Groceries": 740,
    "Subscriptions": 522,
    "Health/Medical": 319,
    "Amazon": 402,
    "Dining": 282,
    "Transport": 116,
    "Other": 107
  },
  runwayScenarios: {
    current: 73,      // months at current burn
    optimized: 85,    // months with identified savings
    withRevenue: 120  // months with hypothetical revenue
  },
  allocation: {
    current: { "US Stocks": 40, "Int'l Stocks": 20, "Bonds": 30, "Crypto": 5, "Cash": 5 },
    target: { "US Stocks": 45, "Int'l Stocks": 20, "Bonds": 25, "Crypto": 5, "Cash": 5 }
  },
  spendingTrend: [
    { date: "2026-03", amount: 6733 }
  ]
};
```

## HTML Template Structure

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Financial Dashboard — [DATE]</title>
  <style>
    /* Light theme */
    body { font-family: -apple-system, system-ui, sans-serif; background: #fff; color: #1a1a1a; margin: 0; padding: 20px; }
    .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 20px; max-width: 1200px; margin: 0 auto; }
    .card { background: #f8f9fa; border-radius: 8px; padding: 20px; border-top: 4px solid #007bff; }
    .card.green { border-top-color: #28a745; }
    .card.yellow { border-top-color: #ffc107; }
    .card.red { border-top-color: #dc3545; }
    .metric-value { font-size: 2rem; font-weight: 700; }
    .metric-label { font-size: 0.875rem; color: #6c757d; text-transform: uppercase; }
    .chart-container { background: #f8f9fa; border-radius: 8px; padding: 20px; }
    h1 { text-align: center; margin-bottom: 30px; }
    .footer { text-align: center; color: #6c757d; margin-top: 40px; font-size: 0.75rem; }

    /* Print-friendly */
    @media print {
      body { background: #fff; }
      .card, .chart-container { break-inside: avoid; border: 1px solid #dee2e6; }
    }
  </style>
</head>
<body>
  <h1>Financial Dashboard</h1>

  <!-- Key Metrics Cards -->
  <div class="grid" style="grid-template-columns: repeat(4, 1fr); margin-bottom: 30px;">
    <div class="card" id="card-burn"></div>
    <div class="card" id="card-runway"></div>
    <div class="card" id="card-networth"></div>
    <div class="card" id="card-delta"></div>
  </div>

  <!-- Charts Grid -->
  <div class="grid">
    <div class="chart-container" style="grid-column: span 2;">
      <canvas id="chart-networth"></canvas>
    </div>
    <div class="chart-container">
      <canvas id="chart-spending"></canvas>
    </div>
    <div class="chart-container" style="grid-column: span 2;">
      <canvas id="chart-runway"></canvas>
    </div>
    <div class="chart-container">
      <canvas id="chart-allocation-current"></canvas>
      <canvas id="chart-allocation-target"></canvas>
    </div>
    <div class="chart-container" style="grid-column: span 2;">
      <canvas id="chart-trend"></canvas>
    </div>
  </div>

  <div class="footer">Generated [TIMESTAMP] — local file, never committed</div>

  <!-- Chart.js embedded inline -->
  <script>/* [EMBED /tmp/chartjs-bundle.js contents here] */</script>

  <!-- Data injection -->
  <script>const DATA = { /* [INJECT DATA HERE] */ };</script>

  <!-- Chart rendering -->
  <script>
    // Render all charts using DATA object
    // [Generate chart initialization code dynamically]
  </script>
</body>
</html>
```

## Generation Checklist

When generating a dashboard instance:

1. Check if `/tmp/chartjs-bundle.js` exists — re-fetch if missing
2. Populate `const DATA = {...}` with current analysis results
3. Embed Chart.js bundle contents inline in the HTML (replace placeholder comment)
4. Apply card color classes based on thresholds above
5. Write to `Documents/Personal-Finance/Dashboard-YYYY-MM.html`
6. Open with: `open Documents/Personal-Finance/Dashboard-YYYY-MM.html`

**Never commit dashboard files.** `Documents/Personal-Finance/` is gitignored.

## Chart Configuration Notes

- **Colors:** Consistent palette. Primary: #007bff. Success: #28a745. Warning: #ffc107. Danger: #dc3545. Muted: #6c757d.
- **Net Worth line:** Single line, area fill below, data points visible
- **Spending doughnut:** Sort categories by amount descending, limit to top 8, group rest as "Other"
- **Runway bars:** 3 bars (current, optimized, with revenue), colored green/yellow/red respectively
- **Allocation doughnuts:** Two side-by-side, same color mapping for asset classes in both
- **Spending trend:** Line chart with data points, area fill, show $8,333 target as dashed reference line
- **All charts:** `responsive: true`, `maintainAspectRatio: false`, legend below
- **Print styles:** `@media print { .card, .chart-container { break-inside: avoid; } }`
