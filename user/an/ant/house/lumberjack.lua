os.loadAPI("/bb/ant/api/ant")

ant.setPosition("out1", {x = 67, y = -273, z = 72, f = 0})
ant.setPosition("tree1", {x = 67, y = -268, z = 69, f = 0})
ant.setPosition("workbench", {x = 25, y = -271, z = 71, f = 0})
ant.setPosition("sortbox", {x = 16, y = -272, z = 70, f = 0})
ant.setPosition("fuelbox", {x = 16, y = -272, z = 72, f = 0})
ant.setPosition("prepark", {x = 22, y = -272, z = 73, f = 2})
ant.setPosition("parklumberjack", {x = 22, y = -271, z = 73, f = 2})

function init()
  print("calibrating...")
  ant.calibrate(19, -271, 71, "south")
  print("set home...")
  ant.saveActPos("home")
  print("refueling...")
  ant.refuel()
  print("leaving home...")
  ant.turnLeft()
  ant.turnLeft()
  harvest()
end

function refuel()
  print("fuel: "..ant.getFuelLevel())
  if (ant.getFuelLevel() < 6000) then
    print("refueling...")
    ant.goto("fuelbox")
    ant.refuel()
  end
end

function harvestTree()
  ant.dig()
  ant.forward()
  ant.dig()
  ant.forward()
  for x=1, 2 do
    for y=1, 50 do
     ant.digUp()
     ant.up()
    end
    ant.dig()
    ant.forward()
    for y=1, 50 do
     ant.digDown()
     ant.down()
    end
    ant.turnRight()
    ant.dig()
    ant.forward()
    ant.turnRight()
  end
end

function harvest()
  refuel()
  ant.goto("out1")
  ant.goto("tree1")
  harvestTree()
  ant.goto("out1")
  ant.goto("sortbox")
  ant.dropAll()
  ant.goto("prepark")
  ant.goto("parklumberjack")
end

init()
