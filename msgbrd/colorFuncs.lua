----------------------------------------------------------------------------
-- colorFuncs: Color code manipulation for Computer Craft
-- Author: Jesse S
-- Version: 1.0
--
-- USAGE:
-- This module exposes two functions:
--   toColor(string)
--     Returns color code in INT form.
--   toString(int)
--     Returns color name in String form.
--	 listColors()
--	   Writes list of colors to terminal

function listColors()
	print("white")
	print("orange")
	print("magenta")
	print("lightBlue")
	print("yellow")
	print("lime")
	print("pink")
	print("gray")
	print("lightGray")
	print("cyan")
	print("purple")
	print("blue")
	print("brown")
	print("green")
	print("red")
	print("black")
end

function toColor( colornameIn )
	if colornameIn == "white" then return colors.white end
	if colornameIn == "orange" then return colors.orange end
	if colornameIn == "magenta" then return colors.magenta end
	if colornameIn == "lightBlue" then return colors.lightBlue end
	if colornameIn == "yellow" then return colors.yellow end
	if colornameIn == "lime" then return colors.lime end
	if colornameIn == "pink" then return colors.pink end
	if colornameIn == "gray" then return colors.gray end
	if colornameIn == "lightGray" then return colors.lightGray end
	if colornameIn == "cyan" then return colors.cyan end
	if colornameIn == "purple" then return colors.purple end
	if colornameIn == "blue" then return colors.blue end
	if colornameIn == "brown" then return colors.brown end
	if colornameIn == "green" then return colors.green end
	if colornameIn == "red" then return colors.red end
	if colornameIn == "black" then return colors.black end
end

function toString( colorINTin )
	if colorINTin == 1 then return "white" end
	if colorINTin == 2 then return "orange" end
	if colorINTin == 4 then return "magenta" end
	if colorINTin == 8 then return "lightBlue" end
	if colorINTin == 16 then return "yellow" end
	if colorINTin == 32 then return "lime" end
	if colorINTin == 64 then return "pink" end
	if colorINTin == 128 then return "gray" end
	if colorINTin == 256 then return "lightGray" end
	if colorINTin == 512 then return "cyan" end
	if colorINTin == 1024 then return "purple" end
	if colorINTin == 2048 then return "blue" end
	if colorINTin == 4096 then return "brown" end
	if colorINTin == 8192 then return "green" end
	if colorINTin == 16384 then return "red" end
	if colorINTin == 32768 then return "black" end
end