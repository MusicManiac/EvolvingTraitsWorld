local ETW_ModDataServer = require("ETW_ModDataServer")
local ETW_CommonFunctions = require("ETW_CommonFunctions")
local ETW_CommonLogicChecks = require("ETW_CommonLogicChecks")
local ETW_Registry = require("ETW_Registry")
local ETWTraitsRegistry = ETW_Registry.traits

local gameMode = ETW_CommonFunctions.gameMode()

---@type EvolvingTraitsWorldSandboxVars
local SBvars = SandboxVars.EvolvingTraitsWorld
local FILENAME = "ETW_ByHealth.lua"

if
	not ETW_CommonFunctions.gameModeSafeguard(
		FILENAME,
		{ ETW_CommonFunctions.GameMode.SP, ETW_CommonFunctions.GameMode.MP_SERVER }
	)
then
	return
end

---@type fun(...: string)
local logETW = ETW_CommonFunctions.log

---Function responsible for managing Immunity traits
local function immunitySystemTraits()
	local playersList = ETW_CommonFunctions.playersList()

	for i = 0, playersList:size() - 1 do
		local player = playersList:get(i)
		logETW("ETW Logger | immunitySystemTraits(): running for player " .. player:getUsername())
		local bodyDamage = player:getBodyDamage()
		local coldStrength = bodyDamage:getColdStrength() / 100 -- 0-100 -> 0-1
		local infectionLevel = bodyDamage:getApparentInfectionLevel() / 100 -- 0-100 -> 0-1
		if coldStrength > 0 or infectionLevel > 0 then
			local modData = ETW_CommonFunctions.getETWModData(player)
			modData.ImmunitySystemCounter = (
				modData.ImmunitySystemCounter
				+ coldStrength
				+ infectionLevel * SBvars.ImmunitySystemInfectionMultiplier
			)
			logETW(
				"ETW Logger | immunitySystemTraits(): modData.ImmunitySystemCounter = " .. modData.ImmunitySystemCounter
			)
			if
				player:hasTrait(CharacterTrait.PRONE_TO_ILLNESS)
				and modData.ImmunitySystemCounter >= SBvars.ImmunitySystemCounter / 2
				and SBvars.TraitsLockSystemCanLoseNegative
			then
				if
					SBvars.DelayedTraitsSystem
					and not ETW_CommonFunctions.checkIfTraitIsInDelayedTraitsTable(
						player,
						CharacterTrait.PRONE_TO_ILLNESS
					)
				then
					ETW_CommonFunctions.addTraitToDelayTable({
						modData = modData,
						trait = CharacterTrait.PRONE_TO_ILLNESS,
						player = player,
						positiveTrait = false,
						gainingTrait = false,
					})
				elseif
					not SBvars.DelayedTraitsSystem
					or (
						SBvars.DelayedTraitsSystem
						and ETW_CommonFunctions.checkDelayedTraits(player, CharacterTrait.PRONE_TO_ILLNESS)
					)
				then
					ETW_CommonFunctions.removeTraitFromPlayer({
						player = player,
						trait = CharacterTrait.PRONE_TO_ILLNESS,
						positiveTrait = false,
					})
				end
			elseif
				not player:hasTrait(CharacterTrait.PRONE_TO_ILLNESS)
				and not player:hasTrait(CharacterTrait.RESILIENT)
				and modData.ImmunitySystemCounter >= SBvars.ImmunitySystemCounter
				and SBvars.TraitsLockSystemCanGainPositive
			then
				if
					SBvars.DelayedTraitsSystem
					and not ETW_CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, CharacterTrait.RESILIENT)
				then
					ETW_CommonFunctions.addTraitToDelayTable({
						modData = modData,
						trait = CharacterTrait.RESILIENT,
						player = player,
						positiveTrait = true,
						gainingTrait = true,
					})
				elseif
					not SBvars.DelayedTraitsSystem
					or (
						SBvars.DelayedTraitsSystem
						and ETW_CommonFunctions.checkDelayedTraits(player, CharacterTrait.RESILIENT)
					)
				then
					ETW_CommonFunctions.addTraitToPlayer({
						player = player,
						trait = CharacterTrait.RESILIENT,
						positiveTrait = true,
					})
					Events.EveryOneMinute.Remove(immunitySystemTraits)
				end
			end
		end
	end
end

