function ReturnToSona() {
  var urlToRedirect = `https://ucsd.sona-systems.com/webstudy_credit.aspx?experiment_id=1535&credit_token=f0911ae1c29b41c79e04fa5350f8c26b&survey_code=`
   + jsPsych.data.getURLVariable('code');
  window.location.href = urlToRedirect;
}
