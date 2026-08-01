local ETW_CombinedTraitChecks = require("ETW_CombinedTraitChecks")
local ETW_CommonFunctions = require("ETW_CommonFunctions")
local ETW_CommonLogicChecks = require("ETW_CommonLogicChecks")

local FILENAME = "ETW_ISRepairEngineOverrideServer.lua"
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

local original_ISRepairEngine_complete = ISRepairEngine.complete
---Overwriting ISRepairEngine:complete() here to insert ETW logic catching player doing engine repairs
function ISRepairEngine:complete()
	logETW("ETW Logger | ISRepairEngine:complete(): caught.")
	local conditionBefore = self.part:getCondition()
	local modData = ETW_CommonFunctions.getETWModData(self.character)
	local originalReturn = original_ISRepairEngine_complete(self)
	local conditionAfterRepair = self.part:getCondition()
	local mechanicsShouldExecute = ETW_CommonLogicChecks.MechanicsShouldExecute(self.character)
	local bodyWorkEnthusiastShouldExecute = ETW_CommonLogicChecks.BodyWorkEnthusiastShouldExecute(self.character)
	if conditionAfterRepair > conditionBefore and (mechanicsShouldExecute or bodyWorkEnthusiastShouldExecute) then
		modData.VehiclePartRepairs = modData.VehiclePartRepairs + (conditionAfterRepair - conditionBefore)
		logETW(
			"ETW Logger | ISRepairEngine.complete(): car part "
				.. conditionBefore
				.. "->"
				.. conditionAfterRepair
				.. " VehiclePartRepairs="
				.. modData.VehiclePartRepairs
		)
		if bodyWorkEnthusiastShouldExecute then
			ETW_CombinedTraitChecks.bodyworkEnthusiastCheck(self.character)
		end
		if mechanicsShouldExecute then
			ETW_CombinedTraitChecks.mechanicsCheck(self.character)
		end
	end
	return originalReturn
end
