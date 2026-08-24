local ETW_CommonFunctions = require("ETW_CommonFunctions")
local ETW_Registry = require("ETW_Registry")

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

---Reports client-authoritative firearm aiming for Anti-Gun Activist's server-authoritative mood effect.
local function antiGunAimingMoodOnServer()
	local player = getPlayer()
	if
		not player
		or not player:hasTrait(ETWTraitsRegistry.ANTI_GUN_ACTIVIST)
		or not player:isAiming()
	then
		return
	end
	local weapon = player:getPrimaryHandItem()
	if not weapon or not instanceof(weapon, "HandWeapon") or weapon:getSubCategory() ~= "Firearm" then
		return
	end
	sendClientCommand(player, "ETW", "applyAntiGunAimingMood", {})
	logETW("ETW Logger | antiGunAimingMoodOnServer(): requested server mood effect while aiming " .. weapon:getFullType())
end

---Reports client-authoritative firearm aiming for Anti-Gun Activist's server-authoritative mood effect.
local function weaponSwingOnServer()
	local player = getPlayer()
	sendClientCommand(player, "ETW", "refreshEquippedWeaponTraits", {})
	logETW("ETW Logger | weaponSwingOnServer(): requested server weapon-trait refresh")
end


Events.OnWeaponSwing.Remove(weaponSwingOnServer)
Events.OnWeaponSwing.Add(weaponSwingOnServer)
Events.OnClothingUpdated.Remove(clothingRefreshOnServer)
Events.OnClothingUpdated.Add(clothingRefreshOnServer)
Events.OnPlayerDeath.Remove(deathRefreshOnServer)
Events.OnPlayerDeath.Add(deathRefreshOnServer)
Events.EveryOneMinute.Remove(antiGunAimingMoodOnServer)
Events.EveryOneMinute.Add(antiGunAimingMoodOnServer)
