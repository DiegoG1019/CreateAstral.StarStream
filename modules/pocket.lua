if not pocket then return end

print("Initializing Pocket Module")

local queryableHosts
local options = {}
local selectionIndex = 1
local menu = 0
local title = ""
local info = ""

local function reloadHosts()
  queryableHosts = { rednet.lookup("astralnet-query") }
end

local function ClearTerm()
  term.clear()
  term.setCursorPos(1, 1)
end

local function BlitLine(msg, fg, bg)
  term.setTextColor(fg)
  term.setBackgroundColor(bg)
  print(msg)
end

local function createOption(name, action)
  return { ["name"] = name, ["action"] = action }
end

function createQueryMenuFor(host)
  ClearTerm()
  BlitLine("Loading '"..host.."' endpoints...", colors.lightBlue, colors.black)
  
  local sender, msg = StarStream.AstralNet.Query("endpoints", nil, host, 20)
  
  if (not sender) or msg.code < 0 then
    BlitLine("Could not load host endpoints :(", colors.lightBlue, colors.black)
    os.sleep(2)
    createStartingMenu()
  else
    title = "Endpoints available for this host"
    options = {}
    for i,v in ipairs(msg.body) do
      table.insert(options, createOption(v, function() info = tostring(StarStream.AstralNet.Query(v, nil, host, 20)); createStartingMenu() end))
    end
  end
  
end

function createStartingMenu()
  
  ClearTerm()
  
  BlitLine("Loading hosts...", colors.lightBlue, colors.black)
  
  reloadHosts()
  options = {}
  
  title = "List of Hosts to query"
  for i,v in ipairs(queryableHosts) do
    table.insert(options, createOption(v, function() createQueryMenuFor(v) end ))
  end
  
  table.insert(options, createOption("* Reload", createStartingMenu ))
  
end

local function render()
  ClearTerm()
  
  BlitLine(title, colors.lightBlue, colors.black)
  BlitLine(info, colors.lime, colors.black)
  
  for i,v in ipairs(options) do
    if selectionIndex == i then
      BlitLine("* "..v.name, colors.cyan, colors.gray)
    else
      BlitLine("* "..v.name, colors.blue, colors.orange)
    end
  end
end

return { function(event, key, is_held)
  if event == "key" and not is_held then
    if keys.up == key then
      selectionIndex = selectionIndex - 1
    elseif keys.down == key then
      selectionIndex = selectionIndex + 1
    elseif keys.enter == key then
      v.action()
    end
    
    if selectionIndex <= 0 then
      selectionIndex = #options
    elseif selectionIndex > #options then
      selectionIndex = 0
    end
    
    render()
  end
end, createStartingMenu }