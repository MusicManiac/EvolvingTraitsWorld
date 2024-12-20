local ETWCombinedTraitChecks = require "ETWCombinedTraitChecks";
local ETWCommonLogicChecks = require "ETWCommonLogicChecks";

local Commands = {}

---@class EngineCheckArgs
---@field vehicleID number
---@field conditionBefore number
---@field detailedDebug boolean

---Function to check by how much engine was repaired. If SP - updates relative moddata and checks traits. If MP - sends command back to client
---@param player IsoPlayer
---@param args EngineCheckArgs
function Commands.checkEngineCondition(player, args)
	local vehicle = getVehicleById(args.vehicleID)
	local part = vehicle:getPartById("Engine")
	if not part then return; end
	local condition = part:getCondition();
	local repairedPercentage = condition - args.conditionBefore
	if args.detailedDebug then print("ETW Logger | Commands.checkEngineCondition(): args.condition: " .. condition) end;
	if not isClient() and not isServer() then
		local modData = player:getModData().EvolvingTraitsWorld;
		---@cast modData EvolvingTraitsWorldModData
		modData.VehiclePartRepairs = modData.VehiclePartRepairs + repairedPercentage;
		if args.detailedDebug then print("ETW Logger | Commands.checkEngineCondition(): modData.VehiclePartRepairs: " .. modData.VehiclePartRepairs) end;
		if ETWCommonLogicChecks.BodyWorkEnthusiastShouldExecute() then ETWCombinedTraitChecks.bodyworkEnthusiastCheck() end;
		if ETWCommonLogicChecks.MechanicsShouldExecute() then ETWCombinedTraitChecks.mechanicsCheck() end;
	else
		local serverArgs = { repairedPercentage = repairedPercentage };
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
