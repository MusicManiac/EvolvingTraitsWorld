---@type ETW_CommonFunctions
local ETW_CommonFunctions = require("ETW_CommonFunctions")
local ETW_ModData = require("ETW_ModData")

local FILENAME = "ETW_ModDataClient.lua"
if
	not ETW_CommonFunctions.gameModeSafeguard(
		FILENAME,
		{ ETW_CommonFunctions.GameMode.SP, ETW_CommonFunctions.GameMode.MP_CLIENT }
	)
then
	return
end

local gameMode = ETW_CommonFunctions.gameMode()
local Commands = {}

---@type fun(...: string)
local logETW = ETW_CommonFunctions.log

---Function responsible for refreshing modData from server
---@param player IsoPlayer
---@param args {ETWModData: table}
function Commands.refreshETWModDataFromServer(player, args)
	player = player or getPlayer()
	--- logETW("ETW Logger | Commands.refreshETWModDataFromServer received updating modData")
	player:getModData().EvolvingTraitsWorld = args.ETWModData
end

---Function responsible for handling server commands
---@param module string
---@param command string
---@param args {string: any}
function Commands.OnServerCommand(module, command, args)
	if module == "ETW" and Commands[command] then
		local argStr = ""
		args = args or {}
		for k, v in pairs(args) do
			argStr = argStr .. " " .. k .. "=" .. tostring(v)
		end
		Commands[command](player, args)
	end
end

---Function responsible for initializing modData on server
---@param playerIndex number
---@param player IsoPlayer
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
