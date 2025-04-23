if pocket then return end

local itemHistory = {}

local inventories;
local energyStorage;
local fluidStorage;

StarStream.Factory = itemHistory

local function appendHistory(tab)
  table.insert(itemHistory, tab)
  while #itemHistory > 2 do
    table.remove(itemHistory, 1)
  end
end

local function readItems() 
  local items = {}
  
  for i, inv in ipairs(inventories) do
    for slot, item in ipairs(inv.list()) do
      if not slot[item.name] then
        slot[item.name] = 0
      end
      
      slot[item.name] = slot[item.name] + item.count
    end
  end
  
  appendHistory({ ["items"] = items, ["stamp"] = os.date("%c") })
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