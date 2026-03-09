---
name: preview-report
description: Generate and preview the daily app analytics report email
user_invocable: true
---

# Preview Daily Report

Generate the daily analytics report HTML and open it in the browser for review.

## Default (yesterday's report)

```bash
php api/cron/your-report-script.php --stdout --date=yesterday > /tmp/report.html && open /tmp/report.html
```

## With a specific date

If the user specifies a date, use `--date=YYYY-MM-DD`:

```bash
php api/cron/your-report-script.php --stdout --date=YYYY-MM-DD > /tmp/report.html && open /tmp/report.html
```

## Troubleshooting

- **"Could not connect to database"**: Make sure the dev server is running or check `.env` for database credentials
- **Empty report**: The date may have no analytics data. Try a different date or check if the dev database has been seeded
- **Missing charts**: Charts are rendered inline as base64 images. If they're broken, check that GD/Imagick PHP extensions are available

After opening the report, ask the user if they want to send it (`php api/cron/your-report-script.php --date=<date>`) or if there are issues to fix.
