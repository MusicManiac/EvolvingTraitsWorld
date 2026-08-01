local ETW_CommonFunctions = require("ETW_CommonFunctions")

---@type EvolvingTraitsWorldSandboxVars
local SBvars = SandboxVars.EvolvingTraitsWorld

---@type EvolvingTraitsWorldRegistries
local ETW_Registry = require("ETW_Registry")
---@type EvolvingTraitsWorldTraitsRegistries
local ETWTraitsRegistry = ETW_Registry.traits

local FILENAME = "ETW_ISFixActionOverrideServer.lua"
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
local random_instance = newrandom()

local original_ISFixAction_complete = ISFixAction.complete
---Overwriting ISFixAction:complete() here to insert ETW logic triggering Restoration Expert
function ISFixAction:complete()
	logETW("ETW Logger | ISFixAction.complete(): caught")
	local originalReturn = original_ISFixAction_complete(self)
	if self.character:hasTrait(ETWTraitsRegistry.RESTORATION_EXPERT) then
		logETW("ETW Logger | ISFixAction.complete(): RestorationExpert present")
		if random_instance:random(100) <= SBvars.RestorationExpertChance then
			self.item:setHaveBeenRepaired(math.max(0, self.item:getHaveBeenRepaired() - 1))
		end
	end
	return originalReturn
end
