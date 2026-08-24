local ETW_CommonFunctions = require("ETW_CommonFunctions")
local ETW_Registry = require("ETW_Registry")
local ETWCombinedTraitChecks = require("ETW_CombinedTraitFunctions")

local FILENAME = "ETW_HealthTraits.lua"
if
	not ETW_CommonFunctions.gameModeSafeguard(
		FILENAME,
		{ ETW_CommonFunctions.GameMode.SP, ETW_CommonFunctions.GameMode.MP_SERVER }
	)
then
	return
end

local ETW_HealthTraits = {}

---@type EvolvingTraitsWorldTraitsRegistries
local ETWTraitsRegistry = ETW_Registry.traits
---@type EvolvingTraitsWorldSandboxVars
local SBvars = SandboxVars.EvolvingTraitsWorld
local logETW = ETW_CommonFunctions.log
local random_instance = newrandom()
local INDEFATIGABLE_PROTECTION_DURATION_MS = 120000
local INDEFATIGABLE_TRIGGER_RADIUS = 1.5
local INDEFATIGABLE_KNOCKDOWN_RADIUS = 2.5

---Maintains or expires Indefatigable's temporary pain and wound-movement protection.
---@param player IsoPlayer
---@param bodyDamage BodyDamage
---@param modData EvolvingTraitsWorldModData
function ETW_HealthTraits.indefatigableProtection(player, bodyDamage, modData)
	local expiresAt = modData.IndefatigableProtectionExpiresAt
	if not expiresAt then
		return
	end
	if getTimestampMs() >= expiresAt then
		ETW_CommonFunctions.restoreWoundSpeedModifiers(
			bodyDamage,
			modData.IndefatigableWoundSpeedModifiers
		)
		modData.IndefatigableProtectionExpiresAt = nil
		modData.IndefatigableWoundSpeedModifiers = nil
		logETW(
			"ETW Logger | indefatigableProtection(): expired for "
				.. tostring(player:getUsername())
				.. " (OnlineID="
				.. player:getOnlineID()
				.. ")"
		)
		return
	end

	player:getStats():set(CharacterStat.PAIN, 0)
	ETW_CommonFunctions.suppressWoundMovementPenalties(bodyDamage)
end

