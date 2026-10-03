local ETW_CommonFunctions = require("ETW_CommonFunctions")
local ETW_CommonServerFunctions = require("ETW_CommonServerFunctions")
local ETW_Registry = require("ETW_Registry")

local FILENAME = "ETW_Alcoholic.lua"
if
	not ETW_CommonFunctions.gameModeSafeguard(
		FILENAME,
		{ ETW_CommonFunctions.GameMode.SP, ETW_CommonFunctions.GameMode.MP_SERVER }
	)
then
	return
end

local ETW_Alcoholic = {}

---@type EvolvingTraitsWorldTraitsRegistries
local ETWTraitsRegistry = ETW_Registry.traits
---@type EvolvingTraitsWorldSandboxVars
local SBvars = SandboxVars.EvolvingTraitsWorld
local logETW = ETW_CommonFunctions.log
local random_instance = newrandom()
local MAX_WITHDRAWAL_STRESS = 0.5
local MAX_ALCOHOLIC_STAGE = 3
local MILD_WITHDRAWAL_SEVERITY = 33
local MODERATE_WITHDRAWAL_SEVERITY = 67
local SEVERE_WITHDRAWAL_SEVERITY = 100
local WITHDRAWAL_HEAD_PAIN_AMOUNT = 20
local WITHDRAWAL_HEAD_PAIN_COOLDOWN_THRESHOLD = 70
local WITHDRAWAL_HEAD_PAIN_COOLDOWN_HOURS = 4
local WITHDRAWAL_FOOD_SICKNESS_INCREASE = 10
local MAX_WITHDRAWAL_FOOD_SICKNESS = 89.99
local WITHDRAWAL_FOOD_SICKNESS_COOLDOWN_THRESHOLD = 70
local WITHDRAWAL_FOOD_SICKNESS_COOLDOWN_HOURS = 4
local WITHDRAWAL_WAKE_UP_COOLDOWN_HOURS = 4
local TEMPERATURE_SWING_DEGREES_PER_MINUTE = 1
local TEMPERATURE_SWING_DIRECTION_COLD = "cold"
local TEMPERATURE_SWING_DIRECTION_HOT = "hot"

local MAX_WITHDRAWAL_SEVERITY_BY_ALCOHOLIC_STAGE = {
	[0] = 0,
	[1] = MILD_WITHDRAWAL_SEVERITY,
	[2] = MODERATE_WITHDRAWAL_SEVERITY,
	[3] = SEVERE_WITHDRAWAL_SEVERITY,
}

local ALCOHOLIC_TRAIT_STAGES = {
	[ETWTraitsRegistry.ALCOHOLIC_MILD] = 1,
	[ETWTraitsRegistry.ALCOHOLIC_MODERATE] = 2,
	[ETWTraitsRegistry.ALCOHOLIC_SEVERE] = 3,
}

local withdrawalStressEventRegistered = false

---Rolls a percentage chance with two decimal places of precision.
---@param chance number Percentage from 0 to 100.
---@return boolean succeeds
local function rollPercentChance(chance)
	local clampedChance = math.max(0, math.min(100, chance))
	return random_instance:random(1, 10000) <= clampedChance * 100
end

---Returns the severity of the Alcoholic trait currently held by the player.
---@param player IsoPlayer
---@return integer stage Zero when the player has no Alcoholic trait.
function ETW_Alcoholic.getAlcoholicTraitStage(player)
	if player:hasTrait(ETWTraitsRegistry.ALCOHOLIC_SEVERE) then
		return ALCOHOLIC_TRAIT_STAGES[ETWTraitsRegistry.ALCOHOLIC_SEVERE]
	elseif player:hasTrait(ETWTraitsRegistry.ALCOHOLIC_MODERATE) then
		return ALCOHOLIC_TRAIT_STAGES[ETWTraitsRegistry.ALCOHOLIC_MODERATE]
	elseif player:hasTrait(ETWTraitsRegistry.ALCOHOLIC_MILD) then
		return ALCOHOLIC_TRAIT_STAGES[ETWTraitsRegistry.ALCOHOLIC_MILD]
	end
	return 0
