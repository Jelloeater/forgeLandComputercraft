sensorSide = "bottom"

function getPlayers( ... )
	-- For some odd reason doing a direct call is okay but doing a wrap causes java.long.Exception in CC, odd...
	return peripheral.call(sensorSide, "getPlayerNames")
end

print("Detecting Awesome!")
while true do
	alarm = false
	playerList = getPlayers()

	for i=1,table.getn(playerList) do -- Gets arraylist size
		local player = playerList[i]

		if 	player ~= "jelloeater20" and player ~= "Kalgaren" then 
		redstone.setBundledOutput("top", colors.white)
		print("PARTY TIME!!!")
		os.sleep(30)
		end
	end

	os.sleep(1)
	redstone.setBundledOutput("top", 0) -- Turns off the party
end
