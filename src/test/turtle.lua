--local monitor, error = loadfile("/bb/api/monitor")
--if (monitor == nil) then
--  print("LIB-ERROR: "..error)
--  return
--end
--local m = monitor()

--local kleinMon = m.findMon(3, 3, 13, 7)
--m.gibberish(kleinMon)

--os.unloadAPI("turtle")
--os.loadAPI("bb/api/betterturtle")
local myturtle, error = loadfile("/bb/api/betterturtle")
if (myturtle == nil) then
  print("LIB-ERROR: "..error)
  return
end
local t = myturtle()

print(t.toString())
t.calibrate(-40, -136, 72, "west")
print(t.toString())
t.turnLeft()
print(t.toString())

print("### init")
print(serial.toString(t.getPositions()))
print("### home1")
t.saveActPos("home")
print(serial.toString(t.getPositions()))
t.turnLeft()
print("--- home2")
t.saveActPos("home")
print(serial.toString(t.getPositions()))
print("---")