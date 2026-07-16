local ETW_ModDataServer = require("ETW_ModDataServer")
local ETW_CommonFunctions = require("ETW_CommonFunctions")
local ETW_CommonLogicChecks = require("ETW_CommonLogicChecks")
local ETW_Moodles

---@type EvolvingTraitsWorldSandboxVars
local SBvars = SandboxVars.EvolvingTraitsWorld

local gameMode = ETW_CommonFunctions.gameMode()

if gameMode == ETW_CommonFunctions.GameMode.SP then
	ETW_Moodles = require("ETW_Moodles")
end

---@type fun(...: any)
local logETW = ETW_CommonFunctions.log
local FILENAME = "ETW_ByTime.lua"

if
	not ETW_CommonFunctions.gameModeSafeguard(
		FILENAME,
		{ ETW_CommonFunctions.GameMode.SP, ETW_CommonFunctions.GameMode.MP_SERVER }
	)
then
	return
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
	local playersList = ETW_CommonFunctions.playersList()
	for i = 0, playersList:size() - 1 do
		local player = playersList:get(i)
		local modData = ETW_CommonFunctions.getETWModData(player)
		if not modData then
			logETW("ETW Logger | sleepSystem(): modData is nil, returning early")
			return
		end
		local startingTraitsModData = modData.StartingTraits
		local startedWithNeedsLessSleep = startingTraitsModData[CharacterTrait.NEEDS_LESS_SLEEP:toString()]
		local startedWithNeedsMoreSleep = startingTraitsModData[CharacterTrait.NEEDS_MORE_SLEEP:toString()]
		local sleepModData = modData.SleepSystem
		local timeOfDay = getGameTime():getTimeOfDay()
		local currentPreferredTargetHour = sleepModData.LastMidpoint
		if player:isAsleep() then
			local hoursAwayFromPreferredHour = math.min(
				math.abs(currentPreferredTargetHour - timeOfDay),
				24 - math.abs(timeOfDay - currentPreferredTargetHour)
			)
			if sleepModData.CurrentlySleeping == false then
				sleepModData.CurrentlySleeping = true
				sleepModData.WentToSleepAt = timeOfDay
				logETW("ETW Logger | sleepSystem(): player went to sleep at: " .. sleepModData.WentToSleepAt)
			end
			if hoursAwayFromPreferredHour <= 6 then
				local sleepHealthinessBarIncreaseMultiplier = SBvars.SleepSystemMultiplier
				if SBvars.AffinitySystem then
					if startedWithNeedsLessSleep then
						sleepHealthinessBarIncreaseMultiplier = sleepHealthinessBarIncreaseMultiplier
							* SBvars.AffinitySystemGainMultiplier
					elseif startedWithNeedsMoreSleep then
						sleepHealthinessBarIncreaseMultiplier = sleepHealthinessBarIncreaseMultiplier
							/ SBvars.AffinitySystemLoseDivider
					end
				end
				local sleepHealthinessBarIncrease = (1 / 6) * sleepHealthinessBarIncreaseMultiplier
				sleepModData.SleepHealthinessBar =
					math.min(200, sleepModData.SleepHealthinessBar + sleepHealthinessBarIncrease)
			else
				local sleepHealthinessBarDecreaseMultiplier = SBvars.SleepSystemMultiplier
				if SBvars.AffinitySystem then
					if startedWithNeedsLessSleep then
						sleepHealthinessBarDecreaseMultiplier = sleepHealthinessBarDecreaseMultiplier
							/ SBvars.AffinitySystemGainMultiplier
					elseif startedWithNeedsMoreSleep then
						sleepHealthinessBarDecreaseMultiplier = sleepHealthinessBarDecreaseMultiplier
							* SBvars.AffinitySystemLoseDivider
					end
				end
				local sleepHealthinessBarDecrease = (1 / 6) * sleepHealthinessBarDecreaseMultiplier
				sleepModData.SleepHealthinessBar =
					math.max(-200, sleepModData.SleepHealthinessBar - sleepHealthinessBarDecrease)
			end
			if gameMode == ETW_CommonFunctions.GameMode.SP then
				ETW_Moodles.sleepHealthMoodleUpdate(
					player,
					{ hoursAwayFromPreferredHour = hoursAwayFromPreferredHour, hide = false }
				)
			elseif gameMode == ETW_CommonFunctions.GameMode.MP_SERVER then
				sendServerCommand(
					player,
					"ETW",
					"sleepHealthMoodleUpdate",
					{ hoursAwayFromPreferredHour = hoursAwayFromPreferredHour, hide = false }
				)
			end
		end
		if not player:isAsleep() and sleepModData.CurrentlySleeping == true then
			if gameMode == ETW_CommonFunctions.GameMode.SP then
				ETW_Moodles.sleepHealthMoodleUpdate(player, { hoursAwayFromPreferredHour = 0, hide = true })
			elseif gameMode == ETW_CommonFunctions.GameMode.MP_SERVER then
				sendServerCommand(
					player,
					"ETW",
					"sleepHealthMoodleUpdate",
					{ hoursAwayFromPreferredHour = 0, hide = true }
				)
			end
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
					if startedWithNeedsLessSleep then
						sleepHealthinessBarIncreaseMultiplier = sleepHealthinessBarIncreaseMultiplier
							/ SBvars.AffinitySystemGainMultiplier
					elseif startedWithNeedsMoreSleep then
						sleepHealthinessBarIncreaseMultiplier = sleepHealthinessBarIncreaseMultiplier
							* SBvars.AffinitySystemLoseDivider
					end
				end
				sleepModData.SleepHealthinessBar =
					math.max(-200, sleepModData.SleepHealthinessBar - (1 / 6) * SBvars.SleepSystemMultiplier)
			end
		end
		if sleepModData.SleepHealthinessBar > 100 then
			if not player:hasTrait(CharacterTrait.NEEDS_LESS_SLEEP) and SBvars.TraitsLockSystemCanGainPositive then
				ETW_CommonFunctions.addTraitToPlayer({
					player = player,
					trait = CharacterTrait.NEEDS_LESS_SLEEP,
					positiveTrait = true,
				})
			end
		elseif sleepModData.SleepHealthinessBar < -100 then
			if not player:hasTrait(CharacterTrait.NEEDS_MORE_SLEEP) and SBvars.TraitsLockSystemCanGainNegative then
				ETW_CommonFunctions.addTraitToPlayer({
					player = player,
					trait = CharacterTrait.NEEDS_MORE_SLEEP,
					positiveTrait = false,
				})
			end
		else
			if player:hasTrait(CharacterTrait.NEEDS_LESS_SLEEP) and SBvars.TraitsLockSystemCanLosePositive then
				ETW_CommonFunctions.removeTraitFromPlayer({
					player = player,
					trait = CharacterTrait.NEEDS_LESS_SLEEP,
					positiveTrait = true,
				})
			end
			if player:hasTrait(CharacterTrait.NEEDS_MORE_SLEEP) and SBvars.TraitsLockSystemCanLoseNegative then
				ETW_CommonFunctions.removeTraitFromPlayer({
					player = player,
					trait = CharacterTrait.NEEDS_MORE_SLEEP,
					positiveTrait = false,
				})
			end
		end
		logETW("ETW Logger | sleepSystem(): modData.SleepHealthinessBar: " .. sleepModData.SleepHealthinessBar)
	end