---Function responsible for managing Food Sickness System traits
local function foodSicknessTraitsETW()
	local playersList = ETW_CommonFunctions.playersList()

	for i = 0, playersList:size() - 1 do
		local player = playersList:get(i)
		logETW("ETW Logger | foodSicknessTraitsETW(): running for player " .. player:getUsername())
		local stats = player:getStats()
		local foodSicknessStrength = stats:get(CharacterStat.FOOD_SICKNESS) / 100 -- 0-100 -> 0-1
		local normalSickness = stats:get(CharacterStat.SICKNESS) -- 0-1
		logETW(
			"ETW Logger | foodSicknessTraitsETW(): foodSicknessStrength = "
				.. foodSicknessStrength
				.. ", normal sickness: "
				.. normalSickness
		)
		local modData = ETW_CommonFunctions.getETWModData(player)
		modData.FoodSicknessWeathered = (
			modData.FoodSicknessWeathered
			+ foodSicknessStrength
			+ math.max((normalSickness - foodSicknessStrength), 0)
				* SBvars.FoodSicknessSystemNormalSicknessMultiplier
		)
		if
			player:hasTrait(CharacterTrait.WEAK_STOMACH)
			and modData.FoodSicknessWeathered >= SBvars.FoodSicknessSystemCounter / 2
			and SBvars.TraitsLockSystemCanLoseNegative
		then
			if
				SBvars.DelayedTraitsSystem
				and not ETW_CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, CharacterTrait.WEAK_STOMACH)
			then
				ETW_CommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = CharacterTrait.WEAK_STOMACH,
					player = player,
					positiveTrait = false,
					gainingTrait = false,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (
					SBvars.DelayedTraitsSystem
					and ETW_CommonFunctions.checkDelayedTraits(player, CharacterTrait.WEAK_STOMACH)
				)
			then
				ETW_CommonFunctions.removeTraitFromPlayer({
					player = player,
					trait = CharacterTrait.WEAK_STOMACH,
					positiveTrait = false,
				})
			end
		elseif
			not player:hasTrait(CharacterTrait.WEAK_STOMACH)
			and not player:hasTrait(CharacterTrait.IRON_GUT)
			and modData.FoodSicknessWeathered >= SBvars.FoodSicknessSystemCounter
			and SBvars.TraitsLockSystemCanGainPositive
		then
			if
				SBvars.DelayedTraitsSystem
				and not ETW_CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, CharacterTrait.IRON_GUT)
			then
				ETW_CommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = CharacterTrait.IRON_GUT,
					player = player,
					positiveTrait = true,
					gainingTrait = true,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (
					SBvars.DelayedTraitsSystem
					and ETW_CommonFunctions.checkDelayedTraits(player, CharacterTrait.IRON_GUT)
				)
			then
				ETW_CommonFunctions.addTraitToPlayer({
					player = player,
					trait = CharacterTrait.IRON_GUT,
					positiveTrait = true,
				})
				Events.EveryOneMinute.Remove(foodSicknessTraitsETW)
			end
		end
	end
end

---Returns the average of the first N entries in a rolling samples table once enough samples were collected.
---@param samples number[]
---@param requiredSamples integer
---@return number|nil
local function getRollingAverage(samples, requiredSamples)
	if #samples < requiredSamples then
		return nil
	end

	local sum = 0
	for i = 1, requiredSamples do
		sum = sum + samples[i]
	end
	return sum / requiredSamples
end

---Pushes a raw habit value into rolling 60-minute, 24-hour and 31-day buckets and returns the newest long-term average.
---@param samples60 number[]
---@param samples24 number[]
---@param samples31 number[]
---@param latestValue number
---@param label string
---@return number
local function updateRollingHabitAverage(samples60, samples24, samples31, latestValue, label)
	table.insert(samples60, latestValue)
	local hourAverage = getRollingAverage(samples60, 60)
	if hourAverage then
		logETW("ETW Logger | " .. label .. "(): average in last 60 min: " .. hourAverage)
		table.insert(samples24, hourAverage)
		samples60[1] = hourAverage
		for i = #samples60, 2, -1 do
			table.remove(samples60, i)
		end

		local dayAverage = getRollingAverage(samples24, 24)
		if dayAverage then
			logETW("ETW Logger | " .. label .. "(): average in last 24 hours: " .. dayAverage)
			table.insert(samples31, dayAverage)
			samples24[1] = dayAverage
			for i = #samples24, 2, -1 do
				table.remove(samples24, i)
			end

			local sum = 0
			for i = 1, #samples31 do
				sum = sum + samples31[i]
			end
			if #samples31 > 31 then
				table.remove(samples31, 1)
			end
			return sum / #samples31
		end
	end

	local sum = 0
	for i = 1, #samples31 do
		sum = sum + samples31[i]
	end
	return sum / #samples31
end

---Converts an inverted raw stat such as hunger or thirst into a normalized score where low is bad and high is good.
---@param value number|nil
---@return number
local function normalizeInvertedVital(value)
	local numericValue = tonumber(value) or 0
	numericValue = math.max(0, math.min(1, numericValue))
	return 1 - numericValue
end

---Adjusts a normalized habit sample so its movement toward or away from a starting trait uses Affinity rates.
---@param modData EvolvingTraitsWorldModData
---@param latestValue number
---@param currentAverage number
---@param negativeTrait CharacterTrait
---@param positiveTrait CharacterTrait
---@return number
local function applyAffinityToHabitSample(modData, latestValue, currentAverage, negativeTrait, positiveTrait)
	local change = latestValue - currentAverage
	local adjustedValue = currentAverage
		+ ETW_CommonFunctions.applyAffinityToDirectionalChange(modData, change, negativeTrait, positiveTrait)
	return math.max(0, math.min(1, adjustedValue))
end

