-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

local controlledVehicles = nil
local oldAISlotCount = -1
local playerVehicleID = -1

-- table that contains the persistent data for the agents
local agents = {}
local wayPoints = {}
local wayPointsIndex = {}

local function getLastIndex( t )
	local lastIndex = 1
	for key, value in pairs( t ) do
		lastIndex = lastIndex + 1
	end
	return lastIndex
end

local function addPoint( carId, maxSpeed )
	local playerPosition = BeamEngine:getSlot(0):getPosition()
	if ( wayPoints[carId] == nil ) then
		wayPoints[carId] = {}
		wayPoints[carId].position = {}
		--wayPoints[carId].position.pos = {}
		--wayPoints[carId].position.maxSpeed = {}
	end
	-- if (wayPoints[carId].position == nil) then
		-- wayPoints[carId].position = {}
	-- end	
	--table.insert( wayPoints[carId].position.pos, playerPosition )
	local index = getLastIndex( wayPoints[carId].position )
	--print(index)
	--if (count == 1) then count = 1 end
	wayPoints[carId].position[index] = {}
	wayPoints[carId].position[index].pos = playerPosition
	wayPoints[carId].position[index].maxSpeed = maxSpeed
	--print(#wayPoints[carId].position)
	--wayPoints[carId][] = playerPosition
	--print("Point added = "..BeamEngine:getSlot(0):getPosition())
	print("Point added")
end

local function agentSeek(id, agent, targetPos, flee, maxSpeed)	
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
	
	-- now the velocity
	local throttle = 1
	local brake = 0
	
	--[[
	if input.enableDynamicSteering then
		if input.enableDynamicSteering == true then
			input.toggleDynamicSteering()
		end
	end
	]]--	
	
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
	if ad.circling > 50 and math.abs(ad.velo) > 3 then
		throttle = -1 + (absDirDiff * 0.6366)
		steer = -steer
	end
	
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
	if ad.tooFar > 250 then
		reverse = false
		steer = math.pi/(math.pi - absDirDiff) * steer
		throttle = ((math.pi - absDirDiff)/math.pi) - (absDirDiff * 0.2)
		if absDirDiff > 0.3 then 
			throttle = 0.6 
		else
			throttle = 1
		end
	end
	
	--reset the variable
	if ad.stopped > 100 then ad.stopped = 0 end
	
	--have it escape
	if flee == true then
		if absDirDiff > 3 then
			reverse = true
			steer = (math.pi - absDirDiff) * steer
		end
		if absDirDiff > 1 and absDirDiff <= 3 then
			steer = math.random(-1,1) * steer
		end
	end
	
	--traction control
	if 
	math.abs(avgVelo - ad.w0velo) > 15 or 
	math.abs(avgVelo - ad.w1velo) > 15 or 
	math.abs(avgVelo - ad.w2velo) > 15 or 
	math.abs(avgVelo - ad.w3velo) > 15 then
		throttle = throttle * 0.5
		--steer = steer * 1.5
	end
	
	--print("touching"..ad.touching)
	--print("stopped"..ad.stopped)
	--print("throttle"..throttle)
	
	--finalizing inputs, guards to ensure variables are within -1 to 1
	throttle = throttle - brake
	if throttle > 1 then throttle = 1 end
	if throttle < -1 then throttle = -1 end
	
	if steer < -1 then steer = -1 end
	if steer > 1 then steer = 1 end
	
	if throttle < 0 then
		brake = throttle * -1
		throttle = 0
	end
	
	-- prevent hydro breaking
	if math.abs(math.abs(steer) - math.abs(ad.origSteer)) > 1.5 then steer = steer * 0.6 end				
	
	-- tell the agent how to move finally
	local newPos = BeamEngine:getSlot(1):getPosition()
	--local newPos1 = newPos + float3(10, 10, 10)
	--local newPos2 = newPos + float3(-10, -10, -10)
	local newPos1 = float3(-3.434, -86.227, -0.67) + float3(2, 2, 2)
	local newPos2 = float3(-3.434, -86.227, -0.67) + float3(-2, -2, -2)	
	--if ( BeamEngine:getSlot(1):getPosition() ~= float3(-3.434, -86.227, -0.67) and go ~= 0 ) then
	--[[if ( ( newPos["x"] >= newPos2["x"] and newPos["y"] >= newPos2["y"] and newPos["z"] >= newPos2["z"] ) and ( newPos["x"] <= newPos1["x"] and newPos["y"] <= newPos1["y"] and newPos["z"] <= newPos1["z"] ) and go ~= 0 ) then
		go = 0
		BeamEngine:getSlot(1):queueLuaCommand("input.axisY=0;input.parkingbrake=1")
	elseif ( go ~= 0) then
		agent:queueLuaCommand("input.axisX="..steer..";input.axisY="..throttle..";input.axisY2="..brake..";input.parkingbrake=0")
	end]]
	
	local airspeed = agent:getVelocity():length()
	local carSpeed = math.floor(airspeed * 3.6) -- in km/h
	--print("carSpeed = "..carSpeed)
	--print("maxSpeed = "..maxSpeed)
	if ( carSpeed >= maxSpeed ) then
		throttle = 0
		brake = ( carSpeed - maxSpeed ) / 5	
	else
		brake = 0
		throttle = (maxSpeed - carSpeed) / 5		
	end
	if ( throttle > 1 ) then throttle = 1 end
	if ( brake > 1 ) then brake = 1 end
	agent:queueLuaCommand("input.axisX="..steer..";input.axisY="..throttle..";input.axisY2="..brake..";input.parkingbrake=0")
end

local function saveWayPoints( carId )
	--dofile( "table.save-0.94.lua" )
	--table.save( wayPoints[carId].position, "wayPoints_"..carId..".lua" )
	--io.read()
	--dofile( "pickle.lua" )
	--print(pickle(wayPoints[carId].position))
	--local f = io.open("wayPoints_"..carId..".lua", "w")
	--f:write(textutils.serialize(wayPoints[carId].position))
	--f:close()
	--hWrite.write(textutils.serialize(wayPoints[carId].position))
	--hWrite.close()
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
		--print("x = "..x..", y = "..y..", z = "..z)
	end
	table.save( fileSt, "wayPoints_"..carId..".lua" )
	print("WayPoints saved!")
end

local function loadWayPoints( carId )
	dofile( "table.save-1.0.lua" )
	if ( wayPoints[carId] == nil ) then
		wayPoints[carId] = {}
		wayPoints[carId].position = {}
	end
	local fileSt, err = table.load( "wayPoints_"..carId..".lua" )
	for key, value in pairs( fileSt.position ) do
		local x = fileSt.position[key].pos["x"]
		local y = fileSt.position[key].pos["y"]
		local z = fileSt.position[key].pos["z"]
		local maxSpeed = fileSt.position[key].maxSpeed
		wayPoints[carId].position[key] = {}
		wayPoints[carId].position[key].pos = float3( x, y, z )
		wayPoints[carId].position[key].maxSpeed = maxSpeed
	end
	--for i = 1, file
	--io.read()
	--local f = io.open("wayPoints_"..carId..".lua", "r")
	--wayPoints[carId].position = textutils.unserialize(hRead.readLine())
	--wayPoints[carId].position = textutils.unserialize(f:readLine())
	--f:close()
	print("WayPoints loaded!")
end

local function printWayPointsForCar( carId )
	--[[
	for i = 1, #wayPoints[carId].position do
		local x = wayPoints[carId].position[i].pos["x"]
		local y = wayPoints[carId].position[i].pos["y"]
		local z = wayPoints[carId].position[i].pos["z"]
		print("x = "..x..", y = "..y..", z = "..z)
	end
	--]]
	for key, value in pairs( wayPoints[carId].position ) do
		local x = wayPoints[carId].position[key].pos["x"]
		local y = wayPoints[carId].position[key].pos["y"]
		local z = wayPoints[carId].position[key].pos["z"]
		print("x = "..x..", y = "..y..", z = "..z)
	end
end

local function update(mode)
	for key, value in pairs(wayPoints) do
		--print(key, value)
		if ( wayPointsIndex[key] == nil ) then
			wayPointsIndex[key] = 1
		end
		local newPos = BeamEngine:getSlot(1):getPosition()
		local newPos1 = wayPoints[key].position[wayPointsIndex[key]].pos + float3(5, 5, 5)
		local newPos2 = wayPoints[key].position[wayPointsIndex[key]].pos + float3(-5, -5, -5)	
		--if ( BeamEngine:getSlot(1):getPosition() ~= float3(-3.434, -86.227, -0.67) and go ~= 0 ) then
		--print(go)
		if ( ( newPos["x"] >= newPos2["x"] and newPos["y"] >= newPos2["y"] and newPos["z"] >= newPos2["z"] ) and ( newPos["x"] <= newPos1["x"] and newPos["y"] <= newPos1["y"] and newPos["z"] <= newPos1["z"] ) and go ~= 0 ) then
			wayPointsIndex[key] = wayPointsIndex[key] + 1
			if (wayPointsIndex[key] > getLastIndex( wayPoints[key].position ) - 1 ) then
				--go = 0
				BeamEngine:getSlot(1):queueLuaCommand("input.axisY=0;input.parkingbrake=1;input.axisY2=0.5")
				wayPointsIndex[key] = 1
			end
			--go = 0
			--BeamEngine:getSlot(1):queueLuaCommand("input.axisY=0;input.parkingbrake=1;input.axisY2=0.5")
			--print("STOP")
		elseif ( go ~= 0 ) then
			agentSeek(1, BeamEngine:getSlot(1), wayPoints[key].position[wayPointsIndex[key]].pos, false, wayPoints[key].position[wayPointsIndex[key]].maxSpeed)
			--[[
			print("x="..newPos["x"]..", y="..newPos["y"]..", z="..newPos["z"])
			print("x1="..newPos1["x"]..", y1="..newPos1["y"]..", z1="..newPos1["z"])
			print("x2="..newPos2["x"]..", y2="..newPos2["y"]..", z2="..newPos2["z"])
			print(" ")
			--]]
		end
	end

	--[[
	local slotCount = BeamEngine:getSlotCount()
	if oldAISlotCount ~= slotCount then updateControlList() end

	--dump(mode)
	local flee = (mode == "car0")
	--print("ai mode: " .. mode)

	-- done, we know the AI vehicles and the player controlled vehicles, now the fun begins
	if playerVehicleID ~= -1 then
		local playerVehicle = BeamEngine:getSlot(playerVehicleID)
		
		
		if not playerVehicle or playerVehicle.activationMode ~= 1 then
			-- switched, update and retry
			updateControlList()
			return
		end
		
		local playerPos = playerVehicle:getPosition()
		-- if a player exists, try to drive towards it
		for k, vID in pairs(controlledVehicles) do
			local agent = BeamEngine:getSlot(vID)
			if agent then
				agentSeek(vID, agent, playerPos, flee)
			end
		end
	end
	--]]
end

local function reset()
	local slotCount = BeamEngine:getSlotCount()
	if oldAISlotCount ~= slotCount then updateControlList() end

	for k, vID in pairs(controlledVehicles) do
		local agent = BeamEngine:getSlot(vID)
		if agent then
			agent:queueLuaCommand("input.axisX=0;input.axisY=0;input.axisY2=0;input.parkingbrake=0")
		end
	end
end


-- public interface
M.update = update
M.reset = reset
M.agentSeek = agentSeek
M.addPoint = addPoint
M.loadWayPoints = loadWayPoints
M.saveWayPoints = saveWayPoints
M.printWayPointsForCar = printWayPointsForCar

return M