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

---Function responsible for managing Immunity traits
local function immunitySystemTraits()
	local playersList = ETW_CommonFunctions.playersList()

	for i = 0, playersList:size() - 1 do
		local player = playersList:get(i)
		ETW_CommonFunctions.log("ETW Logger | immunitySystemTraits(): running for player " .. player:getUsername())
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
			ETW_CommonFunctions.log(
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
		ETW_CommonFunctions.log("ETW Logger | foodSicknessTraitsETW(): running for player " .. player:getUsername())
		local stats = player:getStats()
		local foodSicknessStrength = stats:get(CharacterStat.FOOD_SICKNESS) / 100 -- 0-100 -> 0-1
		local normalSickness = stats:get(CharacterStat.SICKNESS) -- 0-1
		ETW_CommonFunctions.log(
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

---Function responsible for checking if players sleep health is good (if applicable)
--- @param SleepHealthinessBar number
local function sleepCheck(SleepHealthinessBar)
	if not getServerOptions():getBoolean("SleepNeeded") then
		return true
	end
	if SBvars.SleepSystem == true and SleepHealthinessBar > 0 then
		return true
	end
	if SBvars.SleepSystem == false then
		return true
	end
	return false
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
		ETW_CommonFunctions.log("ETW Logger | " .. label .. "(): average in last 60 min: " .. hourAverage)
		table.insert(samples24, hourAverage)
		samples60[1] = hourAverage
		for i = #samples60, 2, -1 do
			table.remove(samples60, i)
		end

		local dayAverage = getRollingAverage(samples24, 24)
		if dayAverage then
			ETW_CommonFunctions.log("ETW Logger | " .. label .. "(): average in last 24 hours: " .. dayAverage)
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

---Records the player's current hunger value into food-system rolling averages.
local function recordFoodStateETW()
	local playersList = ETW_CommonFunctions.playersList()

	for i = 0, playersList:size() - 1 do
		local player = playersList:get(i)
		local modData = ETW_CommonFunctions.getETWModData(player)
		local stats = player:getStats()
		if player:isAsleep() then
			ETW_CommonFunctions.log("ETW Logger | recordFoodStateETW(): skipping sleeping player " .. player:getUsername())
		else
			local hunger = stats:get(CharacterStat.HUNGER)
			ETW_CommonFunctions.log(
				"ETW Logger | recordFoodStateETW(): player "
					.. player:getUsername()
					.. ", hunger = "
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

---Records the player's current thirst value into thirst-system rolling averages.
local function recordThirstStateETW()
	local playersList = ETW_CommonFunctions.playersList()

	for i = 0, playersList:size() - 1 do
		local player = playersList:get(i)
		local modData = ETW_CommonFunctions.getETWModData(player)
		local stats = player:getStats()
		if player:isAsleep() then
			ETW_CommonFunctions.log("ETW Logger | recordThirstStateETW(): skipping sleeping player " .. player:getUsername())
		else
			local thirst = stats:get(CharacterStat.THIRST)
			ETW_CommonFunctions.log(
				"ETW Logger | recordThirstStateETW(): player "
					.. player:getUsername()
					.. ", thirst = "
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

---Applies Food System trait gain/loss rules from the player's long-term average hunger value.
local function foodSystemETW()
	local playersList = ETW_CommonFunctions.playersList()

	for i = 0, playersList:size() - 1 do
		local player = playersList:get(i)
		local modData = ETW_CommonFunctions.getETWModData(player)
		local averageHunger = modData.RecentAverageFood
		ETW_CommonFunctions.log(
			"ETW Logger | foodSystemETW(): running for player "
				.. player:getUsername()
				.. ", RecentAverageFood = "
				.. averageHunger
		)

		if
			player:hasTrait(CharacterTrait.HEARTY_APPETITE)
			and averageHunger <= SBvars.FoodSystemLoseNegativeThreshold
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
			and averageHunger >= SBvars.FoodSystemGainNegativeThreshold
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
			and averageHunger >= SBvars.FoodSystemLosePositiveThreshold
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
			and averageHunger <= SBvars.FoodSystemGainPositiveThreshold
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

---Applies Thirst System trait gain/loss rules from the player's long-term average thirst value.
local function thirstSystemETW()
	local playersList = ETW_CommonFunctions.playersList()

	for i = 0, playersList:size() - 1 do
		local player = playersList:get(i)
		local modData = ETW_CommonFunctions.getETWModData(player)
		local averageThirst = modData.RecentAverageThirst
		ETW_CommonFunctions.log(
			"ETW Logger | thirstSystemETW(): running for player "
				.. player:getUsername()
				.. ", RecentAverageThirst = "
				.. averageThirst
		)

		if
			player:hasTrait(CharacterTrait.HIGH_THIRST)
			and averageThirst <= SBvars.ThirstSystemLoseNegativeThreshold
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
			and averageThirst >= SBvars.ThirstSystemGainNegativeThreshold
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
			and averageThirst >= SBvars.ThirstSystemLosePositiveThreshold
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
			and averageThirst <= SBvars.ThirstSystemGainPositiveThreshold
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

---Function responsible for managing Weight System traits
local function weightSystemETW()
	local playersList = ETW_CommonFunctions.playersList()

	for i = 0, playersList:size() - 1 do
		local player = playersList:get(i)
		ETW_CommonFunctions.log("ETW Logger | weightSystemETW(): running for player " .. player:getUsername())
		local modData = ETW_CommonFunctions.getETWModData(player)
		local startingTraits = modData.StartingTraits
		local weight = player:getNutrition():getWeight()
		if weight >= 100 or weight <= 65 then
			if
				not player:hasTrait(CharacterTrait.SLOW_HEALER)
				and startingTraits.FastHealer ~= true
				and SBvars.TraitsLockSystemCanGainNegative
			then
				ETW_CommonFunctions.addTraitToPlayer({
					player = player,
					trait = CharacterTrait.SLOW_HEALER,
					positiveTrait = false,
				})
			end
			if
				not player:hasTrait(CharacterTrait.THIN_SKINNED)
				and startingTraits.ThickSkinned ~= true
				and SBvars.TraitsLockSystemCanGainNegative
			then
				ETW_CommonFunctions.addTraitToPlayer({
					player = player,
					trait = CharacterTrait.THIN_SKINNED,
					positiveTrait = false,
				})
			end
		else
			if
				player:hasTrait(CharacterTrait.THIN_SKINNED)
				and startingTraits.ThinSkinned ~= true
				and SBvars.TraitsLockSystemCanLoseNegative
			then
					ETW_CommonFunctions.removeTraitFromPlayer({
						player = player,
						trait = CharacterTrait.THIN_SKINNED,
						positiveTrait = false,
					})
			end
			if
				player:hasTrait(CharacterTrait.SLOW_HEALER)
				and startingTraits.SlowHealer ~= true
				and SBvars.TraitsLockSystemCanLoseNegative
			then
					ETW_CommonFunctions.removeTraitFromPlayer({
						player = player,
						trait = CharacterTrait.SLOW_HEALER,
						positiveTrait = false,
					})
			end
		end
		if (weight > 85 and weight < 100) or (weight > 65 and weight < 75) then
			if
				player:hasTrait(CharacterTrait.THICK_SKINNED)
				and startingTraits.ThickSkinned ~= true
				and SBvars.TraitsLockSystemCanLosePositive
			then
				ETW_CommonFunctions.removeTraitFromPlayer({
					player = player,
					trait = CharacterTrait.THICK_SKINNED,
					positiveTrait = true,
				})
			end
			if
				player:hasTrait(CharacterTrait.FAST_HEALER)
				and startingTraits.FastHealer ~= true
				and SBvars.TraitsLockSystemCanLosePositive
			then
				ETW_CommonFunctions.removeTraitFromPlayer({
					player = player,
					trait = CharacterTrait.FAST_HEALER,
					positiveTrait = true,
				})
			end
		end
		if weight >= 75 and weight <= 85 then
			-- losing Thick Skinned and Fast Healer if mental state not good
			if modData.RecentAverageMental <= (SBvars.WeightSystemLowerMentalThreshold / 100) then
				if
					player:hasTrait(CharacterTrait.THICK_SKINNED)
					and startingTraits.ThickSkinned ~= true
					and SBvars.TraitsLockSystemCanLosePositive
				then
					ETW_CommonFunctions.removeTraitFromPlayer({
						player = player,
						trait = CharacterTrait.THICK_SKINNED,
						positiveTrait = true,
					})
				end
				if
					player:hasTrait(CharacterTrait.FAST_HEALER)
					and startingTraits.FastHealer ~= true
					and SBvars.TraitsLockSystemCanLosePositive
				then
					ETW_CommonFunctions.removeTraitFromPlayer({
						player = player,
						trait = CharacterTrait.FAST_HEALER,
						positiveTrait = true,
					})
				end
			else -- gaining Thick Skinned and Fast Healer if weight 75-85, mental is good, passive levels are good and sleep health enabled
				local passiveLevels = player:getPerkLevel(Perks.Strength) + player:getPerkLevel(Perks.Fitness)
				if
					sleepCheck(modData.SleepSystem.SleepHealthinessBar)
					and passiveLevels >= SBvars.WeightSystemSkill
				then
					if
						not player:hasTrait(CharacterTrait.THICK_SKINNED)
						and startingTraits.ThinSkinned ~= true
						and SBvars.TraitsLockSystemCanGainPositive
					then
						ETW_CommonFunctions.addTraitToPlayer({
							player = player,
							trait = CharacterTrait.THICK_SKINNED,
							positiveTrait = true,
						})
					end
					if
						not player:hasTrait(CharacterTrait.FAST_HEALER)
						and startingTraits.SlowHealer ~= true
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
		end
	end
end

---Function responsible for managing Asthmatic trait
local function asthmaticTraitETW()
	local playersList = ETW_CommonFunctions.playersList()

	for i = 0, playersList:size() - 1 do
		local player = playersList:get(i)
		ETW_CommonFunctions.log("ETW Logger | asthmaticTraitETW(): running for player " .. player:getUsername())
		local modData = ETW_CommonFunctions.getETWModData(player)
		local startedWithAsthmatic = modData.StartingTraits[CharacterTrait.ASTHMATIC:toString()]
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
			counterDecrease = counterDecrease
				* ((SBvars.AffinitySystem and startedWithAsthmatic) and SBvars.AffinitySystemGainMultiplier or 1)
			modData.AsthmaticCounter = math.max(lowerBoundary, modData.AsthmaticCounter - counterDecrease)
			ETW_CommonFunctions.log(
				"ETW Logger | asthmaticTraitETW(): counterDecrease: "
					.. counterDecrease
					.. ", modData.AsthmaticCounter: "
					.. modData.AsthmaticCounter
			)
		end
		if not running and not sprinting and temperature >= 0 then
			local counterIncrease = (1 + player:getPerkLevel(Perks.Fitness) * 0.1)
				* (smoker and 0.5 or 1)
				* (asthmatic and 0.5 or 1)
				* endurance
			counterIncrease = counterIncrease
				/ ((SBvars.AffinitySystem and startedWithAsthmatic) and SBvars.AffinitySystemLoseDivider or 1)
			modData.AsthmaticCounter = math.min(upperBoundary, modData.AsthmaticCounter + counterIncrease)
			ETW_CommonFunctions.log(
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
		ETW_CommonFunctions.log("ETW Logger | recordMentalStateETW(): running for player " .. player:getUsername())
		local stats = player:getStats()
		local anger = stats:get(CharacterStat.ANGER) -- 0-1
		local stress = stats:get(CharacterStat.STRESS) -- 0-1
		local unhappiness = stats:get(CharacterStat.UNHAPPINESS) / 100 -- 0-100 -> 0-1
		local panic = stats:get(CharacterStat.PANIC) / 100 -- 0-100 -> 0-1
		local mentalHealth = 1 - ((anger + stress + unhappiness + panic) / 4)
		table.insert(modData.MentalStateInLast60Min, mentalHealth)
		if #modData.MentalStateInLast60Min >= 60 then
			local sum = 0
			for i = 1, 60 do
				sum = sum + modData.MentalStateInLast60Min[i]
			end
			local average = sum / 60
			ETW_CommonFunctions.log("ETW Logger | recordMentalStateETW(): average mental in last 60 min: " .. average)
			table.insert(modData.MentalStateInLast24Hours, average)
			modData.MentalStateInLast60Min = { average }
			-- last 24h mental
			if #modData.MentalStateInLast24Hours >= 24 then
				sum = 0
				for i = 1, 24 do
					sum = sum + modData.MentalStateInLast24Hours[i]
				end
				average = sum / 24
				ETW_CommonFunctions.log(
					"ETW Logger | recordMentalStateETW(): average mental in last 24 hours: " .. average
				)
				table.insert(modData.MentalStateInLast31Days, average)
				modData.MentalStateInLast24Hours = { average }
				-- last days mental
				sum = 0
				for i = 1, #modData.MentalStateInLast31Days do
					sum = sum + modData.MentalStateInLast31Days[i]
				end
				modData.RecentAverageMental = sum / #modData.MentalStateInLast31Days
				ETW_CommonFunctions.log(
					"ETW Logger | recordMentalStateETW(): average mental in last 31 days: "
						.. modData.RecentAverageMental
				)
				if #modData.MentalStateInLast31Days > 31 then
					table.remove(modData.MentalStateInLast31Days, 1)
				end
			end
		end
	end
end

---Function responsible for managing Pain Tolerance trait
local function painToleranceTraitETW()
	local playersList = ETW_CommonFunctions.playersList()

	for i = 0, playersList:size() - 1 do
		local player = playersList:get(i)
		ETW_CommonFunctions.log("ETW Logger | painToleranceTraitETW(): running for player " .. player:getUsername())
		local modData = ETW_CommonFunctions.getETWModData(player)
		modData.PainToleranceCounter = modData.PainToleranceCounter + player:getStats():get(CharacterStat.PAIN) -- pain is 0-100
		ETW_CommonFunctions.log("ETW Logger | painToleranceTraitETW(): pain counter: " .. modData.PainToleranceCounter)
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
				ETW_InitiatePainToleranceTrait(player)
				Events.EveryTenMinutes.Remove(painToleranceTraitETW)
			end
		end
	end
end

---@return boolean
local noTraitsLock = function()
	return (
		SBvars.TraitsLockSystemCanGainNegative
		or SBvars.TraitsLockSystemCanLoseNegative
		or SBvars.TraitsLockSystemCanGainPositive
		or SBvars.TraitsLockSystemCanLosePositive
	)
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
	Events.EveryTenMinutes.Remove(weightSystemETW)
	if SBvars.WeightSystem == true and noTraitsLock() then
		Events.EveryTenMinutes.Add(weightSystemETW)
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
	Events.EveryTenMinutes.Remove(weightSystemETW)
	Events.EveryTenMinutes.Remove(painToleranceTraitETW)
	Events.EveryOneMinute.Remove(asthmaticTraitETW)
	Events.EveryOneMinute.Remove(recordMentalStateETW)
	ETW_CommonFunctions.log("ETW Logger | System: clearEventsETW in " .. FILENAME)
end

if gameMode == ETW_CommonFunctions.GameMode.SP then
	Events.OnCreatePlayer.Remove(initializeEventsETW)
	Events.OnCreatePlayer.Add(initializeEventsETW)
	Events.OnPlayerDeath.Remove(clearEventsETW)
	Events.OnPlayerDeath.Add(clearEventsETW)
elseif gameMode == ETW_CommonFunctions.GameMode.MP_SERVER then
	Events.OnTick.Add(initializeEventsETW)
end
