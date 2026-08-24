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
local indefatigableProtection

---Returns the local player when the passed player is invalid or not ready yet.
---@param player unknown
---@return IsoPlayer|nil
local function resolveLocalPlayer(player)
	if not player or type(player) ~= "userdata" or not player.getModData then
		player = getPlayer()
	end
	if not player or type(player) ~= "userdata" then
		return nil
	end
	return player
end

---@class DisplayTraitNotificationArgs
---@field traitRegistryId string the trait registry id of the trait
---@field arrowIsUp boolean whether the arrow in notification should be up or down, True for up, False for down
---@field color string color of the text in notification, "RED" or "GREEN"

---Displays trait gain/loss notification on client side. Server sends text, color, and arrow direction information to client, and client displays it in a notification.
---@param args DisplayTraitNotificationArgs
Commands.displayTraitNotification = function(player, args)
	player = resolveLocalPlayer(player)
	if not player then
		logETW("ETW Logger | Commands.displayTraitNotification(): player not ready, skipping")
		return
	end
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
	player = resolveLocalPlayer(player)
	if not player then
		logETW("ETW Logger | Commands.displayDelayedTraitNotification(): player not ready, skipping")
		return
	end
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
	player = resolveLocalPlayer(player)
	if not player then
		logETW("ETW Logger | Commands.traitSound(): player not ready, skipping")
		return
	end
	logETW("ETW Logger | Commands.traitSound received")
	ETW_CommonFunctions.traitSound(player)
end

---Displays the Butterfingers effect popup if enabled in this client's mod options.
Commands.displayButterfingersPopup = function(player, args)
	player = resolveLocalPlayer(player)
	if not player then
		logETW("ETW Logger | Commands.displayButterfingersPopup(): player not ready, skipping")
		return
	end
	ETW_CommonFunctions.displayButterfingersPopup(player)
end

---Executes the owning client's Butterfingers held-item drop so MP inventory changes synchronize correctly.
Commands.dropButterfingersHandItems = function(player, args)
	player = resolveLocalPlayer(player)
	if not player then
		logETW("ETW Logger | Commands.dropButterfingersHandItems(): player not ready, skipping")
		return
	end
	local primaryItem = player:getPrimaryHandItem()
	local secondaryItem = player:getSecondaryHandItem()
	player:dropHandItems()
	logETW(
		"ETW Logger | Commands.dropButterfingersHandItems(): executed; primary: "
			.. (primaryItem and primaryItem:getFullType() or "nil")
			.. ", secondary: "
			.. (secondaryItem and secondaryItem:getFullType() or "nil")
	)
end

---Applies the Noodle Legs bump state on the owning client.
Commands.triggerNoodleLegsTrip = function(player, args)
	player = resolveLocalPlayer(player)
	if not player then
		logETW("ETW Logger | Commands.triggerNoodleLegsTrip(): player not ready, skipping")
		return
	end
	local side = args.side == "right" and "right" or "left"
	ETW_CommonFunctions.triggerNoodleLegsTrip(player, side)
end

---Mirrors a server-authoritative Bouncer stagger on the owning client.
Commands.triggerBouncerStagger = function(player, args)
	local zombieOnlineID = tonumber(args.zombieOnlineID)
	if not zombieOnlineID then
		logETW("ETW Logger | Commands.triggerBouncerStagger(): invalid zombie OnlineID, skipping")
		return
	end
	local zombies = getCell():getZombieList()
	for i = 0, zombies:size() - 1 do
		local zombie = zombies:get(i)
		if zombie:getOnlineID() == zombieOnlineID then
			zombie:setStaggerBack(true)
			if args.knockDown == true then
				zombie:setKnockedDown(true)
			end
			logETW(
				"ETW Logger | Commands.triggerBouncerStagger(): mirrored stagger; zombie OnlineID="
					.. zombieOnlineID
					.. "; knockdown: "
					.. tostring(args.knockDown == true)
			)
			return
		end
	end
	logETW(
		"ETW Logger | Commands.triggerBouncerStagger(): zombie not found; OnlineID=" .. zombieOnlineID
	)
end

