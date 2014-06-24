function WaypointsGUI(){}

WaypointsGUI.prototype.initialize = function(){
    //var widget = this;
	
	$('<button>Start recording path</button>').appendTo(this.rootElement).click(function(){	
        callSystemLuaFunction("wayPoints.startRecordingPath", "");
    });
	
	$('<button>Stop recording path</button>').appendTo(this.rootElement).click(function(){
        callSystemLuaFunction("wayPoints.stopRecordingPath", "");
    });	
	
	$('<button>Save waypoints</button>').appendTo(this.rootElement).click(function(){
        //beamng.callSystemLuaFunction("wayPoints.");
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
};

WaypointsGUI.prototype.update = function(streams) {

}