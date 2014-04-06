-- RedNet Switch Control System v1
-- Author: Jesse 

os.loadAPI("/bb/api/jsonV2")

debugmode = false
editDevicesMenuFlag = false
editSettingsMenuFlag = false
devicesFilePath = "/switches.cfg"
settingsFilePath = "/settingsSwitches.cfg"
enableSwitchSetupConfig = "/editmenu.cfg"

function bootloader( ... )
	print ("Setting up network...")


	if peripheral.isPresent("top") and peripheral.getType("top") == "modem" then modemSide = "top" modemPresentFlag = true end
	if peripheral.isPresent("bottom") and peripheral.getType("bottom") == "modem" then modemSide = "bottom" modemPresentFlag = true end
	if peripheral.isPresent("left") and peripheral.getType("left") == "modem" then modemSide = "left" modemPresentFlag = true end
	if peripheral.isPresent("right") and peripheral.getType("right") == "modem" then modemSide = "right" modemPresentFlag = true end
	if peripheral.isPresent("back") and peripheral.getType("back") == "modem" then modemSide = "back" modemPresentFlag = true end
	
	if modemPresentFlag then term.write(" - Located Modem: ".. modemSide) end
	if modemPresentFlag == false then term.write(" - NO MODEM FOUND") os.sleep(10) os.shutdown() end

	if modemPresentFlag then rednet.open(modemSide) end

	loadSettings() -- Loads settings
	loadDeviceList()
	mainProgram()
	print ("To edit config, change setupMenu value to true in /settingsSwitches.cfg")
end

function mainProgram( )

	if enableEditMenu() == true then menuInput() end

	while true do
		listDevices()
		monitorNetwork()
		-- parallel.waitForAny(menuInput, monitorNetwork)
	end
end

function menuInput( ... )
	while true do
		term.clear()
		term.setCursorPos(1,1)
		listDevices()
		term.setCursorPos(1,18)
		term.write("Exit menu to continue booting")
		term.setCursorPos(1,19)
		term.write("Menu: (Edit / Settings / eXit): ")
		local x = read()
		if x == "edit" or x == "e" then editDevicesMenu() end
		if x == "settings" or x == "s" then editSettingsMenu() end
		if x == "exit" or x == "x" then  
		local fileHandle = fs.open(enableSwitchSetupConfig,"w")
		fileHandle.write("false")
		fileHandle.close()
		os.reboot()

		 end
		-- if x == "exit" or x == "x" then os.shutdown() end
	end
	saveSettings()
	os.reboot()
end

function monitorNetwork( ... )
	local senderId, message, protocol = rednet.receive(settings.networkProtocol,settings.networkTimeout) --Wait for device List
	if message == "reboot" then os.reboot() end -- Lets us reboot remotely at anytime
	if message == "sendDeviceCommand" then receiveCommand() end
	if message == "getSwitchStatus" then broadcastSwitchStatus() end
	if message == "enableSwitchSetup" then settings.setupMenu = true saveSettings() os.reboot() end

end

-----------------------------------------------------------------------------------------------------------------------
-- Net Commands
function receiveCommand( ... )
	local senderId, message, protocol = rednet.receive(settings.networkProtocol,settings.networkTimeout) 
	local msg = jsonV2.decode(message)

	for i=1,table.getn(deviceList) do 
		local devIn = deviceList[i]
		if msg.switchId == devIn.SwitchID then 
			if msg.command == "on" then redstone.setOutput(devIn.side, true) devIn.status = true end
			if msg.command == "off" then redstone.setOutput(devIn.side, false) devIn.status = false end
		end
	end
end

function broadcastSwitchStatus( ... )
	local senderId, message, protocol = rednet.receive(settings.networkProtocol,settings.networkTimeout) 

	for i=1,table.getn(deviceList) do 
	local devIn = deviceList[i]
		if tonumber(message) == devIn.SwitchID then 
			if devIn.status == true then rednet.broadcast("true",settings.networkProtocol) end
			if devIn.status == false then rednet.broadcast("false",settings.networkProtocol) end
		end
	end
end

-----------------------------------------------------------------------------------------------------------------------
-- Switch Class
local Switch = {}  -- the table representing the class, which will double as the metatable for the instances
Switch.__index = Switch -- failed table lookups on the instances should fallback to the class table, to get methods

function Switch.new(labelIn,SwitchIDin,sideIn)
	local self = setmetatable({},Switch) -- Lets class self refrence to create new objects based on the class
	
	self.label = labelIn
	self.SwitchID = SwitchIDin
	self.side = sideIn
	self.status = false
	return self
end



function addDevice( ... )
	print("Enter device name to be added: ")
	local deviceLabel = read()

	print("Enter ID number: ")
	local SwitchIDin = tonumber(read())

	print("Enter side(top/bottom/left/right: ")
	local side = read()

	if SwitchIDin == nil or deviceLabel == "" or side == "" then term.clear() print("INVALID SETTINGS") os.sleep(2) else
	table.insert(deviceList, Switch.new(deviceLabel,SwitchIDin,side)) end

end

