require("TimedActions/ISLoadBulletsInMagazine")

local ETW_CommonFunctions = require("ETW_CommonFunctions")
local ETW_Registry = require("ETW_Registry")
local ETWCombinedTraitChecks = require("ETW_CombinedTraitFunctions")
local ETW_FightingTraits = require("TraitsLogic/ETW_FightingTraits")

local FILENAME = "ETW_ISLoadBulletsInMagazineOverrideServer.lua"
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

local original_ISLoadBulletsInMagazine_animEvent = ISLoadBulletsInMagazine.animEvent

---Adds Anti-Gun Activist penalties after vanilla successfully inserts a magazine round.
function ISLoadBulletsInMagazine:animEvent(event, parameter)
	local player = self.character
	local shouldProcess = event == "InsertBullet"
		and instanceof(player, "IsoPlayer")
		and player:hasTrait(ETWTraitsRegistry.ANTI_GUN_ACTIVIST)
	local ammoBefore
	local reloadingXPBefore
	if shouldProcess then
		ammoBefore = self.magazine:getCurrentAmmoCount()
		reloadingXPBefore = player:getXp():getXP(Perks.Reloading)
	end

	local originalReturn = original_ISLoadBulletsInMagazine_animEvent(self, event, parameter)
	if not shouldProcess or self.magazine:getCurrentAmmoCount() <= ammoBefore then
		return originalReturn
	end

	ETW_FightingTraits.antiGunMentalTrait(
		player,
		SBvars.AntiGunMagazineHandlingUnhappinessPerBullet or 0.1,
		"magazine loading"
	)

	local currentReloadingXP = player:getXp():getXP(Perks.Reloading)
	local gainedXP = currentReloadingXP - reloadingXPBefore
	local playerIdentifier = tostring(player:getUsername()) .. " (OnlineID=" .. player:getOnlineID() .. ")"
	if gainedXP <= 0 then
		logETW(
			"ETW Logger | Anti-gun | ISLoadBulletsInMagazine:animEvent(): bullet inserted for "
				.. playerIdentifier
				.. "; vanilla awarded no Reloading XP"
		)
		return originalReturn
	end

	local xpToRemove, progress, reason = ETWCombinedTraitChecks.calculateAntiGunReloadingXPPenalty(player, gainedXP)
	if xpToRemove <= 0 then
		logETW(
			"ETW Logger | Anti-gun | ISLoadBulletsInMagazine:animEvent(): Reloading XP penalty skipped for "
				.. playerIdentifier
				.. "; actual gain: "
				.. gainedXP
				.. "; reason: "
				.. tostring(reason)
				.. (progress and "; level progress: " .. progress * 100 .. "%" or "")
		)
		return originalReturn
	end

	addXpNoMultiplier(player, Perks.Reloading, -xpToRemove)
	local resultingXP = player:getXp():getXP(Perks.Reloading)
	logETW(
		"ETW Logger | Anti-gun | ISLoadBulletsInMagazine:animEvent(): Reloading XP penalty applied for "
			.. playerIdentifier
			.. "; actual Reloading XP gain: "
			.. gainedXP
			.. "; requested removal: "
			.. xpToRemove
			.. "; actual removal: "
			.. currentReloadingXP - resultingXP
			.. "; resulting XP: "
			.. resultingXP
			.. "; level progress: "
			.. progress * 100
			.. "%"
	)
	return originalReturn
end
