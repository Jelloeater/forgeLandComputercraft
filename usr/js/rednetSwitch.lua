-- RedNet Switch Control System v1
-- Author: Jesse

os.loadAPI("/bb/api/jsonV2")
os.loadAPI("/bb/api/colorFuncs")

debugmode = false
editDevicesMenuFlag = false
editSettingsMenuFlag = false
devicesFilePath = "/switches.cfg"
settingsFilePath = "/settingsSwitches.cfg"


function listColors( ... )
print("Color codes: white - orange - magenta - lightBlue - yellow - lime - pink - gray - lightGray - cyan - purple - blue - brown - green - red - black")
end

function bootloader( ... )
	print ("Setting up network...")

	if peripheral.isPresent("top") and peripheral.getType("top") == "modem" then modemSide = "top" modemPresentFlag = true end
	if peripheral.isPresent("bottom") and peripheral.getType("bottom") == "modem" then modemSide = "bottom" modemPresentFlag = true end
	if peripheral.isPresent("left") and peripheral.getType("left") == "modem" then modemSide = "left" modemPresentFlag = true end
	if peripheral.isPresent("right") and peripheral.getType("right") == "modem" then modemSide = "right" modemPresentFlag = true end
	if peripheral.isPresent("back") and peripheral.getType("back") == "modem" then modemSide = "back" modemPresentFlag = true end
	
	if modemPresentFlag then term.write(" - Located Modem: ".. modemSide)  rednet.open(modemSide) end
	if modemPresentFlag == false then term.write(" - NO MODEM FOUND") os.sleep(10) os.shutdown() end

	rednet.open(modemSide)

	if fs.exists (settingsFilePath) then loadSettings() end -- Loads settings
	loadDeviceList()
	mainProgram()
end

function mainProgram( )
	while true do
		if editDevicesMenuFlag then editDevicesMenu() break end
		if editSettingsMenuFlag then editSettingsMenu() break end -- Kicks in from menuInput command
		parallel.waitForAny(menuInput, monitorNetwork)
	end
end

function menuInput( ... )
	term.clear()
	term.setCursorPos(1,1)
	listDevices()

	term.setCursorPos(1,19)
	term.write("Menu: (printServlist / Edit / Settings / eXit): ")
	local x = read()
	if x == "edit" or x == "e" then editDevicesMenuFlag = true end
	if x == "settings" or x == "s" then editDevicesMenuFlag = true end
	if x =="printServList" or x =="s"then printServerDeviceList() end
	if x == "exit" or x == "x" then os.shutdown() end
end

function monitorNetwork( ... )
	local senderId, message, protocol = rednet.receive(settings.networkProtocol,settings.networkTimeout) --Wait for device List
	if message == "reboot" then os.reboot() end -- Lets us reboot remotely at anytime
	if message == "sendDeviceCommand" then receiveCommand() end
	if message == "getSwitchStatus" then broadcastSwitchStatus() end

end

-----------------------------------------------------------------------------------------------------------------------
-- Net Commands
function receiveCommand( ... )
	local senderId, message, protocol = rednet.receive(settings.networkProtocol,settings.networkTimeout) 
	local msg = jsonV2.decode(message)

	for i=1,table.getn(deviceList) do 
		local devIn = deviceList[i]
		if msg.switchId == devIn.color then 
			if msg.command == "on" then redstone.setOutput(devIn.side, true) devIn.status = true end
			if msg.command == "off" then redstone.setOutput(devIn.side, false) devIn.status = false end
		end
	end
end

function broadcastSwitchStatus( ... )
	local senderId, message, protocol = rednet.receive(settings.networkProtocol,settings.networkTimeout) 

	for i=1,table.getn(deviceList) do 
	local devIn = deviceList[i]
		if tonumber(message) == devIn.color then 
			if devIn.status == true then rednet.broadcast("true",settings.networkProtocol) end
			if devIn.status == false then rednet.broadcast("false",settings.networkProtocol) end
		end
	end
