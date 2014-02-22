local sides = {"left", "right", "top", "bottom", "front", "back"}
local m = {}

-- Find the side on which a monitor is present.
function m.getSide()
  for key, side in pairs(sides) do
    if (peripheral.isPresent(side) and (peripheral.getType(side) == "monitor")) then
      return side
    end
  end
  return nil
end

function m.setCursorPos(mon, x, y)
  mon.mon.setCursorPos(x + mon.x - 1, y + mon.y - 1)
end

function m.getCursorPos(mon)
  local cx, cy = mon.mon.getCursorPos()
  cx = cx - mon.x + 1
  cy = cy - mon.y + 1
  return cx, cy
end

function m.getSize(mon)
  return mon.w, mon.h
--  return mon.w - mon.x + 1, mon.h - mon.y + 1
end

-- Finds a monitor and constructs a helper object.
function m.findMon(x, y, w, h)
  local mon = {}
  local theSide = m.getSide()
  mon.side = theSide
  if theSide == nil then
    print("No monitor found! Falling back to terminal.")
    mon.mon = term
    mon.methods = nil
  else
    mon.mon = peripheral.wrap(theSide)
    mon.methods = peripheral.getMethods(theSide)
  end
  if x == nil then
    mon.x = 1
  else
    mon.x = x
  end
  if y == nil then
    mon.y = 1
  else
    mon.y = y
  end

  if (w == nil) or (h == nil) then
    mon.w, mon.h = mon.mon.getSize()
  else
    mon.w = w
    mon.h = h
  end
  local cw, ch = m.getSize(mon)
  mon.content = string.rep(".", cw * ch)

  return mon
end

function m.write(mon, str)
  if (str ~= nil) and (str:len() > 0) then
    local cx, cy = m.getCursorPos(mon)
    local w, h = m.getSize(mon)
    local start = cx + (cy - 1) * w - 1
    local ende = start + 1 + str:len()
    if start > 0 then
      mon.content = mon.content:sub(1, start)..str..mon.content:sub(ende, -1)
    else
      mon.content = str..mon.content:sub(ende, -1)
    end
--    print("##"..str:len().."##"..mon.content:len())
--    print(cx..", "..cy.."#"..str)
    mon.mon.write(str)
  end
end

function m.scroll(mon)
  local cw, ch = m.getSize(mon)
--  print("scrolling "..mon.content)
  mon.content = mon.content:sub(cw + 1, -1)..string.rep(" ", cw)
--  print("scrolling "..mon.content)
  for y = 1, ch do
    m.setCursorPos(mon, 1, y)
--    print("++"..mon.content:sub(1 + (y - 1) * cw, y * cw).."++")
    mon.mon.write(mon.content:sub(1 + (y - 1) * cw, y * cw))
  end
end

-- Prints the text centered on the specified monitor.
-- If monitor is not given, finds the next available monitor to print on.
function m.printCenter(str, yPos, mon)
  if (not mon) then
    mon = m.findMon()
  end
  if (not yPos) then
    local cx, cy = mon.mon.getCursorPos()
    yPos = cy + mon.y - 1
  end
  mon.mon.setCursorPos((mon.w - mon.x + 1)/2 - #str/2, yPos)
  m.write(mon, str)
  return mon
end

-- Prints the text right justified on the specified monitor.
-- If monitor is not given, finds the next available monitor to print on.
function m.printRight(str, yPos, mon)
  if (not mon) then
    mon = m.findMon()
  end
  if (not yPos) then
    local cx, cy = mon.mon.getCursorPos().y
    yPos = cy + mon.y - 1
  end
  mon.mon.setCursorPos(mon.x - 1 + mon.w - #str, yPos)
  m.write(str)
  return mon
end

function m.clearLine(mon, y)
  if (not mon) then
    mon = m.findMon()
  end
  mon.mon.setCursorPos(mon.x, mon.y + y - 1)
  local str = string.rep(" ", mon.w - mon.x + 1)
  mon.mon.write(str)
end

function m.clear(mon)
  if (not mon) then
    mon = m.findMon()
    mon.mon.clear()
    return mon
  end

  for y = 1, mon.h - mon.y + 1 do
    m.clearLine(mon, y)
  end
  mon.mon.setCursorPos(mon.x, mon.y)
  return mon
end

-- Prints the text on the specified monitor.
-- If monitor is not given, finds the next available monitor to print on.
-- Wraps and scrolls text which is to long to fit in one line.
-- Default width/height of 80x24 can be overidden.
function m.print(theText, mon, newLine)
  local text = ""
  if (theText ~= nil) then
    text = tostring(theText)
  end
  if (mon == nil) then
    mon = m.findMon()
  end
  if (mon ~= nil) then
--    print("Text: <"..text..">")
    local cx, cy = m.getCursorPos(mon)
--    print("mon.mon.cp: "..cx..", "..cy)
    local w, h = m.getSize(mon)
    while (text:len() > w - cx + 1) do
      local sub = string.sub(text, 1, w - cx + 1)
      text = string.sub(text, w - cx + 2, -1)
--      print(text:len().."  "..w.."  "..cx)
      sleep(0.3)
      m.write(mon, sub)
      if (cy >= h) then
        m.scroll(mon)
        cy = cy - 1
      end
      m.setCursorPos(mon, 1, cy + 1)
      cx, cy = m.getCursorPos(mon)
    end
    m.write(mon, text)
    if newLine then
      if (cy >= h) then
        m.scroll(mon)
        cy = cy - 1
      end
      m.setCursorPos(mon, 1, cy + 1)
    end
--    print("---")
  end
  return mon
end

function m.println(theText, mon)
  m.print(theText, mon, true)
end

function m.gibberish(mon)
  mon.mon.clear()
  mon.mon.setCursorPos(1, 2)
  mon.mon.write("Test234:-)")

  m.setCursorPos(mon, 1, 1)
  m.print("GIBBERISH 0.1", mon, true)
  while true do
    local text = "01234567890123456789Ein kleiner Hund ging übern Zebrastreifen, sowas aber auch!!"
    m.print(text, mon)
    sleep(0.3)
  end
end

return m