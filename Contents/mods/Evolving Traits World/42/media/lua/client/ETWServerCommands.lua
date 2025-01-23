require "ETWModData";
require "ETWModOptions";
local ETWCombinedTraitChecks = require("ETWCombinedTraitChecks");
local ETWCommonLogicChecks = require("ETWCommonLogicChecks");
local ETWCommonFunctions = require("ETWCommonFunctions");

local modOptions;

---Function responsible for setting up mod options on character load
---@param playerIndex number
---@param player IsoPlayer
local function initializeModOptions(playerIndex, player)
	modOptions = PZAPI.ModOptions:getOptions("ETWModOptions");
end

Events.OnCreatePlayer.Remove(initializeModOptions);
Events.OnCreatePlayer.Add(initializeModOptions);

---@return boolean
local notification = function() return modOptions:getOption("EnableNotifications"):getValue() end
---@return boolean
local delayedNotification = function() return modOptions:getOption("EnableDelayedNotifications"):getValue() end
---@return boolean
local detailedDebug = function() return modOptions:getOption("GatherDetailedDebug"):getValue() end

---Prints out debugs inside console if detailedDebug is enabled
---@param ... string Strings to log
local logETW = function(...) ETWCommonFunctions.log(...) end

local Commands = {}
Commands.ETW = {}

---@class CarRepairCheckArgs
---@field repairedPercentage number
---@field DebugAndNotificationArgs DebugAndNotificationArgs

---After engine was repaired on server side, client gets information from it and update relevant mod data and fire functions to check if player gets the trait.
---@param args CarRepairCheckArgs
Commands.ETW.carRepairCheck = function(args)
	local player = getPlayer();
	local modData = player:getModData().EvolvingTraitsWorld;
	---@type DebugAndNotificationArgs
	local DebugAndNotificationArgs = {detailedDebug = detailedDebug(), notification = notification(), delayedNotification = delayedNotification()};
	---@cast modData EvolvingTraitsWorldModData
	logETW("ETW Logger | Commands.ETW.carRepairCheck: args.repairedPercentage: " .. args.repairedPercentage);
	modData.VehiclePartRepairs = modData.VehiclePartRepairs + args.repairedPercentage;
	if ETWCommonLogicChecks.BodyWorkEnthusiastShouldExecute() then ETWCombinedTraitChecks.bodyworkEnthusiastCheck(DebugAndNotificationArgs) end
	if ETWCommonLogicChecks.MechanicsShouldExecute() then ETWCombinedTraitChecks.mechanicsCheck(DebugAndNotificationArgs) end
end

---Send debug settings to server
Commands.ETW.debugInfoRequest = function()
	local player = getPlayer();
	logETW("ETW Logger | Commands.ETW.debugInfoRequest recieved");
	local args = {detailedDebug = detailedDebug(), notification = notification(), delayedNotification = delayedNotification()};
	sendClientCommand(player, 'ETW', 'debugInfoReply', args);
end

Commands.OnServerCommand = function(module, command, args)
    if Commands[module] and Commands[module][command] then
        local argStr = ''
        for k, v in pairs(args) do argStr = argStr .. ' ' .. k .. '=' .. tostring(v) end
        print('received ' .. module .. ' ' .. command .. ' ' .. argStr)
        Commands[module][command](args)
    end
end

Events.OnServerCommand.Add(Commands.OnServerCommand)
