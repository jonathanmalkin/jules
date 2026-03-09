---
paths:
  - Code/**
---
# Production Deploy Gate

Ask the user before pushing to production branches unless standing orders apply (staging CI + smoke test passed, no new feature/behavior change).

Specifically, before running any of these, get explicit user approval (or confirm standing order bounds are met):
- `git push` to `production` branch (any form)
- `gh workflow run` with `environment=production`
- Any SSH command that modifies production files

After deploying: verify the fix yourself before reporting success.