---Mirrors Unwavering's wound movement-speed modifiers on the owning MP client.
Commands.applyUnwaveringInjurySpeedModifiers = function(player, args)
	player = resolveLocalPlayer(player)
	if not player then
		logETW("ETW Logger | Commands.applyUnwaveringInjurySpeedModifiers(): player not ready, skipping")
		return
	end
	local affectedParts = ETW_CommonFunctions.applyUnwaveringInjurySpeedModifiers(
		player:getBodyDamage(),
		tonumber(args.scratchModifier) or 30,
		tonumber(args.cutModifier) or 30,
		tonumber(args.deepWoundModifier) or 60,
		tonumber(args.burnModifier) or 60
	)
	logETW(
		"ETW Logger | Commands.applyUnwaveringInjurySpeedModifiers(): applied locally; body parts: "
			.. affectedParts
	)
end

---Starts the owning client's local mirror of Indefatigable's wound-movement protection.
Commands.startIndefatigableProtection = function(player, args)
	player = resolveLocalPlayer(player)
	if not player then
		logETW("ETW Logger | Commands.startIndefatigableProtection(): player not ready, skipping")
		return
	end
	local bodyDamage = player:getBodyDamage()
	if not indefatigableProtection or indefatigableProtection.player ~= player then
		indefatigableProtection = {
			player = player,
			woundSpeedModifiers = type(args.woundSpeedModifiers) == "table"
				and args.woundSpeedModifiers
				or ETW_CommonFunctions.captureWoundSpeedModifiers(bodyDamage),
		}
	end
	local durationMs = math.max(0, tonumber(args.durationMs) or 120000)
	indefatigableProtection.expiresAt = getTimestampMs() + durationMs
	local modData = ETW_CommonFunctions.getETWModData(player)
	if modData then
		modData.IndefatigableUses = math.max(0, math.floor(tonumber(args.uses) or 0))
		modData.IndefatigableCooldownUntilHours = tonumber(args.cooldownUntilHours) or 0
	end
	ETW_CommonFunctions.suppressWoundMovementPenalties(bodyDamage)
	logETW(
		"ETW Logger | Commands.startIndefatigableProtection(): started local protection for "
			.. tostring(player:getUsername())
			.. "; duration: "
			.. durationMs
			.. " ms; authoritative uses: "
			.. tostring(args.uses)
			.. "; cooldown until world age hour: "
			.. tostring(args.cooldownUntilHours)
	)
end

---Maintains and restores the owning client's temporary wound-speed modifiers.
local function updateIndefatigableProtection()
	local protection = indefatigableProtection
	if not protection then
		return
	end
	local player = protection.player
	if not player then
		indefatigableProtection = nil
		return
	end
	local bodyDamage = player:getBodyDamage()
	if getTimestampMs() >= (protection.expiresAt or 0) then
		ETW_CommonFunctions.restoreWoundSpeedModifiers(bodyDamage, protection.woundSpeedModifiers)
		indefatigableProtection = nil
		logETW(
			"ETW Logger | updateIndefatigableProtection(): restored local wound-speed modifiers for "
				.. tostring(player:getUsername())
		)
		return
	end
	ETW_CommonFunctions.suppressWoundMovementPenalties(bodyDamage)
end

---@param player IsoPlayer
local function clearIndefatigableProtection(player)
	local protection = indefatigableProtection
	if not protection then
		return
	end
	player = resolveLocalPlayer(player) or protection.player
	if player then
		ETW_CommonFunctions.restoreWoundSpeedModifiers(
			player:getBodyDamage(),
			protection.woundSpeedModifiers
		)
	end
	indefatigableProtection = nil
end

Commands.OnServerCommand = function(module, command, args)
	if module == "ETW" and Commands[command] then
		local argStr = ""
		args = args or {}
		for k, v in pairs(args) do
			argStr = argStr .. " " .. k .. "=" .. tostring(v)
		end
		print("ETW Logger | Commands.OnServerCommand received command " .. command .. " with args " .. argStr)
		Commands[command](getPlayer(), args)
	end
end

Events.OnServerCommand.Add(Commands.OnServerCommand)
Events.OnTick.Remove(updateIndefatigableProtection)
Events.OnTick.Add(updateIndefatigableProtection)
Events.OnPlayerDeath.Remove(clearIndefatigableProtection)
Events.OnPlayerDeath.Add(clearIndefatigableProtection)
