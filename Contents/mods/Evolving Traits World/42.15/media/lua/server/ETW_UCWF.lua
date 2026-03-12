-- This should be ran only if it's SP or if it's a server process
if isClient() then
	print("ETW_UCWF | Detected MP client environment, skipping the file")
	return
end

require("UnifiedCarryWeightFramework")

---@type EvolvingTraitsWorldRegistries
local ETWRegistries = require("ETWRegistry")
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
