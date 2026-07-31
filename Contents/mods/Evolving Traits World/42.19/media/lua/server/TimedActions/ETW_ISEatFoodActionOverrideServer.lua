require("TimedActions/ISEatFoodAction")

local ETW_CommonFunctions = require("ETW_CommonFunctions")
local ETW_CommonLogicChecks = require("ETW_CommonLogicChecks")
local ETW_Registry = require("ETW_Registry")

---@type EvolvingTraitsWorldSandboxVars
local SBvars = SandboxVars.EvolvingTraitsWorld

---@type EvolvingTraitsWorldTraitsRegistries
local ETWTraitsRegistry = ETW_Registry.traits

local FILENAME = "ETW_ISEatFoodActionOverrideServer.lua"
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
local gameMode = ETW_CommonFunctions.gameMode()

local ACTION_UNITS_PER_MINUTE = 3600

local original_ISEatFoodAction_getDuration = ISEatFoodAction.getDuration

---Applies the eating-speed traits after vanilla has calculated the duration so
---portion sizes, utensils, and item-specific EatTime values keep working.
---@return number
function ISEatFoodAction:getDuration()
	local duration = original_ISEatFoodAction_getDuration(self)
	if duration <= 1 then
		return duration
	end

	local item = self.item
	local isFood = item ~= nil
		and item:getCustomMenuOption() ~= getText("ContextMenu_Drink")
		and not item:hasTag(ItemTag.SMOKABLE)
	if isFood and self.character:hasTrait(ETW_Registry.traits.FAST_EATER) then
		local reduction = PZMath.clamp(SBvars.FastEaterSpeed or 25, 0, 90) / 100
		return math.max(1, duration * (1 - reduction))
	end
	if isFood and self.character:hasTrait(ETW_Registry.traits.SLOW_EATER) then
		local increase = PZMath.clamp(SBvars.SlowEaterSpeed or 25, 0, 90) / 100
		return duration * (1 + increase)
	end

	return duration
end

---Returns the best available progress for a completed or interrupted action.
---@param action ISEatFoodAction
---@return number
local function getEatingProgress(action)
	local progress = action.netAction and action.netAction:getProgress() or action:getJobDelta()
	return PZMath.clamp(progress or 0, 0, 1)
end

---Removes Slow Eater and adds Fast Eater when the Eating Speed System thresholds are reached.
---@param player IsoPlayer
---@param modData EvolvingTraitsWorldModData
local function checkEatingSpeedTraits(player, modData)
	local counter = modData.MinutesSpentEating or 0
	local target = SBvars.EatingSpeedSystemMinutes or 60
	if
		player:hasTrait(ETWTraitsRegistry.SLOW_EATER)
		and counter >= target / 2
		and SBvars.TraitsLockSystemCanLoseNegative
	then
		if
			SBvars.DelayedTraitsSystem
			and not ETW_CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, ETWTraitsRegistry.SLOW_EATER)
		then
			ETW_CommonFunctions.addTraitToDelayTable({
				modData = modData,
				trait = ETWTraitsRegistry.SLOW_EATER,
				player = player,
				positiveTrait = false,
				gainingTrait = false,
			})
		elseif
			not SBvars.DelayedTraitsSystem
			or (
				SBvars.DelayedTraitsSystem
					and ETW_CommonFunctions.checkDelayedTraits(player, ETWTraitsRegistry.SLOW_EATER)
			)
		then
			ETW_CommonFunctions.removeTraitFromPlayer({
				player = player,
				trait = ETWTraitsRegistry.SLOW_EATER,
				positiveTrait = false,
			})
		end
	elseif
		not player:hasTrait(ETWTraitsRegistry.SLOW_EATER)
		and not player:hasTrait(ETWTraitsRegistry.FAST_EATER)
		and counter >= target
		and SBvars.TraitsLockSystemCanGainPositive
	then
		if
			SBvars.DelayedTraitsSystem
			and not ETW_CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, ETWTraitsRegistry.FAST_EATER)
		then
			ETW_CommonFunctions.addTraitToDelayTable({
				modData = modData,
				trait = ETWTraitsRegistry.FAST_EATER,
				player = player,
				positiveTrait = true,
				gainingTrait = true,
			})
		elseif
			not SBvars.DelayedTraitsSystem
			or (
				SBvars.DelayedTraitsSystem
					and ETW_CommonFunctions.checkDelayedTraits(player, ETWTraitsRegistry.FAST_EATER)
			)
		then
			ETW_CommonFunctions.addTraitToPlayer({
				player = player,
				trait = ETWTraitsRegistry.FAST_EATER,
				positiveTrait = true,
			})
		end
	end