---Records the player's current normalized food score into food-system rolling averages.
local function recordFoodStateETW()
	local playersList = ETW_CommonFunctions.playersList()

	for i = 0, playersList:size() - 1 do
		local player = playersList:get(i)
		local modData = ETW_CommonFunctions.getETWModData(player)
		local stats = player:getStats()
		if player:isAsleep() then
			logETW(
				"ETW Logger | recordFoodStateETW(): skipping sleeping player " .. player:getUsername()
			)
		else
			local rawHunger = normalizeInvertedVital(stats:get(CharacterStat.HUNGER))
			local hunger = rawHunger
			hunger = applyAffinityToHabitSample(
				modData,
				hunger,
				modData.RecentAverageFood,
				CharacterTrait.HEARTY_APPETITE,
				CharacterTrait.LIGHT_EATER
			)
			logETW(
				"ETW Logger | recordFoodStateETW(): player "
					.. player:getUsername()
					.. ", raw normalized hunger = "
					.. rawHunger
					.. ", affinity-adjusted hunger = "
					.. hunger
			)
			modData.RecentAverageFood = updateRollingHabitAverage(
				modData.FoodStateInLast60Min,
				modData.FoodStateInLast24Hours,
				modData.FoodStateInLast31Days,
				hunger,
				"recordFoodStateETW"
			)
		end
	end
end

---Records the player's current normalized thirst score into thirst-system rolling averages.
local function recordThirstStateETW()
	local playersList = ETW_CommonFunctions.playersList()

	for i = 0, playersList:size() - 1 do
		local player = playersList:get(i)
		local modData = ETW_CommonFunctions.getETWModData(player)
		local stats = player:getStats()
		if player:isAsleep() then
			logETW(
				"ETW Logger | recordThirstStateETW(): skipping sleeping player " .. player:getUsername()
			)
		else
			local rawThirst = normalizeInvertedVital(stats:get(CharacterStat.THIRST))
			local thirst = rawThirst
			thirst = applyAffinityToHabitSample(
				modData,
				thirst,
				modData.RecentAverageThirst,
				CharacterTrait.HIGH_THIRST,
				CharacterTrait.LOW_THIRST
			)
			logETW(
				"ETW Logger | recordThirstStateETW(): player "
					.. player:getUsername()
					.. ", raw normalized thirst = "
					.. rawThirst
					.. ", affinity-adjusted thirst = "
					.. thirst
			)
			modData.RecentAverageThirst = updateRollingHabitAverage(
				modData.ThirstStateInLast60Min,
				modData.ThirstStateInLast24Hours,
				modData.ThirstStateInLast31Days,
				thirst,
				"recordThirstStateETW"
			)
		end
	end
end

---Applies Food System trait gain/loss rules from the player's long-term normalized food score.
local function foodSystemETW()
	local playersList = ETW_CommonFunctions.playersList()

	for i = 0, playersList:size() - 1 do
		local player = playersList:get(i)
		local modData = ETW_CommonFunctions.getETWModData(player)
		local averageFood = modData.RecentAverageFood
		logETW(
			"ETW Logger | foodSystemETW(): running for player "
				.. player:getUsername()
				.. ", RecentAverageFood = "
				.. averageFood
		)

		if
			player:hasTrait(CharacterTrait.HEARTY_APPETITE)
			and averageFood >= SBvars.FoodSystemLoseNegativeThreshold
			and SBvars.TraitsLockSystemCanLoseNegative
		then
			ETW_CommonFunctions.removeTraitFromPlayer({
				player = player,
				trait = CharacterTrait.HEARTY_APPETITE,
				positiveTrait = false,
			})
		elseif
			not player:hasTrait(CharacterTrait.HEARTY_APPETITE)
			and not player:hasTrait(CharacterTrait.LIGHT_EATER)
			and averageFood <= SBvars.FoodSystemGainNegativeThreshold
			and SBvars.TraitsLockSystemCanGainNegative
		then
			ETW_CommonFunctions.addTraitToPlayer({
				player = player,
				trait = CharacterTrait.HEARTY_APPETITE,
				positiveTrait = false,
			})
		end

		if
			player:hasTrait(CharacterTrait.LIGHT_EATER)
			and averageFood <= SBvars.FoodSystemLosePositiveThreshold
			and SBvars.TraitsLockSystemCanLosePositive
		then
			ETW_CommonFunctions.removeTraitFromPlayer({
				player = player,
				trait = CharacterTrait.LIGHT_EATER,
				positiveTrait = true,
			})
		elseif
			not player:hasTrait(CharacterTrait.LIGHT_EATER)
			and not player:hasTrait(CharacterTrait.HEARTY_APPETITE)
			and averageFood >= SBvars.FoodSystemGainPositiveThreshold
			and SBvars.TraitsLockSystemCanGainPositive
		then
			ETW_CommonFunctions.addTraitToPlayer({
				player = player,
				trait = CharacterTrait.LIGHT_EATER,
				positiveTrait = true,
			})
		end
	end
end

