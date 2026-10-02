local ETW_CommonFunctions = require("ETW_CommonFunctions")
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
local random_instance = newrandom()
local MAX_WITHDRAWAL_STRESS = 0.5
local MAX_WITHDRAWAL_SEVERITY_LEVEL = 3
local MINUTES_IN_HOUR = 60

local WITHDRAWAL_SEVERITY_BY_LEVEL = {
	[0] = 0,
	[1] = 33,
	[2] = 67,
	[3] = 100,
}

local ALCOHOLIC_TRAIT_STAGES = {
	[ETWTraitsRegistry.ALCOHOLIC_MILD] = 1,
	[ETWTraitsRegistry.ALCOHOLIC_MODERATE] = 2,
	[ETWTraitsRegistry.ALCOHOLIC_SEVERE] = 3,
}

local withdrawalStressEventRegistered = false

---Returns the severity of the Alcoholic trait currently held by the player.
---@param player IsoPlayer
---@return integer stage Zero when the player has no Alcoholic trait.
function ETW_Alcoholic.getAlcoholicStage(player)
	if player:hasTrait(ETWTraitsRegistry.ALCOHOLIC_SEVERE) then
		return ALCOHOLIC_TRAIT_STAGES[ETWTraitsRegistry.ALCOHOLIC_SEVERE]
	elseif player:hasTrait(ETWTraitsRegistry.ALCOHOLIC_MODERATE) then
		return ALCOHOLIC_TRAIT_STAGES[ETWTraitsRegistry.ALCOHOLIC_MODERATE]
	elseif player:hasTrait(ETWTraitsRegistry.ALCOHOLIC_MILD) then
		return ALCOHOLIC_TRAIT_STAGES[ETWTraitsRegistry.ALCOHOLIC_MILD]
	end
	return 0
end

---Applies shared acute-withdrawal effects and provides severity-specific effect sections.
---@param player IsoPlayer
---@param stats Stats
---@param withdrawalSeverity number Percentage from 0 to 100.
local function withdrawal(player, stats, withdrawalSeverity)
	-- Shared withdrawal effects belong here and can scale with withdrawalSeverity.
	if withdrawalSeverity >= WITHDRAWAL_SEVERITY_BY_LEVEL[3] then
		-- Severe: seizures, severe agitation, hallucinations, or delirium-like symptoms.
	elseif withdrawalSeverity >= WITHDRAWAL_SEVERITY_BY_LEVEL[2] then
		-- Moderate: stronger tremor, nausea, elevated heart rate, worse anxiety, confusion, or perceptual disturbances.
	elseif withdrawalSeverity > 0 then
		-- Mild: anxiety, irritability, sweating, mild tremor, headache, or trouble sleeping.
	end
end

---Rolls the number of sober minutes before the next acute-withdrawal severity change.
---@param alcoholicStage integer
---@return integer minutes
local function rollWithdrawalDelay(alcoholicStage)
	local minimum = 12 * MINUTES_IN_HOUR - alcoholicStage * 1.5 * MINUTES_IN_HOUR
	local maximum = 24 * MINUTES_IN_HOUR - alcoholicStage * 2 * MINUTES_IN_HOUR
	local multiplier = math.max(0, SBvars.AlcoholicWithdrawalDelayMultiplier or 1)
	return math.max(1, math.floor(random_instance:random(minimum, maximum) * multiplier + 0.5))
end

---Returns the discrete timing level represented by an acute-withdrawal severity.
---@param withdrawalSeverity number
---@return integer level
local function withdrawalSeverityLevel(withdrawalSeverity)
	if withdrawalSeverity >= 84 then
		return 3
	elseif withdrawalSeverity >= 50 then
		return 2
	elseif withdrawalSeverity > 0 then
		return 1
	end
	return 0
end

---Selects the next progressive acute-withdrawal severity target and its duration.
---@param alcoholicSystem AlcoholicSystem
---@param alcoholicStage integer
local function selectNextWithdrawalTarget(alcoholicSystem, alcoholicStage)
	local maximumSeverityLevel = math.min(alcoholicStage, MAX_WITHDRAWAL_SEVERITY_LEVEL)
	local currentSeverityLevel = withdrawalSeverityLevel(alcoholicSystem.WithdrawalSeverity)
	local nextSeverityLevel
	if alcoholicSystem.WithdrawalIncreasing then
		if currentSeverityLevel >= maximumSeverityLevel then
			alcoholicSystem.WithdrawalIncreasing = false
			nextSeverityLevel = math.min(currentSeverityLevel - 1, maximumSeverityLevel)
		else
			nextSeverityLevel = currentSeverityLevel + 1
			if nextSeverityLevel >= maximumSeverityLevel then
				alcoholicSystem.WithdrawalIncreasing = false
			end
		end
	else
		nextSeverityLevel = math.min(maximumSeverityLevel, math.max(0, currentSeverityLevel - 1))
	end

	alcoholicSystem.WithdrawalTargetSeverity = WITHDRAWAL_SEVERITY_BY_LEVEL[nextSeverityLevel]
	alcoholicSystem.MinutesUntilNextWithdrawalSeverityChange = rollWithdrawalDelay(alcoholicStage)
end

