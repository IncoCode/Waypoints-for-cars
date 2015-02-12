-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

-- Mod by Incognito
-- Version: 1.0.6
-- Link on the thread: http://www.beamng.com/threads/2947-Waypoints-%28paths%29-for-cars

local M = {}

-- table that contains the persistent data for the agents
local agents = {}

local wayPoints = {}
local wayPointsIndex = {}
local canCarRun = {}

local recordEnabled = 0
local skipPointEnabled = 1

local function getLastIndex( t )
	local lastIndex = 1
	for key, value in pairs( t ) do
		lastIndex = lastIndex + 1
	end
	return lastIndex
end

local function getCurrentCarId()
	local slotCount = BeamEngine:getSlotCount()
	local result = 0
	for objectID = 0, slotCount, 1 do
		local b = BeamEngine:getSlot(objectID)
		if b ~= nil then
			if b.activationMode == 1 then
				result = objectID
				break
				--do return result end
			end
		end
	end
	do return result end
end

local function printCurrentCarId()
	local carId = getCurrentCarId()
	print("Current carId = "..carId)
end

local function clearCarWayPoints( carId )
	wayPoints[carId] = nil
	wayPointsIndex[carId] = nil
	canCarRun[carId] = nil
end

local function initWayPointsArr( carId )
	if ( wayPoints[carId] == nil ) then
		wayPoints[carId] = {}
		wayPoints[carId].position = {}
		wayPoints[carId].maxCount = 0
		if ( canCarRun[carId] == nil ) then
			canCarRun[carId] = 0
		end
	end
end

local function addPoint( carId, maxSpeed )
	local playerPosition = BeamEngine:getSlot(getCurrentCarId()):getPosition()
	initWayPointsArr( carId )
	local index = wayPoints[carId].maxCount
	wayPoints[carId].position[index] = {}
	wayPoints[carId].position[index].pos = playerPosition
	wayPoints[carId].position[index].maxSpeed = maxSpeed
	wayPoints[carId].maxCount = wayPoints[carId].maxCount + 1
	print("Point added!")
end

local function recordPoint()
	local carId = getCurrentCarId()
	--initWayPointsArr( carId )
	local playerPosition = BeamEngine:getSlot(carId):getPosition()
	local oldIndex = wayPoints[carId].maxCount - 1
	local oldX = wayPoints[carId].position[oldIndex].pos["x"]
	local oldY = wayPoints[carId].position[oldIndex].pos["y"]
	local oldZ = wayPoints[carId].position[oldIndex].pos["z"]
	local x = playerPosition["x"]
	local y = playerPosition["y"]
	local z = playerPosition["z"]

	local airspeed = BeamEngine:getSlot(carId):getVelocity():length()
	local carSpeed = math.floor(airspeed * 3.6) -- in km/h
	local diff = 0.5
	if ( carSpeed > 45 and carSpeed <= 65 ) then
		diff = 4
	elseif ( carSpeed > 65 and carSpeed <= 100 ) then
		diff = 6
	else
		diff = 10
	end
	if
	math.abs(x - oldX) >= diff or
	math.abs(y - oldY) >= diff or
	math.abs(z - oldZ) >= diff or
	wayPoints[carId] == nil then
		addPoint( carId, carSpeed )
	end
end

local function startRecordingPath()
	if ( recordEnabled == 0 ) then
		local carId = getCurrentCarId()
		clearCarWayPoints( carId )
		initWayPointsArr( carId )
		wayPoints[carId].maxCount = 1
		addPoint( carId, 15 )
		recordEnabled = 1
		print("Path recording enabled!")
	else
		print("Recording path already enabled!")
	end
end

local function stopRecordingPath()
	recordEnabled = 0
	print("Path recording disabled!")
end

