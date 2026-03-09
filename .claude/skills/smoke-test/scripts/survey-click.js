// survey-click.js — Click through survey interstitial questions
// Shell-safe: no double quotes, no $, no backticks, no !
// Returns: SURVEY_DONE:N / NO_SURVEY:0
(async function() {
  var n = 0;

  for (var attempt = 0; attempt < 6; attempt++) {
    await new Promise(function(r) { setTimeout(r, 800); });

    var radio = document.querySelector('input[type=radio]');
    if (radio === null) {
      if (attempt === 0) {
        await new Promise(function(r) { setTimeout(r, 1500); });
        continue;
      }
      // No radio — check for free-text question with skip button
      var skipBtn = null;
      var allBtns = document.querySelectorAll('button');
      for (var s = 0; s < allBtns.length; s++) {
        var st = (allBtns[s].textContent || '').trim();
        if (st === 'Skip to my results' || st === 'See my results') {
          skipBtn = allBtns[s];
          break;
        }
      }
      if (skipBtn !== null && skipBtn.disabled !== true) {
        skipBtn.click();
        n++;
        await new Promise(function(r) { setTimeout(r, 500); });
        continue;
      }
      break;
    }

    radio.click();
    radio.dispatchEvent(new Event('change', { bubbles: true }));
    await new Promise(function(r) { setTimeout(r, 300); });

    var btns = document.querySelectorAll('button');
    var clicked = false;
    for (var i = 0; i < btns.length; i++) {
      var t = (btns[i].textContent || '').trim();
      if (t === 'Next' || t === 'See my results') {
        btns[i].click();
        n++;
        clicked = true;
        break;
      }
    }
    if (clicked === false) break;
    await new Promise(function(r) { setTimeout(r, 500); });
  }

  return (n > 0 ? 'SURVEY_DONE:' : 'NO_SURVEY:') + n;
})()
