local Commands = {}

---@type ETW_CommonFunctions
local ETW_CommonFunctions = require("ETW_CommonFunctions")

local gameMode = ETW_CommonFunctions.gameMode()

-- This should be ran only if it's SP or if it's mp Client
if gameMode == ETW_CommonFunctions.GameMode.MP_SERVER then
	print("ETW_ModDataClient | Detected " .. gameMode .. " environment, skipping the file")
	return
else
	print("ETW_ModDataClient | Detected " .. gameMode .. " environment, loading the file")
end

local ETW_ModData = require("ETW_ModData")

local gameMode = ETW_CommonFunctions.gameMode()

Commands.refreshETWModDataFromServer = function(player, args)
	local player = getPlayer()
	ETW_CommonFunctions.log("ETW Logger | Commands.refreshETWModDataFromServer received updating modData")
	player:getModData().EvolvingTraitsWorld = args.ETWModData
end

Commands.OnServerCommand = function(module, command, args)
	if module == "ETW" and Commands[command] then
		local argStr = ""
		args = args or {}
		for k, v in pairs(args) do
			argStr = argStr .. " " .. k .. "=" .. tostring(v)
		end
		Commands[command](player, args)
	end
end

local function initializeModDataOnServer(playerIndex, player)
	print("ETW Logger | System: initializing modData for player " .. player:getUsername() .. " on server")
	sendClientCommand(player, "ETW", "createETWModData", {})
end

local function delayedETWCommandAfterPlayerSpawned()
	local player = getPlayer()
	if player then
		initializeModDataOnServer(0, player)
		Events.OnTick.Remove(delayedETWCommandAfterPlayerSpawned)
	end
end

if gameMode == ETW_CommonFunctions.GameMode.SP then
	Events.OnCreatePlayer.Remove(ETW_ModData.createETWModData)
	Events.OnCreatePlayer.Add(ETW_ModData.createETWModData)
	Events.OnPlayerDeath.Remove(ETW_ModData.clearETWModData)
	Events.OnPlayerDeath.Add(ETW_ModData.clearETWModData)
elseif gameMode == ETW_CommonFunctions.GameMode.MP_CLIENT then
	Events.OnTick.Remove(delayedETWCommandAfterPlayerSpawned)
	Events.OnTick.Add(delayedETWCommandAfterPlayerSpawned)
	Events.OnServerCommand.Add(Commands.OnServerCommand)
end