---Applies Thirst System trait gain/loss rules from the player's long-term normalized thirst score.
local function thirstSystemETW()
	local playersList = ETW_CommonFunctions.playersList()

	for i = 0, playersList:size() - 1 do
		local player = playersList:get(i)
		local modData = ETW_CommonFunctions.getETWModData(player)
		local averageThirst = modData.RecentAverageThirst
		logETW(
			"ETW Logger | thirstSystemETW(): running for player "
				.. player:getUsername()
				.. ", RecentAverageThirst = "
				.. averageThirst
		)

		if
			player:hasTrait(CharacterTrait.HIGH_THIRST)
			and averageThirst >= SBvars.ThirstSystemLoseNegativeThreshold
			and SBvars.TraitsLockSystemCanLoseNegative
		then
			ETW_CommonFunctions.removeTraitFromPlayer({
				player = player,
				trait = CharacterTrait.HIGH_THIRST,
				positiveTrait = false,
			})
		elseif
			not player:hasTrait(CharacterTrait.HIGH_THIRST)
			and not player:hasTrait(CharacterTrait.LOW_THIRST)
			and averageThirst <= SBvars.ThirstSystemGainNegativeThreshold
			and SBvars.TraitsLockSystemCanGainNegative
		then
			ETW_CommonFunctions.addTraitToPlayer({
				player = player,
				trait = CharacterTrait.HIGH_THIRST,
				positiveTrait = false,
			})
		end

		if
			player:hasTrait(CharacterTrait.LOW_THIRST)
			and averageThirst <= SBvars.ThirstSystemLosePositiveThreshold
			and SBvars.TraitsLockSystemCanLosePositive
		then
			ETW_CommonFunctions.removeTraitFromPlayer({
				player = player,
				trait = CharacterTrait.LOW_THIRST,
				positiveTrait = true,
			})
		elseif
			not player:hasTrait(CharacterTrait.LOW_THIRST)
			and not player:hasTrait(CharacterTrait.HIGH_THIRST)
			and averageThirst >= SBvars.ThirstSystemGainPositiveThreshold
			and SBvars.TraitsLockSystemCanGainPositive
		then
			ETW_CommonFunctions.addTraitToPlayer({
				player = player,
				trait = CharacterTrait.LOW_THIRST,
				positiveTrait = true,
			})
		end
	end
end

---Returns whether this body part has an active scratch, including one hidden beneath a bandage.
---@param bodyPart BodyPart
---@return boolean
local function hasScratch(bodyPart)
	return bodyPart:scratched() or bodyPart:getScratchTime() > 0
end

---Returns whether this body part has an active laceration, including one hidden beneath a bandage.
---@param bodyPart BodyPart
---@return boolean
local function hasLaceration(bodyPart)
	return bodyPart:isCut() or bodyPart:getCutTime() > 0
end

---Returns whether this body part has an active deep wound, including one hidden beneath a bandage.
---@param bodyPart BodyPart
---@return boolean
local function hasDeepWound(bodyPart)
	return bodyPart:deepWounded() or bodyPart:getDeepWoundTime() > 0
end

---Returns whether this body part has an active bite, including one hidden beneath a bandage.
---@param bodyPart BodyPart
---@return boolean
local function hasBite(bodyPart)
	return bodyPart:bitten() or bodyPart:getBiteTime() > 0
end

---Returns the configured severity contribution of injuries on one body part.
---@param bodyPart BodyPart
---@return number injuryContribution
---@return boolean hasTrackedInjury
local function getBodyPartInjuryContribution(bodyPart)
	local injuryContribution = 0
	local hasTrackedInjury = false

	if hasScratch(bodyPart) then
		hasTrackedInjury = true
		injuryContribution = injuryContribution + SBvars.BodyScratchContribution
	end
	if hasLaceration(bodyPart) then
		hasTrackedInjury = true
		injuryContribution = injuryContribution + SBvars.BodyLacerationContribution
	end
	if hasDeepWound(bodyPart) then
		hasTrackedInjury = true
		injuryContribution = injuryContribution + SBvars.BodyDeepWoundContribution
	end
	if hasBite(bodyPart) then
		hasTrackedInjury = true
		injuryContribution = injuryContribution + SBvars.BodyBiteContribution
	end
	if bodyPart:getBurnTime() > 0 then
		hasTrackedInjury = true
		injuryContribution = injuryContribution + SBvars.BodyBurnContribution
	end
	if bodyPart:getFractureTime() > 0 then
		hasTrackedInjury = true
		injuryContribution = injuryContribution + SBvars.BodyFractureContribution
	end
	if bodyPart:haveBullet() then
		hasTrackedInjury = true
		injuryContribution = injuryContribution + SBvars.BodyLodgedBulletContribution
	end
	if bodyPart:haveGlass() then
		hasTrackedInjury = true
		injuryContribution = injuryContribution + SBvars.BodyLodgedGlassContribution
	end

	return injuryContribution, hasTrackedInjury
end

