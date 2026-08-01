local ETW_CommonFunctions = require("ETW_CommonFunctions")
local ETW_AnimalActionsSharedLogic = require("TimedActions/Animals/ETW_AnimalActionsSharedLogic")

local FILENAME = "ETW_ISButcherAnimalOverrideServer.lua"
if
	not ETW_CommonFunctions.gameModeSafeguard(
		FILENAME,
		{ ETW_CommonFunctions.GameMode.SP, ETW_CommonFunctions.GameMode.MP_SERVER }
	)
then
	return
end

local original_ISButcherAnimal_complete = ISButcherAnimal.complete
---Decorates successful ground/inventory animal butchering to fill the Bloodlust meter.
function ISButcherAnimal:complete()
	local originalReturn = original_ISButcherAnimal_complete(self)
	if originalReturn == true then
		ETW_AnimalActionsSharedLogic.increaseBloodlustMeter(self.character, "ISButcherAnimal:complete()")
	end
	return originalReturn
end
