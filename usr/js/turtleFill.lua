-- = mean set to
-- == equals to

movX = 0
movY = 0

function run() --Main program
	
	if turtle.detectDown() == true then
		turtle.up()
	end

	gotoRightCorner()

	--First Leg (Up)
	xSearch() --How big is X?
	print("X is ".. movX .. " units big")

	turtle.turnLeft()

	--Second Leg (Across)
	ySearch()
	print("Y is ".. movY .. " units big")
	
	turtle.turnLeft()

	-- ThirdLeg (Down)
	legNoCount()	
	print("Leg NoCount")
	
	turtle.turnLeft()

	while true do 

		if movX < 0 then
			break
		end

		if movY < 0 then
			break
		end

	--Start Loop
	--Forth Leg (Across)
	yLeg()
	print("yLeg")
	--we should be back at the start minus at this line

	turtle.turnLeft()

	--Firth Leg (Up), round and round we go
	
	xLeg()
	print("xLeg")
	--End Loop
	end
	
end


function gotoRightCorner(  )
	backup()
	turtle.turnRight()
	while turtle.detect() == false do
			turtle.forward()
	end
	turtle.turnLeft()
	turtle.placeDown()
end

function backup(  )
	turnAround()
	while turtle.detect() == false do
		turtle.forward()
	end
	turnAround()
end

function turnAround(  )
	turtle.turnLeft()
	turtle.turnLeft()
end

function xLeg()
	-- Move forward, drop a block, count down by one
	spacesToMove = 0
	while spacesToMove < movX -1 do
		turtle.forward()
		turtle.placeDown() --Drops block
		spacesToMove = spacesToMove + 1
	end
	movX = movX - 1
	spacesToMove = 0
end

function yLeg()
	-- Move forward, drop a block, count down by one
	spacesToMove = 0
	print(spacesToMove)
	while spacesToMove < movY -1 do
		print(spacesToMove)
		turtle.forward()
		turtle.placeDown() --Drops block
		spacesToMove = spacesToMove + 1
	end
	movY = movY - 1
	spacesToMove = 0
	
end


function legNoCount()
	-- Move forward, drop a block, count down by one
	spacesToMove = -2
	while spacesToMove < movY do
		turtle.forward()
		turtle.placeDown() --Drops block
		spacesToMove = spacesToMove + 1
	end
	spacesToMove = 0
end



function xSearch()
	while turtle.detect() == false do
		turtle.forward()
		turtle.placeDown() --Drops block
		movX = movX + 1
		-- print (movX)
	end
end

function ySearch()
	while turtle.detect() == false do
		turtle.forward()
		turtle.placeDown() --Drops block
		movY = movY + 1
		-- print (movY)
	end
end

	run() --Runs main program
