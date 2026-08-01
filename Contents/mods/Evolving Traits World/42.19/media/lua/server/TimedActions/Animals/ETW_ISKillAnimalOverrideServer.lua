local ETW_CommonFunctions = require("ETW_CommonFunctions")
local ETW_AnimalActionsSharedLogic = require("TimedActions/Animals/ETW_AnimalActionsSharedLogic")

local FILENAME = "ETW_ISKillAnimalOverrideServer.lua"
if
	not ETW_CommonFunctions.gameModeSafeguard(
		FILENAME,
		{ ETW_CommonFunctions.GameMode.SP, ETW_CommonFunctions.GameMode.MP_SERVER }
	)
then
	return
end

local original_ISKillAnimal_complete = ISKillAnimal.complete
---Decorates successful world-animal slaughter to fill the Bloodlust meter.
function ISKillAnimal:complete()
	local originalReturn = original_ISKillAnimal_complete(self)
	if originalReturn == true then
		ETW_AnimalActionsSharedLogic.increaseBloodlustMeter(self.character, "ISKillAnimal:complete()")
	end
	return originalReturn
end
