require("ETW_ModData")
require("ETWModOptions")
local ETWMoodles = require("ETWMoodles")
local ETW_CommonFunctions = require("ETW_CommonFunctions")
local ETW_CommonLogicChecks = require("ETW_CommonLogicChecks")

---@type EvolvingTraitsWorldSandboxVars
local SBvars = SandboxVars.EvolvingTraitsWorld

---@type EvolvingTraitsWorldRegistries
local ETWRegistries = require("ETW_Registry")
---@type EvolvingTraitsWorldTraitsRegistries
local ETWTraitsRegistry = ETWRegistries.traits

local modOptions

---Function responsible for setting up mod options on character load
---@param playerIndex number
---@param player IsoPlayer
local function initializeModOptions(playerIndex, player)
	modOptions = PZAPI.ModOptions:getOptions("ETWModOptions")
end

Events.OnCreatePlayer.Remove(initializeModOptions)
Events.OnCreatePlayer.Add(initializeModOptions)

---@return boolean
local notification = function()
	return modOptions:getOption("EnableNotifications"):getValue()
end
---@return boolean
local delayedNotification = function()
	return modOptions:getOption("EnableDelayedNotifications"):getValue()
end
---@return boolean
local detailedDebug = function()
	return modOptions:getOption("GatherDetailedDebug"):getValue()
end

---Prints out debugs inside console if detailedDebug is enabled
---@param ... any Optional boolean followed by strings to log, if set to true, prints all strings in a single line otherwise prints each string in a new line
local logETW = function(...)
	ETW_CommonFunctions.log(...)
end

---Function responsible for managing Cat Eyes trait
---@param isKill boolean
local function catEyes(isKill)
	local isKill = isKill or false
	local player = getPlayer()
	local nightStrength = getClimateManager():getNightStrength()
	if nightStrength > 0 then
		local playerNum = player:getPlayerNum()
		local checkedSquares = 0
		local squaresVisible = 0
		local square
		local plX, plY, plZ = player:getX(), player:getY(), player:getZ()
		local radius = 30
		local modData = ETW_CommonFunctions.getETWModData(player)
		if not modData then
			logETW("ETW Logger | catEyes(): modData is nil, returning early")
			return
		end
		local playerIsInside = player:isInARoom()
		local hasEagleEyed = player:hasTrait(CharacterTrait.EAGLE_EYED)
		local thisMinuteIncrease = 0
		for x = -radius, radius do
			for y = -radius, radius do
				square = getCell():getGridSquare(plX + x, plY + y, plZ)
				checkedSquares = checkedSquares + 1
				if square and square:isCanSee(playerNum) then
					local squareDarknessLevel = nightStrength
						* (1 - square:getLightLevel(playerNum))
						* 0.01
						* (square:isInARoom() and playerIsInside and 2 or 1)
						* (hasEagleEyed and 2 or 1)
					squaresVisible = squaresVisible + 1
					thisMinuteIncrease = thisMinuteIncrease + squareDarknessLevel
				end
			end
		end
		modData.CatEyesCounter = modData.CatEyesCounter + thisMinuteIncrease
		if isKill then
			logETW("ETW Logger | catEyes(): was triggered by a kill")
		end
		logETW(
			"ETW Logger | catEyes(): Checked squares: "
				.. checkedSquares
				.. ", visible squares: "
				.. squaresVisible
				.. " with total darkness level of "
				.. thisMinuteIncrease,
			"ETW Logger | catEyes(): CatEyesCounter: " .. modData.CatEyesCounter
		)
		if not player:hasTrait(CharacterTrait.NIGHT_VISION) and modData.CatEyesCounter >= SBvars.CatEyesCounter then
			if SBvars.DelayedTraitsSystem and not ETW_CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, CharacterTrait.NIGHT_VISION) then
				ETW_CommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = CharacterTrait.NIGHT_VISION,
					player = player,
					positiveTrait = true,
					gainingTrait = true,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (SBvars.DelayedTraitsSystem and ETW_CommonFunctions.checkDelayedTraits(player, CharacterTrait.NIGHT_VISION))
			then
				ETW_CommonFunctions.addTraitToPlayer(player, CharacterTrait.NIGHT_VISION)
				Events.EveryOneMinute.Remove(catEyes)
				if notification() then
					HaloTextHelper.addTextWithArrow(player, getText("UI_trait_NightVision"), true, HaloTextHelper.getColorGreen())
				end
			end
		end
	end