local function agentSeek( id, agent, targetPos, flee, maxSpeed )
	if agents[id] == nil then
		-- init persistent data
		agents[id] = { stopped = 0, touching = 0, tooFar = 0, origSteer = 0, circling = 0, escapeDist = -1}
	end
	-- shortcut to agent data
	local ad = agents[id]

	-- update the basic info for this agent
	ad.pos  = agent:getPosition()
	ad.dir  = agent:getDirection()
	ad.velo = agent:getVelocity()
	ad.velo = ad.velo:length()
	--print("target="..targetPos)

	local targetVector = targetPos - ad.pos
	local distance = targetVector:length()
	--print(distance)

	-- now the velocity
	local throttle = 1
	local brake = 0

	-- prevent it from getting stuck
	if math.abs(ad.velo) >= 0.5 then
		ad.stopped = ad.stopped - (0.05 * math.abs(ad.velo))
	elseif math.abs(ad.velo) < 0.5 then
		ad.stopped = ad.stopped + (0.5 - math.abs(ad.velo))
	end
	if ad.stopped < 0 then ad.stopped = 0 end

	-- if the two cars are touching
	if distance >= 5 and ad.velo >= 5 then
		ad.touching = ad.touching - 0.5
	elseif distance < 5 and ad.velo < 5 then
		ad.touching = ad.touching + 0.2
	end
	if ad.touching < 0 then ad.touching = 0 end

	--if too far away start running up the tooFar variable
	if distance <= 25 then
		ad.tooFar = ad.tooFar - 1
	elseif distance > 25 then
		ad.tooFar = ad.tooFar + (distance * 0.05)
	end
	if distance < 10 then ad.tooFar = 0 end
	if distance > 50 then ad.tooFar = 1000 end
	if ad.tooFar < 0 then ad.tooFar = 0 end

	if agent:getWheel(0) then ad.w0velo = math.abs(agent:getWheel(0).angularVelocity) end
	if agent:getWheel(1) then ad.w1velo = math.abs(agent:getWheel(1).angularVelocity) end
	if agent:getWheel(2) then ad.w2velo = math.abs(agent:getWheel(2).angularVelocity) end
	if agent:getWheel(3) then ad.w3velo = math.abs(agent:getWheel(3).angularVelocity) end

	if not ad.w0velo then ad.w0velo = 0 end
	if not ad.w1velo then ad.w1velo = 0 end
	if not ad.w2velo then ad.w2velo = 0 end
	if not ad.w3velo then ad.w3velo = 0 end

	local avgVelo = (ad.w0velo + ad.w1velo + ad.w2velo + ad.w3velo)/4

	--print(avgVelo)

	-- the steering?
	local dirVector = (math.atan2((ad.pos.y - targetPos.y),(ad.pos.x - targetPos.x))) + (math.pi/2)

	local dirDiff = ad.dir - dirVector
	if dirDiff > math.pi then dirDiff = -1*(math.pi - (math.abs(math.pi - dirDiff))) end
	if dirDiff > 0 then dirDiff = math.pi - dirDiff
	elseif dirDiff < 0 then dirDiff = -math.pi - dirDiff end

	--local flee = false

	--swap the direction variable
	if flee == true then
		if dirDiff >= 0 then
			dirDiff = math.pi - dirDiff
		elseif dirDiff < 0 then
			dirDiff = -math.pi - dirDiff
		end
		dirDiff = -dirDiff
		if math.abs(dirDiff) < 0.3 then dirDiff = 0 end
	end

	local absDirDiff = math.abs(dirDiff)

	local steer = dirDiff

	ad.origSteer = steer

	local reverse = false

	--make it less predictable
	if ad.escapeDist == -1 then
		ad.escapeDist = math.random(5,15)
	end

	--make it stop circling
	if absDirDiff > 1.2 and absDirDiff < 1.94 and distance < 30 and distance > 10 then
		ad.circling = ad.circling + 1
	else
		ad.circling = ad.circling - 1
	end
	if ad.circling < 0 then ad.circling = 0 end

	--make it spin out a bit less
	if reverse == false then
		if absDirDiff > 0.4 and absDirDiff < 1.5 and math.abs(ad.velo) > 8 then
			throttle = 1 - (absDirDiff * 0.2)
			brake = 0
			--print("slowing")
		end
		if absDirDiff >= 1.5 and math.abs(ad.velo) > 8 then
			throttle = 1 - (ad.velo * 0.003)
			brake = 0.5 + (absDirDiff*0.1)
			--print("braking")
			if brake > 1 then brake = 1 end
			if brake > 0.5 then steer = steer * 0.5 end
		end
		--if the player is beside, stop accelerating
		if absDirDiff > 1 and absDirDiff < 2.14 and distance < 3 and math.abs(ad.velo) < 5 then
			throttle = 0
			--reverse = true
		end
		if math.abs(steer) > 0.5 then
			throttle = throttle - (0.2 * math.abs(steer))
		end
	end

	--if they're close enough and the player is behind, back into him
	if absDirDiff > 2.6 and distance < 50 then
		reverse = true
		steer = (math.pi - absDirDiff) * steer
	end

	--if agent backs into player and touches them for too long, drive away
	if ad.touching > 35 and absDirDiff > 2.9 and reverse == true then
		reverse = false
		throttle = 1
	end

	--if the agent is stopped for too long, switch directions
	if ad.stopped > 30 then
		ad.touching = 0
		ad.stopped = ad.stopped + 0.1
		if reverse == true then
			reverse = false
		else
			reverse = true
		end
		steer = -steer
	end


	--stop circling
	--[[
	if ad.circling > 50 and math.abs(ad.velo) > 3 then
		throttle = -1 + (absDirDiff * 0.6366)
		steer = -steer
	end
	--]]

	--less steering while backing up
	if reverse == true then
		throttle = -0.5 + (-0.5 * math.abs(dirDiff))
		steer = steer * 0.5
	end

	--make sure the steering is reversed
	if ad.velo < -1 then
		steer = -steer
	end

	--escape!
	if (distance < ad.escapeDist) and ad.touching > 35 then
		throttle = -1 + (absDirDiff * 0.6366)
		steer = dirDiff * 0.1
		ad.touching = 36
		if distance > ad.escapeDist then
			ad.touching = 0
			ad.escapeDist = -1
		end
	end

	--if far enough away, forget about reversing and just turn around
	--if ad.tooFar > 250 then
		--reverse = false
		--steer = math.pi/(math.pi - absDirDiff) * steer
		--throttle = ((math.pi - absDirDiff)/math.pi) - (absDirDiff * 0.2)
		--if absDirDiff > 0.3 then
			--throttle = 0.6
		--else
			--throttle = 1
		--end
	--end

	--reset the variable
	if ad.stopped > 100 then ad.stopped = 0 end

	--have it escape
	--if flee == true then
		--if absDirDiff > 3 then
			--reverse = true
			--steer = (math.pi - absDirDiff) * steer
		--end
		--if absDirDiff > 1 and absDirDiff <= 3 then
			--steer = math.random(-1,1) * steer
		--end
	--end

	--traction control
	--[[
	if
	math.abs(avgVelo - ad.w0velo) > 15 or
	math.abs(avgVelo - ad.w1velo) > 15 or
	math.abs(avgVelo - ad.w2velo) > 15 or
	math.abs(avgVelo - ad.w3velo) > 15 then
		throttle = throttle * 0.5
		--steer = steer * 1.5
	end
	--]]

	--print("touching"..ad.touching)
	--print("stopped"..ad.stopped)
	--print("throttle"..throttle)

	--finalizing inputs, guards to ensure variables are within -1 to 1
	throttle = throttle - brake
	if throttle > 1 then throttle = 1 end
	if throttle < -1 then throttle = -1 end

	--[[
	if steer < -1 then steer = -1 end
	if steer > 1 then steer = 1 end
	--]]

	if throttle < 0 then
		brake = throttle * -1
		throttle = 0
	end

	-- prevent hydro breaking
	--if math.abs(math.abs(steer) - math.abs(ad.origSteer)) > 1.5 then steer = steer * 0.6 end

	local airspeed = agent:getVelocity():length()
	local carSpeed = math.floor(airspeed * 3.6) -- in km/h
	--print("brake = "..brake)
	--print("throttle = "..throttle)
	if ( carSpeed >= maxSpeed ) then
		throttle = 0
		brake = ( carSpeed - maxSpeed ) / 5
	else
		brake = 0
		throttle = ( maxSpeed - carSpeed ) / 5

		--traction control
		if
		math.abs(avgVelo - ad.w0velo) > 15 or
		math.abs(avgVelo - ad.w1velo) > 15 or
		math.abs(avgVelo - ad.w2velo) > 15 or
		math.abs(avgVelo - ad.w3velo) > 15 then
			--throttle = throttle * 0.5
			throttle = 0.2
			steer = steer * -1.5
			brake = 0.8
		end
	end
	if ( math.abs(steer) >= 0.15 and carSpeed / maxSpeed <= 0.75 ) then
		throttle = 0.35
		if ( carSpeed > 25 ) then
			brake = 0.8
		end
	end
	if math.abs(math.abs(steer) - math.abs(ad.origSteer)) > 1.5 then steer = steer * 0.6 end
	if ( throttle > 1 ) then throttle = 1 end
	if ( brake > 1 ) then brake = 1 end
	if steer < -1 then steer = -1 end
	if steer > 1 then steer = 1 end
	if reverse == true then
		throttle = -1
		brake = 0.7
        throttle = 0
	end

	-- tell the agent how to move finally
	--print("throttle = "..throttle)
	--print("brake = "..brake)
	--print("stopped = "..ad.stopped)
	--if reverse == true then
		--print("reverse = true")
	--else
		--print("reverse = false")
	--end
	agent:queueLuaCommand("input.event(\"axisx0\", "..-steer..", 0)")
    agent:queueLuaCommand("input.event(\"axisy0\", "..throttle..", 0)")
    agent:queueLuaCommand("input.event(\"axisy1\", "..brake..", 0)")
    agent:queueLuaCommand("input.event(\"axisy2\", 0, 0)")
