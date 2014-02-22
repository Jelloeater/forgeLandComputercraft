-- This will become an api to show and process menus.
local monitor, error = loadfile("/bb/api/monitor")
if (monitor == nil) then
  print("LIB-ERROR: "..error)
  return
end
m = monitor()

function dontknow()
end