end

---Starts or advances an acute-withdrawal temperature swing by one active minute.
---@param player IsoPlayer
---@param stats Stats
---@param alcoholicSystem AlcoholicSystem
---@param withdrawalSeverity number Percentage from 0 to 100.
local function updateTemperatureSwing(player, stats, alcoholicSystem, withdrawalSeverity)
	local direction = alcoholicSystem.TemperatureSwingDirection
	if direction == nil then
		if withdrawalSeverity <= 0 then
			return
		end
		local chance
		if withdrawalSeverity >= SEVERE_WITHDRAWAL_SEVERITY then
			chance = SBvars.AlcoholicSevereWithdrawalTemperatureSwingChancePercent
		elseif withdrawalSeverity >= MODERATE_WITHDRAWAL_SEVERITY then
			chance = SBvars.AlcoholicModerateWithdrawalTemperatureSwingChancePercent
		else
			chance = SBvars.AlcoholicMildWithdrawalTemperatureSwingChancePercent
		end
		if chance <= 0 or not rollPercentChance(chance) then
			return
		end
		local durationMinutes = SBvars.AlcoholicWithdrawalTemperatureSwingDurationMinutes
		direction = random_instance:random(1, 2) == 1 and TEMPERATURE_SWING_DIRECTION_COLD
			or TEMPERATURE_SWING_DIRECTION_HOT
		alcoholicSystem.TemperatureSwingDirection = direction
		alcoholicSystem.TemperatureSwingMinutesRemaining = durationMinutes
		logETW(
			"ETW Logger | updateTemperatureSwing(): started "
				.. direction
				.. " swing for "
				.. durationMinutes
				.. " minutes; chance: "
				.. chance
				.. "%; player: "
				.. player:getUsername()
		)
	elseif direction ~= TEMPERATURE_SWING_DIRECTION_COLD and direction ~= TEMPERATURE_SWING_DIRECTION_HOT then
		logETW(
			"ETW Logger | updateTemperatureSwing(): cleared invalid direction '"
				.. tostring(direction)
				.. "'; player: "
				.. player:getUsername()
		)
		alcoholicSystem.TemperatureSwingDirection = nil
		alcoholicSystem.TemperatureSwingMinutesRemaining = 0
		return
	end

	local amount = direction == TEMPERATURE_SWING_DIRECTION_HOT and TEMPERATURE_SWING_DEGREES_PER_MINUTE
		or -TEMPERATURE_SWING_DEGREES_PER_MINUTE
	local previousTemperature = stats:get(CharacterStat.TEMPERATURE)
	stats:add(CharacterStat.TEMPERATURE, amount)
	logETW(
		"ETW Logger | updateTemperatureSwing(): "
			.. direction
			.. " swing; temperature: "
			.. previousTemperature
			.. "->"
			.. stats:get(CharacterStat.TEMPERATURE)
			.. "; requested change: "
			.. amount
			.. "; player: "
			.. player:getUsername()
	)
	alcoholicSystem.TemperatureSwingMinutesRemaining = math.max(0, alcoholicSystem.TemperatureSwingMinutesRemaining - 1)
	if alcoholicSystem.TemperatureSwingMinutesRemaining <= 0 then
		alcoholicSystem.TemperatureSwingDirection = nil
		logETW(
			"ETW Logger | updateTemperatureSwing(): finished "
				.. direction
				.. " swing; player: "
				.. player:getUsername()
		)
	end
end

---Adds withdrawal headache pain to the player's head body part.
---@param player IsoPlayer
---@param source string
---@return number resultingPain
local function addWithdrawalHeadPain(player, source)
	local head = player:getBodyDamage():getBodyPart(BodyPartType.Head)
	local previousPain = head:getAdditionalPain()
	local resultingPain = math.min(100, previousPain + WITHDRAWAL_HEAD_PAIN_AMOUNT)
	head:setAdditionalPain(resultingPain)
	logETW(
		"ETW Logger | addWithdrawalHeadPain(): source: "
			.. source
			.. "; head pain: "
			.. previousPain
			.. "->"
			.. resultingPain
			.. "; player: "
			.. player:getUsername()
	)
	return resultingPain
