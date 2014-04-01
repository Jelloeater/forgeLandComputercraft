os.loadAPI("/bb/api/jsonV2")
os.loadAPI("/bb/api/colorFuncs")

function run( ... )
	print ("Waiting for Device List...")

	rednet.open("back")
	while true do
		local senderId, message, distance = rednet.receive() --Wait for device List
		print(message)
		if message == "reboot" then os.reboot() 
		if message == "sendDeviceList" then 
		print(message)
			local senderId, message, distance = rednet.receive() --Wait for device List
			deviceListFromServer = jsonV2.decode(message)
		end
	end
			-- FIXME Check if valid JSON
		

		checkSwitch()
	end


end

function checkSwitch(  )
	while true do
		local senderId, message, distance = rednet.receive() --Wait for device List
		if message == "reboot" then os.reboot()

		local commandInfo = jsonV2.decode(message)
		if commandInfo.command == "on" or commandInfo.command == "off" then
		


		end
	end

	local deviceListImport = jsonV2.decode(rawJSON)

	for i=1,table.getn(deviceListImport) do -- Gets arraylist size
		local devIn = deviceListImport[i]
		table.insert(deviceList, Switch.new(
				devIn.label,devIn.redNetSwitchColor))
		end

	end
end

run()
-- Switch Device