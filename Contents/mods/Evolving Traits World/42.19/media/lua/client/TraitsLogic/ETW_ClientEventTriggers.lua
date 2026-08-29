local ETW_CommonFunctions = require("ETW_CommonFunctions")
local ETW_Registry = require("ETW_Registry")
local ETW_NearbyZombieScanner = require("TraitsLogic/ETW_NearbyZombieScanner")

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
local INDEFATIGABLE_TRIGGER_RADIUS_SQUARED = INDEFATIGABLE_TRIGGER_RADIUS * INDEFATIGABLE_TRIGGER_RADIUS
local INDEFATIGABLE_KNOCKDOWN_RADIUS_SQUARED = INDEFATIGABLE_KNOCKDOWN_RADIUS
	* INDEFATIGABLE_KNOCKDOWN_RADIUS
local INDEFATIGABLE_SCANNER_CONSUMER_ID = "Indefatigable"
local indefatigableNearbyCount = 0
local indefatigableKnockdownTargets = {}

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

---Returns whether Indefatigable currently needs nearby-zombie information.
---@param player IsoPlayer
---@return boolean
local function indefatigableScanEnabled(player)
	if not player:hasTrait(ETWTraitsRegistry.INDEFATIGABLE) then
		indefatigableCrowdRequestSent = false
		return false
	end
	local modData = ETW_CommonFunctions.getETWModData(player)
	if not modData then
		return false
	end
	local maximumUses = math.max(0, math.floor(SandboxVars.EvolvingTraitsWorld.IndefatigableUses or 1))
	if maximumUses > 0 and modData.IndefatigableUses >= maximumUses then
		return false
	end
	if getGameTime():getWorldAgeHours() < modData.IndefatigableCooldownUntilHours then
		return false
	end
	return true
end

---Clears Indefatigable's accumulated results before the shared traversal.
local function beginIndefatigableScan()
	indefatigableNearbyCount = 0
	for i = #indefatigableKnockdownTargets, 1, -1 do
		indefatigableKnockdownTargets[i] = nil
	end
end

---Collects Indefatigable's crowd count and knockdown targets from one shared traversal.
---@param _ IsoPlayer
---@param zombie IsoZombie
---@param distanceSquared number
local function inspectZombieForIndefatigable(_, zombie, distanceSquared)
	if distanceSquared <= INDEFATIGABLE_TRIGGER_RADIUS_SQUARED then
		indefatigableNearbyCount = indefatigableNearbyCount + 1
	end
	if distanceSquared <= INDEFATIGABLE_KNOCKDOWN_RADIUS_SQUARED and not zombie:isKnockedDown() then
		table.insert(indefatigableKnockdownTargets, zombie)
	end
end

---Reports MT-style client crowd detection before MP drag-down death can begin.
---@param player IsoPlayer
local function finishIndefatigableScan(player)
	if indefatigableNearbyCount < 4 then
		indefatigableCrowdRequestSent = false
		return
	end
	if indefatigableCrowdRequestSent then
		return
	end
	indefatigableCrowdRequestSent = true
	for _, zombie in ipairs(indefatigableKnockdownTargets) do
		ETW_CommonFunctions.triggerBouncerStagger(player, zombie, true)
	end
	sendClientCommand(player, "ETW", "triggerIndefatigableCrowd", { nearbyCount = indefatigableNearbyCount })
	logETW(
		"ETW Logger | indefatigableCrowdTriggerOnServer(): requested preemptive activation; zombies within 1.5 tiles: "
			.. indefatigableNearbyCount
			.. "; locally knocked down within "
			.. INDEFATIGABLE_KNOCKDOWN_RADIUS
			.. " tiles: "
			.. #indefatigableKnockdownTargets
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
ETW_NearbyZombieScanner.unregister(INDEFATIGABLE_SCANNER_CONSUMER_ID)
ETW_NearbyZombieScanner.register(INDEFATIGABLE_SCANNER_CONSUMER_ID, {
	radius = INDEFATIGABLE_KNOCKDOWN_RADIUS,
	isEnabled = indefatigableScanEnabled,
	beforeScan = beginIndefatigableScan,
	onZombie = inspectZombieForIndefatigable,
	afterScan = finishIndefatigableScan,
})