end

---Rolls withdrawal head pain when its cooldown has expired and starts a cooldown at 70 pain.
---@param player IsoPlayer
---@param alcoholicSystem AlcoholicSystem
---@param chance number Percentage from 0 to 100.
---@param source string
local function tryWithdrawalHeadPain(player, alcoholicSystem, chance, source)
	if chance <= 0 then
		return
	end
	local worldAgeHours = getGameTime():getWorldAgeHours()
	if worldAgeHours < alcoholicSystem.WithdrawalHeadPainCooldownUntilHours or not rollPercentChance(chance) then
		return
	end
	local resultingPain = addWithdrawalHeadPain(player, source)
	if resultingPain >= WITHDRAWAL_HEAD_PAIN_COOLDOWN_THRESHOLD then
		alcoholicSystem.WithdrawalHeadPainCooldownUntilHours = worldAgeHours + WITHDRAWAL_HEAD_PAIN_COOLDOWN_HOURS
		logETW(
			"ETW Logger | tryWithdrawalHeadPain(): head pain reached "
				.. resultingPain
				.. "; cooldown until world age hour: "
				.. alcoholicSystem.WithdrawalHeadPainCooldownUntilHours
				.. "; player: "
				.. player:getUsername()
		)
	end
end

---Adds withdrawal food sickness without allowing this effect to raise it above 89.99%.
---@param player IsoPlayer
---@param stats Stats
---@param source string
---@return number resultingSickness
local function addWithdrawalSickness(player, stats, source)
	local previousSickness = stats:get(CharacterStat.FOOD_SICKNESS)
	if previousSickness >= MAX_WITHDRAWAL_FOOD_SICKNESS then
		return previousSickness
	end
	local amount = math.min(
		WITHDRAWAL_FOOD_SICKNESS_INCREASE,
		MAX_WITHDRAWAL_FOOD_SICKNESS - previousSickness
	)
	stats:add(CharacterStat.FOOD_SICKNESS, amount)
	local resultingSickness = math.min(
		MAX_WITHDRAWAL_FOOD_SICKNESS,
		stats:get(CharacterStat.FOOD_SICKNESS)
	)
	stats:set(CharacterStat.FOOD_SICKNESS, resultingSickness)
	logETW(
		"ETW Logger | addWithdrawalSickness(): source: "
			.. source
			.. "; food sickness: "
			.. previousSickness
			.. "->"
			.. resultingSickness
			.. "; requested increase: "
			.. WITHDRAWAL_FOOD_SICKNESS_INCREASE
			.. "; applied increase: "
			.. amount
			.. "; player: "
			.. player:getUsername()
	)
	return resultingSickness
end

---Rolls withdrawal food sickness when its cooldown has expired and starts a cooldown at 70% sickness.
---@param player IsoPlayer
---@param stats Stats
---@param alcoholicSystem AlcoholicSystem
---@param chance number Percentage from 0 to 100.
---@param source string
local function tryWithdrawalSickness(player, stats, alcoholicSystem, chance, source)
	if chance <= 0 then
		return
	end
	local worldAgeHours = getGameTime():getWorldAgeHours()
	if worldAgeHours < alcoholicSystem.WithdrawalFoodSicknessCooldownUntilHours or not rollPercentChance(chance) then
		return
	end
	local resultingSickness = addWithdrawalSickness(player, stats, source)
	if resultingSickness >= WITHDRAWAL_FOOD_SICKNESS_COOLDOWN_THRESHOLD then
		alcoholicSystem.WithdrawalFoodSicknessCooldownUntilHours =
			worldAgeHours + WITHDRAWAL_FOOD_SICKNESS_COOLDOWN_HOURS
		logETW(
			"ETW Logger | tryWithdrawalSickness(): food sickness reached "
				.. resultingSickness
				.. "; cooldown until world age hour: "
				.. alcoholicSystem.WithdrawalFoodSicknessCooldownUntilHours
				.. "; player: "
				.. player:getUsername()
		)
	end