end

local function saveWayPoints( carId, fileName )
	dofile("table.save-1.0.lua")
	local fileSt = {}
	fileSt.position = {}
	for key, value in pairs( wayPoints[carId].position ) do
		local x = wayPoints[carId].position[key].pos["x"]
		local y = wayPoints[carId].position[key].pos["y"]
		local z = wayPoints[carId].position[key].pos["z"]
		fileSt.position[key] = {}
		fileSt.position[key].pos = {}
		fileSt.position[key].pos["x"] = x
		fileSt.position[key].pos["y"] = y
		fileSt.position[key].pos["z"] = z
		fileSt.position[key].maxSpeed = wayPoints[carId].position[key].maxSpeed
	end
	table.save( fileSt, "Waypoints/"..fileName..".lua" )
	print("WayPoints saved!")
end

local function loadWayPoints( carId, fileName )
	dofile( "table.save-1.0.lua" )
	wayPoints[carId] = nil
	if ( wayPoints[carId] == nil ) then
		wayPoints[carId] = {}
		wayPoints[carId].position = {}
	end
	if ( canCarRun[carId] == nil ) then
		canCarRun[carId] = 0
	end
	local fileSt, err = table.load( "Waypoints/"..fileName..".lua" )
	assert( err == nil )
	for key, value in pairs( fileSt.position ) do
		local x = fileSt.position[key].pos["x"]
		local y = fileSt.position[key].pos["y"]
		local z = fileSt.position[key].pos["z"]
		local maxSpeed = fileSt.position[key].maxSpeed
		wayPoints[carId].position[key] = {}
		wayPoints[carId].position[key].pos = float3( x, y, z )
		wayPoints[carId].position[key].maxSpeed = maxSpeed
	end
	print("WayPoints loaded!")
