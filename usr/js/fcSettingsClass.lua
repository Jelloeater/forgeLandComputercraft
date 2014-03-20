debugmode = false
rednetSide = "bottom" -- Where is the redNet cable

monitorDefaultColor = colors.white
terminalDefaultColor = colors.white
progressBarColor = colors.yellow
bootLoaderColor = colors.green
rednetIndicatorColor = colors.blue

fillColor = colors.yellow
dumpColor = colors.green
onColor = colors.green
offColor = colors.red

statusIndent = 22 -- Indent for Status (28 for 1x2 22 for 2x4 and bigger)
terminalIndent1 = 7 -- Determines dash location
terminalIndent2 = 36 -- Determines (On/Off ... etc location)
terminalHeaderOffset = 0





os.loadAPI("/bb/api/jsonV2")

settingsSingletonRef = false

local Settings = {}  -- the table representing the class, which will double as the metatable for the instances
Settings.__index = Settings -- failed table lookups on the instances should fallback to the class table, to get methods
function Settings.new()
	if settingsSingletonRef == false then 
		local self = setmetatable({},Settings) -- Lets class self refrence to create new objects based on the class
			self.text="lol"
			-- Empty Constructor

		settingsSingletonRef = true -- Blocks constructor
		return self
	end
end

function Settings:loadSettings()

	-- read file from disk

	settingsFilePath = "/settings.cfg"

	-- if settings file missing display message and quit
	self = jsonV2.decodeFromFile(settingsFilePath)

end

function Settings:saveSettings()
	rawJSON = jsonV2.encodePretty(self)
	--write file to disk
end

function Settings:printConfigFile( )
	print("CONFIG= ")
	print(jsonV2.encodePretty(self))
end

function run(  )
		settingsObject = Settings.new()
		-- settingsObject:loadSettings()
		settingsObject:printConfigFile()
		settingsObject:saveSettings()

		settingsObject2 = Settings.new()
		settingsObject2:printConfigFile()

end


print("start")
run()
print("end")