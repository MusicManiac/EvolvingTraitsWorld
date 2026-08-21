local ETW_CommonFunctions = require("ETW_CommonFunctions")
local ETW_Registry = require("ETW_Registry")
local ETWCombinedTraitChecks = require("ETW_CombinedTraitChecks")

local FILENAME = "ETW_FightingTraits.lua"
if
	not ETW_CommonFunctions.gameModeSafeguard(
		FILENAME,
		{ ETW_CommonFunctions.GameMode.SP, ETW_CommonFunctions.GameMode.MP_SERVER }
	)
then
	return
end

local ETW_FightingTraits = {}

---@type EvolvingTraitsWorldTraitsRegistries
local ETWTraitsRegistry = ETW_Registry.traits
---@type EvolvingTraitsWorldSandboxVars
local SBvars = SandboxVars.EvolvingTraitsWorld
local logETW = ETW_CommonFunctions.log

---Marks an Anti-Gun Activist firearm hit for an XP-gain check after vanilla awards the XP.
---@param player IsoGameCharacter
---@param weapon HandWeapon
---@param hitObject IsoMovingObject
---@param damage number
---@param hitCount number
function ETW_FightingTraits.onWeaponHitXP(player, weapon, hitObject, damage, hitCount)
	if
		not instanceof(player, "IsoPlayer")
		or not weapon
		or not weapon:isRanged()
		or not hitCount
		or hitCount <= 0
	then
		return
	end
	---@cast player IsoPlayer
	if not player:hasTrait(ETWTraitsRegistry.ANTI_GUN_ACTIVIST) then
		return
	end
	local modData = ETW_CommonFunctions.getETWModData(player)
	if not modData then
		return
	end
	modData.AntiGunAimingXPCheckPending = true
	local playerIdentifier = tostring(player:getUsername()) .. " (OnlineID=" .. player:getOnlineID() .. ")"
	logETW(
		"ETW Logger | antigun XP weapon-hit event: marked pending XP check for "
			.. playerIdentifier
			.. "; last recorded XP: "
			.. tostring(modData.AntiGunLastRecordedAimingXP)
	)
end

---Removes the configured percentage of the actual Aiming XP gained since the previous recorded value.
---@param player IsoPlayer
---@param modData EvolvingTraitsWorldModData
function ETW_FightingTraits.antiGunAimingXPPenalty(player, modData)
	local currentXP = player:getXp():getXP(Perks.Aiming)
	local lastRecordedXP = modData.AntiGunLastRecordedAimingXP
	local playerIdentifier = tostring(player:getUsername()) .. " (OnlineID=" .. player:getOnlineID() .. ")"
	modData.AntiGunAimingXPCheckPending = nil
	if lastRecordedXP == nil then
		modData.AntiGunLastRecordedAimingXP = currentXP
		logETW(
			"ETW Logger | antigun XP check: initialized missing XP snapshot for "
				.. playerIdentifier
				.. " to "
				.. currentXP
		)
		return
	end

	local gainedXP = currentXP - lastRecordedXP
	if gainedXP <= 0 then
		modData.AntiGunLastRecordedAimingXP = currentXP
		logETW(
			"ETW Logger | antigun XP check: no positive gain for "
				.. playerIdentifier
				.. "; recorded: "
				.. lastRecordedXP
				.. ", current: "
				.. currentXP
		)
		return
	end

	local xpToRemove, progress, reason = ETWCombinedTraitChecks.calculateAntiGunAimingXPPenalty(player, gainedXP)
	if xpToRemove <= 0 then
		modData.AntiGunLastRecordedAimingXP = currentXP
		logETW(
			"ETW Logger | antigun XP check: skipped for "
				.. playerIdentifier
				.. "; actual gain: "
				.. gainedXP
				.. "; reason: "
				.. tostring(reason)
				.. (progress and "; level progress: " .. progress * 100 .. "%" or "")
		)
		return
	end

	addXpNoMultiplier(player, Perks.Aiming, -xpToRemove)
	modData.AntiGunLastRecordedAimingXP = player:getXp():getXP(Perks.Aiming)
	local actualRemovedXP = currentXP - modData.AntiGunLastRecordedAimingXP
	logETW(
		"ETW Logger | antigun XP check: "
			.. playerIdentifier
			.. "; actual gain: "
			.. gainedXP
			.. "; requested removal: "
			.. xpToRemove
			.. "; actual removal: "
			.. actualRemovedXP
			.. "; recorded post-penalty XP: "
			.. modData.AntiGunLastRecordedAimingXP
			.. "; level progress: "
			.. progress * 100
			.. "%"
	)
end

---Adds Anti-Gun Activist unhappiness from firearm use.
---@param player IsoPlayer
---@param increase number|nil
---@param source string|nil
function ETW_FightingTraits.antiGunMentalTrait(player, increase, source)
	local stats = player:getStats()
	local unhappiness = stats:get(CharacterStat.UNHAPPINESS)
	increase = math.max(0, increase or SBvars.AntiGunUnhappinessPerMinute or 0.6)
	local resultingUnhappiness = math.min(100, unhappiness + increase)
	stats:set(CharacterStat.UNHAPPINESS, resultingUnhappiness)
	local playerIdentifier = tostring(player:getUsername()) .. " (OnlineID=" .. player:getOnlineID() .. ")"
	logETW(
		"ETW Logger | antigun mood: "
			.. playerIdentifier
			.. "; unhappiness: "
			.. unhappiness
			.. "->"
			.. resultingUnhappiness
			.. "; source: "
			.. (source or "aiming")
	)
end

---Processes Bloodlust when a nearby zombie dies.
---@param zombie IsoZombie
function ETW_FightingTraits.onZombieDead(zombie)
	local playersList = ETW_CommonFunctions.playersList()
	for i = 0, playersList:size() - 1 do
		local player = playersList:get(i)
		-- TODO: figure if there's better way to do this than checking DistTo for all players
		if player:hasTrait(ETWTraitsRegistry.BLOODLUST) and player:DistTo(zombie) <= 4 then
			local stats = player:getStats()
			local nicotineWithdrawal = stats:get(CharacterStat.NICOTINE_WITHDRAWAL)
			local unhappiness = stats:get(CharacterStat.UNHAPPINESS)
			local stress = math.max(0, stats:get(CharacterStat.STRESS) - nicotineWithdrawal)
			local panic = stats:get(CharacterStat.PANIC)
			stats:set(CharacterStat.UNHAPPINESS, math.max(0, unhappiness - 4 * SBvars.BloodlustMultiplier))
			stats:set(CharacterStat.STRESS, math.max(0, stress - 0.04 * SBvars.BloodlustMultiplier))
			stats:set(CharacterStat.PANIC, math.max(0, panic - 4 * SBvars.BloodlustMultiplier))
			logETW(
				"ETW Logger | onZombieDead(): Bloodlust kill. Unhappiness:"
					.. unhappiness
					.. "->"
					.. stats:get(CharacterStat.UNHAPPINESS)
					.. ", stress: "
					.. math.min(1, stress + nicotineWithdrawal)
					.. "->"
					.. stats:get(CharacterStat.STRESS)
					.. ", panic: "
					.. panic
					.. "->"
					.. stats:get(CharacterStat.PANIC)
			)
		end
	end
end

return ETW_FightingTraits