---Returns the total injury contribution and whether the body has any tracked injury.
---@param player IsoPlayer
---@return number injuryContribution
---@return boolean hasTrackedInjury
local function getInjuryContribution(player)
	local bodyParts = player:getBodyDamage():getBodyParts()
	local injuryContribution = 0
	local hasTrackedInjury = false

	for i = 0, bodyParts:size() - 1 do
		local bodyPartContribution, bodyPartHasInjury = getBodyPartInjuryContribution(bodyParts:get(i))
		injuryContribution = injuryContribution + bodyPartContribution
		hasTrackedInjury = hasTrackedInjury or bodyPartHasInjury
	end

	return injuryContribution, hasTrackedInjury
end

---Updates Thin Skinned and Thick Skinned from the player's injury history.
local function injuriesSystemETW()
	local playersList = ETW_CommonFunctions.playersList()
	local maxCounter = SBvars.InjuriesSystemCounter
	local gainNegativeThreshold = maxCounter * -2 / 3
	local loseNegativeThreshold = maxCounter * -1 / 3
	local losePositiveThreshold = maxCounter * 1 / 3
	local gainPositiveThreshold = maxCounter * 2 / 3

	for i = 0, playersList:size() - 1 do
		local player = playersList:get(i)
		local modData = ETW_CommonFunctions.getETWModData(player)
		local injuryContribution, hasTrackedInjury = getInjuryContribution(player)
		local counterChange = hasTrackedInjury and injuryContribution or -SBvars.InjuriesSystemPassiveCounterDecay
		counterChange = ETW_CommonFunctions.applyAffinityToDirectionalChange(
			modData,
			counterChange,
			CharacterTrait.THIN_SKINNED,
			CharacterTrait.THICK_SKINNED
		)
		modData.injuriesCounter = math.max(-maxCounter, math.min(maxCounter, modData.injuriesCounter + counterChange))

		logETW(
			"ETW Logger | injuriesSystemETW(): player="
				.. player:getUsername()
				.. " counterChange="
				.. counterChange
				.. " injuriesCounter="
				.. modData.injuriesCounter
		)

		if
			player:hasTrait(CharacterTrait.THIN_SKINNED)
			and modData.injuriesCounter >= loseNegativeThreshold
			and SBvars.TraitsLockSystemCanLoseNegative
		then
			ETW_CommonFunctions.removeTraitFromPlayer({
				player = player,
				trait = CharacterTrait.THIN_SKINNED,
				positiveTrait = false,
			})
		elseif
			not player:hasTrait(CharacterTrait.THIN_SKINNED)
			and not player:hasTrait(CharacterTrait.THICK_SKINNED)
			and modData.injuriesCounter <= gainNegativeThreshold
			and SBvars.TraitsLockSystemCanGainNegative
		then
			ETW_CommonFunctions.addTraitToPlayer({
				player = player,
				trait = CharacterTrait.THIN_SKINNED,
				positiveTrait = false,
			})
		end

		if
			player:hasTrait(CharacterTrait.THICK_SKINNED)
			and modData.injuriesCounter <= losePositiveThreshold
			and SBvars.TraitsLockSystemCanLosePositive
		then
			ETW_CommonFunctions.removeTraitFromPlayer({
				player = player,
				trait = CharacterTrait.THICK_SKINNED,
				positiveTrait = true,
			})
		elseif
			not player:hasTrait(CharacterTrait.THICK_SKINNED)
			and not player:hasTrait(CharacterTrait.THIN_SKINNED)
			and modData.injuriesCounter >= gainPositiveThreshold
			and SBvars.TraitsLockSystemCanGainPositive
		then
			ETW_CommonFunctions.addTraitToPlayer({
				player = player,
				trait = CharacterTrait.THICK_SKINNED,
				positiveTrait = true,
			})
		end
	end
end

---Returns whether a fracture on this body part can be splinted by the vanilla health panel.
---@param bodyPart BodyPart
---@return boolean
local function isSplintableFracture(bodyPart)
	local bodyPartType = bodyPart:getType()
	return bodyPartType ~= BodyPartType.Head
		and bodyPartType ~= BodyPartType.Torso_Upper
		and bodyPartType ~= BodyPartType.Torso_Lower
end

---Returns whether this body part has a wound for which a clean bandage is appropriate care.
---@param bodyPart BodyPart
---@return boolean
local function hasBandageTreatableWound(bodyPart)
	return hasScratch(bodyPart)
		or hasLaceration(bodyPart)
		or hasDeepWound(bodyPart)
		or bodyPart:stitched()
		or hasBite(bodyPart)
		or bodyPart:getBurnTime() > 0
		or bodyPart:haveBullet()
		or bodyPart:haveGlass()
end

