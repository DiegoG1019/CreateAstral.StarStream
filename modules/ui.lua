local function getDefaultOutput()
  if not pocket then return nil end
  return "!default"
end

settings.define("ui.output", 
  { 
    ["description"] = "Whether or not the UI is enabled",
    ["default"] = getDefaultOutput(),
    ["type"] = "string"
  }
)

local menus = {}

print("Initializing UI Module")

local outputMode = settings.get("ui.output")
if not outputMode then print("UI is disabled"); return end

if not fs.exists("basalt.lua") then
  os.run({}, "/rom/programs/http/wget", "run", "https://raw.githubusercontent.com/Pyroxenium/Basalt2/main/install.lua", "-r")
end

local basalt = require 'basalt'

if outputMode ~= "!default" then
  local newOut = assert(peripheral.wrap(outputMode))
  if newOut.blit then
---@diagnostic disable-next-line: param-type-mismatch
    term.redirect(newOut)
  end
  print("Redirected Output")
end

local queryableHosts
local options = {}
local selectionIndex = 1
local menu = 0
local title = ""
local info = ""

local function reloadHosts()
  queryableHosts = { rednet.lookup("astralnet-query") }
end

local function clearTerm()
  term.clear()
  term.setCursorPos(1, 1)
end

local function blitLine(msg, fg, bg)
  term.setTextColor(fg)
  term.setBackgroundColor(bg)
  print(msg)
end

local function createOption(name, action)
  return { ["name"] = name, ["action"] = action }
end

function menus.createQueryMenuFor(host)
  clearTerm()
  blitLine("Loading '"..host.."' endpoints...", colors.lightBlue, colors.black)
  
  local sender, msg = StarStream.AstralNet.Query("endpoints", nil, host, 20)
  
  if (not sender) or assert(msg).code < 0 then
    blitLine("Could not load host endpoints :(", colors.lightBlue, colors.black)
    os.sleep(2)
    menus.createStartingMenu()
  else
    title = "Endpoints available for this host"
    options = {}
    for i,v in ipairs(assert(msg).body) do
      table.insert(options, createOption(v, function() info = tostring(StarStream.AstralNet.Query(v, nil, host, 20)); menus.createStartingMenu() end))
    end
  end
  
end

function menus.createStartingMenu()
  
  clearTerm()
  
  blitLine("Loading hosts...", colors.lightBlue, colors.black)
  
  reloadHosts()
  options = {}
  
  title = "List of Hosts to query"
  for i,v in ipairs(queryableHosts) do
    table.insert(options, createOption(v, function() menus.createQueryMenuFor(v) end ))
  end
  
  table.insert(options, createOption("* Reload", menus.createStartingMenu ))
  
end

local function render()
  clearTerm()
  
  blitLine(title, colors.lightBlue, colors.black)
  blitLine(info, colors.lime, colors.black)
  
  for i,v in ipairs(options) do
    if selectionIndex == i then
      blitLine("* "..v.name, colors.cyan, colors.gray)
    else
      blitLine("* "..v.name, colors.blue, colors.orange)
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
      options[selectionIndex].action()
    end
    
    if selectionIndex <= 0 then
      selectionIndex = #options
    elseif selectionIndex > #options then
      selectionIndex = 0
    end
    
    render()
  end
end, menus.createStartingMenu }