end

---Rolls an asleep player's withdrawal wake-up chance when its cooldown has expired.
---@param player IsoPlayer
---@param alcoholicSystem AlcoholicSystem
---@param chance number Percentage from 0 to 100.
---@param source string
local function tryWithdrawalWakeUp(player, alcoholicSystem, chance, source)
	if chance <= 0 then
		return
	end
	local worldAgeHours = getGameTime():getWorldAgeHours()
	if worldAgeHours < alcoholicSystem.WithdrawalWakeUpCooldownUntilHours or not rollPercentChance(chance) then
		return
	end
	player:forceAwake()
	alcoholicSystem.WithdrawalWakeUpCooldownUntilHours = worldAgeHours + WITHDRAWAL_WAKE_UP_COOLDOWN_HOURS
	logETW(
		"ETW Logger | tryWithdrawalWakeUp(): source: "
			.. source
			.. "; chance: "
			.. chance
			.. "%; cooldown until world age hour: "
			.. alcoholicSystem.WithdrawalWakeUpCooldownUntilHours
			.. "; player: "
			.. player:getUsername()
	)
end

---Applies shared per-minute acute-withdrawal effects and provides severity-specific effect sections.
---@param player IsoPlayer
---@param stats Stats
---@param alcoholicSystem AlcoholicSystem
---@param withdrawalSeverity number Percentage from 0 to 100.
local function withdrawal(player, stats, alcoholicSystem, withdrawalSeverity)
	local dropChance
	local dropChanceReason
	local screamChance
	local screamChanceReason
	local headPainChance
	local headPainChanceReason
	local sicknessChance
	local sicknessChanceReason
	local wakeUpChance
	local wakeUpChanceReason
	-- Shared withdrawal effects belong here and can scale with withdrawalSeverity.
	if withdrawalSeverity >= SEVERE_WITHDRAWAL_SEVERITY then
		-- Severe: seizures, severe agitation, hallucinations, or delirium-like symptoms.
		dropChance = SBvars.AlcoholicSevereWithdrawalHandItemDropChancePercent
		dropChanceReason = "withdrawal(): severe hand-item drop"
		screamChance = SBvars.AlcoholicSevereWithdrawalScreamChancePercent
		screamChanceReason = "withdrawal(): severe scream"
		headPainChance = SBvars.AlcoholicSevereWithdrawalHeadPainChancePercent
		headPainChanceReason = "withdrawal(): severe head pain"
		sicknessChance = SBvars.AlcoholicSevereWithdrawalSicknessChancePercent
		sicknessChanceReason = "withdrawal(): severe sickness"
		wakeUpChance = SBvars.AlcoholicSevereWithdrawalWakeUpChancePercent
		wakeUpChanceReason = "withdrawal(): severe wake-up"
	elseif withdrawalSeverity >= MODERATE_WITHDRAWAL_SEVERITY then
		-- Moderate: stronger tremor, nausea, elevated heart rate, worse anxiety, confusion, or perceptual disturbances.
		dropChance = SBvars.AlcoholicModerateWithdrawalHandItemDropChancePercent
		dropChanceReason = "withdrawal(): moderate hand-item drop"
		screamChance = SBvars.AlcoholicModerateWithdrawalScreamChancePercent
		screamChanceReason = "withdrawal(): moderate scream"
		headPainChance = SBvars.AlcoholicModerateWithdrawalHeadPainChancePercent
		headPainChanceReason = "withdrawal(): moderate head pain"
		sicknessChance = SBvars.AlcoholicModerateWithdrawalSicknessChancePercent
		sicknessChanceReason = "withdrawal(): moderate sickness"
		wakeUpChance = SBvars.AlcoholicModerateWithdrawalWakeUpChancePercent
		wakeUpChanceReason = "withdrawal(): moderate wake-up"
	elseif withdrawalSeverity > 0 then
		-- Mild: anxiety, irritability, sweating, mild tremor, headache, or trouble sleeping.
		dropChance = SBvars.AlcoholicMildWithdrawalHandItemDropChancePercent
		dropChanceReason = "withdrawal(): mild hand-item drop"
		screamChance = SBvars.AlcoholicMildWithdrawalScreamChancePercent
		screamChanceReason = "withdrawal(): mild scream"
		headPainChance = SBvars.AlcoholicMildWithdrawalHeadPainChancePercent
		headPainChanceReason = "withdrawal(): mild head pain"
		sicknessChance = SBvars.AlcoholicMildWithdrawalSicknessChancePercent
		sicknessChanceReason = "withdrawal(): mild sickness"
		wakeUpChance = SBvars.AlcoholicMildWithdrawalWakeUpChancePercent
		wakeUpChanceReason = "withdrawal(): mild wake-up"
	end
	if dropChance and dropChanceReason and rollPercentChance(dropChance) then
		ETW_CommonServerFunctions.triggerHandItemDrop(player, dropChanceReason)
	end
	if screamChance and screamChanceReason and rollPercentChance(screamChance) then
		ETW_CommonServerFunctions.triggerSurprisedScream(player, true, screamChanceReason)
	end
	if headPainChance and headPainChanceReason then
		tryWithdrawalHeadPain(player, alcoholicSystem, headPainChance, headPainChanceReason)
	end
	if sicknessChance and sicknessChanceReason then
		tryWithdrawalSickness(player, stats, alcoholicSystem, sicknessChance, sicknessChanceReason)
	end
	if wakeUpChance and wakeUpChanceReason and player:isAsleep() then
		tryWithdrawalWakeUp(player, alcoholicSystem, wakeUpChance, wakeUpChanceReason)
	end
	updateTemperatureSwing(player, stats, alcoholicSystem, withdrawalSeverity)
