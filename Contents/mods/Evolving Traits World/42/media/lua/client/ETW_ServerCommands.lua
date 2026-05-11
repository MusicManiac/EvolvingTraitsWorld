local ETW_ModDataClient = require("ETW_ModData")
local ETW_CommonFunctions = require("ETW_CommonFunctions")

---@type fun(...: string)
local logETW = ETW_CommonFunctions.log

local FILENAME = "ETWServerCommands.lua"
if
	not ETW_CommonFunctions.gameModeSafeguard(
		FILENAME,
		{ ETW_CommonFunctions.GameMode.SP, ETW_CommonFunctions.GameMode.MP_CLIENT }
	)
then
	return
end

local Commands = {}

---@class DisplayTraitNotificationArgs
---@field traitRegistryId string the trait registry id of the trait
---@field arrowIsUp boolean whether the arrow in notification should be up or down, True for up, False for down
---@field color string color of the text in notification, "RED" or "GREEN"

---Displays trait gain/loss notification on client side. Server sends text, color, and arrow direction information to client, and client displays it in a notification.
---@param args DisplayTraitNotificationArgs
Commands.displayTraitNotification = function(player, args)
	player = player or getPlayer()
	logETW("ETW Logger | Commands.displayTraitNotification received")
	ETW_CommonFunctions.displayTraitNotification(player, args.traitRegistryId, args.arrowIsUp, args.color)
end

---@class DisplayDelayedTraitNotificationArgs
---@field gainingTrait boolean true if gaining trait, false if losing trait
---@field traitRegistryId string the trait registry id of the trait
---@field arrowIsUp boolean whether the arrow in notification should be up or down, True for up, False for down
---@field color string color of the text in notification, "RED" or "GREEN"

---Displays trait gain/loss notification on client side. Server sends text, color, and arrow direction information to client, and client displays it in a notification.
---@param args DisplayDelayedTraitNotificationArgs
Commands.displayDelayedTraitNotification = function(player, args)
	player = player or getPlayer()
	logETW("ETW Logger | Commands.displayDelayedTraitNotification received")
	ETW_CommonFunctions.displayDelayedTraitNotification(
		player,
		args.gainingTrait,
		args.traitRegistryId,
		args.arrowIsUp,
		args.color
	)
end

---Plays a trait sound if enabled in settings
Commands.traitSound = function(player, args)
	player = player or getPlayer()
	logETW("ETW Logger | Commands.traitSound received")
	ETW_CommonFunctions.traitSound(player)
end

Commands.OnServerCommand = function(module, command, args)
	if module == "ETW" and Commands[command] then
		local argStr = ""
		args = args or {}
		for k, v in pairs(args) do
			argStr = argStr .. " " .. k .. "=" .. tostring(v)
		end
		print("ETW Logger | Commands.OnServerCommand received command " .. command .. " with args " .. argStr)
		Commands[command](player, args)
	end
end

Events.OnServerCommand.Add(Commands.OnServerCommand)
