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
local WITHDRAWAL_STAGE_HEAVY = 3
local MINUTES_IN_HOUR = 60

local ALCOHOLIC_TRAIT_STAGES = {
	[ETWTraitsRegistry.ALCOHOLIC_MILD] = 1,
	[ETWTraitsRegistry.ALCOHOLIC_MODERATE] = 2,
	[ETWTraitsRegistry.ALCOHOLIC_HIGH] = 3,
	[ETWTraitsRegistry.ALCOHOLIC_SEVERE] = 4,
}

local withdrawalStressEventRegistered = false

---Returns the severity of the Alcoholic trait currently held by the player.
---@param player IsoPlayer
---@return integer stage Zero when the player has no Alcoholic trait.
function ETW_Alcoholic.getAlcoholicStage(player)
	if player:hasTrait(ETWTraitsRegistry.ALCOHOLIC_SEVERE) then
		return ALCOHOLIC_TRAIT_STAGES[ETWTraitsRegistry.ALCOHOLIC_SEVERE]
	elseif player:hasTrait(ETWTraitsRegistry.ALCOHOLIC_HIGH) then
		return ALCOHOLIC_TRAIT_STAGES[ETWTraitsRegistry.ALCOHOLIC_HIGH]
	elseif player:hasTrait(ETWTraitsRegistry.ALCOHOLIC_MODERATE) then
		return ALCOHOLIC_TRAIT_STAGES[ETWTraitsRegistry.ALCOHOLIC_MODERATE]
	elseif player:hasTrait(ETWTraitsRegistry.ALCOHOLIC_MILD) then
		return ALCOHOLIC_TRAIT_STAGES[ETWTraitsRegistry.ALCOHOLIC_MILD]
	end
	return 0
end

---Placeholder for the first acute-withdrawal stage.
---@param player IsoPlayer
local function lightWithdrawal(player)
end

---Placeholder for the second acute-withdrawal stage.
---@param player IsoPlayer
local function mediumWithdrawal(player)
end

---Placeholder for the third acute-withdrawal stage.
---@param player IsoPlayer
local function heavyWithdrawal(player)
end

---Rolls the number of sober minutes before the next acute-withdrawal stage.
---@param alcoholicStage integer
---@return integer minutes
local function rollWithdrawalDelay(alcoholicStage)
	local minimum = 12 * MINUTES_IN_HOUR - alcoholicStage * 1.5 * MINUTES_IN_HOUR
	local maximum = 24 * MINUTES_IN_HOUR - alcoholicStage * 2 * MINUTES_IN_HOUR
	local multiplier = math.max(0, SBvars.AlcoholicWithdrawalDelayMultiplier or 1)
	return math.max(1, math.floor(random_instance:random(minimum, maximum) * multiplier + 0.5))
end

---Advances acute withdrawal when the current persisted delay has elapsed.
---@param player IsoPlayer
---@param alcoholicSystem AlcoholicSystem
---@param alcoholicStage integer
local function updateWithdrawal(player, alcoholicSystem, alcoholicStage)
	if alcoholicSystem.WithdrawalStage >= WITHDRAWAL_STAGE_HEAVY then
		return
	end
	if alcoholicSystem.MinutesUntilNextWithdrawalStage <= 0 then
		alcoholicSystem.MinutesUntilNextWithdrawalStage = rollWithdrawalDelay(alcoholicStage)
	end
	alcoholicSystem.MinutesUntilNextWithdrawalStage = alcoholicSystem.MinutesUntilNextWithdrawalStage - 1
	if alcoholicSystem.MinutesUntilNextWithdrawalStage > 0 then
		return
	end

	if alcoholicSystem.WithdrawalStage == 0 then
		lightWithdrawal(player)
		alcoholicSystem.WithdrawalStage = 1
	elseif alcoholicSystem.WithdrawalStage == 1 then
		mediumWithdrawal(player)
		alcoholicSystem.WithdrawalStage = 2
	else
		heavyWithdrawal(player)
		alcoholicSystem.WithdrawalStage = WITHDRAWAL_STAGE_HEAVY
	end

	if alcoholicSystem.WithdrawalStage < WITHDRAWAL_STAGE_HEAVY then
		alcoholicSystem.MinutesUntilNextWithdrawalStage = rollWithdrawalDelay(alcoholicStage)
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
			if modData and modData.AlcoholicSystem.WithdrawalStage > 0 then
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
		alcoholicSystem.WithdrawalStage = 0
		alcoholicSystem.MinutesUntilNextWithdrawalStage = 0
		alcoholicSystem.WithdrawalStress = 0

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
	updateWithdrawal(player, alcoholicSystem, alcoholicStage)
	if alcoholicSystem.WithdrawalStage > 0 then
		ETW_Alcoholic.ensureWithdrawalStressEvent()
	end
end

return ETW_Alcoholic
