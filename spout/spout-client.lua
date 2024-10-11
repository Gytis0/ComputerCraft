function listenForEstablishment()
	local finished = false
	while not finished do
		print("Waiting for connection establishment...")
		local event, modemSide, senderChannel, replyChannel, message, senderDistance = os.pullEvent("modem_message")
		if message == "Hello" then
			finished = true
			net.transmit(replyChannel, senderChannel, {computerId, firstType, secondType})
			print("Connected")
		end
	end
end

function listen()
	while true do
		print("Waiting for action...")
		local event, modemSide, senderChannel, replyChannel, message, senderDistance = os.pullEvent("modem_message")
		if message[1] == computerId then
			redstone.setOutput(message[2], not redstone.getOutput(message[2]))
			print("Side: " .. message[2])
			print("Output: " .. tostring(redstone.getOutput(message[2])))
		end
	end
end

function getMyTypes()
	local file = fs.open("types.txt", "r")
	if file == nil then print("I don't have a types.txt file."); return end

	firstType = file.readLine()
	secondType = file.readLine()
	file.close()
end

net = peripheral.find("modem")
sendChannel = 834
recvChannel = 833
net.open(recvChannel)

redstone.setOutput("left", false)
redstone.setOutput("right", false)

computerId = os.computerID()
getMyTypes()
listenForEstablishment()

listen()