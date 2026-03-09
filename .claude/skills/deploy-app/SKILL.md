---
name: deploy-app
description: Validate locally, deploy the web app to staging, smoke test, and (with human approval) deploy to production. Triggers on "deploy the app", "push to staging", "push to production", or "/deploy-app".
user_invocable: true
---

# Deploy App

**Working directory:** All `scripts/` paths are relative to `Code/my-app/`. `cd` there before running any script.

## Full Pipeline

1. Deploy to staging
2. Smoke test staging
3. Human approval
4. Deploy to production
5. Smoke test production (generates verifiable data)
6. Pull analytics immediately, verify smoke test session was recorded

## Step 1: Deploy to Staging

Run the deploy script:

```
cd Code/my-app && bash scripts/deploy-staging.sh
```

The script handles pre-flight checks, local validation (lint + build + unit tests), pushes main to the staging branch, monitors GitHub Actions, and verifies the health endpoint.

Only proceed to step 2 after the script exits successfully (or the health endpoint is confirmed healthy).

## Step 2: Smoke Test Staging

Run the `/smoke-test` skill against staging (staging.example.com).

Only proceed to step 3 if the smoke test passes.

## Step 3: Human Approval

Check deploy approval rules:
- Staging CI passed? Smoke test passed? -> Yes to both = proceed automatically.
- Is this a **first deploy of a new feature** or **user-visible behavior change**? -> Ask First.
- Otherwise (bug fixes, infrastructure, copy optimizations, refactors) -> Just deploy. Report at wrap-up.

If Ask First applies, ask explicitly: "Staging is deployed and smoke tests passed. Deploy to production?"

## Step 4: Deploy to Production

After human approval, run the production deploy script:

```
cd Code/my-app && bash scripts/deploy-production.sh
```

The script pushes staging -> production (with automatic merge fallback for non-fast-forward), monitors GitHub Actions, and verifies the health endpoint.

Only tell the user "deployed to production" after the script exits successfully.

## Step 5: Smoke Test Production

Note the current timestamp before starting. Then run `/smoke-test` against production (app.example.com).

This generates real sessions and events that Step 6 will verify.

## Step 6: Verify Analytics

Post-deploy verification must use data collected AFTER deploy, never pre-deploy analytics.

Immediately after the production smoke test passes (no waiting):

1. Pull fresh data: `make analytics-pull`
2. Query for events created since the timestamp noted in Step 5. Verify that `session_created`, `results_saved`, and `email_signup` events exist in that window.
3. If the smoke test events are present, analytics pipeline is confirmed working.
4. If events are missing, flag it and suggest checking the health endpoint and error logs.

## If the script fails

- **"Working tree is dirty"** -- Automatically stage all modified/deleted tracked files, generate a commit message from the diff, commit, and rerun the deploy script. Do not ask for permission.
- **"Not on main"** -- Ask the user if they want to switch branches or if this is intentional.
- **"Local validation failed"** -- Read the validation output. Fix lint errors or test failures, commit the fix, and rerun.
- **"GitHub Actions pipeline failed"** -- Run `gh run view <RUN_ID> --log-failed` to get the failure details. Diagnose and fix.
- **"Health check failed"** -- Curl the health endpoint manually and report the response. May be a temporary hosting issue -- wait 30 seconds and retry once.
