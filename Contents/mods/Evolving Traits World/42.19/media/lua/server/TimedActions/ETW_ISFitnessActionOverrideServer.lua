require("TimedActions/ISFitnessAction")

local ETW_CommonFunctions = require("ETW_CommonFunctions")
local ETW_CombinedTraitFunctions = require("ETW_CombinedTraitFunctions")
local ETW_Registry = require("ETW_Registry")
local ETW_BySkills = require("DynamicLogic/ETW_BySkills")

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

---Applies the exercise-only effects of Gym Rat and Couch Potato to a vanilla exercise repeat.
function ISFitnessAction:exeLooped()
	local player = self.character
	local isPlayer = instanceof(player, "IsoPlayer")
	local isGymRat = isPlayer and player:hasTrait(ETWTraitsRegistry.GYM_RAT)
	local isCouchPotato = isPlayer and player:hasTrait(ETWTraitsRegistry.COUCH_POTATO)
	local gymRatXPMultiplier = math.max(1, SBvars.GymRatExerciseXPMultiplier or 2)
	local couchPotatoXPMultiplier = math.max(0.1, math.min(1, SBvars.CouchPotatoExerciseXPMultiplier or 0.5))
	local shouldProcess = (isGymRat and gymRatXPMultiplier > 1)
		or (isCouchPotato and couchPotatoXPMultiplier < 1)
	local fitnessXPBefore = shouldProcess and player:getXp():getXP(Perks.Fitness) or 0
	local strengthXPBefore = shouldProcess and player:getXp():getXP(Perks.Strength) or 0

	local originalReturn = original_ISFitnessAction_exeLooped(self)
	if isPlayer then
		---@cast player IsoPlayer
		ETW_BySkills.traitsGainsBySkill(player, "exerciseRegularity")
	end
	if isCouchPotato then
		local fatigueMultiplier = math.max(1, math.floor(SBvars.CouchPotatoExerciseFatigueMultiplier or 2))
		for _ = 2, fatigueMultiplier do
			self.fitness:incFutureStiffness()
		end
	end
	if not shouldProcess then
		return originalReturn
	end
	---@cast player IsoPlayer
	local fitnessXPAfter = player:getXp():getXP(Perks.Fitness)
	local strengthXPAfter = player:getXp():getXP(Perks.Strength)
	local fitnessGain = math.max(0, fitnessXPAfter - fitnessXPBefore)
	local strengthGain = math.max(0, strengthXPAfter - strengthXPBefore)
	local xpMultiplier = isGymRat and gymRatXPMultiplier or couchPotatoXPMultiplier
	local fitnessAdjustment, _, fitnessReason = ETW_CombinedTraitFunctions.calculateProtectedXPAdjustment(
		player,
		Perks.Fitness,
		fitnessGain,
		xpMultiplier
	)
	local strengthAdjustment, _, strengthReason = ETW_CombinedTraitFunctions.calculateProtectedXPAdjustment(
		player,
		Perks.Strength,
		strengthGain,
		xpMultiplier
	)
	if fitnessAdjustment ~= 0 then
		addXpNoMultiplier(player, Perks.Fitness, fitnessAdjustment)
	end
	if strengthAdjustment ~= 0 then
		addXpNoMultiplier(player, Perks.Strength, strengthAdjustment)
	end
	if fitnessAdjustment ~= 0 or strengthAdjustment ~= 0 then
		logETW(
			"ETW Logger | ExerciseTraits | ISFitnessAction:exeLooped(): applied XP adjustments for "
				.. tostring(player:getUsername())
				.. " (OnlineID="
				.. player:getOnlineID()
				.. "); Fitness gain: "
				.. fitnessGain
				.. ", Fitness adjustment: "
				.. fitnessAdjustment
				.. ", Strength gain: "
				.. strengthGain
				.. ", Strength adjustment: "
				.. strengthAdjustment
		)
	else
		logETW(
			"ETW Logger | ExerciseTraits | ISFitnessAction:exeLooped(): no XP adjustment applied for "
				.. tostring(player:getUsername())
				.. " (OnlineID="
				.. player:getOnlineID()
				.. "); Fitness: "
				.. tostring(fitnessReason)
				.. ", Strength: "
				.. tostring(strengthReason)
		)
	end
	return originalReturn
end
