local ETW_CommonFunctions = require("ETW_CommonFunctions")

---@type EvolvingTraitsWorldSandboxVars
local SBvars = SandboxVars.EvolvingTraitsWorld

local FILENAME = "ETW_ISChopTreeActionOverrideServer.lua"
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

local original_ISChopTreeAction_complete = ISChopTreeAction.complete
---Overwriting ISChopTreeAction:complete() here to track chopped trees and award Axeman
function ISChopTreeAction:complete()
	local originalReturn = original_ISChopTreeAction_complete(self)
	local modData = ETW_CommonFunctions.getETWModData(self.character)
	modData.TreesChopped = modData.TreesChopped + 1
	logETW("ETW Logger | ISChopTreeAction.complete(): modData.TreesChopped = " .. modData.TreesChopped)
	if modData.TreesChopped >= SBvars.AxemanTrees then
		if
			SBvars.DelayedTraitsSystem
			and not ETW_CommonFunctions.checkIfTraitIsInDelayedTraitsTable(self.character, CharacterTrait.AXEMAN)
		then
			ETW_CommonFunctions.addTraitToDelayTable({
				modData = modData,
				trait = CharacterTrait.AXEMAN,
				player = self.character,
				positiveTrait = true,
				gainingTrait = true,
			})
		elseif
			not SBvars.DelayedTraitsSystem
			or (
				SBvars.DelayedTraitsSystem
				and ETW_CommonFunctions.checkDelayedTraits(self.character, CharacterTrait.AXEMAN)
			)
		then
			ETW_CommonFunctions.addTraitToPlayer({
				player = self.character,
				trait = CharacterTrait.AXEMAN,
				positiveTrait = true,
			})
		end
	end
	return originalReturn
end