---Returns the severity-weighted counter change produced by the player's current wound care.
---Wound infection is intentionally not considered; only actionable physical treatment states are evaluated.
---@param player IsoPlayer
---@return number counterChange
---@return integer properlyTendedCount
---@return integer needsAttentionCount
local function getHealerCounterChange(player)
	local bodyParts = player:getBodyDamage():getBodyParts()
	local counterChange = 0
	local properlyTendedCount = 0
	local needsAttentionCount = 0

	for i = 0, bodyParts:size() - 1 do
		local bodyPart = bodyParts:get(i)
		local injuryContribution, hasTrackedInjury = getBodyPartInjuryContribution(bodyPart)
		if bodyPart:stitched() and not hasDeepWound(bodyPart) then
			hasTrackedInjury = true
			injuryContribution = injuryContribution + SBvars.BodyDeepWoundContribution
		end
		if hasTrackedInjury then
			local bandageTreatableWound = hasBandageTreatableWound(bodyPart)
			local hasCleanBandage = bandageTreatableWound
				and bodyPart:bandaged()
				and bodyPart:getBandageLife() > 0
			local hasDirtyBandage = bandageTreatableWound
				and bodyPart:bandaged()
				and bodyPart:getBandageLife() <= 0
			local untreatedFracture = bodyPart:getFractureTime() > 0
				and bodyPart:getSplintFactor() <= 0
				and isSplintableFracture(bodyPart)

			local needsAttention = bodyPart:haveGlass()
				or bodyPart:haveBullet()
				or hasDirtyBandage
				or (bodyPart:bleeding() and not bodyPart:bandaged())
				or (bodyPart:getBurnTime() > 0 and bodyPart:isNeedBurnWash())
				or untreatedFracture

			local properlyTended = hasCleanBandage
				or bodyPart:stitched()
				or (bodyPart:getFractureTime() > 0 and bodyPart:getSplintFactor() > 0)

			if needsAttention then
				needsAttentionCount = needsAttentionCount + 1
				counterChange = counterChange
					- injuryContribution * SBvars.HealerSystemNeedsAttentionMultiplier
			elseif properlyTended then
				properlyTendedCount = properlyTendedCount + 1
				counterChange = counterChange
					+ injuryContribution * SBvars.HealerSystemProperlyTendedMultiplier
			elseif bandageTreatableWound then
				needsAttentionCount = needsAttentionCount + 1
				counterChange = counterChange
					- injuryContribution * SBvars.HealerSystemNeedsAttentionMultiplier
			end
		end
	end

	return counterChange, properlyTendedCount, needsAttentionCount
end

---Updates Slow Healer and Fast Healer from the quality of the player's wound care.
local function healerSystemETW()
	local playersList = ETW_CommonFunctions.playersList()
	local maxCounter = SBvars.HealerSystemCounter
	local gainNegativeThreshold = maxCounter * -2 / 3
	local loseNegativeThreshold = maxCounter * -1 / 3
	local losePositiveThreshold = maxCounter * 1 / 3
	local gainPositiveThreshold = maxCounter * 2 / 3

	for i = 0, playersList:size() - 1 do
		local player = playersList:get(i)
		local modData = ETW_CommonFunctions.getETWModData(player)
		local counterChange, properlyTendedCount, needsAttentionCount = getHealerCounterChange(player)
		counterChange = counterChange / 10
		counterChange = ETW_CommonFunctions.applyAffinityToDirectionalChange(
			modData,
			counterChange,
			CharacterTrait.SLOW_HEALER,
			CharacterTrait.FAST_HEALER
		)
		modData.healerCounter = math.max(-maxCounter, math.min(maxCounter, modData.healerCounter + counterChange))

		logETW(
			"ETW Logger | healerSystemETW(): player="
				.. player:getUsername()
				.. " properlyTended="
				.. properlyTendedCount
				.. " needsAttention="
				.. needsAttentionCount
				.. " counterChange="
				.. counterChange
				.. " healerCounter="
				.. modData.healerCounter
		)

		if
			player:hasTrait(CharacterTrait.SLOW_HEALER)
			and modData.healerCounter >= loseNegativeThreshold
			and SBvars.TraitsLockSystemCanLoseNegative
		then
			ETW_CommonFunctions.removeTraitFromPlayer({
				player = player,
				trait = CharacterTrait.SLOW_HEALER,
				positiveTrait = false,
			})
		elseif
			not player:hasTrait(CharacterTrait.SLOW_HEALER)
			and not player:hasTrait(CharacterTrait.FAST_HEALER)
			and modData.healerCounter <= gainNegativeThreshold
			and SBvars.TraitsLockSystemCanGainNegative
		then
			ETW_CommonFunctions.addTraitToPlayer({
				player = player,
				trait = CharacterTrait.SLOW_HEALER,
				positiveTrait = false,
			})
		end

		if
			player:hasTrait(CharacterTrait.FAST_HEALER)
			and modData.healerCounter <= losePositiveThreshold
			and SBvars.TraitsLockSystemCanLosePositive
		then
			ETW_CommonFunctions.removeTraitFromPlayer({
				player = player,
				trait = CharacterTrait.FAST_HEALER,
				positiveTrait = true,
			})
		elseif
			not player:hasTrait(CharacterTrait.FAST_HEALER)
			and not player:hasTrait(CharacterTrait.SLOW_HEALER)
			and modData.healerCounter >= gainPositiveThreshold
			and SBvars.TraitsLockSystemCanGainPositive
		then
			ETW_CommonFunctions.addTraitToPlayer({
				player = player,
				trait = CharacterTrait.FAST_HEALER,
				positiveTrait = true,
			})
		end
	end
end

