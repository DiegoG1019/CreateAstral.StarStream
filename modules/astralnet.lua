-- Basically just receive a rednet request and return the requested item from queryable info

print("Initializing AstralNet Module")

StarStream.AstralNet = {}
StarStream.AstralNet.Query = function(uri, message, recipient, timeout)
  rednet.send(recipient, { ["uri"] = uri, ["body"] = message })
  return rednet.receive("astralnet-query-response", timeout)
end

return { function(event, sender_id, message, protocol)
  if event == "rednet_message" and sender_id and sender_id ~= os.getComputerID() and protocol == "astralnet-query" and type(message) == "table" then
    
    local uri = message.uri or ""
    local info = StarStream.queryableInfo[message.uri]
    if info then
      if type(info) == "function" then
        local resp, code = info(message.body)
        rednet.send(sender_id, { ["body"] = resp, ["code"] = code, ["tstamp"] = os.time() }, "astralnet-query-response")
      end
        
      rednet.send(sender_id, { ["body"] = info, ["code"] = 1, ["tstamp"] = os.time() }, "astralnet-query-response")
    else
      rednet.send(sender_id, nil, "astralnet-query-response")
    end
    
    return true
  end
end,

function()
  
  local endpoints = {}
  
  for k,v in pairs(StarStream.queryableInfo) do
    table.insert(endpoints, k)
  end
  
  if #endpoints > 0 then  
    table.insert(endpoints, endpoints)
    StarStream.queryableInfo.endpoints = endpoints
    StarStream.queryableInfo[""] = endpoints
    
    settings.define("astralnet.host", { description = "The hostname of this factory controller", default = nil, type = "string" })
    local hostname = tostring(settings.get("astralnet.host") or "")..":"..os.getComputerID()
    rednet.host("astralnet-query", hostname)
    
    print("Started hosting 'astralnet-query'")
  end
end }
