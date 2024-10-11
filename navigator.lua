function updateLoc()
	x, y, z = gps.locate()
	x = math.ceil(x)
	y = math.ceil(y)
	z = math.ceil(z)
end

function getDistance(a, b)
	distance = 0
	distance = distance + math.abs(a[1]-b[1])
	distance = distance + math.abs(a[3]-b[3])
	return distance
end

function back()
	if turtle.back() then
		updateLoc()
		return true
	else return false end
end

function forward()
    if turtle.forward() then
    	updateLoc()
        return true
    else return false end
end

function up()
    if turtle.up() then
    	updateLoc()
        return true
    else return false end
end

function down()
    if turtle.down() then
    	updateLoc()
        return true
    else return false end
end
 
function turnLeft()
    turtle.turnLeft()
    facing = facing - 1
    if facing == 0 then facing = 4 end
end
 
function turnRight()
    turtle.turnRight()
    facing = facing + 1
    if facing == 5 then facing = 1 end
end
 
function getFacing(attemptIndex)
    if attemptIndex == 4 then return false end
    local tempX = x
    local tempZ = z
    local result = 0
    if forward() then
        if x > tempX then result = 2 end
        if x < tempX then result = 4 end
        if z > tempZ then result = 3 end
        if z < tempZ then result = 1 end
        back()
        return result
    else
        turtle.turnLeft()
        return getFacing(attemptIndex + 1)
    end
end

function setFacing(targetFacing)
	if math.abs(facing - targetFacing) == 2 then
		turnLeft()
		turnLeft()
		return
	elseif facing - targetFacing == -3 or facing - targetFacing > 0 then
		turnLeft()
		return
	elseif facing - targetFacing == 3 or facing - targetFacing < 0 then
		turnRight()
		return
	end
end

function faceBlock(block)
	updateLoc()
	local xDiff = x - block[1]
	local zDiff = z - block[3]

	if math.abs(xDiff) > math.abs(zDiff) then
		if xDiff > 0 then setFacing(4)
		else setFacing(2) end
	else
		if zDiff > 0 then setFacing(1)
		else setFacing(3) end
	end
end
 
function moveTo(target, distance)
	local attempt = 0
	local elevated = 0
	if distance == nil then distance = 0 end
	while true do
		if attempt >= 2 then
			if up() then
				elevated = elevated + 1
				attempt = 0
			elseif down() then
				elevated = elevated - 1
				attempt = 0
			end
		end
		--reach x
    	if x < target[1] then setFacing(2) end
   		if x > target[1] then setFacing(4) end

   		while true do
   			if getDistance({x,y,z}, target) <= distance or x == target[1] then
				break
			end
   			if not forward() then break end
   			attempt = 0
   		end

   		--reach z
   		if z < target[3] then setFacing(3) end
   		if z > target[3] then setFacing(1) end

   		while true do
   			if getDistance({x,y,z}, target) <= distance or z == target[3] then 
   				break
   			end
   			if not forward() then break end
   			attempt = 0
   		end
    	
    	if getDistance({x, y, z}, target) <= distance then
    		if elevated == 0 then return true
    		elseif elevated > 0 then 
    			if not down() then print("Got stuck..."); return false end
    		elseif elevated < 0 then
    			if not up() then print("Got stuck..."); return false end
    		end
    	else
    		attempt = attempt + 1
    	end
    end
end

function initialise()
	updateLoc()
	facing = getFacing(0)
end
x, y, z = 0, 0, 0