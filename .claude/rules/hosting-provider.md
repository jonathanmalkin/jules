---
paths:
  - "**/your-project/**"
---

# Hosting Provider Environment

Production/staging secrets are loaded from files in the user home directory, NOT from the hosting panel's PHP variables:
- Production: `~/.env.production` (loaded by PHP bootstrap)
- Staging: `~/.env.staging`

SSH access: `ssh your-server` (config in `~/.ssh/config`, key in 1Password)

## PHP Bootstrap Pattern

Scripts that need DB access must follow this canonical pattern (from `api/cron/your-cron-script.php`):

```php
$libDir = __DIR__ . '/../lib';
require_once $libDir . '/database.php';
// then: your env-loading and environment-detection functions
```

- Scripts must live in `api/cron/` and use `__DIR__` relative paths
- **Config keys:** Use consistent naming for DB config keys (e.g., `db_host`, `db_name`, `db_user`, `db_pass`)
- **Env vars:** Use a clear naming convention for secrets (e.g., `DB_PASSWORD`)
- Document which DB driver your project uses (mysqli vs PDO) to avoid API mismatches
- Run from app root: `cd ~/www/app.example.com/public_html && php api/cron/script.php`

## Path Structure

Subdomain path: `~/www/{subdomain}/public_html/`. The `public_html/` level is easy to miss.

MySQL CLI needs credentials from the app's `.env` files -- use PHP scripts that load the DB config instead of direct MySQL access.
