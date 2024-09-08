if not isClient() then return end;

require "ETWModData";
local ETWCombinedTraitChecks = require("ETWCombinedTraitChecks");
local ETWCommonLogicChecks = require "ETWCommonLogicChecks";

---@return boolean
local detailedDebug = function() return EvolvingTraitsWorld.settings.GatherDetailedDebug end;

local Commands = {}
Commands.ETW = {}

---@class CarRepairCheckArgs
---@field repairedPercentage number

---After engine was repaired on server side, client gets information from it and update relevant mod data and fire functions to check if player gets the trait.
---@param args CarRepairCheckArgs
Commands.ETW.carRepairCheck = function(args)
	local player = getPlayer();
	local modData = player:getModData().EvolvingTraitsWorld;
	---@cast modData EvolvingTraitsWorldModData
	if detailedDebug() then print("ETW Logger | Commands.ETW.carRepairCheck: args.repairedPercentage: " .. args.repairedPercentage) end;
	modData.VehiclePartRepairs = modData.VehiclePartRepairs + args.repairedPercentage;
	if ETWCommonLogicChecks.BodyWorkEnthusiastShouldExecute() then ETWCombinedTraitChecks.bodyworkEnthusiastCheck() end;
	if ETWCommonLogicChecks.MechanicsShouldExecute() then ETWCombinedTraitChecks.mechanicsCheck() end;
end

Commands.OnServerCommand = function(module, command, args)
    if Commands[module] and Commands[module][command] then
        local argStr = ''
        for k, v in pairs(args) do argStr = argStr .. ' ' .. k .. '=' .. tostring(v) end;
        print('received ' .. module .. ' ' .. command .. ' ' .. argStr)
        Commands[module][command](args)
    end
end

Events.OnServerCommand.Add(Commands.OnServerCommand)