end

---Records elapsed action time once and checks the Slow/Fast Eater thresholds.
---@param action ISEatFoodAction
---@param progress number
local function recordEatingTime(action, progress)
	if action.etwEatingTimeRecorded then
		return
	end
	local item = action.item
	local isFood = item ~= nil
		and item:getCustomMenuOption() ~= getText("ContextMenu_Drink")
		and not item:hasTag(ItemTag.SMOKABLE)
	local shouldExecute = ETW_CommonLogicChecks.EatingSpeedSystemShouldExecute(action.character)
	if not shouldExecute or not isFood then
		logETW(
			"ETW Logger | ISEatFoodAction: skipped; shouldExecute = "
				.. tostring(shouldExecute)
				.. ", isFood = "
				.. tostring(isFood)
		)
		return
	end
	local duration = tonumber(action.maxTime) or 0
	if duration <= 0 then
		duration = tonumber(action:getDuration()) or 0
	end
	duration = math.max(0, duration)
	local minutesSpentEating = duration * PZMath.clamp(progress, 0, 1) / ACTION_UNITS_PER_MINUTE
	if minutesSpentEating <= 0 then
		logETW(
			"ETW Logger | ISEatFoodAction: no time recorded; duration = "
				.. duration
				.. ", progress = "
				.. progress
		)
		return
	end
	action.etwEatingTimeRecorded = true
	local modData = ETW_CommonFunctions.getETWModData(action.character)
	modData.MinutesSpentEating = (modData.MinutesSpentEating or 0) + minutesSpentEating
	logETW(
		"ETW Logger | ISEatFoodAction: minutesSpentEating = " .. minutesSpentEating,
		"ETW Logger | ISEatFoodAction: modData.MinutesSpentEating = " .. modData.MinutesSpentEating
	)
	checkEatingSpeedTraits(action.character, modData)
end

local original_ISEatFoodAction_complete = ISEatFoodAction.complete
---Records the full duration when an eating action completes in single-player or on the server.
function ISEatFoodAction:complete()
	logETW("ETW Logger | ISEatFoodAction:complete(): caught")
	local originalReturn = original_ISEatFoodAction_complete(self)
	recordEatingTime(self, 1)
	return originalReturn
end

local original_ISEatFoodAction_stop = ISEatFoodAction.stop
---Records partial duration before single-player clears an interrupted action's progress.
function ISEatFoodAction:stop()
	logETW("ETW Logger | ISEatFoodAction:stop(): caught")
	if gameMode == ETW_CommonFunctions.GameMode.SP then
		recordEatingTime(self, getEatingProgress(self))
	end
	return original_ISEatFoodAction_stop(self)
end

local original_ISEatFoodAction_serverStop = ISEatFoodAction.serverStop
---Records authoritative network progress whenever an eating action finishes on the server.
function ISEatFoodAction:serverStop()
	logETW("ETW Logger | ISEatFoodAction:serverStop(): caught")
	local progress = getEatingProgress(self)
	logETW(
		"ETW Logger | ISEatFoodAction:serverStop(): progress = "
			.. progress
			.. ", maxTime = "
			.. tostring(self.maxTime)
	)
	recordEatingTime(self, progress)
	return original_ISEatFoodAction_serverStop(self)
end
