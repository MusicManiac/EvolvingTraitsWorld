local ETW_CommonFunctions = require("ETW_CommonFunctions")
local ETW_CommonLogicChecks = require("ETW_CommonLogicChecks")

---@type EvolvingTraitsWorldSandboxVars
local SBvars = SandboxVars.EvolvingTraitsWorld

---@type fun(...: string)
local logETW = ETW_CommonFunctions.log

local FILENAME = "ETW_AnimalsActionsOverrideServer.lua"

if
	not ETW_CommonFunctions.gameModeSafeguard(
		FILENAME,
		{ ETW_CommonFunctions.GameMode.SP, ETW_CommonFunctions.GameMode.MP_SERVER }
	)
then
	return
end

local gameMode = ETW_CommonFunctions.gameMode()
local bloodlustMeterCapacity = 72
local ETW_Moodles

if gameMode == ETW_CommonFunctions.GameMode.SP then
	ETW_Moodles = require("ETW_Moodles")
end

---Increases the Bloodlust meter for a completed animal action.
---@param player IsoPlayer
---@param actionName string
local function increaseBloodlustMeterFromAnimalAction(player, actionName)
	if
		SBvars.BloodlustFromAnimalsMultiplier <= 0
		or not ETW_CommonLogicChecks.BloodlustShouldExecute(player)
	then
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
	logETW(
		"ETW Logger | "
			.. actionName
			.. ": BloodlustMeter="
			.. bloodlust.BloodlustMeter
	)

	if gameMode == ETW_CommonFunctions.GameMode.SP then
		ETW_Moodles.bloodlustMoodleUpdate(player, { hide = false })
	elseif gameMode == ETW_CommonFunctions.GameMode.MP_SERVER then
		sendServerCommand(player, "ETW", "bloodlustMoodleUpdate", { hide = false })
	end
end

local original_ISButcherAnimal_complete = ISButcherAnimal.complete
---Decorates successful ground/inventory animal butchering to fill the Bloodlust meter.
function ISButcherAnimal:complete()
	local originalReturn = original_ISButcherAnimal_complete(self)
	if originalReturn == true then
		increaseBloodlustMeterFromAnimalAction(self.character, "ISButcherAnimal:complete()")
	end
	return originalReturn
end

local original_ISKillAnimal_complete = ISKillAnimal.complete
---Decorates successful world-animal slaughter to fill the Bloodlust meter.
function ISKillAnimal:complete()
	local originalReturn = original_ISKillAnimal_complete(self)
	if originalReturn == true then
		increaseBloodlustMeterFromAnimalAction(self.character, "ISKillAnimal:complete()")
	end
	return originalReturn
end

local original_ISKillAnimalInInventory_complete = ISKillAnimalInInventory.complete
---Decorates successful inventory-animal slaughter to fill the Bloodlust meter.
function ISKillAnimalInInventory:complete()
	local originalReturn = original_ISKillAnimalInInventory_complete(self)
	if originalReturn == true then
		increaseBloodlustMeterFromAnimalAction(self.character, "ISKillAnimalInInventory:complete()")
	end
	return originalReturn
end
