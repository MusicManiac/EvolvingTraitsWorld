local ETW_CommonFunctions = require("ETW_CommonFunctions")
local ETW_Registry = require("ETW_Registry")

local FILENAME = "ETW_FightingTraits.lua"
if
	not ETW_CommonFunctions.gameModeSafeguard(
		FILENAME,
		{ ETW_CommonFunctions.GameMode.SP, ETW_CommonFunctions.GameMode.MP_SERVER }
	)
then
	return
end

local ETW_FightingTraits = {}

---@type EvolvingTraitsWorldTraitsRegistries
local ETWTraitsRegistry = ETW_Registry.traits
---@type EvolvingTraitsWorldSandboxVars
local SBvars = SandboxVars.EvolvingTraitsWorld
local logETW = ETW_CommonFunctions.log

---Processes Bloodlust when a nearby zombie dies.
---@param zombie IsoZombie
function ETW_FightingTraits.onZombieDead(zombie)
	local playersList = ETW_CommonFunctions.playersList()
	for i = 0, playersList:size() - 1 do
		local player = playersList:get(i)
		-- TODO: figure if there's better way to do this than checking DistTo for all players
		if player:hasTrait(ETWTraitsRegistry.BLOODLUST) and player:DistTo(zombie) <= 4 then
			local stats = player:getStats()
			local nicotineWithdrawal = stats:get(CharacterStat.NICOTINE_WITHDRAWAL)
			local unhappiness = stats:get(CharacterStat.UNHAPPINESS)
			local stress = math.max(0, stats:get(CharacterStat.STRESS) - nicotineWithdrawal)
			local panic = stats:get(CharacterStat.PANIC)
			stats:set(CharacterStat.UNHAPPINESS, math.max(0, unhappiness - 4 * SBvars.BloodlustMultiplier))
			stats:set(CharacterStat.STRESS, math.max(0, stress - 0.04 * SBvars.BloodlustMultiplier))
			stats:set(CharacterStat.PANIC, math.max(0, panic - 4 * SBvars.BloodlustMultiplier))
			logETW(
				"ETW Logger | onZombieDead(): Bloodlust kill. Unhappiness:"
					.. unhappiness
					.. "->"
					.. stats:get(CharacterStat.UNHAPPINESS)
					.. ", stress: "
					.. math.min(1, stress + nicotineWithdrawal)
					.. "->"
					.. stats:get(CharacterStat.STRESS)
					.. ", panic: "
					.. panic
					.. "->"
					.. stats:get(CharacterStat.PANIC)
			)
		end
	end
end

return ETW_FightingTraits
