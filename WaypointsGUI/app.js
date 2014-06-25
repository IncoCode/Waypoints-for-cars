function WaypointsGUI(){}

function isInt(n) {
   return typeof n === 'number' && n % 1 == 0;
}

WaypointsGUI.prototype.initialize = function(){	
	$('<div id="popup_box" hidden><a id="popupBoxClose">Close</a></div>').appendTo(this.rootElement);	
	
	$('<button>Start recording path</button>').appendTo(this.rootElement).click(function(){	
        callSystemLuaFunction("wayPoints.startRecordingPath", "");
    });
	
	$('<button>Stop recording path</button>').appendTo(this.rootElement).click(function(){
        callSystemLuaFunction("wayPoints.stopRecordingPath", "");
    });
	
	$('<button>Save waypoints</button>').appendTo(this.rootElement).click(function(){
		callSystemLuaFuncCallback("wayPoints.getCarsId()", function(arg){
			console.log(arg);
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
	
	$('<button>Load waypoints</button>').appendTo(this.rootElement).click(function(){
        //beamng.callSystemLuaFunction("beamstate.breakAllBreakgroups()");
    });
	
	$('<button>Run all cars</button>').appendTo(this.rootElement).click(function(){
        callSystemLuaFunction("wayPoints.runAllCars", "");
    });
	
	$('<button>Print current car id</button>').appendTo(this.rootElement).click(function(){
        callSystemLuaFunction("wayPoints.printCurrentCarId", "");
    });
	
	$('#popup_box').load("apps/WaypointsGUI/saveForm.html", function() {
	
		$("#saveWayPoints").click(function() {
			console.log("4");
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
	
	console.log("WaypointsGUI inizialize");
};

WaypointsGUI.prototype.update = function(streams) {

}