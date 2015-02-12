function WaypointsGUI(){}

WaypointsGUI.prototype.fillCarsId = function(comboBox) {
	callSystemLuaFuncCallback("wayPoints.getCarsId()", function(arg){
		$.each(arg, function(index, value) {
			if (index == 'selected') {
				return true;
			}
			var option = $("<option></option>").attr("value", index).text(index);
			if (arg['selected'] == index) {
				option.attr("selected", "1");
			}
			$(comboBox).append(option);
		});
	});
}

WaypointsGUI.prototype.stopRunCar = function(carId) {
	if ( this.isStopCar ) {
		callSystemLuaFunction("wayPoints.stopCar", carId);
	}
	else {
		callSystemLuaFunction("wayPoints.runCar", carId);
	}
}

WaypointsGUI.prototype.showSelectCarForm = function() {
	var self = this;
	var frm = this.selectCarForm;
	$(frm).empty();

	$('<label>CarId: </label>').appendTo(frm);
	var carsIdCb = $('<select></select>').appendTo(frm);
	$('<br>').appendTo(frm);
	$('<button>Select</button>').appendTo(frm).click(function(){
		var carId = $(carsIdCb).find('option:selected').val();
		self.stopRunCar(carId);
		$(frm).fadeOut('slow');
	});
	$('<br>').appendTo(frm);
	$('<button>Close</button>').appendTo(frm).click(function(){
		$(frm).fadeOut('slow');
	});

	// fill data
	this.fillCarsId(carsIdCb);

	$(frm).fadeIn('slow');
}

WaypointsGUI.prototype.showLoadForm = function() {
	var self = this;
	var frm = this.loadFrm;
	$(frm).empty();

	$('<label>CarId: </label>').appendTo(frm);
	var carsIdCb = $('<select></select>').appendTo(frm);
	$('<br>').appendTo(frm);
	$('<label>FileName: </label>').appendTo(frm);
	var wayPointsCb = $('<select></select>').appendTo(frm);
	$('<br>').appendTo(frm);
	// load btn
	$('<button>Load</button>').appendTo(frm).click(function(){
		var carId = $(carsIdCb).find('option:selected').val();
		var fileName = $(wayPointsCb).find('option:selected').val();
		callSystemLuaFunction("wayPoints.loadWayPoints", carId +",\"" +fileName +"\"");
		$(frm).fadeOut("slow");
	});
	$('<br>').appendTo(frm);
	// close btn
	$('<button>Close</button>').appendTo(frm).click(function() {
		frm.fadeOut('slow');
	});

	// fill data
	this.fillCarsId(carsIdCb);

	callSystemLuaFuncCallback("wayPoints.getWaypointsFiles()", function(arg){
		$.each(arg, function(index, value) {
			var option = $("<option></option>").attr("value", value).text(value);
			$(wayPointsCb).append(option);
		});
	});

	$(frm).fadeIn('slow');
}

WaypointsGUI.prototype.showSaveForm = function() {
	var self = this;
	var frm = this.saveFrm;
	$(frm).empty();

	$('<label>CarId: </label>').appendTo(frm);
	var carsIdCb = $('<select></select>').appendTo(frm);
	$('<br>').appendTo(frm);
	$('<label>FileName: </label>').appendTo(frm);
	var fileNameI = $('<input type="text">').appendTo(frm);
	$('<br>').appendTo(frm);
	// save btn
	$('<button>Save</button>').appendTo(frm).click(function() {
		var carId = $(carsIdCb).find('option:selected').val();
		var fileName = $(fileNameI).val();
		callSystemLuaFunction("wayPoints.saveWayPoints", carId +",\"" +fileName +"\"");
		$(frm).fadeOut("slow");
	});
	$('<br>').appendTo(frm);
	// close btn
	$('<button>Close</button>').appendTo(frm).click(function() {
		$(frm).fadeOut("slow");
	});

	// fill data
	this.fillCarsId(carsIdCb);

	$(frm).fadeIn('slow');
}

WaypointsGUI.prototype.initialize = function(){
	this.loadFrm = $('<div class="wpPopupLoadBox" hidden></div>').appendTo(this.rootElement);
	this.saveFrm = $('<div class="wpPopupSaveBox" hidden></div>').appendTo(this.rootElement);
	this.selectCarForm = $('<div class="wpSelectCarForm" hidden></div>').appendTo(this.rootElement);
	this.isStopCar = false;
	var self = this;

	$('<button>Start recording path</button>').appendTo(this.rootElement).click(function(){
        callSystemLuaFunction("wayPoints.startRecordingPath", "");
    });

	$('<button>Stop recording path</button>').appendTo(this.rootElement).click(function(){
        callSystemLuaFunction("wayPoints.stopRecordingPath", "");
    });

	// save waypoints
	$('<button>Save waypoints</button>').appendTo(this.rootElement).click(function(){
		self.showSaveForm();
    });

	// load waypoints
	$('<button>Load waypoints</button>').appendTo(this.rootElement).click(function(){
		self.showLoadForm();
    });

	$('<button>Run all cars</button>').appendTo(this.rootElement).click(function(){
        callSystemLuaFunction("wayPoints.runAllCars", "");
    });

	$('<button>Stop all cars</button>').appendTo(this.rootElement).click(function(){
        callSystemLuaFunction("wayPoints.stopAllCars", "");
    });

	$('<button>Stop car</button>').appendTo(this.rootElement).click(function(){
		self.isStopCar = true;
        self.showSelectCarForm();
    });

	$('<button>Run car</button>').appendTo(this.rootElement).click(function(){
		self.isStopCar = false;
        self.showSelectCarForm();
    });

	$('<button>Print current car id</button>').appendTo(this.rootElement).click(function(){
        callSystemLuaFunction("wayPoints.printCurrentCarId", "");
    });

	console.log("WaypointsGUI inizialize");
}