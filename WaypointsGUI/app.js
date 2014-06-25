function WaypointsGUI(){}

WaypointsGUI.prototype.initialize = function(){	
	$('<div id="popup_box" hidden></div>').appendTo(this.rootElement);
	$('<div id="popup_box2" hidden></div>').appendTo(this.rootElement);
	
	$('<button>Start recording path</button>').appendTo(this.rootElement).click(function(){	
        callSystemLuaFunction("wayPoints.startRecordingPath", "");
    });
	
	$('<button>Stop recording path</button>').appendTo(this.rootElement).click(function(){
        callSystemLuaFunction("wayPoints.stopRecordingPath", "");
    });
	
	// save waypoints
	$('<button>Save waypoints</button>').appendTo(this.rootElement).click(function(){
		callSystemLuaFuncCallback("wayPoints.getCarsId()", function(arg){
			//console.log(arg);
			$.each(arg, function(index, value) {
				if (index == 'selected') {
					return true;
				}
				var option = $("<option></option>")
					.attr("value", index)
					.text(index);
				if (arg['selected'] == index) {
					option.attr("selected", "1");
				}
				$('#carIds').append(option);
			});			
		});
		$('#popup_box').fadeIn("slow");
    });
	
	// load waypoints
	$('<button>Load waypoints</button>').appendTo(this.rootElement).click(function(){
        callSystemLuaFuncCallback("wayPoints.getCarsId()", function(arg){
			//console.log(arg);
			$.each(arg, function(index, value) {
				if (index == 'selected') {
					return true;
				}
				var option = $("<option></option>")
					.attr("value", index)
					.text(index);
				if (arg['selected'] == index) {
					option.attr("selected", "1");
				}
				$('#carIdsLoad').append(option);
			});			
		});
		
		callSystemLuaFuncCallback("wayPoints.getWaypointsFiles()", function(arg){
			console.log(arg);
			$.each(arg, function(index, value) {
				var option = $("<option></option>")
					.attr("value", value)
					.text(value);
				$('#fileNames').append(option);
			});			
		});
		$('#popup_box2').fadeIn("slow");
    });
	
	$('<button>Run all cars</button>').appendTo(this.rootElement).click(function(){
        callSystemLuaFunction("wayPoints.runAllCars", "");
    });
	
	$('<button>Print current car id</button>').appendTo(this.rootElement).click(function(){
        callSystemLuaFunction("wayPoints.printCurrentCarId", "");
    });
	
	// save form
	$('#popup_box').load("apps/WaypointsGUI/saveForm.html", function() {
	
		$("#saveWayPoints").click(function() {			
			var carId = $("#carIds option:selected").val();
			var fileName = $("#fileName").val();
			callSystemLuaFunction("wayPoints.saveWayPoints", carId +",\"" +fileName +"\"");
			$('#popup_box').fadeOut("slow");
			$('#fileName').val("");
			$('#carIds')
				.find('option')
				.remove();
		});
		
		$("#closeSaveForm").click(function(){
			$('#popup_box').fadeOut("slow");
		});
	});
	
	// load form
	$('#popup_box2').load("apps/WaypointsGUI/loadForm.html", function() {
	
		$("#loadWayPoints").click(function() {			
			var carId = $("#carIdsLoad option:selected").val();
			var fileName = $("#fileNames option:selected").val();
			callSystemLuaFunction("wayPoints.loadWayPoints", carId +",\"" +fileName +"\"");
			$('#popup_box2').fadeOut("slow");
			$('#fileNames')
				.find('option')
				.remove();
			$('#carIdsLoad')
				.find('option')
				.remove();
		});
		
		$("#closeLoadForm").click(function(){
			$('#popup_box2').fadeOut("slow");
		});
	});
	
	console.log("WaypointsGUI inizialize");
};

WaypointsGUI.prototype.update = function(streams) {

}