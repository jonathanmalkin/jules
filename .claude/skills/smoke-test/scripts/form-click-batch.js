// form-click-batch.js — Click through up to 15 form steps per eval
// Shell-safe: no double quotes, no $, no backticks, no !
// Returns: BATCH_DONE:N / RESULTS_FOUND:N / SURVEY_FOUND:N / NO_OPTIONS:N
(async function() {
  var A = [3, 1, 4, 2, 5];
  var n = 0;
  var retries = 0;

  for (var i = 0; i < 15; i++) {
    if (document.querySelector('[data-testid=download-scores-button]'))
      return 'RESULTS_FOUND:' + n;
    if (document.querySelector('input[type=radio]'))
      return 'SURVEY_FOUND:' + n;

    var val = A[i % 5];
    var opt = document.querySelector('[data-testid=likert-option-' + val + ']');

    if (opt === null) {
      if (retries < 4) {
        retries++;
        i--;
        await new Promise(function(r) { setTimeout(r, 800); });
        continue;
      }
      return 'NO_OPTIONS:' + n;
    }
    retries = 0;

    opt.click();
    await new Promise(function(r) { setTimeout(r, 200); });

    var next = document.querySelector('[data-testid=form-next]');
    if (next && next.disabled === false) {
      next.click();
    }
    await new Promise(function(r) { setTimeout(r, 400); });
    n++;
  }

  return 'BATCH_DONE:' + n;
})()
