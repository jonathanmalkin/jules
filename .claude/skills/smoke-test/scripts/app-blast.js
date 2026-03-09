// app-blast.js — Fast deterministic form + survey traversal
// Runs inside agent-browser eval via Playwright page.evaluate()
// Completes entire form + survey in seconds (vs 7+ min with per-click scripts)
//
// SHELL-SAFETY: This file is read via $(cat) into double-quoted eval args.
// Rules enforced: No double quotes, no $variables, no backticks, no ! operator.
// Use single quotes only. Use === null / === false instead of negation.
// These constraints ensure the JS survives shell expansion unchanged.
//
// Expects: Browser on first form step (after consent gate)
// Returns: 'RESULTS_REACHED: N steps, M survey' on success
//
// Invoke: agent-browser eval "$(cat /path/to/app-blast.js)"

(async function() {
  var ANSWERS = [3, 1, 4, 2, 5];
  var q = 0;
  var surveyed = 0;
  var MAX_Q = 80;
  var retries = 0;
  var MAX_RETRIES = 6;

  // Phase 1: Click through all form steps with varied answers
  while (q < MAX_Q) {
    var val = ANSWERS[q % ANSWERS.length];
    var opt = document.querySelector('[data-testid=likert-option-' + val + ']');

    if (opt === null) {
      // Might be a section transition or loading state — wait and retry
      if (retries < MAX_RETRIES) {
        retries++;
        await new Promise(function(r) { setTimeout(r, 800); });
        continue;
      }
      break;
    }
    retries = 0;

    opt.click();
    await new Promise(function(r) { setTimeout(r, 200); });

    var next = document.querySelector('[data-testid=form-next]');
    if (next && next.disabled === false) {
      next.click();
    }
    await new Promise(function(r) { setTimeout(r, 400); });
    q++;
  }

  // Phase 2: Survey interstitial (3 questions expected)
  // Survey shows radio buttons (input[type=radio]) — distinct from form likert divs
  for (var attempt = 0; attempt < 6; attempt++) {
    await new Promise(function(r) { setTimeout(r, 800); });

    var radio = document.querySelector('input[type=radio]');
    if (radio === null) {
      // No radio buttons — survey might still be loading on first try
      if (attempt === 0) {
        await new Promise(function(r) { setTimeout(r, 1500); });
        continue;
      }
      break;
    }

    // Click the first available radio option
    radio.click();
    radio.dispatchEvent(new Event('change', { bubbles: true }));
    await new Promise(function(r) { setTimeout(r, 300); });

    // Find and click the Next or See my results button
    var allButtons = document.querySelectorAll('button');
    var found = false;
    for (var i = 0; i < allButtons.length; i++) {
      var txt = (allButtons[i].textContent || '').trim();
      if (txt === 'Next' || txt === 'See my results') {
        allButtons[i].click();
        surveyed++;
        found = true;
        break;
      }
    }
    if (found === false) break;
    await new Promise(function(r) { setTimeout(r, 500); });
  }

  // Phase 3: Wait for calculating animation + results page to render
  await new Promise(function(r) { setTimeout(r, 3000); });

  var resultsBtn = document.querySelector('[data-testid=download-scores-button]');
  if (resultsBtn) {
    return 'RESULTS_REACHED: ' + q + ' steps, ' + surveyed + ' survey';
  }

  if (surveyed > 0) {
    return 'SURVEY_DONE_NO_RESULTS: ' + q + ' steps, ' + surveyed + ' survey';
  }

  if (q >= MAX_Q) {
    return 'FORM_INCOMPLETE: ' + q + ' steps (max hit)';
  }

  return 'FORM_DONE_NO_SURVEY: ' + q + ' steps, survey not detected';
})()
