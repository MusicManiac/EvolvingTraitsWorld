require("TimedActions/ISFitnessAction")

local ETW_CommonFunctions = require("ETW_CommonFunctions")
local ETW_Registry = require("ETW_Registry")

local FILENAME = "ETW_ISFitnessActionOverrideServer.lua"
if
	not ETW_CommonFunctions.gameModeSafeguard(
		FILENAME,
		{ ETW_CommonFunctions.GameMode.SP, ETW_CommonFunctions.GameMode.MP_SERVER }
	)
then
	return
end

---@type EvolvingTraitsWorldTraitsRegistries
local ETWTraitsRegistry = ETW_Registry.traits
---@type EvolvingTraitsWorldSandboxVars
local SBvars = SandboxVars.EvolvingTraitsWorld
local logETW = ETW_CommonFunctions.log

local original_ISFitnessAction_exeLooped = ISFitnessAction.exeLooped

---Applies Gym Rat's exercise-only XP multiplier to the actual XP awarded by a vanilla exercise repeat.
function ISFitnessAction:exeLooped()
	local player = self.character
	local xpMultiplier = math.max(1, SBvars.GymRatExerciseXPMultiplier or 2)
	local shouldProcess = instanceof(player, "IsoPlayer")
		and player:hasTrait(ETWTraitsRegistry.GYM_RAT)
		and xpMultiplier > 1
	local fitnessXPBefore
	local strengthXPBefore
	if shouldProcess then
		fitnessXPBefore = player:getXp():getXP(Perks.Fitness)
		strengthXPBefore = player:getXp():getXP(Perks.Strength)
	end

	local originalReturn = original_ISFitnessAction_exeLooped(self)
	if not shouldProcess then
		return originalReturn
	end

	local fitnessXPAfter = player:getXp():getXP(Perks.Fitness)
	local strengthXPAfter = player:getXp():getXP(Perks.Strength)
	local fitnessGain = math.max(0, fitnessXPAfter - fitnessXPBefore)
	local strengthGain = math.max(0, strengthXPAfter - strengthXPBefore)
	local bonusMultiplier = xpMultiplier - 1
	local fitnessBonus = fitnessGain * bonusMultiplier
	local strengthBonus = strengthGain * bonusMultiplier
	if fitnessBonus > 0 then
		addXpNoMultiplier(player, Perks.Fitness, fitnessBonus)
	end
	if strengthBonus > 0 then
		addXpNoMultiplier(player, Perks.Strength, strengthBonus)
	end
	if fitnessBonus > 0 or strengthBonus > 0 then
		logETW(
			"ETW Logger | GymRat | ISFitnessAction:exeLooped(): applied exercise XP bonus for "
				.. tostring(player:getUsername())
				.. " (OnlineID="
				.. player:getOnlineID()
				.. "); Fitness gain: "
				.. fitnessGain
				.. ", Fitness bonus: "
				.. fitnessBonus
				.. ", Strength gain: "
				.. strengthGain
				.. ", Strength bonus: "
				.. strengthBonus
		)
	else
		logETW(
			"ETW Logger | GymRat | ISFitnessAction:exeLooped(): vanilla awarded no Fitness or Strength XP for "
				.. tostring(player:getUsername())
				.. " (OnlineID="
				.. player:getOnlineID()
				.. ") this repeat"
		)
	end
	return originalReturn
end
