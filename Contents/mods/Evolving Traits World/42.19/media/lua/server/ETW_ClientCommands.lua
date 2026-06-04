local ETWCombinedTraitChecks = require("ETW_CombinedTraitChecks")
local ETW_CommonLogicChecks = require("ETW_CommonLogicChecks")

---@type ETW_CommonFunctions
local ETW_CommonFunctions = require("ETW_CommonFunctions")

local gameMode = ETW_CommonFunctions.gameMode()
local Commands = {}

local FILENAME = "ETW_ClientCommands.lua"
if
	not ETW_CommonFunctions.gameModeSafeguard(
		FILENAME,
		{ ETW_CommonFunctions.GameMode.SP, ETW_CommonFunctions.GameMode.MP_SERVER }
	)
then
	return
end

---@type fun(...: any)
local logETW = ETW_CommonFunctions.log

---@class EngineCheckArgs
---@field vehicleID number
---@field conditionBefore number

---Function to check by how much engine was repaired. If SP - updates relative moddata and checks traits. If MP - sends command back to client
---@param player IsoPlayer
---@param args EngineCheckArgs
function Commands.checkEngineCondition(player, args)
	local vehicle = getVehicleById(args.vehicleID)
	local part = vehicle:getPartById("Engine")
	if not part then
		return
	end
	local condition = part:getCondition()
	local repairedPercentage = condition - args.conditionBefore
	logETW("ETW Logger | Commands.checkEngineCondition(): args.condition: " .. condition)
	if gameMode == ETW_CommonFunctions.GameMode.SP then
		---@type EvolvingTraitsWorldModData
		local modData = player:getModData().EvolvingTraitsWorld
		modData.VehiclePartRepairs = modData.VehiclePartRepairs + repairedPercentage
		logETW(
			"ETW Logger | Commands.checkEngineCondition(): modData.VehiclePartRepairs: " .. modData.VehiclePartRepairs
		)
		if ETW_CommonLogicChecks.BodyWorkEnthusiastShouldExecute(player) then
			ETWCombinedTraitChecks.bodyworkEnthusiastCheck(player)
		end
		if ETW_CommonLogicChecks.MechanicsShouldExecute(player) then
			ETWCombinedTraitChecks.mechanicsCheck(args.DebugAndNotificationArgs)
		end
	elseif gameMode == ETW_CommonFunctions.GameMode.MP_SERVER then
		local serverArgs = { repairedPercentage = repairedPercentage }
		sendServerCommand(player, "ETW", "carRepairCheck", serverArgs)
	end
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