end

---Rolls the number of sober minutes before the next acute-withdrawal severity change.
---@param alcoholicTraitStage integer
---@return integer minutes
local function rollWithdrawalDelay(alcoholicTraitStage)
	local minimum = 8 * 60 + alcoholicTraitStage * 1.5 * 60
	local maximum = 24 * 60 + alcoholicTraitStage * 3 * 60
	local multiplier = math.max(0, SBvars.AlcoholicWithdrawalDelayMultiplier)
	return math.max(1, math.floor(random_instance:random(minimum, maximum) * multiplier + 0.5))
end

---Returns the next lower acute-withdrawal severity target.
---@param currentSeverity number
---@return number severity
local function nextLowerWithdrawalSeverity(currentSeverity)
	if currentSeverity > MODERATE_WITHDRAWAL_SEVERITY then
		return MODERATE_WITHDRAWAL_SEVERITY
	elseif currentSeverity > MILD_WITHDRAWAL_SEVERITY then
		return MILD_WITHDRAWAL_SEVERITY
	end
	return 0
end

---Selects the next increasing acute-withdrawal severity target and its duration.
---@param player IsoPlayer
---@param alcoholicSystem AlcoholicSystem
---@param alcoholicTraitStage integer
local function selectNextWithdrawalTarget(player, alcoholicSystem, alcoholicTraitStage)
	local maximumSeverity =
		MAX_WITHDRAWAL_SEVERITY_BY_ALCOHOLIC_STAGE[math.min(alcoholicTraitStage, MAX_ALCOHOLIC_STAGE)]
	local currentSeverity = alcoholicSystem.WithdrawalSeverity
	local nextSeverity
	if currentSeverity < MILD_WITHDRAWAL_SEVERITY then
		nextSeverity = MILD_WITHDRAWAL_SEVERITY
	elseif currentSeverity < MODERATE_WITHDRAWAL_SEVERITY then
		nextSeverity = MODERATE_WITHDRAWAL_SEVERITY
	else
		nextSeverity = SEVERE_WITHDRAWAL_SEVERITY
	end
	nextSeverity = math.min(nextSeverity, maximumSeverity)

	alcoholicSystem.WithdrawalTargetSeverity = nextSeverity
	alcoholicSystem.MinutesUntilNextWithdrawalSeverityChange = rollWithdrawalDelay(alcoholicTraitStage)
	logETW(
		"ETW Logger | selectNextWithdrawalTarget(): severity: "
			.. currentSeverity
			.. "; target: "
			.. nextSeverity
			.. "; duration: "
			.. alcoholicSystem.MinutesUntilNextWithdrawalSeverityChange
			.. " minutes; alcoholic stage: "
			.. alcoholicTraitStage
			.. "; player: "
			.. player:getUsername()
	)
