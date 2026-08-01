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

---@type EvolvingTraitsWorldSandboxVars
local SBvars = SandboxVars.EvolvingTraitsWorld

local gameMode = ETW_CommonFunctions.gameMode()
local bloodlustMeterCapacity = 72
local ETW_Moodles

if gameMode == ETW_CommonFunctions.GameMode.SP then
	ETW_Moodles = require("ETW_Moodles")
end

---Increases the Bloodlust meter for a completed animal action.
---@param player IsoPlayer
---@param actionName string
function AnimalActionsSharedLogic.increaseBloodlustMeter(player, actionName)
	if SBvars.BloodlustFromAnimalsMultiplier <= 0 or not ETW_CommonLogicChecks.BloodlustShouldExecute(player) then
		return
	end

	local modData = ETW_CommonFunctions.getETWModData(player)
	local bloodlust = modData.BloodlustSystem
	local hardCap = bloodlustMeterCapacity * SBvars.BloodlustMeterMaxCapMultiplier
	-- A point-blank zombie kill contributes 1 * BloodlustMeterFillMultiplier.
	local increase = SBvars.BloodlustMeterFillMultiplier * SBvars.BloodlustFromAnimalsMultiplier

	if bloodlust.BloodlustMeter > bloodlustMeterCapacity then
		increase = increase * 0.5
	end

	bloodlust.BloodlustMeter = math.min(hardCap, bloodlust.BloodlustMeter + increase)
	bloodlust.LastKillTimestamp = player:getHoursSurvived()
	ETW_CommonFunctions.log("ETW Logger | " .. actionName .. ": BloodlustMeter=" .. bloodlust.BloodlustMeter)

	if gameMode == ETW_CommonFunctions.GameMode.SP then
		ETW_Moodles.bloodlustMoodleUpdate(player, { hide = false })
	elseif gameMode == ETW_CommonFunctions.GameMode.MP_SERVER then
		sendServerCommand(player, "ETW", "bloodlustMoodleUpdate", { hide = false })
	end
end

return AnimalActionsSharedLogic