---Activates Indefatigable at low health or preemptively when at least four zombies crowd the player.
---@param player IsoPlayer
---@param bodyDamage BodyDamage
---@param modData EvolvingTraitsWorldModData
---@param clientCrowdTrigger boolean|nil
function ETW_HealthTraits.indefatigableTrait(player, bodyDamage, modData, clientCrowdTrigger)
	local health = bodyDamage:getHealth()
	local playerIdentifier = tostring(player:getUsername()) .. " (OnlineID=" .. player:getOnlineID() .. ")"
	if player:isDead() or health <= 0 then
		if clientCrowdTrigger == true then
			logETW("ETW Logger | indefatigableTrait(): rejected client crowd trigger after death for " .. playerIdentifier)
		end
		return
	end

	local maximumUses = math.max(0, math.floor(SBvars.IndefatigableUses or 1))
	local uses = math.max(0, math.floor(modData.IndefatigableUses or 0))
	if maximumUses > 0 and uses >= maximumUses then
		if clientCrowdTrigger == true then
			logETW("ETW Logger | indefatigableTrait(): rejected client crowd trigger; uses exhausted for " .. playerIdentifier)
		end
		return
	end

	local worldAgeHours = getGameTime():getWorldAgeHours()
	local cooldownUntil = tonumber(modData.IndefatigableCooldownUntilHours) or 0
	if worldAgeHours < cooldownUntil then
		if clientCrowdTrigger == true then
			logETW(
				"ETW Logger | indefatigableTrait(): rejected client crowd trigger; cooldown remaining for "
					.. playerIdentifier
					.. ": "
					.. (cooldownUntil - worldAgeHours)
					.. " hours"
			)
		end
		return
	end

	local serverCrowdCount = ETWCombinedTraitChecks.forEachNearbyLivingZombie(
		player,
		INDEFATIGABLE_TRIGGER_RADIUS,
		nil
	)
	local crowdTrigger = serverCrowdCount >= 4 or clientCrowdTrigger == true
	local triggerHealth = PZMath.clamp(SBvars.IndefatigableTriggerHealthPercent or 20, 15, 40)
	if not crowdTrigger and health > triggerHealth then
		return
	end

	local requiresNearbyZombie = SBvars.IndefatigableRequiresNearbyZombie ~= false
	local knockdownTargets = {}
	local nearbyCount = ETWCombinedTraitChecks.forEachNearbyLivingZombie(
		player,
		(requiresNearbyZombie or crowdTrigger) and 5 or INDEFATIGABLE_KNOCKDOWN_RADIUS,
		function(zombie, distanceSquared)
			if
				distanceSquared <= INDEFATIGABLE_KNOCKDOWN_RADIUS * INDEFATIGABLE_KNOCKDOWN_RADIUS
				and not zombie:isKnockedDown()
			then
				table.insert(knockdownTargets, zombie)
			end
		end
	)
	if clientCrowdTrigger == true and serverCrowdCount < 4 and nearbyCount < 4 then
		logETW(
			"ETW Logger | indefatigableTrait(): rejected client crowd trigger for "
				.. playerIdentifier
				.. "; server zombies within 1.5: "
				.. serverCrowdCount
				.. "; within 5: "
				.. nearbyCount
		)
		return
	end
	if requiresNearbyZombie and nearbyCount == 0 then
		return
	end

	for _, zombie in ipairs(knockdownTargets) do
		ETW_CommonFunctions.triggerBouncerStagger(player, zombie, true)
	end

	local parts = bodyDamage:getBodyParts()
	for i = 0, parts:size() - 1 do
		parts:get(i):SetHealth(100)
	end
	bodyDamage:setOverallBodyHealth(100)

	local stats = player:getStats()
	stats:set(CharacterStat.PAIN, 0)
	stats:set(CharacterStat.FATIGUE, 0)
	stats:set(CharacterStat.ENDURANCE, 1)

	if not modData.IndefatigableWoundSpeedModifiers then
		modData.IndefatigableWoundSpeedModifiers = ETW_CommonFunctions.captureWoundSpeedModifiers(bodyDamage)
	end
	ETW_CommonFunctions.suppressWoundMovementPenalties(bodyDamage)
	modData.IndefatigableProtectionExpiresAt = getTimestampMs() + INDEFATIGABLE_PROTECTION_DURATION_MS
	modData.IndefatigableUses = uses + 1
	local cooldownDays = math.max(0, SBvars.IndefatigableCooldownDays or 7)
	modData.IndefatigableCooldownUntilHours = worldAgeHours + cooldownDays * 24

	if isServer() then
		sendServerCommand(player, "ETW", "startIndefatigableProtection", {
			durationMs = INDEFATIGABLE_PROTECTION_DURATION_MS,
			woundSpeedModifiers = modData.IndefatigableWoundSpeedModifiers,
			uses = modData.IndefatigableUses,
			cooldownUntilHours = modData.IndefatigableCooldownUntilHours,
		})
	end
	ETW_CommonFunctions.displayTraitNotification(player, ETWTraitsRegistry.INDEFATIGABLE:toString(), true, "GREEN")
	logETW(
		"ETW Logger | indefatigableTrait(): activated for "
			.. tostring(player:getUsername())
			.. " (OnlineID="
			.. player:getOnlineID()
			.. "); health: "
			.. health
			.. "->100; use: "
			.. modData.IndefatigableUses
			.. "/"
			.. (maximumUses == 0 and "infinite" or tostring(maximumUses))
			.. "; nearby zombies: "
			.. nearbyCount
			.. "; trigger: "
			.. (crowdTrigger and "four-zombie crowd" or "low health")
			.. "; server crowd within 1.5: "
			.. serverCrowdCount
			.. "; knocked down: "
			.. #knockdownTargets
			.. " within "
			.. INDEFATIGABLE_KNOCKDOWN_RADIUS
			.. " tiles"
			.. "; cooldown: "
			.. cooldownDays
			.. " days; protection: 120 real-time seconds"
	)
end

---Applies Unwavering's persistent wound movement-speed modifiers once.
---@param player IsoPlayer
---@param bodyDamage BodyDamage
---@param modData EvolvingTraitsWorldModData
function ETW_HealthTraits.unwaveringTrait(player, bodyDamage, modData)
	local scratchModifier = 30
	local cutModifier = 30
	local deepWoundModifier = 60
	local burnModifier = 60
	local affectedParts = ETW_CommonFunctions.applyUnwaveringInjurySpeedModifiers(
		bodyDamage,
		scratchModifier,
		cutModifier,
		deepWoundModifier,
		burnModifier
	)
	modData.UnwaveringInjurySpeedApplied = true
	if isServer() then
		sendServerCommand(player, "ETW", "applyUnwaveringInjurySpeedModifiers", {
			scratchModifier = scratchModifier,
			cutModifier = cutModifier,
			deepWoundModifier = deepWoundModifier,
			burnModifier = burnModifier,
		})
	end
	logETW(
		"ETW Logger | unwaveringTrait(): applied injury speed modifiers to "
			.. tostring(player:getUsername())
			.. " (OnlineID="
			.. player:getOnlineID()
			.. "); body parts: "
			.. affectedParts
			.. "; scratch/cut/deep wound/burn: +"
			.. scratchModifier
			.. "/+"
			.. cutModifier
			.. "/+"
			.. deepWoundModifier
			.. "/+"
			.. burnModifier
	)
