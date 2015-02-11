function WaypointsGUI(){}

WaypointsGUI.prototype.initialize = function(){	
	$('<div id="wpPopupSaveBox" hidden></div>').appendTo(this.rootElement);
	$('<div id="wpPopupLoadBox" hidden></div>').appendTo(this.rootElement);
	
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
		$('#wpPopupSaveBox').fadeIn("slow");
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
		$('#wpPopupLoadBox').fadeIn("slow");
    });
	
	$('<button>Run all cars</button>').appendTo(this.rootElement).click(function(){
        callSystemLuaFunction("wayPoints.runAllCars", "");
    });
	
	$('<button>Print current car id</button>').appendTo(this.rootElement).click(function(){
        callSystemLuaFunction("wayPoints.printCurrentCarId", "");
    });
	
	// save form
	$('#wpPopupSaveBox').load("apps/WaypointsGUI/saveForm.html", function() {
	
		$("#wpSaveWayPoints").click(function() {			
			var carId = $("#carIds option:selected").val();
			var fileName = $("#fileName").val();
			callSystemLuaFunction("wayPoints.wpSaveWayPoints", carId +",\"" +fileName +"\"");
			$('#wpPopupSaveBox').fadeOut("slow");
			$('#fileName').val("");
			$('#carIds')
				.find('option')
				.remove();
		});
		
		$("#wpCloseSaveForm").click(function(){
			$('#wpPopupSaveBox').fadeOut("slow");
		});
	});
	
	// load form
	$('#wpPopupLoadBox').load("apps/WaypointsGUI/loadForm.html", function() {
	
		$("#wpLoadWayPoints").click(function() {			
			var carId = $("#carIdsLoad option:selected").val();
			var fileName = $("#fileNames option:selected").val();
			callSystemLuaFunction("wayPoints.wpLoadWayPoints", carId +",\"" +fileName +"\"");
			$('#wpPopupLoadBox').fadeOut("slow");
			$('#fileNames')
				.find('option')
				.remove();
			$('#carIdsLoad')
				.find('option')
				.remove();
		});
		
		$("#wpCloseLoadForm").click(function(){
			$('#wpPopupLoadBox').fadeOut("slow");
		});
	});
	
	console.log("WaypointsGUI inizialize");
};

WaypointsGUI.prototype.update = function(streams) {

}