---Function responsible for managing Asthmatic trait
local function asthmaticTraitETW()
	local playersList = ETW_CommonFunctions.playersList()

	for i = 0, playersList:size() - 1 do
		local player = playersList:get(i)
		logETW("ETW Logger | asthmaticTraitETW(): running for player " .. player:getUsername())
		local modData = ETW_CommonFunctions.getETWModData(player)
		local running = player:isRunning()
		local sprinting = player:isSprinting()
		local smoker = player:hasTrait(CharacterTrait.SMOKER)
		local asthmatic = player:hasTrait(CharacterTrait.ASTHMATIC)
		local outside = player:isOutside()
		local endurance = player:getStats():get(CharacterStat.ENDURANCE) -- 0-1
		local temperature = getClimateManager():getAirTemperatureForCharacter(player)
		local temperatureMultiplier = math.max(0, 1.01 ^ (-7.6 * temperature) + 0.53)
		local lowerBoundary = -2 * SBvars.AsthmaticCounter
		local upperBoundary = 2 * SBvars.AsthmaticCounter
		if (running or sprinting) and (temperature <= 10 or smoker) then
			local counterDecrease = temperatureMultiplier
				* (outside and 1.2 or 1)
				* (smoker and 1.5 or 0.8)
				* (asthmatic and 1.5 or 0.8)
				* (sprinting and 1.5 or 1)
			local counterChange = ETW_CommonFunctions.applyAffinityToDirectionalChange(
				modData,
				-counterDecrease,
				CharacterTrait.ASTHMATIC,
				nil
			)
			modData.AsthmaticCounter = math.max(lowerBoundary, modData.AsthmaticCounter + counterChange)
			logETW(
				"ETW Logger | asthmaticTraitETW(): counterDecrease: "
					.. -counterChange
					.. ", modData.AsthmaticCounter: "
					.. modData.AsthmaticCounter
			)
		end
		if not running and not sprinting and temperature >= 0 then
			local counterIncrease = (1 + player:getPerkLevel(Perks.Fitness) * 0.1)
				* (smoker and 0.5 or 1)
				* (asthmatic and 0.5 or 1)
				* endurance
			counterIncrease = ETW_CommonFunctions.applyAffinityToDirectionalChange(
				modData,
				counterIncrease,
				CharacterTrait.ASTHMATIC,
				nil
			)
			modData.AsthmaticCounter = math.min(upperBoundary, modData.AsthmaticCounter + counterIncrease)
			logETW(
				"ETW Logger | asthmaticTraitETW(): counterDecrease: "
					.. counterIncrease
					.. ", modData.AsthmaticCounter: "
					.. modData.AsthmaticCounter
			)
		end
		if
			modData.AsthmaticCounter <= -SBvars.AsthmaticCounter
			and not player:hasTrait(CharacterTrait.ASTHMATIC)
			and SBvars.TraitsLockSystemCanGainNegative
		then
			ETW_CommonFunctions.addTraitToPlayer({
				player = player,
				trait = CharacterTrait.ASTHMATIC,
				positiveTrait = false,
			})
		elseif
			modData.AsthmaticCounter >= SBvars.AsthmaticCounter
			and player:hasTrait(CharacterTrait.ASTHMATIC)
			and SBvars.TraitsLockSystemCanLoseNegative
		then
			ETW_CommonFunctions.removeTraitFromPlayer({
				player = player,
				trait = CharacterTrait.ASTHMATIC,
				positiveTrait = false,
			})
		end
	end
end

---Function responsible for recording players mental state into mod data
local function recordMentalStateETW()
	local playersList = ETW_CommonFunctions.playersList()

	for i = 0, playersList:size() - 1 do
		local player = playersList:get(i)
		local modData = ETW_CommonFunctions.getETWModData(player)
		logETW("ETW Logger | recordMentalStateETW(): running for player " .. player:getUsername())
		local stats = player:getStats()
		local anger = stats:get(CharacterStat.ANGER) -- 0-1
		local stress = stats:get(CharacterStat.STRESS) -- 0-1
		local unhappiness = stats:get(CharacterStat.UNHAPPINESS) / 100 -- 0-100 -> 0-1
		local panic = stats:get(CharacterStat.PANIC) / 100 -- 0-100 -> 0-1
		local mentalHealth = 1 - ((anger + stress + unhappiness + panic) / 4)
		modData.RecentAverageMental = updateRollingHabitAverage(
			modData.MentalStateInLast60Min,
			modData.MentalStateInLast24Hours,
			modData.MentalStateInLast31Days,
			mentalHealth,
			"recordMentalStateETW"
		)
	end
end

