local ETW_CommonFunctions = require("ETW_CommonFunctions")
local ETW_Registry = require("ETW_Registry")
local ETWCombinedTraitChecks = require("ETW_CombinedTraitFunctions")

local FILENAME = "ETW_CombatTraits.lua"
if
	not ETW_CommonFunctions.gameModeSafeguard(
		FILENAME,
		{ ETW_CommonFunctions.GameMode.SP, ETW_CommonFunctions.GameMode.MP_SERVER }
	)
then
	return
end

local ETW_CombatTraits = {}

---@type EvolvingTraitsWorldTraitsRegistries
local ETWTraitsRegistry = ETW_Registry.traits
---@type EvolvingTraitsWorldSandboxVars
local SBvars = SandboxVars.EvolvingTraitsWorld
local logETW = ETW_CommonFunctions.log
local random_instance = newrandom()

---Attempts to stagger a nearby zombie when the player is surrounded.
---@param player IsoPlayer
---@param modData EvolvingTraitsWorldModData
function ETW_CombatTraits.bouncerTrait(player, modData)
	local cooldownTicks = modData.BouncerCooldownTicks or 0
	if cooldownTicks > 0 then
		modData.BouncerCooldownTicks = cooldownTicks - 1
		return
	end

	local maximumDistance = math.max(0, SBvars.BouncerDistance or 1.75)
	local closestTarget = nil
	local closestDistanceSquared = maximumDistance * maximumDistance + 1
	local nearbyCount = ETWCombinedTraitChecks.forEachNearbyLivingZombie(
		player,
		maximumDistance,
		function(zombie, distanceSquared)
			if not zombie:isKnockedDown() and distanceSquared < closestDistanceSquared then
				closestTarget = zombie
				closestDistanceSquared = distanceSquared
			end
		end
	)
	if nearbyCount < 3 or not closestTarget then
		return
	end

	local chance = PZMath.clamp(SBvars.BouncerChance or 5, 0, 100)
	local roll = random_instance:random(1, 100)
	if roll > chance then
		return
	end

	local configuredCooldown = math.max(0, SBvars.BouncerCooldown or 60)
	modData.BouncerCooldownTicks = math.floor(configuredCooldown)
	ETW_CommonFunctions.triggerBouncerStagger(player, closestTarget)
	local closestDistance = math.sqrt(closestDistanceSquared)
	logETW(
		"ETW Logger | bouncerTrait(): triggered for "
			.. tostring(player:getUsername())
			.. " (OnlineID="
			.. player:getOnlineID()
			.. "); zombie OnlineID="
			.. closestTarget:getOnlineID()
			.. "; nearby zombies: "
			.. nearbyCount
			.. "; distance: "
			.. closestDistance
			.. "; roll: "
			.. roll
			.. "/100; chance: "
			.. chance
			.. "%; cooldown: "
			.. modData.BouncerCooldownTicks
			.. " ticks"
	)
end

---@param player IsoPlayer
---@param weapon HandWeapon
---@return string|nil prowessName
local function getMatchingProwess(player, weapon)
	if weapon:isRanged() then
		if player:hasTrait(ETWTraitsRegistry.PROWESS_GUNS) then
			return "Guns"
		end
		return nil
	end
	if
		player:hasTrait(ETWTraitsRegistry.PROWESS_BLADE)
		and (
			weapon:isOfWeaponCategory(WeaponCategory.AXE)
			or weapon:isOfWeaponCategory(WeaponCategory.SMALL_BLADE)
			or weapon:isOfWeaponCategory(WeaponCategory.LONG_BLADE)
		)
	then
		return "Blade"
	end
	if
		player:hasTrait(ETWTraitsRegistry.PROWESS_BLUNT)
		and (
			weapon:isOfWeaponCategory(WeaponCategory.SMALL_BLUNT)
			or weapon:isOfWeaponCategory(WeaponCategory.BLUNT)
		)
	then
		return "Blunt"
	end
	if
		player:hasTrait(ETWTraitsRegistry.PROWESS_SPEAR)
		and weapon:isOfWeaponCategory(WeaponCategory.SPEAR)
	then
		return "Spear"
	end
	return nil
end

---@param player IsoPlayer
---@param weapon HandWeapon
---@param prowessName string
---@param source string
local function restoreProwessConditionLoss(player, weapon, prowessName, source)
	local currentCondition = weapon:getCondition()
	local weaponData = weapon:getModData()
	local username = tostring(player:getUsername())
	local onlineID = player:getOnlineID()
	local samePlayer = weaponData.ETWProwessSnapshotUsername == username
		and weaponData.ETWProwessSnapshotOnlineID == onlineID
	local previousCondition = samePlayer and weaponData.ETWProwessLastCondition or nil
	if previousCondition and previousCondition > currentCondition then
		local chance = PZMath.clamp(SBvars.ProwessConditionRestoreChance or 33, 0, 100)
		local roll = random_instance:random(1, 10000)
		local restored = roll <= chance * 100
		if restored then
			local restoredCondition = math.min(weapon:getConditionMax(), currentCondition + 1)
			weapon:setCondition(restoredCondition)
		end
		local playerIdentifier = username .. " (OnlineID=" .. onlineID .. ")"
		logETW(
			"ETW Logger | prowess condition roll: "
				.. playerIdentifier
				.. "; prowess: "
				.. prowessName
				.. "; weapon: "
				.. weapon:getFullType()
				.. "; detected condition: "
				.. previousCondition
				.. "->"
				.. currentCondition
				.. "; roll: "
				.. roll
				.. "/10000; chance: "
				.. chance
				.. "%; restored: "
				.. tostring(restored)
				.. "; resulting condition: "
				.. weapon:getCondition()
				.. "; source: "
				.. source
		)
	end
	weaponData.ETWProwessSnapshotUsername = username
	weaponData.ETWProwessSnapshotOnlineID = onlineID
	weaponData.ETWProwessLastCondition = weapon:getCondition()