end

---Function responsible for finding midpoint between 2 timestamps
---time1 and time2 are passed in chronological order, time2 was after time1
---@param time1 number
---@param time2 number
---@return number
local function findMidpoint(time1, time2)
	local midPoint = 0
	if time1 > time2 then
		midPoint = (time1 + time2 + 24) / 2
	else
		midPoint = (time1 + time2) / 2
	end
	if midPoint >= 24 then
		midPoint = midPoint - 24
	end
	return midPoint
end

---Function responsible for managing Sleep System traits
local function sleepSystem()
	local player = getPlayer()
	local modData = ETW_CommonFunctions.getETWModData(player)
	if not modData then
		logETW("ETW Logger | sleepSystem(): modData is nil, returning early")
		return
	end
	local startingTraitsModData = modData.StartingTraits
	local sleepModData = modData.SleepSystem
	local timeOfDay = getGameTime():getTimeOfDay()
	local currentPreferredTargetHour = sleepModData.LastMidpoint
	if player:isAsleep() then
		local hoursAwayFromPreferredHour =
			math.min(math.abs(currentPreferredTargetHour - timeOfDay), 24 - math.abs(timeOfDay - currentPreferredTargetHour))
		if sleepModData.CurrentlySleeping == false then
			sleepModData.CurrentlySleeping = true
			sleepModData.WentToSleepAt = timeOfDay
			logETW("ETW Logger | sleepSystem(): player went to sleep at: " .. sleepModData.WentToSleepAt)
		end
		if hoursAwayFromPreferredHour <= 6 then
			local sleepHealthinessBarIncreaseMultiplier = SBvars.SleepSystemMultiplier
			if SBvars.AffinitySystem then
				if startingTraitsModData.NeedsLessSleep then
					sleepHealthinessBarIncreaseMultiplier = sleepHealthinessBarIncreaseMultiplier * SBvars.AffinitySystemGainMultiplier
				elseif startingTraitsModData.NeedsMoreSleep then
					sleepHealthinessBarIncreaseMultiplier = sleepHealthinessBarIncreaseMultiplier / SBvars.AffinitySystemLoseDivider
				end
			end
			local sleepHealthinessBarIncrease = (1 / 6) * sleepHealthinessBarIncreaseMultiplier
			sleepModData.SleepHealthinessBar = math.min(200, sleepModData.SleepHealthinessBar + sleepHealthinessBarIncrease)
		else
			local sleepHealthinessBarDecreaseMultiplier = SBvars.SleepSystemMultiplier
			if SBvars.AffinitySystem then
				if startingTraitsModData.NeedsLessSleep then
					sleepHealthinessBarDecreaseMultiplier = sleepHealthinessBarDecreaseMultiplier / SBvars.AffinitySystemGainMultiplier
				elseif startingTraitsModData.NeedsMoreSleep then
					sleepHealthinessBarDecreaseMultiplier = sleepHealthinessBarDecreaseMultiplier * SBvars.AffinitySystemLoseDivider
				end
			end
			local sleepHealthinessBarDecrease = (1 / 6) * sleepHealthinessBarDecreaseMultiplier
			sleepModData.SleepHealthinessBar = math.max(-200, sleepModData.SleepHealthinessBar - sleepHealthinessBarDecrease)
		end
		ETWMoodles.sleepHealthMoodleUpdate(player, hoursAwayFromPreferredHour, false)
	end
	if not player:isAsleep() and sleepModData.CurrentlySleeping == true then
		ETWMoodles.sleepHealthMoodleUpdate(player, 0, true)
		sleepModData.LastMidpoint = findMidpoint(sleepModData.WentToSleepAt, timeOfDay)
		sleepModData.CurrentlySleeping = false
		sleepModData.HoursSinceLastSleep = 0
		logETW(
			"ETW Logger | sleepSystem(): SleepHealthinessBar: " .. sleepModData.SleepHealthinessBar,
			"ETW Logger | sleepSystem(): new sleepModData.LastMidpoint: "
				.. sleepModData.LastMidpoint
				.. ", calculated from "
				.. sleepModData.WentToSleepAt
				.. " and "
				.. timeOfDay
		)
	end
	if not player:isAsleep() then
		sleepModData.HoursSinceLastSleep = sleepModData.HoursSinceLastSleep + 1 / 6
		if sleepModData.HoursSinceLastSleep >= 24 then
			local sleepHealthinessBarIncreaseMultiplier = SBvars.SleepSystemMultiplier
			if SBvars.AffinitySystem then
				if startingTraitsModData.NeedsLessSleep then
					sleepHealthinessBarIncreaseMultiplier = sleepHealthinessBarIncreaseMultiplier / SBvars.AffinitySystemGainMultiplier
				elseif startingTraitsModData.NeedsMoreSleep then
					sleepHealthinessBarIncreaseMultiplier = sleepHealthinessBarIncreaseMultiplier * SBvars.AffinitySystemLoseDivider
				end
			end
			sleepModData.SleepHealthinessBar = math.max(-200, sleepModData.SleepHealthinessBar - (1 / 6) * SBvars.SleepSystemMultiplier)
		end
	end
	if sleepModData.SleepHealthinessBar > 100 then
		if not player:hasTrait(CharacterTrait.NEEDS_LESS_SLEEP) and SBvars.TraitsLockSystemCanGainPositive then
			ETW_CommonFunctions.addTraitToPlayer(player, CharacterTrait.NEEDS_LESS_SLEEP)
			if notification() then
				HaloTextHelper.addTextWithArrow(player, getText("UI_trait_LessSleep"), true, HaloTextHelper.getColorGreen())
			end
		end
	elseif sleepModData.SleepHealthinessBar < -100 then
		if not player:hasTrait(CharacterTrait.NEEDS_MORE_SLEEP) and SBvars.TraitsLockSystemCanGainNegative then
			ETW_CommonFunctions.addTraitToPlayer(player, CharacterTrait.NEEDS_MORE_SLEEP)
			if notification() then
				HaloTextHelper.addTextWithArrow(player, getText("UI_trait_MoreSleep"), true, HaloTextHelper.getColorRed())
			end
		end
	else
		if player:hasTrait(CharacterTrait.NEEDS_LESS_SLEEP) and SBvars.TraitsLockSystemCanLosePositive then
			ETW_CommonFunctions.removeTraitFromPlayer(player, CharacterTrait.NEEDS_LESS_SLEEP)
			if notification() then
				HaloTextHelper.addTextWithArrow(player, getText("UI_trait_LessSleep"), false, HaloTextHelper.getColorRed())
			end
		end
		if player:hasTrait(CharacterTrait.NEEDS_MORE_SLEEP) and SBvars.TraitsLockSystemCanLoseNegative then
			ETW_CommonFunctions.removeTraitFromPlayer(player, CharacterTrait.NEEDS_MORE_SLEEP)
			if notification() then
				HaloTextHelper.addTextWithArrow(player, getText("UI_trait_MoreSleep"), true, HaloTextHelper.getColorGreen())
			end
		end
	end
	logETW("ETW Logger | sleepSystem(): modData.SleepHealthinessBar: " .. sleepModData.SleepHealthinessBar)
