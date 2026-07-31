require("TimedActions/ISEatFoodAction")

local ETW_CommonFunctions = require("ETW_CommonFunctions")
local ETW_CommonLogicChecks = require("ETW_CommonLogicChecks")
local ETW_TimedActionsSharedLogic = require("TimedActions/ETW_TimedActionsSharedLogic")

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

local ACTION_UNITS_PER_MINUTE = 3600
local currentlyEating = {}

local original_ISEatFoodAction_start = ISEatFoodAction.start
---Starts a session used to account for both completed and interrupted eating actions.
function ISEatFoodAction:start()
	logETW("ETW Logger | ISEatFoodAction:start(): caught")
	local username = self.character:getUsername()
	currentlyEating[username] = nil
	if
		ETW_CommonLogicChecks.EatingSpeedSystemShouldExecute(self.character)
		and ETW_TimedActionsSharedLogic.isFoodEatingAction(self)
	then
		currentlyEating[username] = {
			itemId = self.item:getID(),
			itemType = self.item:getFullType(),
			duration = math.max(0, self.maxTime or 0),
		}
	end
	return original_ISEatFoodAction_start(self)
end

---Returns and removes the eating session when it matches the current food item.
---@param action ISEatFoodAction
---@return table|nil
local function takeEatingSession(action)
	local username = action.character:getUsername()
	local eatingSession = currentlyEating[username]
	currentlyEating[username] = nil
	if
		eatingSession
		and eatingSession.itemId == action.item:getID()
		and eatingSession.itemType == action.item:getFullType()
	then
		return eatingSession
	end
	if eatingSession then
		logETW("ETW Logger | ISEatFoodAction: eating session does not match the current food; ignoring it")
	end
	return nil
end

---Returns the best available progress for a completed or interrupted action.
---@param action ISEatFoodAction
---@return number
local function getEatingProgress(action)
	local progress = action.netAction and action.netAction:getProgress() or action:getJobDelta()
	return PZMath.clamp(progress or 0, 0, 1)
end

---Records elapsed action time and checks the Slow/Fast Eater thresholds.
---@param action ISEatFoodAction
---@param eatingSession table
---@param progress number
local function recordEatingTime(action, eatingSession, progress)
	if not ETW_CommonLogicChecks.EatingSpeedSystemShouldExecute(action.character) then
		return
	end
	local minutesSpentEating = eatingSession.duration * PZMath.clamp(progress, 0, 1) / ACTION_UNITS_PER_MINUTE
	if minutesSpentEating <= 0 then
		return
	end
	local modData = ETW_CommonFunctions.getETWModData(action.character)
	modData.MinutesSpentEating = (modData.MinutesSpentEating or 0) + minutesSpentEating
	logETW(
		"ETW Logger | ISEatFoodAction: minutesSpentEating = " .. minutesSpentEating,
		"ETW Logger | ISEatFoodAction: modData.MinutesSpentEating = " .. modData.MinutesSpentEating
	)
	ETW_TimedActionsSharedLogic.checkEatingSpeedTraits(action.character, modData)
end

local original_ISEatFoodAction_complete = ISEatFoodAction.complete
---Records the full duration on completion, or network progress when the server force-stops the action.
function ISEatFoodAction:complete()
	logETW("ETW Logger | ISEatFoodAction:complete(): caught")
	local eatingSession = takeEatingSession(self)
	local progress = self.forceStopped and getEatingProgress(self) or 1
	local originalReturn = original_ISEatFoodAction_complete(self)
	if eatingSession then
		recordEatingTime(self, eatingSession, progress)
	end
	return originalReturn
end

local original_ISEatFoodAction_stop = ISEatFoodAction.stop
---Records partial duration before vanilla clears an interrupted action's progress.
function ISEatFoodAction:stop()
	logETW("ETW Logger | ISEatFoodAction:stop(): caught")
	local eatingSession = takeEatingSession(self)
	if eatingSession then
		recordEatingTime(self, eatingSession, getEatingProgress(self))
	end
	return original_ISEatFoodAction_stop(self)
end