end

---Function responsible for managing hourly Smoker trait decay
local function smoker()
	local playersList = ETW_CommonFunctions.playersList()
	for i = 0, playersList:size() - 1 do
		local player = playersList:get(i)
		local modData = ETW_CommonFunctions.getETWModData(player)
		if not modData then
			logETW("ETW Logger | smoker(): modData is nil, returning early")
			return
		end
		local smokerModData = modData.SmokeSystem
		local startedWithSmoker = modData.StartingTraits[CharacterTrait.SMOKER:toString()]
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
		if SBvars.AffinitySystem and startedWithSmoker then
			addictionDecay = addictionDecay / SBvars.AffinitySystemLoseDivider
		end
		smokerModData.SmokingAddiction =
			math.max(SBvars.SmokerCounter * -2, smokerModData.SmokingAddiction - addictionDecay)
		logETW(
			"ETW Logger | smoker(): smoking addictionDecay: "
				.. addictionDecay
				.. ", modData.SmokingAddiction: "
				.. smokerModData.SmokingAddiction
		)
		local playerHasSmoker = player:hasTrait(CharacterTrait.SMOKER)
		if
			smokerModData.SmokingAddiction >= SBvars.SmokerCounter
			and not playerHasSmoker
			and SBvars.TraitsLockSystemCanGainNegative
		then
			ETW_CommonFunctions.addTraitToPlayer({
				player = player,
				trait = CharacterTrait.SMOKER,
				positiveTrait = false,
			})
		elseif
			smokerModData.SmokingAddiction <= -SBvars.SmokerCounter
			and playerHasSmoker
			and SBvars.TraitsLockSystemCanLoseNegative
		then
			stats:set(CharacterStat.NICOTINE_WITHDRAWAL, 0)
			ETW_CommonFunctions.removeTraitFromPlayer({
				player = player,
				trait = CharacterTrait.SMOKER,
				positiveTrait = false,
			})
		end
	end
end

---Function responsible for setting up events
---@param playerIndex number
---@param player IsoPlayer
local function initializeEventsETW(playerIndex, player)
	Events.EveryTenMinutes.Remove(sleepSystem)
	if ETW_CommonLogicChecks.SleepSystemShouldExecute(player) then
		Events.EveryTenMinutes.Add(sleepSystem)
	end
	Events.EveryOneMinute.Remove(smoker)
	if ETW_CommonLogicChecks.SmokerShouldExecute(player) then
		Events.EveryOneMinute.Add(smoker)
	end
	if gameMode == ETW_CommonFunctions.GameMode.MP_SERVER then
		Events.OnTick.Remove(initializeEventsETW)
	end
end

---Function responsible for clearing events
---@param character IsoPlayer
local function clearEventsETW(character)
	Events.EveryTenMinutes.Remove(sleepSystem)
	Events.EveryOneMinute.Remove(smoker)
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