---Function responsible for managing Pain Tolerance trait
local function painToleranceTraitETW()
	local playersList = ETW_CommonFunctions.playersList()

	for i = 0, playersList:size() - 1 do
		local player = playersList:get(i)
		logETW("ETW Logger | painToleranceTraitETW(): running for player " .. player:getUsername())
		local modData = ETW_CommonFunctions.getETWModData(player)
		modData.PainToleranceCounter = modData.PainToleranceCounter + player:getStats():get(CharacterStat.PAIN) -- pain is 0-100
		logETW("ETW Logger | painToleranceTraitETW(): pain counter: " .. modData.PainToleranceCounter)
		if modData.PainToleranceCounter >= SBvars.PainToleranceCounter then
			if
				SBvars.DelayedTraitsSystem
				and not ETW_CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, ETWTraitsRegistry.PAIN_TOLERANCE)
			then
				ETW_CommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = ETWTraitsRegistry.PAIN_TOLERANCE,
					player = player,
					positiveTrait = true,
					gainingTrait = true,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (
					SBvars.DelayedTraitsSystem
					and ETW_CommonFunctions.checkDelayedTraits(player, ETWTraitsRegistry.PAIN_TOLERANCE)
				)
			then
				ETW_CommonFunctions.addTraitToPlayer({
					player = player,
					trait = ETWTraitsRegistry.PAIN_TOLERANCE,
					positiveTrait = true,
				})
				Events.EveryTenMinutes.Remove(painToleranceTraitETW)
			end
		end
	end
end

---Function responsible for setting up events
---@param playerIndex number
---@param player IsoPlayer
local function initializeEventsETW(playerIndex, player)
	Events.EveryOneMinute.Remove(immunitySystemTraits)
	if ETW_CommonLogicChecks.ImmunitySystemShouldExecute(player) then
		Events.EveryOneMinute.Add(immunitySystemTraits)
	end
	Events.EveryOneMinute.Remove(foodSicknessTraitsETW)
	if ETW_CommonLogicChecks.FoodSicknessSystemShouldExecute(player) then
		Events.EveryOneMinute.Add(foodSicknessTraitsETW)
	end
	Events.EveryOneMinute.Remove(recordFoodStateETW)
	if ETW_CommonLogicChecks.FoodSystemShouldExecute(player) then
		Events.EveryOneMinute.Add(recordFoodStateETW)
	end
	Events.EveryTenMinutes.Remove(foodSystemETW)
	if ETW_CommonLogicChecks.FoodSystemShouldExecute(player) then
		Events.EveryTenMinutes.Add(foodSystemETW)
	end
	Events.EveryOneMinute.Remove(recordThirstStateETW)
	if ETW_CommonLogicChecks.ThirstSystemShouldExecute(player) then
		Events.EveryOneMinute.Add(recordThirstStateETW)
	end
	Events.EveryTenMinutes.Remove(thirstSystemETW)
	if ETW_CommonLogicChecks.ThirstSystemShouldExecute(player) then
		Events.EveryTenMinutes.Add(thirstSystemETW)
	end
	Events.EveryTenMinutes.Remove(injuriesSystemETW)
	if ETW_CommonLogicChecks.InjuriesSystemShouldExecute(player) then
		Events.EveryTenMinutes.Add(injuriesSystemETW)
	end
	Events.EveryOneMinute.Remove(healerSystemETW)
	if ETW_CommonLogicChecks.HealerSystemShouldExecute(player) then
		Events.EveryOneMinute.Add(healerSystemETW)
	end
	Events.EveryTenMinutes.Remove(painToleranceTraitETW)
	if ETW_CommonLogicChecks.PainToleranceShouldExecute(player) then
		Events.EveryTenMinutes.Add(painToleranceTraitETW)
	end
	Events.EveryOneMinute.Remove(asthmaticTraitETW)
	if ETW_CommonLogicChecks.AsthmaticShouldExecute(player) then
		Events.EveryOneMinute.Add(asthmaticTraitETW)
	end
	Events.EveryOneMinute.Remove(recordMentalStateETW)
	Events.EveryOneMinute.Add(recordMentalStateETW)
	if gameMode == ETW_CommonFunctions.GameMode.MP_SERVER then
		Events.OnTick.Remove(initializeEventsETW)
	end
end

---Function responsible for clearing events
---@param character IsoPlayer
local function clearEventsETW(character)
	Events.EveryOneMinute.Remove(immunitySystemTraits)
	Events.EveryOneMinute.Remove(foodSicknessTraitsETW)
	Events.EveryOneMinute.Remove(recordFoodStateETW)
	Events.EveryTenMinutes.Remove(foodSystemETW)
	Events.EveryOneMinute.Remove(recordThirstStateETW)
	Events.EveryTenMinutes.Remove(thirstSystemETW)
	Events.EveryTenMinutes.Remove(injuriesSystemETW)
	Events.EveryOneMinute.Remove(healerSystemETW)
	Events.EveryTenMinutes.Remove(painToleranceTraitETW)
	Events.EveryOneMinute.Remove(asthmaticTraitETW)
	Events.EveryOneMinute.Remove(recordMentalStateETW)
	logETW("ETW Logger | System: clearEventsETW in " .. FILENAME)
end

if gameMode == ETW_CommonFunctions.GameMode.SP then
	Events.OnCreatePlayer.Remove(initializeEventsETW)
	Events.OnCreatePlayer.Add(initializeEventsETW)
	Events.OnPlayerDeath.Remove(clearEventsETW)
	Events.OnPlayerDeath.Add(clearEventsETW)
elseif gameMode == ETW_CommonFunctions.GameMode.MP_SERVER then
	Events.OnTick.Add(initializeEventsETW)
end
