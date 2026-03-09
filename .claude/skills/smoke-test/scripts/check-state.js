// check-state.js — Detect current page state
// Shell-safe: no double quotes, no $, no backticks, no !
// Returns: RESULTS / SURVEY / FORM / CALCULATING / UNKNOWN
(function() {
  if (document.querySelector('[data-testid=download-scores-button]')) return 'RESULTS';
  if (document.querySelector('[data-testid=share-download-button]')) return 'RESULTS';
  if (document.querySelector('input[type=radio]')) return 'SURVEY';
  if (document.querySelector('[data-testid=likert-option-3]')) return 'FORM';
  var text = document.body.textContent || '';
  if (text.indexOf('Calculating') >= 0 || text.indexOf('calculating') >= 0) return 'CALCULATING';
  return 'UNKNOWN';
})()