end

---Advances acute withdrawal through its initial delay, rising stages, peak hold, and final settled stage.
---@param player IsoPlayer
---@param alcoholicSystem AlcoholicSystem
---@param alcoholicTraitStage integer
local function updateWithdrawal(player, alcoholicSystem, alcoholicTraitStage)
	if not alcoholicSystem.WithdrawalIncreasing and alcoholicSystem.WithdrawalTargetSeverity == nil then
		return
	end
	if not alcoholicSystem.WithdrawalStartDelayCompleted and alcoholicSystem.WithdrawalTargetSeverity == nil then
		local delayMinutes = rollWithdrawalDelay(alcoholicTraitStage)
		alcoholicSystem.WithdrawalTargetSeverity = 0
		alcoholicSystem.MinutesUntilNextWithdrawalSeverityChange = delayMinutes
		logETW(
			"ETW Logger | updateWithdrawal(): waiting "
				.. delayMinutes
				.. " minutes before withdrawal starts; alcoholic stage: "
				.. alcoholicTraitStage
				.. "; player: "
				.. player:getUsername()
		)
	end
	if alcoholicSystem.WithdrawalTargetSeverity == nil then
		selectNextWithdrawalTarget(player, alcoholicSystem, alcoholicTraitStage)
	end

	local minutesRemaining = math.max(1, alcoholicSystem.MinutesUntilNextWithdrawalSeverityChange)
	local targetSeverity = alcoholicSystem.WithdrawalTargetSeverity
	local previousSeverity = alcoholicSystem.WithdrawalSeverity
	alcoholicSystem.WithdrawalSeverity = alcoholicSystem.WithdrawalSeverity
		+ (targetSeverity - alcoholicSystem.WithdrawalSeverity) / minutesRemaining
	alcoholicSystem.MinutesUntilNextWithdrawalSeverityChange = minutesRemaining - 1

	if alcoholicSystem.MinutesUntilNextWithdrawalSeverityChange <= 0 then
		alcoholicSystem.WithdrawalSeverity = targetSeverity
		if not alcoholicSystem.WithdrawalStartDelayCompleted and targetSeverity <= 0 then
			alcoholicSystem.WithdrawalStartDelayCompleted = true
			alcoholicSystem.WithdrawalTargetSeverity = nil
			logETW(
				"ETW Logger | updateWithdrawal(): initial delay completed; withdrawal starts next minute; player: "
					.. player:getUsername()
			)
			return
		end
		logETW(
			"ETW Logger | updateWithdrawal(): reached severity "
				.. targetSeverity
				.. "; previous severity: "
				.. previousSeverity
				.. "; player: "
				.. player:getUsername()
		)
		local maximumSeverity =
			MAX_WITHDRAWAL_SEVERITY_BY_ALCOHOLIC_STAGE[math.min(alcoholicTraitStage, MAX_ALCOHOLIC_STAGE)]
		if alcoholicSystem.WithdrawalIncreasing then
			if targetSeverity >= maximumSeverity then
				alcoholicSystem.WithdrawalIncreasing = false
				if maximumSeverity > MILD_WITHDRAWAL_SEVERITY then
					local peakHoldMinutes = rollWithdrawalDelay(alcoholicTraitStage)
					alcoholicSystem.WithdrawalTargetSeverity = maximumSeverity
					alcoholicSystem.MinutesUntilNextWithdrawalSeverityChange = peakHoldMinutes
					logETW(
						"ETW Logger | updateWithdrawal(): holding peak severity "
							.. maximumSeverity
							.. " for "
							.. peakHoldMinutes
							.. " minutes; player: "
							.. player:getUsername()
					)
				else
					alcoholicSystem.WithdrawalTargetSeverity = nil
					logETW(
						"ETW Logger | updateWithdrawal(): settled at mild severity; player: " .. player:getUsername()
					)
				end
			else
				alcoholicSystem.WithdrawalTargetSeverity = nil
			end
		elseif previousSeverity == targetSeverity then
			local settledSeverity = nextLowerWithdrawalSeverity(targetSeverity)
			local declineMinutes = rollWithdrawalDelay(alcoholicTraitStage)
			alcoholicSystem.WithdrawalTargetSeverity = settledSeverity
			alcoholicSystem.MinutesUntilNextWithdrawalSeverityChange = declineMinutes
			logETW(
				"ETW Logger | updateWithdrawal(): peak hold completed; declining to severity "
					.. settledSeverity
					.. " over "
					.. declineMinutes
					.. " minutes; player: "
					.. player:getUsername()
			)
		else
			alcoholicSystem.WithdrawalTargetSeverity = nil
			logETW(
				"ETW Logger | updateWithdrawal(): settled at severity "
					.. targetSeverity
					.. "; player: "
					.. player:getUsername()
			)
		end
	end
