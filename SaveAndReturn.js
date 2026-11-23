/* ==================================================================
   SAVE TO DATAPIPE (-> Google Drive), THEN RETURN TO PROLIFIC
   ------------------------------------------------------------------
   Uses DATAPIPE_EXPERIMENT_ID and saveURL from the config block in
   Exp2.html. The saved file is <curID>.json and contains the same
   curData object the old save.php version sent.

   The participant never receives a copy of the data. If every upload
   attempt fails, they see a "Try again" button and a message to
   contact the researcher with their ID; they are NOT redirected to
   Prolific, so a failed save cannot be submitted as complete.
   ================================================================== */

var saveInProgress = false;

function SaveAndReturn() {
  if (saveInProgress || dataSaved) { return; }
  saveInProgress = true;

  // stop a second click from re-running Done() / starting a second save
  var btn = document.getElementById('SubmitButton');
  if (btn) {
    btn.onclick = null;
    btn.removeAttribute('href');
    btn.textContent = 'Saving your data, please wait. Do not close this page.';
  }

  var endTime = new Date();
  var totalTime = endTime - startExperimentTime;
  var curData = {
    "curID": curID,
    "institution": 'Dartmouth',
    "windowWidth": $(window).width(),
    "windowHeight": $(window).height(),
    "screenWidth": screen.width,
    "screenHeight": screen.height,
    "begTime": startExperimentTime,
    "endTime": endTime,
    "totalTime": totalTime,
    "expParams": expParams,
    "totalTrial": totalTrials,
    "surveyResponses": surveyResponses
  };

  UploadData(JSON.stringify(curData), curID + '.json');
}

function UploadData(dataString, filename) {
  var maxAttempts = 4;

  function attempt(n) {
    fetch(saveURL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Accept': '*/*' },
      body: JSON.stringify({
        experimentID: DATAPIPE_EXPERIMENT_ID,
        filename: filename,
        data: dataString
      })
    }).then(function (response) {
      if (response.ok) { return onSaved(); }
      return response.text().then(function (body) {
        // An earlier attempt may have reached DataPipe even though its
        // reply was lost; the retry then reports the file already
        // exists. Treat that as saved.
        if (body.indexOf('FILE_EXISTS') !== -1) { return onSaved(); }
        console.error('DataPipe save failed (' + response.status + '):', body);
        retry(n);
      });
    }).catch(function (err) {
      console.error('DataPipe save failed:', err);   // network error
      retry(n);
    });
  }

  function retry(n) {
    if (n + 1 < maxAttempts) {
      setTimeout(function () { attempt(n + 1); }, 2000 * (n + 1)); // 2, 4, 6 s
    } else {
      onFailed();
    }
  }

  function onSaved() {
    try { localStorage.removeItem('assign_' + experimentName); } catch (e) {}
    dataSaved = true;
    saveInProgress = false;
    ReturnToSona();
  }

  function onFailed() {
    saveInProgress = false;
    var btn = document.getElementById('SubmitButton');
    if (!btn) { return; }
    btn.textContent = 'Try again';
    btn.setAttribute('href', 'javascript:void(0)');
    btn.onclick = function () {
      if (saveInProgress || dataSaved) { return; }
      saveInProgress = true;
      btn.onclick = null;
      btn.removeAttribute('href');
      btn.textContent = 'Saving your data, please wait. Do not close this page.';
      $('#saveErrorMsg').remove();
      UploadData(dataString, filename);
    };
    $(btn).after(
      '<p id="saveErrorMsg" style="color: rgb(180,0,0);">' +
      'There was a problem saving your responses. Please click "Try again". ' +
      'If it still does not work, please keep this page open and email ' +
      'yifan.fang.gr@dartmouth.edu with your ID: <b>' + curID + '</b></p>');
  }

  attempt(0);
}