end

---Function responsible for managing hourly Smoker trait decay
local function smoker()
	local player = getPlayer()
	local modData = ETW_CommonFunctions.getETWModData(player)
	if not modData then
		logETW("ETW Logger | smoker(): modData is nil, returning early")
		return
	end
	local smokerModData = modData.SmokeSystem
	local timeSinceLastSmoke = player:getTimeSinceLastSmoke() * 60
	smokerModData.MinutesSinceLastSmoke = smokerModData.MinutesSinceLastSmoke + 1
	logETW(
		"ETW Logger | smoker(): timeSinceLastSmoke: "
			.. timeSinceLastSmoke
			.. ", modData.MinutesSinceLastSmoke: "
			.. smokerModData.MinutesSinceLastSmoke
	)
	local stats = player:getStats()
	local stress = stats:get(CharacterStat.STRESS) -- stress is 0-1, may be higher with stress from cigarettes
	local panic = stats:get(CharacterStat.PANIC) -- 0-100
	local addictionDecay = SBvars.SmokingAddictionDecay * (0.0167 / 10) * (1 - stress) * (1 - panic / 100)
	addictionDecay = math.max(0, addictionDecay) -- make sure values doesn't go into negative
	if SBvars.AffinitySystem and modData.StartingTraits.Smoker then
		addictionDecay = addictionDecay / SBvars.AffinitySystemLoseDivider
	end
	smokerModData.SmokingAddiction = math.max(SBvars.SmokerCounter * -2, smokerModData.SmokingAddiction - addictionDecay)
	logETW(
		"ETW Logger | smoker(): smoking addictionDecay: "
			.. addictionDecay
			.. ", modData.SmokingAddiction: "
			.. smokerModData.SmokingAddiction
	)
	if
		smokerModData.SmokingAddiction >= SBvars.SmokerCounter
		and not player:hasTrait(CharacterTrait.SMOKER)
		and SBvars.TraitsLockSystemCanGainNegative
	then
		ETW_CommonFunctions.addTraitToPlayer(player, CharacterTrait.SMOKER)
		if notification() then
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Smoker"), true, HaloTextHelper.getColorRed())
		end
	elseif
		smokerModData.SmokingAddiction <= -SBvars.SmokerCounter
		and player:hasTrait(CharacterTrait.SMOKER)
		and SBvars.TraitsLockSystemCanLoseNegative
	then
		stats:set(CharacterStat.NICOTINE_WITHDRAWAL, 0)
		ETW_CommonFunctions.removeTraitFromPlayer(player, CharacterTrait.SMOKER)
		if notification() then
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Smoker"), false, HaloTextHelper.getColorGreen())
		end
	end
