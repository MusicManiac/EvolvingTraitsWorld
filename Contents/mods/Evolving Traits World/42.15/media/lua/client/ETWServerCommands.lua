require("ETW_ModData")
require("ETWModOptions")
local ETWCombinedTraitChecks = require("ETWCombinedTraitChecks")
local ETW_CommonLogicChecks = require("ETW_CommonLogicChecks")
local ETW_CommonFunctions = require("ETW_CommonFunctions")

local modOptions

---Function responsible for setting up mod options on character load
---@param playerIndex number
---@param player IsoPlayer
local function initializeModOptions(playerIndex, player)
	modOptions = PZAPI.ModOptions:getOptions("ETWModOptions")
end

Events.OnCreatePlayer.Remove(initializeModOptions)
Events.OnCreatePlayer.Add(initializeModOptions)

---@return boolean
local notification = function()
	return modOptions:getOption("EnableNotifications"):getValue()
end
---@return boolean
local delayedNotification = function()
	return modOptions:getOption("EnableDelayedNotifications"):getValue()
end
---@return boolean
local detailedDebug = function()
	return modOptions:getOption("GatherDetailedDebug"):getValue()
end

---Prints out debugs inside console if detailedDebug is enabled
---@param ... string Strings to log
local logETW = function(...)
	ETW_CommonFunctions.log(...)
end

local Commands = {}
Commands = {}

---@class CarRepairCheckArgs
---@field repairedPercentage number
---@field DebugAndNotificationArgs DebugAndNotificationArgs

---After engine was repaired on server side, client gets information from it and update relevant mod data and fire functions to check if player gets the trait.
---@param args CarRepairCheckArgs
Commands.carRepairCheck = function(args)
	local player = getPlayer()
	local modData = ETW_CommonFunctions.getETWModData(player)
	---@type DebugAndNotificationArgs
	local DebugAndNotificationArgs =
		{ detailedDebug = detailedDebug(), notification = notification(), delayedNotification = delayedNotification() }
	logETW("ETW Logger | Commands.carRepairCheck: args.repairedPercentage: " .. args.repairedPercentage)
	modData.VehiclePartRepairs = modData.VehiclePartRepairs + args.repairedPercentage
	if ETW_CommonLogicChecks.BodyWorkEnthusiastShouldExecute(player) then
		ETWCombinedTraitChecks.bodyworkEnthusiastCheck(DebugAndNotificationArgs)
	end
	if ETW_CommonLogicChecks.MechanicsShouldExecute(player) then
		ETWCombinedTraitChecks.mechanicsCheck(DebugAndNotificationArgs)
	end
end

---Send debug settings to server
Commands.debugInfoRequest = function()
	local player = getPlayer()
	logETW("ETW Logger | Commands.debugInfoRequest received")
	local args = { detailedDebug = detailedDebug(), notification = notification(), delayedNotification = delayedNotification() }
	sendClientCommand(player, "ETW", "debugInfoReply", args)
end

---@class DisplayTraitNotificationArgs
---@field text string text to show in notification
---@field arrowIsUp boolean whether the arrow in notification should be up or down, True for up, False for down
---@field color HaloTextHelper.ColorRGB color of the text in notification

---Displays trait gain/loss notification on client side. Server sends text, color, and arrow direction information to client, and client displays it in a notification.
---@param args DisplayTraitNotificationArgs
Commands.displayTraitNotification = function(args)
	local player = getPlayer()
	logETW("ETW Logger | Commands.displayTraitNotification received")
	if notification() then
		HaloTextHelper.addTextWithArrow(player, args.text, args.arrowIsUp, args.color)
	end
end

---@class DisplayDelayedTraitNotificationArgs
---@field text string text to show in notification
---@field arrowIsUp boolean whether the arrow in notification should be up or down, True for up, False for down
---@field color HaloTextHelper.ColorRGB color of the text in notification

---Displays trait gain/loss notification on client side. Server sends text, color, and arrow direction information to client, and client displays it in a notification.
---@param args DisplayDelayedTraitNotificationArgs
Commands.displayDelayedTraitNotification = function(args)
	local player = getPlayer()
	logETW("ETW Logger | Commands.displayDelayedTraitNotification received")
	if delayedNotification() then
		HaloTextHelper.addTextWithArrow(player, args.text, args.arrowIsUp, args.color)
	end
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

Events.OnServerCommand.Add(Commands.OnServerCommand)