end

---@param weapon HandWeapon
local function clearProwessConditionSnapshot(weapon)
	local weaponData = weapon:getModData()
	weaponData.ETWProwessSnapshotUsername = nil
	weaponData.ETWProwessSnapshotOnlineID = nil
	weaponData.ETWProwessLastCondition = nil
end

---Records condition before an attack and resolves condition loss from a previous miss.
---@param player IsoPlayer
---@param weapon HandWeapon
function ETW_CombatTraits.onWeaponSwing(player, weapon)
	if not player or not weapon then
		return
	end
	if weapon:isRanged() then
		if not player:hasTrait(ETWTraitsRegistry.PROWESS_GUNS) then
			clearProwessConditionSnapshot(weapon)
			return
		end
	elseif
		not player:hasTrait(ETWTraitsRegistry.PROWESS_BLADE)
		and not player:hasTrait(ETWTraitsRegistry.PROWESS_BLUNT)
		and not player:hasTrait(ETWTraitsRegistry.PROWESS_SPEAR)
	then
		clearProwessConditionSnapshot(weapon)
		return
	end
	local prowessName = getMatchingProwess(player, weapon)
	if prowessName then
		restoreProwessConditionLoss(player, weapon, prowessName, "next attack")
	else
		clearProwessConditionSnapshot(weapon)
	end
end

---Resolves durability recovery after a matching melee Prowess hit.
---@param player IsoPlayer
---@param weapon HandWeapon
local function prowessMeleeTrait(player, weapon)
	local prowessName = getMatchingProwess(player, weapon)
	if not prowessName or prowessName == "Guns" then
		return
	end
	restoreProwessConditionLoss(player, weapon, prowessName, "weapon hit")
end

---Processes firearm Anti-Gun XP tracking and matching melee Prowess hits.
---@param player IsoGameCharacter
---@param weapon HandWeapon
---@param hitObject IsoMovingObject
---@param damage number
---@param hitCount number
function ETW_CombatTraits.onWeaponHitXP(player, weapon, hitObject, damage, hitCount)
	if not instanceof(player, "IsoPlayer") or not weapon then
		return
	end
	---@cast player IsoPlayer
	if not weapon:isRanged() then
		if
			player:hasTrait(ETWTraitsRegistry.PROWESS_BLADE)
			or player:hasTrait(ETWTraitsRegistry.PROWESS_BLUNT)
			or player:hasTrait(ETWTraitsRegistry.PROWESS_SPEAR)
		then
			prowessMeleeTrait(player, weapon)
		end
		return
	end
	if player:hasTrait(ETWTraitsRegistry.PROWESS_GUNS) then
		local prowessName = getMatchingProwess(player, weapon)
		if prowessName == "Guns" then
			restoreProwessConditionLoss(player, weapon, prowessName, "firearm hit")
		end
	end
	if not hitCount or hitCount <= 0 or not player:hasTrait(ETWTraitsRegistry.ANTI_GUN_ACTIVIST) then
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
function ETW_CombatTraits.antiGunAimingXPPenalty(player, modData)
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
---@param stats Stats
---@param increase number|nil
---@param source string|nil
function ETW_CombatTraits.antiGunMentalTrait(player, stats, increase, source)
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

---Reduces panic and stress while Terminator aims a firearm.
---@param player IsoPlayer
---@param stats Stats
---@param source string|nil
function ETW_CombatTraits.terminatorMentalTrait(player, stats, source)
	local panic = stats:get(CharacterStat.PANIC)
	local stress = stats:get(CharacterStat.STRESS)
	local panicReduction = math.max(0, SBvars.TerminatorPanicReductionPerMinute or 10)
	local stressReduction = math.max(0, SBvars.TerminatorStressReductionPercentPerMinute or 1) / 100
	local resultingPanic = math.max(0, panic - panicReduction)
	local resultingStress = math.max(0, stress - stressReduction)
	stats:set(CharacterStat.PANIC, resultingPanic)
	stats:set(CharacterStat.STRESS, resultingStress)
	logETW(
		"ETW Logger | terminator mood: "
			.. tostring(player:getUsername())
			.. " (OnlineID="
			.. player:getOnlineID()
			.. "); panic: "
			.. panic
			.. "->"
			.. resultingPanic
			.. "; stress: "
			.. stress
			.. "->"
			.. resultingStress
			.. "; source: "
			.. (source or "aiming")
	)
end

---Processes Bloodlust when a nearby zombie dies.
---@param zombie IsoZombie
function ETW_CombatTraits.onZombieDead(zombie)
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

return ETW_CombatTraits
