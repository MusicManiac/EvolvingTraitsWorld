local ETW_CommonFunctions = require("ETW_CommonFunctions")
local ETW_Registry = require("ETW_Registry")
local ETWCombinedTraitChecks = require("ETW_CombinedTraitFunctions")

local FILENAME = "ETW_ClientEventTriggers.lua"
if
	not ETW_CommonFunctions.gameModeSafeguard(
		FILENAME,
		{ ETW_CommonFunctions.GameMode.MP_CLIENT }
	)
then
	return
end

local logETW = ETW_CommonFunctions.log
---@type EvolvingTraitsWorldTraitsRegistries
local ETWTraitsRegistry = ETW_Registry.traits
local lastClothingRefreshRequest
local indefatigableCrowdRequestSent = false
local INDEFATIGABLE_TRIGGER_RADIUS = 1.5
local INDEFATIGABLE_KNOCKDOWN_RADIUS = 2.5

---@param character IsoGameCharacter
---@param source string
local function equippedItemTraitsRefreshOnServer(character, source)
	if not character or not instanceof(character, "IsoPlayer") or not character:isLocalPlayer() then
		return
	end
	local player = character
	---@cast player IsoPlayer
	sendClientCommand(player, "ETW", "refreshEquippedItemTraits", {})
	logETW(
		"ETW Logger | equippedItemTraitsRefreshOnServer(): requested server item-trait refresh; source: "
			.. source
	)
end

---@param character IsoGameCharacter
local function clothingRefreshOnServer(character)
	if not character or not instanceof(character, "IsoPlayer") or not character:isLocalPlayer() then
		return
	end
	local now = getTimestampMs()
	if lastClothingRefreshRequest and now < lastClothingRefreshRequest + 1000 then
		logETW(
			"ETW Logger | clothingRefreshOnServer(): throttled refresh request"
		)
		return
	end
	lastClothingRefreshRequest = now
	equippedItemTraitsRefreshOnServer(character, "clothing updated")
end

---@param character IsoGameCharacter
local function deathRefreshOnServer(character)
	equippedItemTraitsRefreshOnServer(character, "player death")
end

---Reports client-authoritative firearm aiming for server-authoritative firearm-trait mood effects.
local function firearmAimingMoodOnServer()
	local player = getPlayer()
	if
		not player
		or (
			not player:hasTrait(ETWTraitsRegistry.ANTI_GUN_ACTIVIST)
			and not player:hasTrait(ETWTraitsRegistry.TERMINATOR)
		)
		or not player:isAiming()
	then
		return
	end
	local weapon = player:getPrimaryHandItem()
	if not weapon or not instanceof(weapon, "HandWeapon") or weapon:getSubCategory() ~= "Firearm" then
		return
	end
	local command = player:hasTrait(ETWTraitsRegistry.TERMINATOR)
		and "applyTerminatorAimingMood"
		or "applyAntiGunAimingMood"
	sendClientCommand(player, "ETW", command, {})
	logETW(
		"ETW Logger | firearmAimingMoodOnServer(): requested "
			.. command
			.. " while aiming "
			.. weapon:getFullType()
	)
end

---Requests a server refresh for weapon traits after a client-authoritative swing.
local function weaponSwingOnServer()
	local player = getPlayer()
	sendClientCommand(player, "ETW", "refreshEquippedWeaponTraits", {})
	logETW("ETW Logger | weaponSwingOnServer(): requested server weapon-trait refresh")
end

---Reports MT-style client crowd detection before MP drag-down death can begin.
local function indefatigableCrowdTriggerOnServer()
	local player = getPlayer()
	if not player or not player:hasTrait(ETWTraitsRegistry.INDEFATIGABLE) then
		indefatigableCrowdRequestSent = false
		return
	end
	local modData = ETW_CommonFunctions.getETWModData(player)
	if not modData then
		return
	end
	local maximumUses = math.max(0, math.floor(SandboxVars.EvolvingTraitsWorld.IndefatigableUses or 1))
	if maximumUses > 0 and (modData.IndefatigableUses or 0) >= maximumUses then
		return
	end
	if getGameTime():getWorldAgeHours() < (modData.IndefatigableCooldownUntilHours or 0) then
		return
	end
	local nearbyCount = ETWCombinedTraitChecks.forEachNearbyLivingZombie(
		player,
		INDEFATIGABLE_TRIGGER_RADIUS,
		nil
	)
	if nearbyCount < 4 then
		indefatigableCrowdRequestSent = false
		return
	end
	if indefatigableCrowdRequestSent then
		return
	end
	indefatigableCrowdRequestSent = true
	local knockdownTargets = {}
	ETWCombinedTraitChecks.forEachNearbyLivingZombie(
		player,
		INDEFATIGABLE_KNOCKDOWN_RADIUS,
		function(zombie)
			if not zombie:isKnockedDown() then
				table.insert(knockdownTargets, zombie)
			end
		end
	)
	for _, zombie in ipairs(knockdownTargets) do
		ETW_CommonFunctions.triggerBouncerStagger(player, zombie, true)
	end
	sendClientCommand(player, "ETW", "triggerIndefatigableCrowd", { nearbyCount = nearbyCount })
	logETW(
		"ETW Logger | indefatigableCrowdTriggerOnServer(): requested preemptive activation; zombies within 1.5 tiles: "
			.. nearbyCount
			.. "; locally knocked down within "
			.. INDEFATIGABLE_KNOCKDOWN_RADIUS
			.. " tiles: "
			.. #knockdownTargets
	)
end


Events.OnWeaponSwing.Remove(weaponSwingOnServer)
Events.OnWeaponSwing.Add(weaponSwingOnServer)
Events.OnClothingUpdated.Remove(clothingRefreshOnServer)
Events.OnClothingUpdated.Add(clothingRefreshOnServer)
Events.OnPlayerDeath.Remove(deathRefreshOnServer)
Events.OnPlayerDeath.Add(deathRefreshOnServer)
Events.EveryOneMinute.Remove(firearmAimingMoodOnServer)
Events.EveryOneMinute.Add(firearmAimingMoodOnServer)
Events.OnTick.Remove(indefatigableCrowdTriggerOnServer)
Events.OnTick.Add(indefatigableCrowdTriggerOnServer)
