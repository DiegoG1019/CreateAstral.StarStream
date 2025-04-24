if not pocket then return end

print("Initializing Pocket Module")

local queryableHosts
local options = {}
local selectionIndex = 1
local menu = 0
local title = ""
local info = ""

local function ClearTerm()
  term.clear()
  term.setCursorPos(1, 1)
end

local function createOption(name, action)
  return { ["name"] = name, ["action"] = action }
end

local function createQueryMenuFor(host)
  ClearTerm()
  term.blit("Loading '"..host.."' endpoints...", colors.lightBlue, colors.black)
  
  local sender, msg = StarStream.AstralNet.Query("endpoints", nil, host, 20)
  
  if (not sender) or msg.code < 0 then
    term.blit("Could not load host endpoints :(", colors.red, colors.black)
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

local function createStartingMenu()
  
  ClearTerm()
  
  print(colours.lightBlue)
  
  term.blit("Loading hosts...", colours.lightBlue, colors.black)
  
  reloadHosts()
  options = {}
  
  title = "List of Hosts to query"
  for i,v in ipairs(queryableHosts) do
    table.insert(options, createOption(v, function() createQueryMenuFor(v) end ))
  end
  
  table.insert(options, createOption("* Reload", createStartingMenu ))
  
end

local function reloadHosts()
  queryableHosts = { rednet.lookup("astralnet-query") }
end

local function render()
  ClearTerm()
  
  term.blit(title, colors.lightBlue, colors.black)
  term.blit(info, colors.yellow. colors.black)
  
  for i,v in ipairs(options) do
    if selectionIndex == i then
      term.blit("* "..v.name, colors.cyan, colors.lightgray)
    else
      term.blit("* "..v.name, colors.blue, colors.orange)
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