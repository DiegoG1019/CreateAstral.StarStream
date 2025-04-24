local modules = {}
local repoUser = "DiegoG1019"
local repoName = "CreateAstral.StarStream"
local ghDownloadAddr = "https://raw.githubusercontent.com/"..repoUser.."/"..repoName.."/refs/heads/main/"
local ghQueryAddr = "https://api.github.com/repos/"..repoUser.."/"..repoName.."/git/trees/main?recursive=true"

StarStream = {}
StarStream.queryableInfo = {}

local json = require 'json'

function string.starts(String,Start)
   return string.sub(String,1,string.len(Start)) == Start
end

function update()
  print("Updating...")
  local r = inner_update()
  
  if r then 
    print("Updated!")
    os.reboot()
  end
  
  print("No updates found")
  os.sleep(2)
end

function getFilesRecursively(path, tab)
  path = path or ""
  tab = tab or {}
  
  local pendingDirs = {}
  for i,v in ipairs(path) do
    if fs.isDir(v) then
      table.insert(pendingDirs, path.."/"..v)
    else
      table.insert(tab, path.."/"..v, true)
    end
  end
  
  for i,v in ipairs(pendingDirs) do
    getFilesRecursively(v, tab)
  end
  
  return tab;
end

local function getDownloadUri(treeItem)
  return treeItem.localpath or treeItem.path
end

function inner_update()
  local manifest;
	local manifestFile = fs.open("manifest.json", "r")
	if not manifestFile then
		manifest = {}
	else
    manifest = json.decode(manifestFile.readAll())
    manifestFile.close()
  end

	local r, statusMsg = http.get(ghQueryAddr)
  if not r then
    print("Failed to GET from "..ghQueryAddr..": "..statusMsg)
    return false
  end
	
	local contents = json.decode(r.readAll());
  r.close();
	
	if not contents.tree or #(contents.tree) == 0 then return false end
	
  for i,v in ipairs(contents.tree) do
    if v.path == "startup.lua" then v.path = "starstream.startup.lua"; v.dlpath = "startup.lua" end
  end
  
  print("Parsed git tree info")
  
  local pendingDownload = {}
  
  local pendingDeletion = {}
  getFilesRecursively(pendingDeletion)  
  
  print("Iterating over git tree")
	for i,v in ipairs(contents.tree) do
    pendingDeletion[v.path] = nil
    print("Removed file "..v.path.." from deletion")
    
		if v.path ~= "LICENSE" and not string.starts(v.path, ".") then 
      
			if not manifest[v.path] or v.sha ~= manifest[v.path] then
        manifest[v.path] = v.sha
        if not v.size then
          if not fs.isDir(v.path) then
            fs.makeDir(v.path)
          end
        else
          table.insert(pendingDownload, v)
        end
      end
		end
	end
  
  if (#pendingDownload == 0) and (#pendingDeletion == 0) then return false end
  
  print("Deleting upstream-removed files")
  for k,v in pairs(pendingDeletion) do
    if v == true then
      print("Deleting file" ..k)
      fs.delete(k)
    end
  end
  
  print("Downloading outdated files")
  for i,v in ipairs(pendingDownload) do
    print("Downloading file "..v.path)
    local response, statusStr = http.get(ghDownloadAddr..(v.dlpath or v.path))
    if not response then
      print("ERROR: Could not get file "..v.path.." :"..statusStr)
    else
      local downfile = fs.open(v.path, "w")
      downfile.write(response.readAll())
      downfile.close()
      response.close()
    end
  end
  
  print("Updating manifest")
  manifestFile = fs.open("manifest.json", "w")
  manifestFile.write(json.encode(manifest))
  manifestFile.close()
  
  return true
end

function loadModules()
  
  local moduleInfo = {}
  
  table.insert(moduleInfo, { require 'modules.astralnet' })
  table.insert(moduleInfo, { require 'modules.factory' })
  table.insert(moduleInfo, { require 'modules.pocket' })
  
  local awaitingInit = {}
  
  for i,v in ipairs(moduleInfo) do
    
    local moduleFunc, moduleInitFunc = v[1], v[2]
    
    if type(moduleFunc) == "table" then
      moduleInitFunc = moduleFunc[2]
      moduleFunc = moduleFunc[1]
    end
    
    if type(moduleFunc) == "function" then
      table.insert(modules, moduleFunc)
    end
    
    if type(moduleInitFunc) == "function" then
      table.insert(awaitingInit, moduleInitFunc)
    end
  end
  
  print("Registered "..#modules.." module listeners")
  
  print("Initializing "..#awaitingInit.." modules")
  
  for i,v in ipairs(awaitingInit) do
    v()
  end
  
  print("Initialized modules")
  os.sleep(2)
end

if not pocket then

  update()
  
  loadModules()
  
  local timerId = os.startTimer(60)
  
  while true do
    local event = { os.pullEvent() }
    
    if event[0] == "alarm" and timerId == event[1] 
    then 
      update()
    else
      for i,v in ipairs(modules) do
        local success, retval = pcall(v, unpack(event))
        if retval == true then break end
      end
    end
    
    os.sleep(0.5)
  end
  
else

  update()
  
  loadModules()
  
  local timerId = os.startTimer(60)
  
  while true do
    local event = { os.pullEvent() }
    
    if event[0] == "alarm" and timerId == event[1] 
    then 
      update()
    else
      for i,v in ipairs(modules) do
        local success, retval = pcall(v, unpack(event))
        if retval == true then break end
      end
    end
    
  end
  
end