end

---Rolls Noodle Legs' chance to trip while running or sprinting.
---@param player IsoPlayer
function ETW_HealthTraits.noodleLegsTrait(player)
	local isSprinting = player:isSprinting()
	if not player:isRunning() and not isSprinting then
		return
	end
	local sprintingLevel = player:getPerkLevel(Perks.Sprinting)
	local nimble = player:getPerkLevel(Perks.Nimble)
	local chanceIn = math.max(1, SBvars.NoodleLegsTripChanceOneIn or 5000)
	chanceIn = chanceIn * (1 + (nimble + sprintingLevel) * 0.025)
	if player:hasTrait(CharacterTrait.GRACEFUL) then
		chanceIn = chanceIn * 1.2
	elseif player:hasTrait(CharacterTrait.CLUMSY) then
		chanceIn = chanceIn * 0.8
	end
	if isSprinting then
		chanceIn = chanceIn * 0.6
	end
	chanceIn = math.max(1, math.floor(chanceIn))
	if random_instance:random(1, chanceIn) ~= 1 then
		return
	end

	local side = random_instance:random(1, 2) == 1 and "left" or "right"
	ETW_CommonFunctions.triggerNoodleLegsTrip(player, side)
	logETW(
		"ETW Logger | noodleLegsTrait(): triggered trip while "
			.. (isSprinting and "sprinting" or "running")
			.. "; chance: 1/"
			.. chanceIn
			.. ", side: "
			.. side
	)
end

---Caps pain for a player with Pain Tolerance.
---@param player IsoPlayer
function ETW_HealthTraits.painToleranceTrait(player)
	local stats = player:getStats()
	local pain = stats:get(CharacterStat.PAIN)
	if pain > SBvars.PainToleranceThreshold then
		stats:set(CharacterStat.PAIN, SBvars.PainToleranceThreshold)
	end
end

---Applies Anemic's additional damage to actively bleeding, unstemmed wounds.
---@param bodyDamage BodyDamage
function ETW_HealthTraits.anemicTrait(bodyDamage)
	if bodyDamage:getNumPartsBleeding() <= 0 then
		return
	end
	local damage = math.max(0, SBvars.AnemicBleedingDamage or 0.4)
	local parts = bodyDamage:getBodyParts()
	local damagedParts = 0
	local totalDamage = 0
	for i = 0, parts:size() - 1 do
		local part = parts:get(i)
		if part:bleeding() and not part:IsBleedingStemmed() then
			local partDamage = damage
			if part:getType() == BodyPartType.Head or part:getType() == BodyPartType.Neck then
				partDamage = partDamage * 2
			end
			part:ReduceHealth(partDamage)
			damagedParts = damagedParts + 1
			totalDamage = totalDamage + partDamage
		end
	end
	if damagedParts > 0 then
		logETW(
			"ETW Logger | anemicTrait(): damaged "
				.. damagedParts
				.. " bleeding parts for "
				.. totalDamage
				.. " total health"
		)
	end
end

---Restores health to actively bleeding, unstemmed wounds for Thick Blooded.
---@param bodyDamage BodyDamage
function ETW_HealthTraits.thickBloodedTrait(bodyDamage)
	if bodyDamage:getNumPartsBleeding() <= 0 then
		return
	end
	local health = math.max(0, SBvars.ThickBloodedBleedingHealthPerMinute or 0.15)
	if health == 0 then
		return
	end
	local parts = bodyDamage:getBodyParts()
	local restoredParts = 0
	local totalHealth = 0
	for i = 0, parts:size() - 1 do
		local part = parts:get(i)
		if part:bleeding() and not part:IsBleedingStemmed() then
			local partHealth = health
			if part:getType() == BodyPartType.Head or part:getType() == BodyPartType.Neck then
				partHealth = partHealth * 2
			end
			part:AddHealth(partHealth)
			restoredParts = restoredParts + 1
			totalHealth = totalHealth + partHealth
		end
	end
	if restoredParts > 0 then
		logETW(
			"ETW Logger | thickBloodedTrait(): restored "
				.. totalHealth
				.. " health across "
				.. restoredParts
				.. " bleeding parts"
		)
	end
