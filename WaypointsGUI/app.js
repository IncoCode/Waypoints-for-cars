function WaypointsGUI(){}

WaypointsGUI.prototype.initialize = function(){
    //this._updateHydrosData();
    var widget = this;
	
	$('<button>Start recording path</button>').appendTo(this.rootElement).click(function(){
        beamng.sendActiveObjectLua("beamstate.breakAllBreakgroups()");
    });
	
	$('<button>Stop recording path</button>').appendTo(this.rootElement).click(function(){
        beamng.sendActiveObjectLua("beamstate.breakAllBreakgroups()");
    });
	
	$('<button>Save waypoints</button>').appendTo(this.rootElement).click(function(){
        beamng.sendActiveObjectLua("beamstate.breakAllBreakgroups()");
    });
	
	$('<button>Load waypoints</button>').appendTo(this.rootElement).click(function(){
        beamng.sendActiveObjectLua("beamstate.breakAllBreakgroups()");
    });
	
	$('<button>Run all cars</button>').appendTo(this.rootElement).click(function(){
        beamng.sendActiveObjectLua("beamstate.breakAllBreakgroups()");
    });
	
	$('<button>Print current car id</button>').appendTo(this.rootElement).click(function(){
        beamng.sendActiveObjectLua("beamstate.breakAllBreakgroups()");
    });
};

WaypointsGUI.prototype.update = function(streams) {

}