---Moves acute-withdrawal severity toward its target by one minute of the rolled duration.
---@param alcoholicSystem AlcoholicSystem
---@param alcoholicStage integer
local function updateWithdrawal(alcoholicSystem, alcoholicStage)
	if
		alcoholicSystem.WithdrawalSeverity <= 0
		and not alcoholicSystem.WithdrawalIncreasing
		and alcoholicSystem.WithdrawalTargetSeverity == nil
	then
		return
	end
	if alcoholicSystem.WithdrawalTargetSeverity == nil then
		selectNextWithdrawalTarget(alcoholicSystem, alcoholicStage)
	end

	local minutesRemaining = math.max(1, alcoholicSystem.MinutesUntilNextWithdrawalSeverityChange)
	local targetSeverity = alcoholicSystem.WithdrawalTargetSeverity
	alcoholicSystem.WithdrawalSeverity = alcoholicSystem.WithdrawalSeverity
		+ (targetSeverity - alcoholicSystem.WithdrawalSeverity) / minutesRemaining
	alcoholicSystem.MinutesUntilNextWithdrawalSeverityChange = minutesRemaining - 1

	if alcoholicSystem.MinutesUntilNextWithdrawalSeverityChange <= 0 then
		alcoholicSystem.WithdrawalSeverity = targetSeverity
		alcoholicSystem.WithdrawalTargetSeverity = nil
	end
end

---Adds withdrawal stress for connected Alcoholic players and unregisters itself when idle.
local function withdrawalStressUpdate()
	local hasWithdrawingAlcoholic = false
	local players = ETW_CommonFunctions.playersList()
	for i = 0, players:size() - 1 do
		local player = players:get(i)
		local alcoholicStage = ETW_Alcoholic.getAlcoholicStage(player)
		if alcoholicStage > 0 then
			local modData = ETW_CommonFunctions.getETWModData(player)
			if modData and modData.AlcoholicSystem.WithdrawalSeverity > 0 then
				hasWithdrawingAlcoholic = true
				local stats = player:getStats()
				local alcoholicSystem = modData.AlcoholicSystem
				local increase = math.max(0, SBvars.AlcoholicWithdrawalStressIncreasePerTick or 0.00001)
				alcoholicSystem.WithdrawalStress = math.min(
					MAX_WITHDRAWAL_STRESS,
					alcoholicSystem.WithdrawalStress + increase * alcoholicStage
				)
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
end

---Removes the withdrawal stress handler during orchestrator cleanup.
function ETW_Alcoholic.clearWithdrawalStressEvent()
	Events.OnTick.Remove(withdrawalStressUpdate)
	withdrawalStressEventRegistered = false
end

---Samples intoxication and updates the Alcoholic trait's positive and withdrawal effects.
---@param player IsoPlayer
---@param stats Stats
---@param modData EvolvingTraitsWorldModData
---@param alcoholicStage integer
function ETW_Alcoholic.oneMinuteUpdate(player, stats, modData, alcoholicStage)
	local alcoholicSystem = modData.AlcoholicSystem
	local intoxication = stats:get(CharacterStat.INTOXICATION)
	local baseIntoxicationRequired = SBvars.AlcoholicPositiveEffectBaseIntoxicationPercent or 20
	local intoxicationRequiredPerStage = SBvars.AlcoholicPositiveEffectIntoxicationPercentPerStage or 10
	local positiveEffectThreshold = baseIntoxicationRequired + intoxicationRequiredPerStage * alcoholicStage
	local withdrawalResetPercent = SBvars.AlcoholicWithdrawalResetThresholdPercent or 50
	local withdrawalResetThreshold = positiveEffectThreshold * withdrawalResetPercent / 100

	if intoxication >= withdrawalResetThreshold then
		alcoholicSystem.MinutesSinceBeingDrunk = 0
		alcoholicSystem.WithdrawalSeverity = 0
		alcoholicSystem.MinutesUntilNextWithdrawalSeverityChange = 0
		alcoholicSystem.WithdrawalTargetSeverity = nil
		alcoholicSystem.WithdrawalStress = 0
		alcoholicSystem.WithdrawalIncreasing = true

		if intoxication >= positiveEffectThreshold then
			local baseReduction = math.max(0, SBvars.AlcoholicStressAndPanicReductionPerMinute or 2)
			local stageReduction = math.max(0, SBvars.AlcoholicStressAndPanicReductionPerStage or 1)
			local reductionPercent = baseReduction + stageReduction * alcoholicStage
			stats:set(
				CharacterStat.STRESS,
				math.max(0, stats:get(CharacterStat.STRESS) - reductionPercent / 100)
			)
			stats:set(CharacterStat.PANIC, math.max(0, stats:get(CharacterStat.PANIC) - reductionPercent))
		end
		return
	end

	alcoholicSystem.MinutesSinceBeingDrunk = alcoholicSystem.MinutesSinceBeingDrunk + 1
	updateWithdrawal(alcoholicSystem, alcoholicStage)
	if alcoholicSystem.WithdrawalSeverity > 0 then
		withdrawal(player, stats, alcoholicSystem.WithdrawalSeverity)
		ETW_Alcoholic.ensureWithdrawalStressEvent()
	end
end

return ETW_Alcoholic