end

---Applies Quick Rest to endurance recovered since the previous tick.
---@param player IsoPlayer
---@param modData EvolvingTraitsWorldModData
function ETW_HealthTraits.quickRestTrait(player, modData)
	local stats = player:getStats()
	local endurance = stats:get(CharacterStat.ENDURANCE)
	if (player:isSitOnGround() or player:isSittingOnFurniture())
		and endurance > modData.QuickRestLastEndurance
	then
		local multiplier = math.max(1, SBvars.QuickRestRecoveryMultiplier or 2)
		local bonus = (endurance - modData.QuickRestLastEndurance) * (multiplier - 1)
		stats:set(CharacterStat.ENDURANCE, math.min(1, endurance + bonus))
	end
	modData.QuickRestLastEndurance = stats:get(CharacterStat.ENDURANCE)
end

---Transfers endurance between Hardy's reserve and the normal endurance bar.
---@param player IsoPlayer
---@param modData EvolvingTraitsWorldModData
function ETW_HealthTraits.hardyTrait(player, modData)
	-- TODO: moodle support as a display of available endurance reserve
	if not player:hasTrait(ETWTraitsRegistry.HARDY) then
		modData.HardyReserve = nil
		return
	end
	local stats = player:getStats()
	local endurance = stats:get(CharacterStat.ENDURANCE)
	local maximumReserve = PZMath.clamp((SBvars.HardyExtraEndurancePercent or 25) / 100, 0, 1)
	local transfer = PZMath.clamp(SBvars.HardyTransferPerMinute or 0.05, 0, 1)
	modData.HardyReserve = PZMath.clamp(modData.HardyReserve or maximumReserve, 0, maximumReserve)
	if endurance < 0.85 and modData.HardyReserve > 0 then
		local amount = math.min(transfer, modData.HardyReserve, 1 - endurance)
		stats:set(CharacterStat.ENDURANCE, endurance + amount)
		modData.HardyReserve = modData.HardyReserve - amount
		logETW(
			"ETW Logger | hardyTrait(): transferred "
				.. amount
				.. " from reserve; endurance: "
				.. endurance
				.. "->"
				.. (endurance + amount)
				.. ", reserve: "
				.. modData.HardyReserve
		)
	elseif endurance >= 0.99 and modData.HardyReserve < maximumReserve then
		local amount = math.min(transfer, maximumReserve - modData.HardyReserve, endurance)
		stats:set(CharacterStat.ENDURANCE, endurance - amount)
		modData.HardyReserve = modData.HardyReserve + amount
		logETW(
			"ETW Logger | hardyTrait(): replenished reserve by "
				.. amount
				.. "; endurance: "
				.. endurance
				.. "->"
				.. (endurance - amount)
				.. ", reserve: "
				.. modData.HardyReserve
		)
	end
end

---Adjusts positive calorie gains when Ideal Weight is below or above its target range.
---@param player IsoPlayer
---@param modData EvolvingTraitsWorldModData
function ETW_HealthTraits.idealWeightTrait(player, modData)
	local nutrition = player:getNutrition()
	local calories = nutrition:getCalories()
	if player:hasTrait(ETWTraitsRegistry.IDEAL_WEIGHT) and calories > modData.IdealWeightLastCalories then
		local originalCalories = calories
		local gain = calories - modData.IdealWeightLastCalories
		local weight = nutrition:getWeight()
		local lowerWeight = SBvars.IdealWeightLowerThreshold or 78
		local upperWeight = SBvars.IdealWeightUpperThreshold or 82
		if weight <= lowerWeight then
			calories = modData.IdealWeightLastCalories + gain * math.max(0, SBvars.IdealWeightUnderMultiplier or 1.5)
		elseif weight >= upperWeight then
			calories = modData.IdealWeightLastCalories + gain * math.max(0, SBvars.IdealWeightOverMultiplier or 0.75)
		end
		nutrition:setCalories(calories)
		if calories ~= originalCalories then
			logETW(
				"ETW Logger | idealWeightTrait(): weight: "
					.. weight
					.. ", calories: "
					.. originalCalories
					.. "->"
					.. calories
			)
		end
	end
	modData.IdealWeightLastCalories = calories
end

return ETW_HealthTraits
