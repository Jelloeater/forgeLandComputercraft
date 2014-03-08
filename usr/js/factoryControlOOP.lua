


debugmode = false
monitor = peripheral.wrap("top") -- Where is the monitor
rednetSide = "bottom" -- Where is the redNet cable

monitorDefaultColor = colors.white
term.setTextColor(colors.green)
monitor.setTextScale(.5) -- Sets Text Size
statusIndent = 28 -- Indent for Status
-- .5 for 1x2 1 for 2x4

switch = {label,statusFlag,lineNumber,redNet1}
switchInvert = {label="Generator",statusFlag = false, lineNumber = 2,redNet1=colors.white}
tank = {label="Tank",fillFlag = false, dumpFlag = false,lineNumber = 3,redNetFill=colors.pink,redNetDump = colors.yellow}

function switch:new(label,statusFlag,lineNumber,redNet1)
	self.label = label
	self.statusFlag = statusFlag
	self.lineNumber = lineNumber
	self.redNet1 = redNet1
	return self
end


function switch:monitorStatus( ... )
	monitor.setCursorPos(1, self.lineNumber)
	monitor.write(self.label.." is: ")
	if self:getStatus(self.statusFlag) == "OFFLINE" then monitor.setTextColor(colors.red) end
	if self:getStatus(self.statusFlag) == "ONLINE" then monitor.setTextColor(colors.green) end
	monitor.setCursorPos(statusIndent,self.lineNumber)
	monitor.write(self:getStatus(self.statusFlag))
	monitor.setTextColor(monitorDefaultColor)
end

function switch:getStatus( statusFlag )
	if statusFlag == false then
	status = "OFFLINE"
	end
	if statusFlag == true then
	status = "ONLINE"
	end
	return status
end

function switch:on( ... )
	if self.statusFlag == false then -- Off State
		redstone.setBundledOutput(rednetSide, redstone.getBundledOutput(rednetSide)+self.redNet1)
		self.statusFlag = true
	end
end

function switch:off( ... )
	if self.statusFlag == true then -- On State
		redstone.setBundledOutput(rednetSide, redstone.getBundledOutput(rednetSide)-self.redNet1)
		self.statusFlag = false
	end
end

function switch:monitorStatus( ... )
	monitor.setCursorPos(1, self.lineNumber)
	monitor.write(self.label.." is: ")
	if self:getStatus(self.statusFlag) == "OFFLINE" then monitor.setTextColor(colors.red) end
	if self:getStatus(self.statusFlag) == "ONLINE" then monitor.setTextColor(colors.green) end
	monitor.setCursorPos(statusIndent,self.lineNumber)
	monitor.write(self:getStatus(self.statusFlag))
	monitor.setTextColor(monitorDefaultColor)
end

function switchInvert:getStatus( statusFlag )
	if statusFlag == false then
	status = "OFFLINE"
	end
	if statusFlag == true then
	status = "ONLINE"
	end
	return status
end

function switchInvert:on( ... )
	if self.statusFlag == false then -- Off State
		redstone.setBundledOutput(rednetSide, redstone.getBundledOutput(rednetSide)-self.redNet1)
		self.statusFlag = true
	end
end

function switchInvert:off( ... )
	if self.statusFlag == true then -- On State
		redstone.setBundledOutput(rednetSide, redstone.getBundledOutput(rednetSide)+self.redNet1)
		self.statusFlag = false
	end
end

function tank:monitorStatus( ... )
	monitor.setCursorPos(1, self.lineNumber)
	monitor.write(self.label.." is: ")
	if self:getStatus(self.fillFlag, self.dumpFlag) == "OFFLINE" then monitor.setTextColor(colors.red) end
	if self:getStatus(self.fillFlag, self.dumpFlag) == "FILLING" then monitor.setTextColor(colors.yellow) end
	if self:getStatus(self.fillFlag, self.dumpFlag) == "EMPTYING" then monitor.setTextColor(colors.green) end
	monitor.setCursorPos(statusIndent,self.lineNumber)
	monitor.write(self:getStatus(self.fillFlag, self.dumpFlag))
	monitor.setTextColor(monitorDefaultColor)
end