end

---Function responsible for managing daily Herbalist trait decay
local function herbalist()
	local player = getPlayer()
	local modData = ETW_CommonFunctions.getETWModData(player)
	if not modData then
		logETW("ETW Logger | herbalist(): modData is nil, returning early")
		return
	end
	modData.HerbsPickedUp = math.max(
		0,
		modData.HerbsPickedUp - ((SBvars.AffinitySystem and modData.StartingTraits.Herbalist) and 1 / SBvars.AffinitySystemLoseDivider or 1)
	)
	logETW("ETW Logger | herbalist(): modData.HerbsPickedUp: " .. modData.HerbsPickedUp)
	if modData.HerbsPickedUp < SBvars.HerbalistHerbsPicked / 2 and player:hasTrait(CharacterTrait.HERBALIST) then
		ETW_CommonFunctions.removeTraitFromPlayer(player, CharacterTrait.HERBALIST)
		if notification() then
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Herbalist"), false, HaloTextHelper.getColorRed())
		end
	end
end

---Helper function to fire catEyes() on zombie kill
---@param zombie IsoZombie
local function catEyesKill(zombie)
	local player = zombie:getAttackedBy()
	---@cast player IsoPlayer
	if not player or not instanceof(player, "IsoPlayer") or not player:isLocalPlayer() then
		return
	else
		catEyes(true)
	end
end

---Function responsible for setting up events
---@param playerIndex number
---@param player IsoPlayer
local function initializeEventsETW(playerIndex, player)
	modOptions = PZAPI.ModOptions:getOptions("ETWModOptions")
	Events.EveryOneMinute.Remove(catEyes)
	Events.OnZombieDead.Remove(catEyesKill)
	if ETW_CommonLogicChecks.CatEyesShouldExecute(player) then
		Events.EveryOneMinute.Add(catEyes)
		Events.OnZombieDead.Add(catEyesKill)
	end
	Events.EveryTenMinutes.Remove(sleepSystem)
	if ETW_CommonLogicChecks.SleepSystemShouldExecute(player) then
		Events.EveryTenMinutes.Add(sleepSystem)
	end
	Events.EveryOneMinute.Remove(smoker)
	if ETW_CommonLogicChecks.SmokerShouldExecute(player) then
		Events.EveryOneMinute.Add(smoker)
	end
	Events.EveryDays.Remove(herbalist)
	if ETW_CommonLogicChecks.HerbalistShouldExecute(player) and SBvars.TraitsLockSystemCanLosePositive then
		Events.EveryDays.Add(herbalist)
	end
	Events.EveryHours.Remove(progressDelayedTraits)
	if SBvars.DelayedTraitsSystem then
		Events.EveryHours.Add(progressDelayedTraits)
	end
end

---Function responsible for clearing events
---@param character IsoPlayer
local function clearEventsETW(character)
	Events.EveryOneMinute.Remove(catEyes)
	Events.EveryTenMinutes.Remove(sleepSystem)
	Events.EveryOneMinute.Remove(smoker)
	Events.EveryDays.Remove(herbalist)
	if detailedDebug() then
		print("ETW Logger | System: clearEventsETW in ETWByTime.lua")
	end
end

Events.OnCreatePlayer.Remove(initializeEventsETW)
Events.OnCreatePlayer.Add(initializeEventsETW)
Events.OnPlayerDeath.Remove(clearEventsETW)
Events.OnPlayerDeath.Add(clearEventsETW)
