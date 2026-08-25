require("TimedActions/ISUnloadBulletsFromMagazine")

local ETW_CommonFunctions = require("ETW_CommonFunctions")
local ETW_Registry = require("ETW_Registry")
local ETW_CombatTraits = require("TraitsLogic/ETW_CombatTraits")

local FILENAME = "ETW_ISUnloadBulletsFromMagazineOverrideServer.lua"
if
	not ETW_CommonFunctions.gameModeSafeguard(
		FILENAME,
		{ ETW_CommonFunctions.GameMode.SP, ETW_CommonFunctions.GameMode.MP_SERVER }
	)
then
	return
end

---@type EvolvingTraitsWorldTraitsRegistries
local ETWTraitsRegistry = ETW_Registry.traits
---@type EvolvingTraitsWorldSandboxVars
local SBvars = SandboxVars.EvolvingTraitsWorld
local logETW = ETW_CommonFunctions.log

local original_ISUnloadBulletsFromMagazine_animEvent = ISUnloadBulletsFromMagazine.animEvent

---Adds Anti-Gun Activist unhappiness after vanilla successfully removes a magazine round.
function ISUnloadBulletsFromMagazine:animEvent(event, parameter)
	local player = self.character
	local shouldProcess = event == "RemoveBullet"
		and instanceof(player, "IsoPlayer")
		and player:hasTrait(ETWTraitsRegistry.ANTI_GUN_ACTIVIST)
	local ammoBefore
	if shouldProcess then
		ammoBefore = self.magazine:getCurrentAmmoCount()
	end

	local originalReturn = original_ISUnloadBulletsFromMagazine_animEvent(self, event, parameter)
	if not shouldProcess or self.magazine:getCurrentAmmoCount() >= ammoBefore then
		return originalReturn
	end

	ETW_CombatTraits.antiGunMentalTrait(
		player,
		player:getStats(),
		SBvars.AntiGunMagazineHandlingUnhappinessPerBullet or 0.1,
		"magazine unloading"
	)
	logETW(
		"ETW Logger | Anti-gun | ISUnloadBulletsFromMagazine:animEvent(): bullet removed for "
			.. tostring(player:getUsername())
			.. " (OnlineID="
			.. player:getOnlineID()
			.. "); magazine ammo: "
			.. ammoBefore
			.. "->"
			.. self.magazine:getCurrentAmmoCount()
	)
	return originalReturn
end
