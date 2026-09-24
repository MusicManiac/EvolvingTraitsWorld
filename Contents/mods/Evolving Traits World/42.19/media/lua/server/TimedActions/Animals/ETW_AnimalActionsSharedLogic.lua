local ETW_CommonFunctions = require("ETW_CommonFunctions")

local AnimalActionsSharedLogic = {}

local FILENAME = "ETW_AnimalActionsSharedLogic.lua"
if
	not ETW_CommonFunctions.gameModeSafeguard(
		FILENAME,
		{ ETW_CommonFunctions.GameMode.SP, ETW_CommonFunctions.GameMode.MP_SERVER }
	)
then
	return AnimalActionsSharedLogic
end

local ETW_CommonLogicChecks = require("ETW_CommonLogicChecks")
local ETW_CommonServerFunctions = require("ETW_CommonServerFunctions")

---@type EvolvingTraitsWorldSandboxVars
local SBvars = SandboxVars.EvolvingTraitsWorld

---Adds Bloodlust progress for a completed animal action.
---@param player IsoPlayer
---@param actionName string
function AnimalActionsSharedLogic.addBloodlustProgress(player, actionName)
	if SBvars.BloodlustFromAnimalsMultiplier <= 0 or not ETW_CommonLogicChecks.BloodlustShouldExecute(player) then
		return
	end

	ETW_CommonServerFunctions.addBloodlustProgress(player, SBvars.BloodlustFromAnimalsMultiplier, actionName)
end

return AnimalActionsSharedLogic
