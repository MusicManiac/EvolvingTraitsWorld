local ETW_ModDataServer = require("ETW_ModDataServer")
local ETW_CommonFunctions = require("ETW_CommonFunctions")
local ETW_CommonLogicChecks = require("ETW_CommonLogicChecks")
local ETWRegistries = require("ETW_Registry")
local ETWTraitsRegistry = ETWRegistries.traits

local gameMode = ETW_CommonFunctions.gameMode()

---@type EvolvingTraitsWorldSandboxVars
local SBvars = SandboxVars.EvolvingTraitsWorld

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
					and not ETW_CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, CharacterTrait.PRONE_TO_ILLNESS)
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
					or (SBvars.DelayedTraitsSystem and ETW_CommonFunctions.checkDelayedTraits(player, CharacterTrait.PRONE_TO_ILLNESS))
				then
					ETW_CommonFunctions.removeTraitFromPlayer(player, CharacterTrait.PRONE_TO_ILLNESS)
					ETW_CommonFunctions.displayTraitNotification(player, getText("UI_trait_pronetoillness"), false, HaloTextHelper.getColorGreen())
				end
			elseif
				not player:hasTrait(CharacterTrait.PRONE_TO_ILLNESS)
				and not player:hasTrait(CharacterTrait.RESILIENT)
				and modData.ImmunitySystemCounter >= SBvars.ImmunitySystemCounter
				and SBvars.TraitsLockSystemCanGainPositive
			then
				if SBvars.DelayedTraitsSystem and not ETW_CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, CharacterTrait.RESILIENT) then
					ETW_CommonFunctions.addTraitToDelayTable({
						modData = modData,
						trait = CharacterTrait.RESILIENT,
						player = player,
						positiveTrait = true,
						gainingTrait = true,
					})
				elseif
					not SBvars.DelayedTraitsSystem
					or (SBvars.DelayedTraitsSystem and ETW_CommonFunctions.checkDelayedTraits(player, CharacterTrait.RESILIENT))
				then
					ETW_CommonFunctions.addTraitToPlayer(player, CharacterTrait.RESILIENT)
					Events.EveryOneMinute.Remove(immunitySystemTraits)
					ETW_CommonFunctions.displayTraitNotification(player, getText("UI_trait_resilient"), true, HaloTextHelper.getColorGreen())
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
			+ math.max((normalSickness - foodSicknessStrength), 0) * SBvars.FoodSicknessSystemNormalSicknessMultiplier
		)
		if
			player:hasTrait(CharacterTrait.WEAK_STOMACH)
			and modData.FoodSicknessWeathered >= SBvars.FoodSicknessSystemCounter / 2
			and SBvars.TraitsLockSystemCanLoseNegative
		then
			if SBvars.DelayedTraitsSystem and not ETW_CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, CharacterTrait.WEAK_STOMACH) then
				ETW_CommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = CharacterTrait.WEAK_STOMACH,
					player = player,
					positiveTrait = false,
					gainingTrait = false,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (SBvars.DelayedTraitsSystem and ETW_CommonFunctions.checkDelayedTraits(player, CharacterTrait.WEAK_STOMACH))
			then
				ETW_CommonFunctions.removeTraitFromPlayer(player, CharacterTrait.WEAK_STOMACH)
				ETW_CommonFunctions.displayTraitNotification(player, getText("UI_trait_WeakStomach"), false, HaloTextHelper.getColorGreen())
			end
		elseif
			not player:hasTrait(CharacterTrait.WEAK_STOMACH)
			and not player:hasTrait(CharacterTrait.IRON_GUT)
			and modData.FoodSicknessWeathered >= SBvars.FoodSicknessSystemCounter
			and SBvars.TraitsLockSystemCanGainPositive
		then
			if SBvars.DelayedTraitsSystem and not ETW_CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, CharacterTrait.IRON_GUT) then
				ETW_CommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = CharacterTrait.IRON_GUT,
					player = player,
					positiveTrait = true,
					gainingTrait = true,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (SBvars.DelayedTraitsSystem and ETW_CommonFunctions.checkDelayedTraits(player, CharacterTrait.IRON_GUT))
			then
				ETW_CommonFunctions.addTraitToPlayer(player, CharacterTrait.IRON_GUT)
				Events.EveryOneMinute.Remove(foodSicknessTraitsETW)
				ETW_CommonFunctions.displayTraitNotification(player, getText("UI_trait_IronGut"), true, HaloTextHelper.getColorGreen())
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
				ETW_CommonFunctions.addTraitToPlayer(player, CharacterTrait.SLOW_HEALER)
				ETW_CommonFunctions.displayTraitNotification(
					notification,
					player,
					getText("UI_trait_SlowHealer"),
					true,
					HaloTextHelper.getColorRed()
				)
			end
			if
				not player:hasTrait(CharacterTrait.THIN_SKINNED)
				and startingTraits.ThickSkinned ~= true
				and SBvars.TraitsLockSystemCanGainNegative
			then
				ETW_CommonFunctions.addTraitToPlayer(player, CharacterTrait.THIN_SKINNED)
				ETW_CommonFunctions.displayTraitNotification(player, getText("UI_trait_ThinSkinned"), true, HaloTextHelper.getColorRed())
			end
		else
			if
				player:hasTrait(CharacterTrait.THIN_SKINNED)
				and startingTraits.ThinSkinned ~= true
				and SBvars.TraitsLockSystemCanLoseNegative
			then
				ETW_CommonFunctions.removeTraitFromPlayer(player, CharacterTrait.THIN_SKINNED)
				ETW_CommonFunctions.displayTraitNotification(player, getText("UI_trait_ThinSkinned"), false, HaloTextHelper.getColorGreen())
			end
			if
				player:hasTrait(CharacterTrait.SLOW_HEALER)
				and startingTraits.SlowHealer ~= true
				and SBvars.TraitsLockSystemCanLoseNegative
			then
				ETW_CommonFunctions.removeTraitFromPlayer(player, CharacterTrait.SLOW_HEALER)
				ETW_CommonFunctions.displayTraitNotification(player, getText("UI_trait_SlowHealer"), false, HaloTextHelper.getColorGreen())
			end
		end
		if (weight > 85 and weight < 100) or (weight > 65 and weight < 75) then
			if
				not player:hasTrait(CharacterTrait.HEARTY_APPETITE)
				and startingTraits.LightEater ~= true
				and SBvars.TraitsLockSystemCanGainNegative
			then
				ETW_CommonFunctions.addTraitToPlayer(player, CharacterTrait.HEARTY_APPETITE)
				ETW_CommonFunctions.displayTraitNotification(player, getText("UI_trait_heartyappetite"), true, HaloTextHelper.getColorRed())
			end
			if
				not player:hasTrait(CharacterTrait.HIGH_THIRST)
				and startingTraits.LowThirst ~= true
				and SBvars.TraitsLockSystemCanGainNegative
			then
				ETW_CommonFunctions.addTraitToPlayer(player, CharacterTrait.HIGH_THIRST)
				ETW_CommonFunctions.displayTraitNotification(player, getText("UI_trait_HighThirst"), true, HaloTextHelper.getColorRed())
			end
			if
				player:hasTrait(CharacterTrait.THICK_SKINNED)
				and startingTraits.ThickSkinned ~= true
				and SBvars.TraitsLockSystemCanLosePositive
			then
				ETW_CommonFunctions.removeTraitFromPlayer(player, CharacterTrait.THICK_SKINNED)
				ETW_CommonFunctions.displayTraitNotification(player, getText("UI_trait_thickskinned"), false, HaloTextHelper.getColorRed())
			end
			if
				player:hasTrait(CharacterTrait.FAST_HEALER)
				and startingTraits.FastHealer ~= true
				and SBvars.TraitsLockSystemCanLosePositive
			then
				ETW_CommonFunctions.removeTraitFromPlayer(player, CharacterTrait.FAST_HEALER)
				ETW_CommonFunctions.displayTraitNotification(player, getText("UI_trait_FastHealer"), false, HaloTextHelper.getColorRed())
			end
			if
				player:hasTrait(CharacterTrait.LIGHT_EATER)
				and startingTraits.LightEater ~= true
				and SBvars.TraitsLockSystemCanLosePositive
			then
				ETW_CommonFunctions.removeTraitFromPlayer(player, CharacterTrait.LIGHT_EATER)
				ETW_CommonFunctions.displayTraitNotification(player, getText("UI_trait_lighteater"), false, HaloTextHelper.getColorRed())
			end
			if
				player:hasTrait(CharacterTrait.LOW_THIRST)
				and startingTraits.LowThirst ~= true
				and SBvars.TraitsLockSystemCanLosePositive
			then
				ETW_CommonFunctions.removeTraitFromPlayer(player, CharacterTrait.LOW_THIRST)
				ETW_CommonFunctions.displayTraitNotification(player, getText("UI_trait_LowThirst"), false, HaloTextHelper.getColorRed())
			end
		end
		if weight >= 75 and weight <= 85 then
			-- losing Hearty Appetite and High Thirst if weight 75-85
			if
				player:hasTrait(CharacterTrait.HEARTY_APPETITE)
				and startingTraits.HeartyAppetite ~= true
				and SBvars.TraitsLockSystemCanLoseNegative
			then
				ETW_CommonFunctions.removeTraitFromPlayer(player, CharacterTrait.HEARTY_APPETITE)
				ETW_CommonFunctions.displayTraitNotification(player, getText("UI_trait_heartyappetite"), false, HaloTextHelper.getColorGreen())
			end
			if
				player:hasTrait(CharacterTrait.HIGH_THIRST)
				and startingTraits.HighThirst ~= true
				and SBvars.TraitsLockSystemCanLoseNegative
			then
				ETW_CommonFunctions.removeTraitFromPlayer(player, CharacterTrait.HIGH_THIRST)
				ETW_CommonFunctions.displayTraitNotification(player, getText("UI_trait_HighThirst"), false, HaloTextHelper.getColorGreen())
			end
			-- losing Thick Skinned and Fast Healer if mental state not good
			if modData.RecentAverageMental <= (SBvars.WeightSystemLowerMentalThreshold / 100) then
				if
					player:hasTrait(CharacterTrait.THICK_SKINNED)
					and startingTraits.ThickSkinned ~= true
					and SBvars.TraitsLockSystemCanLosePositive
				then
					ETW_CommonFunctions.removeTraitFromPlayer(player, CharacterTrait.THICK_SKINNED)
					ETW_CommonFunctions.displayTraitNotification(player, getText("UI_trait_thickskinned"), false, HaloTextHelper.getColorRed())
				end
				if
					player:hasTrait(CharacterTrait.FAST_HEALER)
					and startingTraits.FastHealer ~= true
					and SBvars.TraitsLockSystemCanLosePositive
				then
					ETW_CommonFunctions.removeTraitFromPlayer(player, CharacterTrait.FAST_HEALER)
					ETW_CommonFunctions.displayTraitNotification(player, getText("UI_trait_FastHealer"), false, HaloTextHelper.getColorRed())
				end
			else -- gaining Thick Skinned and Fast Healer if weight 75-85, mental is good, passive levels are good and sleep health enabled
				local passiveLevels = player:getPerkLevel(Perks.Strength) + player:getPerkLevel(Perks.Fitness)
				if sleepCheck(modData.SleepSystem.SleepHealthinessBar) and passiveLevels >= SBvars.WeightSystemSkill then
					if
						not player:hasTrait(CharacterTrait.THICK_SKINNED)
						and startingTraits.ThinSkinned ~= true
						and SBvars.TraitsLockSystemCanGainPositive
					then
						ETW_CommonFunctions.addTraitToPlayer(player, CharacterTrait.THICK_SKINNED)
						ETW_CommonFunctions.displayTraitNotification(player, getText("UI_trait_thickskinned"), true, HaloTextHelper.getColorGreen())
					end
					if
						not player:hasTrait(CharacterTrait.FAST_HEALER)
						and startingTraits.SlowHealer ~= true
						and SBvars.TraitsLockSystemCanGainPositive
					then
						ETW_CommonFunctions.addTraitToPlayer(player, CharacterTrait.FAST_HEALER)
						ETW_CommonFunctions.displayTraitNotification(player, getText("UI_trait_FastHealer"), true, HaloTextHelper.getColorGreen())
					end
				end
			end
			-- losing Light Eater and Low Thirst if mental is not good or if sleep is bad
			if
				modData.RecentAverageMental <= (SBvars.WeightSystemUpperMentalThreshold / 100)
				or sleepCheck(modData.SleepSystem.SleepHealthinessBar) == false
			then
				if
					player:hasTrait(CharacterTrait.LIGHT_EATER)
					and startingTraits.LightEater ~= true
					and SBvars.TraitsLockSystemCanLosePositive
				then
					ETW_CommonFunctions.removeTraitFromPlayer(player, CharacterTrait.LIGHT_EATER)
					ETW_CommonFunctions.displayTraitNotification(player, getText("UI_trait_lighteater"), false, HaloTextHelper.getColorRed())
				end
				if
					player:hasTrait(CharacterTrait.LOW_THIRST)
					and startingTraits.LowThirst ~= true
					and SBvars.TraitsLockSystemCanLosePositive
				then
					ETW_CommonFunctions.removeTraitFromPlayer(player, CharacterTrait.LOW_THIRST)
					ETW_CommonFunctions.displayTraitNotification(player, getText("UI_trait_LowThirst"), false, HaloTextHelper.getColorRed())
				end
			else
				-- gaining Light Eater and Low Thirst if mental is good, sleep is good, and weight 75-85
				if
					not player:hasTrait(CharacterTrait.LIGHT_EATER)
					and startingTraits.HeartyAppetite ~= true
					and SBvars.TraitsLockSystemCanGainPositive
				then
					ETW_CommonFunctions.addTraitToPlayer(player, CharacterTrait.LIGHT_EATER)
					ETW_CommonFunctions.displayTraitNotification(player, getText("UI_trait_lighteater"), true, HaloTextHelper.getColorGreen())
				end
				if
					not player:hasTrait(CharacterTrait.LOW_THIRST)
					and startingTraits.HighThirst ~= true
					and SBvars.TraitsLockSystemCanGainPositive
				then
					ETW_CommonFunctions.addTraitToPlayer(player, CharacterTrait.LOW_THIRST)
					ETW_CommonFunctions.displayTraitNotification(player, getText("UI_trait_LowThirst"), true, HaloTextHelper.getColorGreen())
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
				* ((SBvars.AffinitySystem and modData.StartingTraits.Asthmatic) and SBvars.AffinitySystemGainMultiplier or 1)
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
				/ ((SBvars.AffinitySystem and modData.StartingTraits.Asthmatic) and SBvars.AffinitySystemLoseDivider or 1)
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
			ETW_CommonFunctions.addTraitToPlayer(player, CharacterTrait.ASTHMATIC)
			ETW_CommonFunctions.displayTraitNotification(player, getText("UI_trait_Asthmatic"), true, HaloTextHelper.getColorRed())
		elseif
			modData.AsthmaticCounter >= SBvars.AsthmaticCounter
			and player:hasTrait(CharacterTrait.ASTHMATIC)
			and SBvars.TraitsLockSystemCanLoseNegative
		then
			ETW_CommonFunctions.removeTraitFromPlayer(player, CharacterTrait.ASTHMATIC)
			ETW_CommonFunctions.displayTraitNotification(player, getText("UI_trait_Asthmatic"), false, HaloTextHelper.getColorGreen())
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
				ETW_CommonFunctions.log("ETW Logger | recordMentalStateETW(): average mental in last 24 hours: " .. average)
				table.insert(modData.MentalStateInLast31Days, average)
				modData.MentalStateInLast24Hours = { average }
				-- last days mental
				sum = 0
				for i = 1, #modData.MentalStateInLast31Days do
					sum = sum + modData.MentalStateInLast31Days[i]
				end
				modData.RecentAverageMental = sum / #modData.MentalStateInLast31Days
				ETW_CommonFunctions.log(
					"ETW Logger | recordMentalStateETW(): average mental in last 31 days: " .. modData.RecentAverageMental
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
				SBvars.DelayedTraitsSystem and not ETW_CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, ETWTraitsRegistry.PAIN_TOLERANCE)
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
				or (SBvars.DelayedTraitsSystem and ETW_CommonFunctions.checkDelayedTraits(player, ETWTraitsRegistry.PAIN_TOLERANCE))
			then
				ETW_CommonFunctions.addTraitToPlayer(player, ETWTraitsRegistry.PAIN_TOLERANCE)
				ETW_InitiatePainToleranceTrait(player)
				Events.EveryTenMinutes.Remove(painToleranceTraitETW)
				ETW_CommonFunctions.displayTraitNotification(player, getText("UI_trait_PainTolerance"), true, HaloTextHelper.getColorGreen())
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
	Events.EveryTenMinutes.Remove(weightSystemETW)
	Events.EveryTenMinutes.Remove(painToleranceTraitETW)
	Events.EveryOneMinute.Remove(asthmaticTraitETW)
	Events.EveryOneMinute.Remove(recordMentalStateETW)
	ETW_CommonFunctions.log("ETW Logger | System: clearEventsETW in ETWByHealth.lua")
end

if gameMode == ETW_CommonFunctions.GameMode.SP then
	Events.OnCreatePlayer.Remove(initializeEventsETW)
	Events.OnCreatePlayer.Add(initializeEventsETW)
	Events.OnPlayerDeath.Remove(clearEventsETW)
	Events.OnPlayerDeath.Add(clearEventsETW)
elseif gameMode == ETW_CommonFunctions.GameMode.MP_SERVER then
	Events.OnTick.Add(initializeEventsETW)
end
