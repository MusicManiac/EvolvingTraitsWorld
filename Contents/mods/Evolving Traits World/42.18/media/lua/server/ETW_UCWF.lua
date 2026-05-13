---@type ETW_CommonFunctions
local ETW_CommonFunctions = require("ETW_CommonFunctions")

local FILENAME = "ETW_UCWF.lua"
if
	not ETW_CommonFunctions.gameModeSafeguard(
		FILENAME,
		{ ETW_CommonFunctions.GameMode.SP, ETW_CommonFunctions.GameMode.MP_SERVER }
	)
then
	return
end

require("UnifiedCarryWeightFramework")

---@type EvolvingTraitsWorldRegistries
local ETW_Registry = require("ETW_Registry")
---@type EvolvingTraitsWorldTraitsRegistries
local ETWTraitsRegistry = ETW_Registry.traits

---@type EvolvingTraitsWorldSandboxVars
local SBvars = SandboxVars.EvolvingTraitsWorld

UnifiedCarryWeightFramework.registerMaxModifier({
	id = "ETW.HoarderTraitCarryWeight",

	resolve = function(ctx)
		local player = ctx.player
		---@cast player IsoPlayer
		if player:hasTrait(ETWTraitsRegistry.HOARDER) then
			return {
				add = player:getPerkLevel(Perks.Strength) * SBvars.HoarderWeight,
			}
		end
		return {}
	end,
})
