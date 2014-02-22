local monitor, error = loadfile("/bb/api/monitor")
if (monitor == nil) then
  print("LIB-ERROR: "..error)
  return
end
m = monitor()

local sides = {"left", "right", "top", "bottom", "front", "back"}

-- Find the side on which a modem is present.
function getSide()
  for key, side in pairs(sides) do
    if (peripheral.isPresent(side) and (peripheral.getType(side) == "modem")) then
      return side
    end
  end
  return nil
end

function msgLoop(server, mon)
  while true do
    local event, arg1, arg2 = os.pullEvent()
    if event == "rednet_message" then
      if arg1 == server then
        print("Msg: "..arg1.." >> "..arg2)
        if arg2 == "CLS" then
          m.clear(mon)
        elseif arg2 == "SERVER_SHUTDOWN" then
          break
        else
          m.println(arg2, mon)
        end
      end
    elseif event == "char" then
      if arg1 == "q" or arg1 == "Q" then
        doExit = true
        rednet.send(server, "displayclient_disconnect")
        break
      end
    end
  end
end

local mon = m.findMon()
mon.mon.clear()
mon.mon.setCursorPos(1, 1)
mon.mon.write(">")
rednet.open(getSide())
doExit = false
sleep(2)

while not doExit do
  rednet.broadcast("displayclient")
  local server, msg, dist = rednet.receive(5)
  if (not msg) then
    print("Server not found.")
  elseif (msg == "displayclient") then
-- ignore other clients broadcasts
  elseif (msg ~= "connection accepted") then
    print("Unexpected message: "..msg)
  else
    print("connected to "..server)
    msgLoop(server, mon)
    print("done")
  end
end
mon.mon.clear()
mon.mon.setCursorPos(1, 1)
rednet.close(getSide())