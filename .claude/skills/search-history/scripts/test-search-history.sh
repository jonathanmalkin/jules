#!/usr/bin/env bash
# test-search-history.sh — Validate search-history skill prerequisites
# Exit 0 on all pass, exit 1 with diagnostic on first failure.

set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); exit 1; }

echo "=== search-history skill validation ==="

# Test 1: Each glob pattern matches >= 1 file
echo ""
echo "Test 1: Glob patterns match files"
for pattern in \
  "Documents/Field-Notes/Logs/*-Session-Report*.md" \
  "Documents/Field-Notes/Logs/*-Session-Issues*.md" \
  "Documents/Field-Notes/Logs/*-Session-Retro*.md" \
  "Documents/Field-Notes/Logs/*-Memory-Synthesis*.md" \
  "Documents/Field-Notes/Plans/*.md" \
  "Documents/Field-Notes/Research/*.md"; do
  count=$(ls $pattern 2>/dev/null | wc -l | tr -d ' ')
  if [[ "$count" -ge 1 ]]; then
    pass "$pattern ($count files)"
  else
    fail "$pattern matched 0 files"
  fi
done

# Test 2: Grep finds "Session focus" in session reports
echo ""
echo "Test 2: Session reports contain 'Session focus'"
if grep -ril "Session focus" Documents/Field-Notes/Logs/*-Session-Report*.md >/dev/null 2>&1; then
  pass "Found 'Session focus' in session reports"
else
  fail "'Session focus' not found in any session report"
fi

# Test 3: Date-prefixed files exist with 2026-03 prefix
echo ""
echo "Test 3: Date-prefixed files (2026-03-*) exist"
count=$(ls Documents/Field-Notes/Logs/2026-03-* 2>/dev/null | wc -l | tr -d ' ')
if [[ "$count" -ge 1 ]]; then
  pass "Found $count files with 2026-03- prefix in Logs"
else
  fail "No files with 2026-03- prefix found in Logs"
fi

# Test 4: Decision Log exists and contains date-headed entries
echo ""
echo "Test 4: Decision Log format"
if [[ -f "Documents/Field-Notes/Decision-Log.md" ]]; then
  if grep -q '^### 20' "Documents/Field-Notes/Decision-Log.md"; then
    pass "Decision Log exists with ### 20XX date entries"
  else
    fail "Decision Log exists but no '### 20' format markers found"
  fi
else
  fail "Documents/Field-Notes/Decision-Log.md not found"
fi

# Test 5: System Evolution exists and contains expected header
echo ""
echo "Test 5: System Evolution format"
if [[ -f "Documents/System/System-Evolution.md" ]]; then
  if grep -q '# System Evolution' "Documents/System/System-Evolution.md"; then
    pass "System Evolution exists with expected header"
  else
    fail "System Evolution exists but missing '# System Evolution' header"
  fi
else
  fail "Documents/System/System-Evolution.md not found"
fi

# Test 6: Plans directory has date-prefixed files
echo ""
echo "Test 6: Plans have date-prefixed files"
count=$(ls Documents/Field-Notes/Plans/2026-03-*.md 2>/dev/null | wc -l | tr -d ' ')
if [[ "$count" -ge 1 ]]; then
  pass "Found $count date-prefixed plans (2026-03-*)"
else
  fail "No date-prefixed plans found"
fi

# Test 7: Research directory has date-prefixed files
echo ""
echo "Test 7: Research docs have date-prefixed files"
count=$(ls Documents/Field-Notes/Research/2026-03-*.md 2>/dev/null | wc -l | tr -d ' ')
if [[ "$count" -ge 1 ]]; then
  pass "Found $count date-prefixed research docs (2026-03-*)"
else
  fail "No date-prefixed research docs found"
fi

# Summary
echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
exit 0
