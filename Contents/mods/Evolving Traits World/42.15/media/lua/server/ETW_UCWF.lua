---@type ETW_CommonFunctions
local ETW_CommonFunctions = require("ETW_CommonFunctions")

local gameMode = ETW_CommonFunctions.gameMode()

-- This should be ran only if it's SP or if it's a server process
if gameMode == ETW_CommonFunctions.GameMode.MP_CLIENT then
	print("ETW_UCWF | Detected " .. gameMode .. " environment, skipping the file")
	return
else
	print("ETW_UCWF | Detected " .. gameMode .. " environment, loading the file")
end

require("UnifiedCarryWeightFramework")

---@type EvolvingTraitsWorldRegistries
local ETWRegistries = require("ETW_Registry")
---@type EvolvingTraitsWorldTraitsRegistries
local ETWTraitsRegistry = ETWRegistries.traits

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