end

local function printWayPointsForCar( carId )
	for key, value in pairs( wayPoints[carId].position ) do
		local x = wayPoints[carId].position[key].pos["x"]
		local y = wayPoints[carId].position[key].pos["y"]
		local z = wayPoints[carId].position[key].pos["z"]
		print("x = "..x..", y = "..y..", z = "..z)
	end
end

local function runCar( carId )
	if ( wayPoints[carId] == nil ) then
		print("Load waypoints for this car!")
	else
		if agents[id] ~= nil then
			agents[carId].stopped = 0
		end
		canCarRun[carId] = 1
		wayPoints[carId].maxCount = getLastIndex( wayPoints[carId].position )
		print("Car was run!")
	end
end

local function stopCar( carId )
	if ( canCarRun[carId] ~= nil ) then
		canCarRun[carId] = 0

		local agent = BeamEngine:getSlot(carId)
		agent:queueLuaCommand("input.event(\"axisx0\", 0, 0)")
		agent:queueLuaCommand("input.event(\"axisy0\", 0, 0)")
		agent:queueLuaCommand("input.event(\"axisy1\", 0, 0)")
		agent:queueLuaCommand("input.event(\"axisy2\", 0, 0)")

		print("Car stopped!")
	end
end

local function stopAllCars()
	print( "Attempting to stop all cars..." )
    for key in pairs( wayPoints ) do
        stopCar( key )
        print( "Car "..key.." was stopped!" )
    end
end

