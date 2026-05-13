---@type ETW_CommonFunctions
local ETW_CommonFunctions = require("ETW_CommonFunctions")

---@type ETW_ModData
local ETW_ModData = require("ETW_ModData")

local Commands = {}

local gameMode = ETW_CommonFunctions.gameMode()

-- This should be ran only if it's SP or if it's a server process
if gameMode ~= ETW_CommonFunctions.GameMode.MP_SERVER then
	ETW_CommonFunctions.log("ETW_ModDataServer | Detected " .. gameMode .. " environment, skipping the file")
	return
else
	ETW_CommonFunctions.log("ETW_ModDataServer | Detected " .. gameMode .. " environment, loading the file")
end

local function refreshETWModDataForAllClients()
	local onlinePlayers = getOnlinePlayers()

	for i = 0, onlinePlayers:size() - 1 do
		local player = onlinePlayers:get(i)
		ETW_CommonFunctions.log("ETW Logger | System: refreshing modData for player " .. player:getUsername())
		local modData = ETW_CommonFunctions.getETWModData(player)
		sendServerCommand(player, "ETW", "refreshETWModDataFromServer", { ETWModData = modData })
	end
end

Events.EveryOneMinute.Remove(refreshETWModDataForAllClients)
Events.EveryOneMinute.Add(refreshETWModDataForAllClients)

---@param player IsoPlayer
---@param args any
function Commands.createETWModData(player, args)
	ETW_CommonFunctions.log(
		"ETW Logger | System: character " .. player:getUsername() .. " was created, received command to create its ETW modData"
	)
	ETW_ModData.createETWModData(player:getPlayerNum(), player)
end

---@param player IsoPlayer
---@param args any
function Commands.clearETWModData(player, args)
	ETW_CommonFunctions.log("ETW Logger | System: character " .. player:getUsername() .. " died, received command to clear its ETW modData")
	ETW_ModData.clearETWModData(player)
end

Commands.OnClientCommand = function(module, command, player, args)
	if module == "ETW" and Commands[command] then
		local argStr = ""
		args = args or {}
		for k, v in pairs(args) do
			argStr = argStr .. " " .. k .. "=" .. tostring(v)
		end
		Commands[command](player, args)
	end
end

Events.OnClientCommand.Add(Commands.OnClientCommand)
