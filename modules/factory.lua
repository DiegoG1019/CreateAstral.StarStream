if pocket then return end

print("Initializing Factory Module")

local itemHistory = {}
local fluidHistory = {}
local energyHistory = {}

local inventories;
local energyStorage;
local fluidStorage;

StarStream.queryableInfo.factory = {}
StarStream.queryableInfo.factory.items = itemHistory;
StarStream.queryableInfo.factory.fluids = fluidHistory;
StarStream.queryableInfo.factory.energy = energyHistory;

settings.define("factory.redstoneMode", 
  { 
    ["description"] = "When this setting is not nil, the factory will only take readings upon being given a redstone signal from the designated side. Otherwise, it will take readings every 30 seconds",
    ["default"] = nil,
    ["type"] = "string"
  }
)

local function prepareReadings(container, newReadings, tstamp)
  
  local out = {}
  local prev = container.readings
  
  container.lastReading = tstamp
  container.readings = newReadings
  
  if not prev then
    container.differences = nil
  else
    local diff = {}
    container.differences = diff
    
    for title, count in pairs(newReadings) do
      if prev[title] then
        diff[title] = count - prev[title]
      end
    end
    
    for title, count in pairs(prev) do
      if not newReadings[title] then
        diff[title] = -prev[title]
      end
    end
    
  end
  
end

local function readItems() 
  local items = {}
  for i, inv in ipairs(inventories) do
    for slot, item in ipairs(inv.list()) do
      local itemc = items[item.name] or 0
      items[item.name] = itemc + item.count
    end
  end
  
  local fluids = {}
  --[[for i, storage in ipairs(fluidStorage) do
    for fluid, amount pairs(inv.tanks()) do
      local fluidc = fluids[fluid] or 0
      fluids[fluid] = fluidc + (amount or 0)
    end
  end]] -- test how the table looks
  
  local energy = {}
  local tce = 0
  local tme = 0
  for i, energy in ipairs(energyStorage) do
    tce = tce + energy.getEnergy()
    tme = tme + energy.getEnergyCapacity()
  end
  energy.TotalCurrentEnergy = tce
  energy.TotalMaxEnergy = tme
  
  local tstamp = os.date("%c");
  prepareReadings(itemHistory, items, tstamp)
  prepareReadings(fluidHistory, fluids, tstamp)
  prepareReadings(energyHistory, energy, tstamp)
end

local function reloadPeripherals()
  inventories = {}
  energyStorage = {}
  fluidStorage = {}
  
  for i,v in ipairs(peripheral.getNames()) do
    local inv = peripheral.wrap(v)
    if inv.getItemDetail then 
      table.insert(inventories, inv)
    end
    
    if inv.getEnergy then
      table.insert(energyStorage, inv)
    end
    
    if inv.tanks then
      table.insert(fluidStorage, inv)
    end
  end
  
end

local redMode = settings.get("factory.redstoneMode")
local timerId
if not redMode then
  timerId = os.startTimer(1)
  
  return function(event, ev_timerId)
    if event ~= "timer" or timerId ~= ev_timerId then
      return
    end
    
    timerId = os.startTimer(30)
    reloadPeripherals()
    readItems()
    return true
  end
else
  
  return function(event)
    if event == "redstone" and redstone.getInput(redMode) then
      reloadPeripherals()
      readItems()
      return true
    end
  end
  
end
  