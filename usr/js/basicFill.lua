blockBelow = turtle.detectDown()

while blockBelow == false detectDown
	turtle.placeDown()
	turtle.forward()
	blockBelow = turtle.detectDown()
end