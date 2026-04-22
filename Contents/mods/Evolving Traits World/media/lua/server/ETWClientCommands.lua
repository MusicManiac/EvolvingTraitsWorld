local ETWCombinedTraitChecks = require "ETWCombinedTraitChecks"
local ETWCommonLogicChecks = require "ETWCommonLogicChecks"
local CommonFunctions = require "ETW_CommonFunctions"

local Commands = {}

---Function to check by how much engine was repaired. If SP - updates relative moddata and checks traits. If MP - sends command back to client
---@param player IsoPlayer
---@param args EngineCheckArgs
function Commands.checkEngineCondition(player, args)
	local vehicle = getVehicleById(args.vehicleID)
	local part = vehicle:getPartById("Engine")
	if not part then return; end
	local condition = part:getCondition()
	local repairedPercentage = condition - args.conditionBefore
	CommonFunctions.log("ETW Logger | Commands.checkEngineCondition(): args.condition: " .. condition)
	if not isClient() and not isServer() then
		local modData = player:getModData().EvolvingTraitsWorld;
		---@cast modData EvolvingTraitsWorldModData
		modData.VehiclePartRepairs = modData.VehiclePartRepairs + repairedPercentage;
		CommonFunctions.log("ETW Logger | Commands.checkEngineCondition(): modData.VehiclePartRepairs: " .. modData.VehiclePartRepairs)
		if ETWCommonLogicChecks.BodyWorkEnthusiastShouldExecute() then ETWCombinedTraitChecks.bodyworkEnthusiastCheck() end
		if ETWCommonLogicChecks.MechanicsShouldExecute() then ETWCombinedTraitChecks.mechanicsCheck() end
	else
		local serverArgs = { repairedPercentage = repairedPercentage }
		sendServerCommand(player, "ETW", "carRepairCheck", serverArgs)
	end
end

Commands.OnClientCommand = function(module, command, player, args)
	if module == 'ETW' and Commands[command] then
		local argStr = ''
		args = args or {}
		for k,v in pairs(args) do
			argStr = argStr..' '..k..'='..tostring(v)
		end
		Commands[command](player, args)
	end
end

Events.OnClientCommand.Add(Commands.OnClientCommand)
