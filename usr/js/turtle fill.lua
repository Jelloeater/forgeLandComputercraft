print ("First turn (r/l)?")
firstTurn = read()


movX = 0
movY = 0

function run() --Main program
	--First Leg (Up)
	xSearch() --How big is X?
	print("X is ".. movX .. "units big")

	turtleTurner()

	--Second Leg (Across)
	ySearch()
	print("Y is ".. movY .. "units big")
	
	turtleTurner()

	--Third Leg (Down)
	legNoCount()
	
	turtleTurner()


	--Start Loop
	--Forth Leg (Across)
	yLeg()
	--we should be back at the start minus at this line

	turtleTurner()

	--Firth Leg (Up), round and round we go
	
	xLeg()
	--End Loop
	
end

function xLeg()
	-- Move forward, drop a block, count down by one
	while spacesToMove > movX then
		turtle.forward
		turtle.placeDown --Drops block
		spacesToMove = spacesToMove + 1
	end
	movX = movX - 1
	print("xLeg Done")
end

function yLeg()
	-- Move forward, drop a block, count down by one
	while spacesToMove > movY then
		turtle.forward
		turtle.placeDown --Drops block
		spacesToMove = spacesToMove + 1
	end
	movY = movY - 1
	print("yLeg Done")
end


function legNoCount()
	while turtledetect() = false then
		turtle.forward
		turtle.placeDown --Drops block
	end
	print("Leg Done :)")
end



function xSearch()
	while turtledetect() = false then
		turtle.forward
		turtle.placeDown --Drops block
		movX = movX + 1
		print (movX)
	end
	print("Done searching for X")
end

function ySearch()
	while turtledetect() = false then
		turtle.forward
		turtle.placeDown --Drops block
		movY = movY + 1
		print (movY)
	end
	print("Done searching for Y")
end

function turtleTurner()
	if firstTurn = "l" then
		turtle.turnLeft
		end
	if firstTurn = "r" then
		turtle.turnLeft
		end
end
	run() --Runs main program