end

---Adds withdrawal stress for connected Alcoholic players and unregisters itself when idle.
local function withdrawalStressUpdate()
	local hasWithdrawingAlcoholic = false
	local players = ETW_CommonFunctions.playersList()
	for i = 0, players:size() - 1 do
		local player = players:get(i)
		local alcoholicTraitStage = ETW_Alcoholic.getAlcoholicTraitStage(player)
		if alcoholicTraitStage > 0 then
			local modData = ETW_CommonFunctions.getETWModData(player)
			if modData and modData.AlcoholicSystem.WithdrawalSeverity > 0 then
				hasWithdrawingAlcoholic = true
				local stats = player:getStats()
				local alcoholicSystem = modData.AlcoholicSystem
				local increase = math.max(0, SBvars.AlcoholicWithdrawalStressIncreasePerTick)
				alcoholicSystem.WithdrawalStress =
					math.min(MAX_WITHDRAWAL_STRESS, alcoholicSystem.WithdrawalStress + increase * alcoholicTraitStage)
				stats:set(
					CharacterStat.STRESS,
					math.max(stats:get(CharacterStat.STRESS), alcoholicSystem.WithdrawalStress)
				)
			end
		end
	end

	if not hasWithdrawingAlcoholic then
		Events.OnTick.Remove(withdrawalStressUpdate)
		withdrawalStressEventRegistered = false
		logETW("ETW Logger | withdrawalStressUpdate(): unregistered idle withdrawal-stress event")
	end
end

---Registers the withdrawal stress handler only while it has work to perform.
function ETW_Alcoholic.ensureWithdrawalStressEvent()
	if withdrawalStressEventRegistered then
		return
	end
	Events.OnTick.Remove(withdrawalStressUpdate)
	Events.OnTick.Add(withdrawalStressUpdate)
	withdrawalStressEventRegistered = true
	logETW("ETW Logger | ensureWithdrawalStressEvent(): registered withdrawal-stress event")
end

---Removes the withdrawal stress handler during orchestrator cleanup.
function ETW_Alcoholic.clearWithdrawalStressEvent()
	Events.OnTick.Remove(withdrawalStressUpdate)
	if withdrawalStressEventRegistered then
		logETW("ETW Logger | clearWithdrawalStressEvent(): removed withdrawal-stress event")
	end
	withdrawalStressEventRegistered = false
end

