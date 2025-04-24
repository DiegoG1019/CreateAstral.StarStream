local modules = {}
local repoUser = "DiegoG1019"
local repoName = "CreateAstral.StarStream"
local ghDownloadAddr = "https://raw.githubusercontent.com/"..repoUser.."/"..repoName.."/refs/heads/main/"
local ghQueryAddr = "https://api.github.com/repos/"..repoUser.."/"..repoName.."/git/trees/main"

StarStream = {}
StarStream.queryableInfo = {}

local json = require 'json'

function string.starts(String,Start)
   return string.sub(String,1,string.len(Start))==Start
end

function update()
  print("Updating...")
  local r = inner_update()
  
  if r then 
    print("Updated!")
    os.reboot()
  end
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
	
	if not contents.tree or #(contents.tree) == 0 then return false end
	
  local pendingDownload = {}
  
  local pendingDeletion = {}
  getFilesRecursively(pendingDeletion)  
  
	for i,v in ipairs(contents.tree) do
    table.insert(enabled, v.path)
    
		if not string.starts(v.path, ".") and not v.path == "LICENSE" then 
			if not v.sha == manifest[v.path] then
        manifest[v.path] = v.sha
        if not v.size then
          if not fs.isDir(v.path) then
            fs.makeDir(v.path)
          end
        else
          pendingDeletion[v.path] = nil
          table.insert(pendingDownload, v)
        end
      end
		end
	end
  
  if (#pendingDownload == 0) and (#pendingDeletion == 0) then return false end
  
  for k,v in pairs(pendingDeletion) do
    if v == true then
      fs.delete(k)
    end
  end
  
  for i,v in ipairs(pendingDownload) do
    local response = http.get(v.url)
    local rcode = r.getResponseCode()
    if not rcode >= 200 and not rcode <= 299 then
      print("ERROR: Could not get file "..v.path)
    else
      fs.open(v.path, "w+")
      fs.write(r.readAll())
    end
  end
  
  manifestFile = fs.open("manifest.json", "w+")
  manifestFile.write(json.encode(manifest))
  manifestFile.close()
  
  return true
end

function loadModules()
  
  local files
  
  if fs.isDir("modules") then
    files = fs.list("modules")
  end
  
  if not files or #files == 0 then
    print("No modules to load")
    return
  end
  
  local awaitingInit = {}
  
  for i,v in ipairs(files) do
    print("Loading module "..v)
    local moduleFunc, moduleInitFunc = require "modules/"..v
    
    if type(moduleFunc) == "function" then
      print("Registered listener for module "..v)
      table.insert(modules, moduleFunc)
    else
      print("Did not register a listener for module "..v)
    end
    
    if type(moduleInitFunc) == "function" then
      table.insert(awaitingInit, moduleInitFunc)
    end
    
  end
  
  for i,v in ipairs(awaitingInit) do
    v()
  end
  
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