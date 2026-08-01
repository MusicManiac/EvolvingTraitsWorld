local ETW_CommonFunctions = require("ETW_CommonFunctions")
local ETW_AnimalActionsSharedLogic = require("TimedActions/Animals/ETW_AnimalActionsSharedLogic")

local FILENAME = "ETW_ISKillAnimalInInventoryOverrideServer.lua"
if
	not ETW_CommonFunctions.gameModeSafeguard(
		FILENAME,
		{ ETW_CommonFunctions.GameMode.SP, ETW_CommonFunctions.GameMode.MP_SERVER }
	)
then
	return
end

local original_ISKillAnimalInInventory_complete = ISKillAnimalInInventory.complete
---Decorates successful inventory-animal slaughter to fill the Bloodlust meter.
function ISKillAnimalInInventory:complete()
	local originalReturn = original_ISKillAnimalInInventory_complete(self)
	if originalReturn == true then
		ETW_AnimalActionsSharedLogic.increaseBloodlustMeter(self.character, "ISKillAnimalInInventory:complete()")
	end
	return originalReturn
end