function tank:getStatus( fillFlag, dumpFlag )
	if fillFlag == false and dumpFlag == false then
	status = "OFFLINE"
	end
	if fillFlag == true and dumpFlag == false then
	status = "FILLING"
	end
	if fillFlag == false and dumpFlag == true then
	status = "EMPTYING"
	end
	return status
end
-- We should NEVER have both flags set to true, that would be silly
function tank:fill( ... )
	if self.fillFlag == false and self.dumpFlag == false then -- Off State
	redstone.setBundledOutput(rednetSide, redstone.getBundledOutput(rednetSide)+self.redNetFill)
	self.fillFlag = true
	self.dumpFlag = false
	end

	if self.fillFlag == false and self.dumpFlag == true then -- Dump State
	redstone.setBundledOutput(rednetSide, redstone.getBundledOutput(rednetSide)+self.redNetFill)
	redstone.setBundledOutput(rednetSide, redstone.getBundledOutput(rednetSide)-self.redNetDump)
	self.fillFlag = true
	self.dumpFlag = false
	end
end

function tank:dump( ... )
	if self.fillFlag == false and self.dumpFlag == false then -- Off State
	redstone.setBundledOutput(rednetSide, redstone.getBundledOutput(rednetSide)+self.redNetDump)
	self.fillFlag = false
	self.dumpFlag = true
	end

	if self.fillFlag == true and self.dumpFlag == false then -- Fill State
	redstone.setBundledOutput(rednetSide, redstone.getBundledOutput(rednetSide)-self.redNetFill)
	redstone.setBundledOutput(rednetSide, redstone.getBundledOutput(rednetSide)+self.redNetDump)
	self.fillFlag = false
	self.dumpFlag = true
	end
end

function tank:off( ... )
	if self.fillFlag == true then -- Fill State
	redstone.setBundledOutput(rednetSide, redstone.getBundledOutput(rednetSide)-self.redNetFill)
	self.fillFlag = false
	end

	if self.dumpFlag == true then -- Dump State
	redstone.setBundledOutput(rednetSide, redstone.getBundledOutput(rednetSide)-self.redNetDump)
	self.dumpFlag = false
	end
end

function monitorRedraw( ... ) -- Status Monitor Display
	monitor.clear()
	networkBridge:monitorStatus()
	-- tank:monitorStatus()

end

function termRedraw( ... ) -- Terminal Display
	term.clear()

	term.setCursorPos(1,1)
	term.write("           Factory Control System v1.0")

	term.setCursorPos(1,2)
	term.write("1     - "..networkBridge.label.." On")

	term.setCursorPos(1,3)
	term.write("2     - "..networkBridge.label.." Off")

	-- term.setCursorPos(1,4)
	-- term.write("3     - "..tank.label.." Fill")

	-- term.setCursorPos(1,5)
	-- term.write("4     - "..tank.label.." Dump")

	-- term.setCursorPos(1,6)
	-- term.write("5     - "..tank.label.." Off")


	term.setCursorPos(1,19)
	if debugmode == true then
		term.write("DEBUG RedNet: ")
		term.write(redstone.getBundledOutput(rednetSide))
		term.write(" ")
	end

	term.write("Select a menu option (on/off): ")

	local inputOption = read()
	menuOption(inputOption)
	
end

function menuOption( menuChoice ) -- Menu Options for Terminal
	if menuChoice == "debugon" then debugmode = true end
	if menuChoice == "debugoff" then debugmode = false end
	if menuChoice == "on" then activateAll() end
	if menuChoice == "off" then shutdownAll() end
	if menuChoice == "1" then networkBridge:on() end
	if menuChoice == "2" then networkBridge:off() end
	-- if menuChoice == "3" then tank:fill() end
	-- if menuChoice == "4" then tank:dump() end
	-- if menuChoice == "5" then tank:off() end


end


function setStartupState( ... )
	-- All systems are logically off at start, except basementGenerator

end

function shutdownAll( ... )

end

function activateAll( ... )

end

function run(	) -- Main Program Logic
-- setStartupState() --TODO find bug
-- w/ setStartupState disabled, system starts in off state
-- basementGenerator("startup")
--itemname = switch:new(label,statusFlag,lineNumber,redNet1)
networkBridge = switch:new("Network Bridge",false,1,colors.white)

	while true do
		monitorRedraw() -- PASSIVE OUTPUT
		termRedraw()	-- ACTIVE INPUT
	end
end

run() --Runs main program