local function update()
	if ( recordEnabled == 1 ) then
		recordPoint()
	end
	for key in pairs(wayPoints) do
		if ( canCarRun[key] == 1 ) then
			if ( wayPointsIndex[key] == nil ) then
				wayPointsIndex[key] = 1
			end
			local newPos = BeamEngine:getSlot(key):getPosition()
			local coorDiff = 5
			local newPos1 = wayPoints[key].position[wayPointsIndex[key]].pos + float3(coorDiff, coorDiff, coorDiff)
			local newPos2 = wayPoints[key].position[wayPointsIndex[key]].pos + float3(-coorDiff, -coorDiff, -coorDiff)

			if ( skipPointEnabled == 1 and wayPointsIndex[key] ~= 1 ) then
				local i = wayPointsIndex[key]
				local distance  = (wayPoints[key].position[i].pos - newPos):length()
				if ( wayPoints[key].position[i + 1] == nil ) then
					i = 1
				end
				local distance2 = (wayPoints[key].position[i + 1].pos - newPos):length()
				while ( distance2 < distance ) do
					i = i + 1
					if ( wayPoints[key].position[i + 1] == nil ) then
						i = 1
					end
					distance2 = (wayPoints[key].position[i + 1].pos - newPos):length()
				end
				wayPointsIndex[key] = i
			end

			if ( ( newPos["x"] >= newPos2["x"] and newPos["y"] >= newPos2["y"] and newPos["z"] >= newPos2["z"] ) and ( newPos["x"] <= newPos1["x"] and newPos["y"] <= newPos1["y"] and newPos["z"] <= newPos1["z"] ) and go ~= 0 ) then
				wayPointsIndex[key] = wayPointsIndex[key] + 1
				if ( wayPointsIndex[key] > wayPoints[key].maxCount - 1 ) then
					wayPointsIndex[key] = 1
					agentSeek(key, BeamEngine:getSlot(key), wayPoints[key].position[wayPointsIndex[key]].pos, false, wayPoints[key].position[wayPointsIndex[key]].maxSpeed)
				end
			elseif ( canCarRun[key] ~= 0 ) then
				agentSeek(key, BeamEngine:getSlot(key), wayPoints[key].position[wayPointsIndex[key]].pos, false, wayPoints[key].position[wayPointsIndex[key]].maxSpeed)
			end
		end
	end
end

local function enableSkipPoints()
	skipPointEnabled = 1
end

local function disableSkipPoints()
	skipPointEnabled = 0
end

local function runAllCars()
    print( "Attempting to run all cars..." )
    for key in pairs( wayPoints ) do
        runCar( key )
        print( "Car "..key.." was run!" )
    end
end

local function getCarsId()
	local slotCount = BeamEngine:getSlotCount()
	local result = {}
	for objectID = 0, slotCount, 1 do
		local b = BeamEngine:getSlot( objectID )
		if b ~= nil then
			result[objectID] = 1
			if b.activationMode == 1 then
				result['selected'] = objectID
			end
		end
	end
	do return result end
end

local function getWaypointsFiles()
	local directory = "Waypoints"
	local dir = FS:openDirectory( directory )
	local waypointsFiles = {}
	if dir then
        local file = nil
        repeat
            file = dir:getNextFilename()
            if not file then break end
            if string.find( file, ".lua" ) then
                if FS:fileExists( directory.."/"..file ) > 0 then
                    table.insert( waypointsFiles, file:sub( 1 , -5 ) )
                end
            end
        until not file
        FS:closeDirectory( dir )
	end
	do return waypointsFiles end
end

local function resetWaypoints( carId )
	wayPointsIndex[carId] = 1
end

-- public interface
M.update               = update
M.reset                = reset
M.agentSeek            = agentSeek
M.addPoint             = addPoint
M.loadWayPoints        = loadWayPoints
M.saveWayPoints        = saveWayPoints
M.printWayPointsForCar = printWayPointsForCar
M.runCar               = runCar
M.printCurrentCarId    = printCurrentCarId
M.clearCarWayPoints    = clearCarWayPoints
M.startRecordingPath   = startRecordingPath
M.stopRecordingPath    = stopRecordingPath
M.stopCar              = stopCar
M.enableSkipPoints     = enableSkipPoints
M.disableSkipPoints    = disableSkipPoints
M.runAllCars           = runAllCars
M.runCars              = runAllCars
M.getCarsId            = getCarsId
M.getWaypointsFiles    = getWaypointsFiles
M.stopAllCars		   = stopAllCars
M.resetWaypoints	   = resetWaypoints

return M