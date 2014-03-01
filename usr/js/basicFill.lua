blockBelow = turtle.detectDown()

while blockBelow == false detectDown do
	turtle.placeDown()
	turtle.forward()
	blockBelow = turtle.detectDown()
end