function editDevice( ... )
	print("Enter device to edit: ")
	local editDevice = read()

	print("Enter new label: ")
	local newLabel = read()

	for i=1,table.getn(deviceList) do -- Gets arraylist size
		if deviceList[i].label == editDevice then
			if newLabel ~= "" then deviceList[i].label = newLabel end

			print("Enter new ID number ["..tostring(deviceList[i].SwitchID).."] : ")
			local switchIDin = read()
			local switchIDnum = tonumber(switchIDin)

			if switchIDin ~= "" and switchIDnum ~= nil then deviceList[i].SwitchID = switchIDnum 	end 

			print("Enter side) ["..deviceList[i].side.."]: ")
			local sideIn = read()
			if sideIn ~= "" then deviceList[i].side = sideIn end

		break
		end	
			
	end
end


function removeDevice( ... )
	print("Enter device to be removed: ")
	local removeDevice = read()

	for i=1,table.getn(deviceList) do -- Gets arraylist size
		if deviceList[i].label == removeDevice then 
			table.remove(deviceList, i)
			print("Removed "..removeDevice)
			break
		end
	end
end

function listDevices( ... ) -- Need two print commands due to formating
	term.clear()
	term.setCursorPos(1,1)
	print("Device List - Network ID: " .. settings.networkProtocol)
	for i=1,table.getn(deviceList) do 
		local devIn = deviceList[i]
		if devIn.status == true then term.setTextColor(colors.green) end
		if devIn.status == false then term.setTextColor(colors.red) end
 		term.write("Label: "..devIn.label)
 		local x, y = term.getCursorPos()
 		term.setCursorPos(25,y)
 		term.write("ID#: "..tostring(devIn.SwitchID))
 		term.setCursorPos(39,y)
 		term.write("Side: "..devIn.side)
 		print()
 		term.setTextColor(colors.white)
	end
end

function editDevicesMenu( ... )
	term.clear()

	while true do 
		listDevices()
		term.setCursorPos(1,19)	term.write("(Add / Edit / Remove / Clear / eXit): ")
		local menuChoice = read()
		
		if menuChoice == "add" or menuChoice == "a" then addDevice() end
		if menuChoice == "edit" or menuChoice == "e" then editDevice() end
		if menuChoice == "remove" or menuChoice == "r" then removeDevice() end
		if menuChoice == "clear" or menuChoice == "c" then clearList() end
		if menuChoice == "exit" or menuChoice == "x" then break end
	end 

	saveDevices()
	mainProgram()
end

function saveDevices( ... )
	local prettystring = jsonV2.encodePretty(deviceList)
	local fileHandle = fs.open(devicesFilePath,"w")
	fileHandle.write(prettystring)
	fileHandle.close()
end

function clearList( ... )
	print("Are you sure you want to ERASE ALL DEVICES? (yes/no)")
	local menuChoice = read()
	if menuChoice == "yes" then deviceList={} end
end


function loadDeviceList( ... )
	deviceList = {} -- Create table

	if fs.exists (devicesFilePath) then
		local fileHandle = fs.open(devicesFilePath,"r")
		local RAWjson = fileHandle.readAll()
		fileHandle.close()

		local deviceListImport = jsonV2.decode(RAWjson)

		for i=1,table.getn(deviceListImport) do -- Gets arraylist size
			local devIn = deviceListImport[i]
			table.insert(deviceList, Switch.new(devIn.label,devIn.SwitchID,devIn.side))
		end	
	end
end

-----------------------------------------------------------------------------------------------------------------------
-- Settings Class
settings = {}  -- the table representing the class, holds all the data, we don't need a singleton because THIS IS LUA.

settings.networkProtocol = "deviceNet"
settings.networkTimeout = 4
settings.setupMenu = true

function parseTrueFalse( stringIN )
	if stringIN == "true" or stringIN == "True" then return true else return false end
end

function listSettings( ... ) -- Need two print commands due to formating
	term.clear()
	print("Settings - I hope you know what you're doing -_-")
	print("")
	term.write("networkProtocol = ") print(settings.networkProtocol)
	term.write("networkTimeout = ") print(settings.networkTimeout)
	-- term.write("setupMenu = ") print(settings.setupMenu)
end

function editSettingsMenu( ... )
	term.clear()

	while true do 
		listSettings()
		term.setCursorPos(1,19)	term.write("(setting name / eXit): ")
		local menuChoice = read()

		if menuChoice == "networkProtocol" then settings.networkProtocol = read() end
		if menuChoice == "networkTimeout" then settings.networkTimeout = tonumber(read()) end
		-- if menuChoice == "setupMenu" then settings.setupMenu = parseTrueFalse(read()) end

		if menuChoice == "exit" or menuChoice == "x" then 	break 	end
	end 

	saveSettings()
	mainProgram()
end

function saveSettings( ... )
	local prettystring = jsonV2.encodePretty(settings)
	local fileHandle = fs.open(settingsFilePath,"w")
	fileHandle.write(prettystring)
	fileHandle.close()
end

function loadSettings( ... )
	if fs.exists (settingsFilePath) then
		local fileHandle = fs.open(settingsFilePath,"r")
		local RAWjson = fileHandle.readAll()
		fileHandle.close()
		settings = jsonV2.decode(RAWjson)
	end
	saveSettings()
end

function enableEditMenu( ... )
	local flag = false

	if fs.exists (enableSwitchSetupConfig) then
		local fileHandle = fs.open(enableSwitchSetupConfig,"r")
		local stringIN = fileHandle.readAll()
		if stringIN == "true" then flag = true end
	else
		local fileHandle = fs.open(enableSwitchSetupConfig,"w")
		fileHandle.write("false")
		fileHandle.close()
	end

	return flag
end

bootloader()
-- Switch Device