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

---Function responsible for refreshing modData from server when the local player is ready.
---@param player IsoPlayer
---@param args {ETWModData: table}
function Commands.refreshETWModDataFromServer(player, args)
	player = player or getPlayer()
	if not player or not player.getModData or not args then
		logETW("ETW Logger | Commands.refreshETWModDataFromServer(): player or args not ready, skipping update")
		return
	end
	local ok, modData = pcall(function()
		return player:getModData()
	end)
	if not ok or not modData then
		logETW("ETW Logger | Commands.refreshETWModDataFromServer(): getModData unavailable, skipping update")
		return
	end
	modData.EvolvingTraitsWorld = args.ETWModData
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
		Commands[command](getPlayer(), args)
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

---Function responsible for requesting ETW modData clear on the server after player death in MP.
---@param player IsoPlayer
local function requestServerClearETWModData(player)
	if not player then
		logETW("ETW Logger | requestServerClearETWModData(): player not ready, skipping clear request")
		return
	end
	logETW("ETW Logger | requestServerClearETWModData(): requesting ETW modData clear on server")
	sendClientCommand(player, "ETW", "clearETWModData", {})
end

if gameMode == ETW_CommonFunctions.GameMode.SP then
	Events.OnCreatePlayer.Remove(ETW_ModData.createETWModData)
	Events.OnCreatePlayer.Add(ETW_ModData.createETWModData)
	Events.OnPlayerDeath.Remove(ETW_ModData.clearETWModData)
	Events.OnPlayerDeath.Add(ETW_ModData.clearETWModData)
elseif gameMode == ETW_CommonFunctions.GameMode.MP_CLIENT then
	Events.OnTick.Remove(delayedETWCommandAfterPlayerSpawned)
	Events.OnTick.Add(delayedETWCommandAfterPlayerSpawned)
	Events.OnPlayerDeath.Remove(requestServerClearETWModData)
	Events.OnPlayerDeath.Add(requestServerClearETWModData)
	Events.OnServerCommand.Add(Commands.OnServerCommand)
end