---Samples intoxication and updates the Alcoholic trait's positive and withdrawal effects.
---@param player IsoPlayer
---@param stats Stats
---@param modData EvolvingTraitsWorldModData
---@param alcoholicTraitStage integer
function ETW_Alcoholic.oneMinuteUpdate(player, stats, modData, alcoholicTraitStage)
	local alcoholicSystem = modData.AlcoholicSystem
	local intoxication = stats:get(CharacterStat.INTOXICATION)
	local baseIntoxicationRequired = SBvars.AlcoholicPositiveEffectBaseIntoxicationPercent or 20
	local intoxicationRequiredPerStage = SBvars.AlcoholicPositiveEffectIntoxicationPercentPerStage or 10
	local positiveEffectThreshold = baseIntoxicationRequired + intoxicationRequiredPerStage * alcoholicTraitStage
	local withdrawalResetPercent = SBvars.AlcoholicWithdrawalResetThresholdPercent or 50
	local withdrawalResetThreshold = positiveEffectThreshold * withdrawalResetPercent / 100

	if intoxication >= withdrawalResetThreshold then
		local withdrawalWasTracked = alcoholicSystem.MinutesSinceBeingDrunk > 0
			or alcoholicSystem.WithdrawalSeverity > 0
			or alcoholicSystem.WithdrawalTargetSeverity ~= nil
			or alcoholicSystem.WithdrawalStress > 0
			or alcoholicSystem.TemperatureSwingDirection ~= nil
		if withdrawalWasTracked then
			logETW(
				"ETW Logger | oneMinuteUpdate(): reset withdrawal at intoxication "
					.. intoxication
					.. "; reset threshold: "
					.. withdrawalResetThreshold
					.. "; previous severity: "
					.. alcoholicSystem.WithdrawalSeverity
					.. "; player: "
					.. player:getUsername()
			)
		end
		alcoholicSystem.MinutesSinceBeingDrunk = 0
		alcoholicSystem.WithdrawalSeverity = 0
		alcoholicSystem.MinutesUntilNextWithdrawalSeverityChange = 0
		alcoholicSystem.WithdrawalTargetSeverity = nil
		alcoholicSystem.WithdrawalStress = 0
		alcoholicSystem.WithdrawalIncreasing = true
		alcoholicSystem.WithdrawalStartDelayCompleted = false
		alcoholicSystem.TemperatureSwingDirection = nil
		alcoholicSystem.TemperatureSwingMinutesRemaining = 0

		if intoxication >= positiveEffectThreshold then
			local baseReduction = math.max(0, SBvars.AlcoholicStressAndPanicReductionPerMinute)
			local stageReduction = math.max(0, SBvars.AlcoholicStressAndPanicReductionPerStage)
			local reductionPercent = baseReduction + stageReduction * alcoholicTraitStage
			local previousStress = stats:get(CharacterStat.STRESS)
			local previousPanic = stats:get(CharacterStat.PANIC)
			stats:set(CharacterStat.STRESS, math.max(0, previousStress - reductionPercent / 100))
			stats:set(CharacterStat.PANIC, math.max(0, previousPanic - reductionPercent))
			if previousStress > 0 or previousPanic > 0 then
				logETW(
					"ETW Logger | oneMinuteUpdate(): positive Alcoholic effect; stress: "
						.. previousStress
						.. "->"
						.. stats:get(CharacterStat.STRESS)
						.. "; panic: "
						.. previousPanic
						.. "->"
						.. stats:get(CharacterStat.PANIC)
						.. "; player: "
						.. player:getUsername()
				)
			end
		end
		return
	end

	alcoholicSystem.MinutesSinceBeingDrunk = alcoholicSystem.MinutesSinceBeingDrunk + 1
	updateWithdrawal(player, alcoholicSystem, alcoholicTraitStage)
	local withdrawalActive = alcoholicSystem.WithdrawalSeverity > 0
	if withdrawalActive then
		withdrawal(player, stats, alcoholicSystem, alcoholicSystem.WithdrawalSeverity)
		ETW_Alcoholic.ensureWithdrawalStressEvent()
	elseif alcoholicSystem.TemperatureSwingDirection ~= nil then
		logETW(
			"ETW Logger | oneMinuteUpdate(): withdrawal ended; cancelling temperature swing; player: "
				.. player:getUsername()
		)
		alcoholicSystem.TemperatureSwingDirection = nil
		alcoholicSystem.TemperatureSwingMinutesRemaining = 0
	end
end

return ETW_Alcoholic
