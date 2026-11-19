function SaveAndReturn() {


	var endTime = new Date();
	var totalTime = endTime - startExperimentTime;
  	var curData = {
    	"curID": curID,
			"sonaCode": jsPsych.data.getURLVariable('code'),
    	"windowWidth": $(window).width(),
    	"windowHeight": $(window).height(),
   		"screenWidth": screen.width,
   	 	"screenHeight": screen.height,
   	 	"begTime": startExperimentTime,
    	"endTime": endTime,
    	"totalTime": totalTime,
			"expParams": expParams,
    	"totalTrial": totalTrials,
			"surveyResponses": surveyResponses,
  		};
  		var dataToServer = {
  		'id': curID,
    	'experimenter': 'DA',
   	 	'experimentName': 'Exp1a_Cs',
    	'curData': JSON.stringify(curData)
  	};
  $.post("https://rcweb.dartmouth.edu/StoermerLab/save.php", dataToServer, ReturnToSona());
}