end

-----------------------------------------------------------------------------------------------------------------------
-- Switch Class
local Switch = {}  -- the table representing the class, which will double as the metatable for the instances
Switch.__index = Switch -- failed table lookups on the instances should fallback to the class table, to get methods

function Switch.new(labelIn,colorIn,sideIn)
	local self = setmetatable({},Switch) -- Lets class self refrence to create new objects based on the class
	
	self.label = labelIn
	self.color = colorIn
	self.side = sideIn
	self.status = false
	return self
end



function addDevice( ... )
	print("Enter device name to be added: ")
	local deviceLabel = read()

	listColors()
	print("Enter color code: ")
	local colorCode = colorFuncs.toColor(read())

	print("Enter side(top/bottom/left/right: ")
	local side = read()

	if colorCode == nil or deviceLabel == "" or side == "" then term.clear() print("INVALID SETTINGS") os.sleep(2) else
	table.insert(deviceList, Switch.new(deviceLabel,colorCode,side)) end

end

function editDevice( ... )
	print("Enter device to edit: ")
	local editDevice = read()

	print("Enter new label: ")
	local newLabel = read()

	for i=1,table.getn(deviceList) do -- Gets arraylist size
		if deviceList[i].label == editDevice then
			if newLabel ~= "" then deviceList[i].label = newLabel end

			listColors()	
			print("Enter new color code ["..colorFuncs.toString(deviceList[i].color).."] : ")
			local colorIn = read()
			local colorCode = colorFuncs.toColor(colorIn)

			if colorIn ~= "" and colorCodeOn ~= nil then deviceList[i].color = colorCode 	end 
			-- Non blank AND correct color = set color, a incorrect color returns NOTHING, which blocks setter

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
	print("Device List - Network ID: " .. settings.networkProtocol)
	for i=1,table.getn(deviceList) do 
		local devIn = deviceList[i]
		if devIn.status == true then term.setTextColor(colors.green) end
		if devIn.status == false then term.setTextColor(colors.red) end
 		print("Label: "..devIn.label.." Color: "..colorFuncs.toString(devIn.color).." Side: "..devIn.side)
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
	editDevicesMenuFlag = false
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
			table.insert(deviceList, Switch.new(devIn.label,devIn.color,devIn.side))
		end	
	end
end

-----------------------------------------------------------------------------------------------------------------------
-- Settings Class
settings = {}  -- the table representing the class, holds all the data, we don't need a singleton because THIS IS LUA.

settings.networkProtocol = "deviceNet"
settings.networkTimeout = 4


function listSettings( ... ) -- Need two print commands due to formating
	term.clear()
	print("Settings - I hope you know what you're doing -_-")
	print("")
	term.write("networkProtocol = ") print(settings.networkProtocol)
	term.write("networkTimeout = ") print(settings.networkTimeout)
end

function editSettingsMenu( ... )
	term.clear()

	while true do 
		listSettings()
		term.setCursorPos(1,19)	term.write("(setting name / eXit): ")
		local menuChoice = read()

		if menuChoice == "networkProtocol" then settings.networkProtocol = read() end
		if menuChoice == "networkTimeout" then settings.networkTimeout = tonumber(read()) end

		if menuChoice == "exit" or menuChoice == "x" then break end
	end 

	saveSettings()
	editSettingsMenuFlag = false
	mainProgram()
end

function saveSettings( ... )
	local prettystring = jsonV2.encodePretty(settings)
	local fileHandle = fs.open(settingsFilePath,"w")
	fileHandle.write(prettystring)
	fileHandle.close()
end

function loadSettings( ... )
	local fileHandle = fs.open(settingsFilePath,"r")
	local RAWjson = fileHandle.readAll()
	fileHandle.close()

	settings = jsonV2.decode(RAWjson)
end

bootloader()
-- Switch Device