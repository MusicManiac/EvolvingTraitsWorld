local function gameMode()
	if not isClient() and not isServer() then
		return "SP"
	elseif isClient() then
		return "MP_Client"
	end
	return "MP_Server"
end

-- This should be ran only if it's SP or if it's a server process
if gameMode() == "MP_Client" then
	print("ETW_UCWF | Detected MP client environment, skipping the file")
	return
else
	print("ETW_UCWF | Detected " .. gameMode() .. " environment, loading the file")
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
