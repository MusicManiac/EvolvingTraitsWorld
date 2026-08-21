local ETW_CombinedTraitFunctions = require("ETW_CombinedTraitFunctions")
local ETW_CommonFunctions = require("ETW_CommonFunctions")
local ETW_CommonLogicChecks = require("ETW_CommonLogicChecks")

local FILENAME = "ETW_ISFixVehiclePartActionOverrideServer.lua"
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

local original_ISFixVehiclePartAction_complete = ISFixVehiclePartAction.complete
function ISFixVehiclePartAction:complete()
	logETW("ETW Logger | ISFixVehiclePartAction:complete(): caught")
	local partConditionBeforeRepair = self.item:getCondition()
	local originalReturn = original_ISFixVehiclePartAction_complete(self)
	local modData = ETW_CommonFunctions.getETWModData(self.character)
	local conditionAfterRepair = self.item:getCondition()
	local mechanicsShouldExecute = ETW_CommonLogicChecks.MechanicsShouldExecute(self.character)
	local bodyWorkEnthusiastShouldExecute = ETW_CommonLogicChecks.BodyWorkEnthusiastShouldExecute(self.character)
	if
		conditionAfterRepair > partConditionBeforeRepair and (mechanicsShouldExecute or bodyWorkEnthusiastShouldExecute)
	then
		modData.VehiclePartRepairs = modData.VehiclePartRepairs + (conditionAfterRepair - partConditionBeforeRepair)
		logETW(
			"ETW Logger | ISFixVehiclePartAction.complete(): car part "
				.. partConditionBeforeRepair
				.. "->"
				.. conditionAfterRepair
				.. " VehiclePartRepairs="
				.. modData.VehiclePartRepairs
		)
		if bodyWorkEnthusiastShouldExecute then
			ETW_CombinedTraitFunctions.bodyworkEnthusiastCheck(self.character)
		end
		if mechanicsShouldExecute then
			ETW_CombinedTraitFunctions.mechanicsCheck(self.character)
		end
	end
	return originalReturn
end
