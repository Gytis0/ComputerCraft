function esablishConnections()
	local pcs = hub.getNamesRemote()
	for k,v in pairs(pcs) do
		peripheral.call(v, "reboot")
		print("Rebooting pc: " .. v)
	end

	os.sleep(1)

	hub.open(recvChannel)
	hub.transmit(sendChannel, recvChannel, "Hello")
	parallel.waitForAny(recieveInfo, waitTime)
end

function recieveInfo()
	while true do
		local event, modemSide, senderChannel, replyChannel, message, senderDistance = os.pullEvent("modem_message")
		computers[message[1]] = {message[2], message[3]}
	end
end

--returns {id, side of the computer}
--returns nil if not found
function findComputer(honey)
	for k,v in pairs(computers) do
		if v[1] == honey then return k, "left"
		elseif v[2] == honey then return k, "right"
		else return nil end
	end
end

function fillMap()
	counter = 1
	for k,v in pairs(computers) do
		map[counter] = v[1]
		map[counter+1] = v[2]
		counter = counter + 2
	end
end

function waitTime()
	local startTime = os.time()
	local timeToPass = timeToWait * 0.02

	while true do
		local diffTime = os.time() - startTime
		if diffTime < 0 then diffTime = diffTime + 24 end

		if diffTime >= timeToPass then return true end
		os.sleep(1)
	end
end

computers = {}
timeToWait = 3
hub = peripheral.find("modem")
sendChannel = 833
recvChannel = 834

esablishConnections()

map = {}
fillMap()

finish = false
while true do repeat
	utils.clear()

	for k,v in pairs(map) do
		print(k .. ". " .. v)
	end

	selection = tonumber(read())
	if selection > table.getn(map) or selection < 1 then print("No such option."); break end

	local id, side = findComputer(map[selection])
	hub.transmit(sendChannel, recvChannel, {id, side})
	print("Toggling computer: " .. id)
	print("On the side: " .. side)
	os.sleep(1)
until finish == true end