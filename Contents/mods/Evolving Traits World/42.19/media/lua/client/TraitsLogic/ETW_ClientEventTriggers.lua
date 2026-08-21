local ETW_CommonFunctions = require("ETW_CommonFunctions")
local ETW_Registry = require("ETW_Registry")

local FILENAME = "ETW_ClientEventTriggers.lua"
if not ETW_CommonFunctions.gameModeSafeguard(FILENAME, { ETW_CommonFunctions.GameMode.MP_CLIENT }) then
	return
end

local logETW = ETW_CommonFunctions.log
---@type EvolvingTraitsWorldTraitsRegistries
local ETWTraitsRegistry = ETW_Registry.traits

---@param character IsoGameCharacter
local function clothingRefreshOnServer(character)
	if not character or not instanceof(character, "IsoPlayer") or not character:isLocalPlayer() then
		return
	end
	local player = character
	---@cast player IsoPlayer
	sendClientCommand(player, "ETW", "refreshClothingTraits", {})
	logETW("ETW Logger | clothingRefreshOnServer(): requested server clothing-trait refresh")
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
	logETW("ETW Logger | antigun mood client: requested server mood effect while aiming " .. weapon:getFullType())
end

Events.OnClothingUpdated.Remove(clothingRefreshOnServer)
Events.OnClothingUpdated.Add(clothingRefreshOnServer)
Events.OnPlayerDeath.Remove(clothingRefreshOnServer)
Events.OnPlayerDeath.Add(clothingRefreshOnServer)
Events.EveryOneMinute.Remove(antiGunAimingMoodOnServer)
Events.EveryOneMinute.Add(antiGunAimingMoodOnServer)
