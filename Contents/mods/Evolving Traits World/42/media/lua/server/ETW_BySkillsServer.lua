local ETW_BySkills = {}

local UCWF = require("UnifiedCarryWeightFramework")
local CombinedTraitChecks = require("ETW_CombinedTraitChecks")
local CommonFunctions = require("ETW_CommonFunctions")
local ETW_CommonLogicChecks = require("ETW_CommonLogicChecks")
local ETW_CommonFunctions = require("ETW_CommonFunctions")

---@type EvolvingTraitsWorldRegistries
local ETW_Registry = require("ETW_Registry")
---@type EvolvingTraitsWorldTraitsRegistries
local ETWTraitsRegistry = ETW_Registry.traits

---@type EvolvingTraitsWorldSandboxVars
local SBvars = SandboxVars.EvolvingTraitsWorld

---@type fun(...: string)
local logETW = CommonFunctions.log
local FILENAME = "ETWBySkills.lua"

if
	not CommonFunctions.gameModeSafeguard(FILENAME, { CommonFunctions.GameMode.SP, CommonFunctions.GameMode.MP_SERVER })
then
	return
end

local gameMode = CommonFunctions.gameMode()

local validHearingTriggers = {
	["characterInitialization"] = true,
	[Perks.Sprinting] = true,
	[Perks.Lightfoot] = true,
	[Perks.Nimble] = true,
	[Perks.Sneak] = true,
	[Perks.Axe] = true,
	[Perks.Blunt] = true,
	[Perks.SmallBlunt] = true,
	[Perks.LongBlade] = true,
	[Perks.SmallBlade] = true,
	[Perks.Spear] = true,
	[CharacterTrait.HARD_OF_HEARING] = true,
	[CharacterTrait.KEEN_HEARING] = true,
}

local validHoarderTriggers = {
	["characterInitialization"] = true,
	[Perks.Strength] = true,
	[ETWTraitsRegistry.HOARDER] = true,
}

local validGymRatTriggers = {
	["characterInitialization"] = true,
	[Perks.Strength] = true,
	[Perks.Fitness] = true,
	[ETWTraitsRegistry.GYM_RAT] = true,
}

local validRunnerTriggers = {
	["characterInitialization"] = true,
	[Perks.Sprinting] = true,
	[CharacterTrait.JOGGER] = true,
}

local validLightStepTriggers = {
	["characterInitialization"] = true,
	[Perks.Lightfoot] = true,
	[ETWTraitsRegistry.LIGHTSTEP] = true,
}

local validGymnastTriggers = {
	["characterInitialization"] = true,
	[Perks.Lightfoot] = true,
	[Perks.Nimble] = true,
	[CharacterTrait.GYMNAST] = true,
}

local validClumsyTriggers = {
	["characterInitialization"] = true,
	[Perks.Lightfoot] = true,
	[Perks.Sneak] = true,
	[CharacterTrait.CLUMSY] = true,
}

local validGracefulTriggers = {
	["characterInitialization"] = true,
	[Perks.Nimble] = true,
	[Perks.Sneak] = true,
	[Perks.Lightfoot] = true,
	[CharacterTrait.GRACEFUL] = true,
}

local validBurglarTriggers = {
	["characterInitialization"] = true,
	[Perks.Nimble] = true,
	[Perks.Mechanics] = true,
	[Perks.Electricity] = true,
	[CharacterTrait.BURGLAR] = true,
}

local validLowProfileTriggers = {
	["characterInitialization"] = true,
	[Perks.Sneak] = true,
	[ETWTraitsRegistry.LOW_PROFILE] = true,
}

local validConspicuousTriggers = {
	["characterInitialization"] = true,
	[Perks.Sneak] = true,
	[CharacterTrait.CONSPICUOUS] = true,
	[CharacterTrait.INCONSPICUOUS] = true,
}

local validBrawlerTriggers = {
	["characterInitialization"] = true,
	["kill"] = true,
	[Perks.Axe] = true,
	[Perks.Blunt] = true,
	[CharacterTrait.BRAWLER] = true,
}

local validAxeThrowerTriggers = {
	["characterInitialization"] = true,
	["kill"] = true,
	[Perks.Axe] = true,
	[ETWTraitsRegistry.AXE_THROWER] = true,
}

local validBaseballPlayerTriggers = {
	["characterInitialization"] = true,
	["kill"] = true,
	[Perks.Blunt] = true,
	[CharacterTrait.BASEBALL_PLAYER] = true,
}

local validHunterTriggers = {
	["characterInitialization"] = true,
	["kill"] = true,
	[Perks.Sneak] = true,
	[Perks.Aiming] = true,
	[Perks.Trapping] = true,
	[Perks.SmallBlade] = true,
	[CharacterTrait.HUNTER] = true,
}

local validStickFighterTriggers = {
	["characterInitialization"] = true,
	["kill"] = true,
	[Perks.SmallBlunt] = true,
	[ETWTraitsRegistry.STICK_FIGHTER] = true,
}

local validBladeEnthusiastTriggers = {
	["characterInitialization"] = true,
	["kill"] = true,
	[Perks.LongBlade] = true,
	[ETWTraitsRegistry.BLADE_ENTHUSIAST] = true,
}

local validKnifeFighterTriggers = {
	["characterInitialization"] = true,
	["kill"] = true,
	[Perks.SmallBlade] = true,
	[ETWTraitsRegistry.KNIFE_FIGHTER] = true,
}

local validPolearmTriggers = {
	["characterInitialization"] = true,
	["kill"] = true,
	[Perks.Spear] = true,
	[ETWTraitsRegistry.POLEARM_FIGHTER] = true,
}

local validRestorationExpertTriggers = {
	["characterInitialization"] = true,
	[Perks.Maintenance] = true,
	[ETWTraitsRegistry.RESTORATION_EXPERT] = true,
}

local validHandyTriggers = {
	["characterInitialization"] = true,
	[Perks.Maintenance] = true,
	[Perks.Woodwork] = true,
	[CharacterTrait.HANDY] = true,
}

local validLearnerTriggers = {
	["characterInitialization"] = true,
	[Perks.Maintenance] = true,
	[Perks.Woodwork] = true,
	[Perks.Cooking] = true,
	[Perks.Farming] = true,
	[Perks.Doctor] = true,
	[Perks.Electricity] = true,
	[Perks.MetalWelding] = true,
	[Perks.Mechanics] = true,
	[Perks.Tailoring] = true,
	[CharacterTrait.SLOW_LEARNER] = true,
	[CharacterTrait.FAST_LEARNER] = true,
}

local validFurnitureAssemblerTriggers = {
	["characterInitialization"] = true,
	[Perks.Woodwork] = true,
	[ETWTraitsRegistry.FURNITURE_ASSEMBLER] = true,
}

local validHomeCookTriggers = {
	["characterInitialization"] = true,
	[Perks.Cooking] = true,
	[ETWTraitsRegistry.HOME_COOK] = true,
}

local validCookTriggers = {
	["characterInitialization"] = true,
	[Perks.Cooking] = true,
	[CharacterTrait.COOK] = true,
}

local validGardenerTriggers = {
	["characterInitialization"] = true,
	[Perks.Farming] = true,
	[CharacterTrait.GARDENER] = true,
}

local validPetTherapyTriggers = {
	["characterInitialization"] = true,
	[Perks.Husbandry] = true,
	[ETWTraitsRegistry.PET_THERAPY] = true,
}

local validWhittlerTriggers = {
	["characterInitialization"] = true,
	[Perks.Carving] = true,
	[CharacterTrait.WHITTLER] = true,
}

local validBlacksmithTriggers = {
	["characterInitialization"] = true,
	[Perks.Blacksmith] = true,
	[CharacterTrait.BLACKSMITH] = true,
}

local validWildernessKnowledgeTriggers = {
	["characterInitialization"] = true,
	[Perks.PlantScavenging] = true,
	[Perks.FlintKnapping] = true,
	[Perks.Maintenance] = true,
	[Perks.Carving] = true,
	[CharacterTrait.WILDERNESS_KNOWLEDGE] = true,
}

local validFirstAidTriggers = {
	["characterInitialization"] = true,
	[Perks.Doctor] = true,
	[CharacterTrait.FIRST_AID] = true,
}

local validAVClubTriggers = {
	["characterInitialization"] = true,
	[Perks.Electricity] = true,
	[ETWTraitsRegistry.AV_CLUB] = true,
}

local validBodyWorkEnthusiastTriggers = {
	["characterInitialization"] = true,
	[Perks.MetalWelding] = true,
	[Perks.Mechanics] = true,
	[ETWTraitsRegistry.BODYWORK_ENTHUSIAST] = true,
}

local validMechanicsTriggers = {
	["characterInitialization"] = true,
	[Perks.Mechanics] = true,
	[CharacterTrait.MECHANICS] = true,
}

local validSewerTriggers = {
	["characterInitialization"] = true,
	[Perks.Tailoring] = true,
	[CharacterTrait.TAILOR] = true,
}

local validGunEnthusiastTriggers = {
	["characterInitialization"] = true,
	["kill"] = true,
	[Perks.Aiming] = true,
	[Perks.Reloading] = true,
	[ETWTraitsRegistry.GUN_ENTHUSIAST] = true,
}

local validAnglerTriggers = {
	["characterInitialization"] = true,
	[Perks.Fishing] = true,
	[ETWTraitsRegistry.ANGLER] = true,
}

local validHikerTriggers = {
	["characterInitialization"] = true,
	[Perks.Trapping] = true,
	[Perks.PlantScavenging] = true,
	[CharacterTrait.HIKER] = true,
}

local validFishingTriggers = {
	["characterInitialization"] = true,
	[Perks.Fishing] = true,
	[CharacterTrait.FISHING] = true,
}

---Gain traits by skills (in majority cases)
---@param player IsoPlayer
---@param trigger PerkFactory.Perk|string|CharacterTrait
function ETW_BySkills.traitsGainsBySkill(player, trigger)
	logETW(
		"ETW Logger | traitsGainsBySkill(): running for player "
			.. player:getUsername()
			.. ", trigger "
			.. tostring(trigger)
	)
	local modData = CommonFunctions.getETWModData(player)
	if not modData then
		logETW("ETW Logger | traitsGainsBySkill(): modData is nil, returning early")
		return
	end

	-- locals for perk levels
	local strength = player:getPerkLevel(Perks.Strength)
	local fitness = player:getPerkLevel(Perks.Fitness)
	local sprinting = player:getPerkLevel(Perks.Sprinting)
	local lightfooted = player:getPerkLevel(Perks.Lightfoot)
	local nimble = player:getPerkLevel(Perks.Nimble)
	local sneaking = player:getPerkLevel(Perks.Sneak)
	local axe = player:getPerkLevel(Perks.Axe)
	local longBlunt = player:getPerkLevel(Perks.Blunt)
	local shortBlunt = player:getPerkLevel(Perks.SmallBlunt)
	local longBlade = player:getPerkLevel(Perks.LongBlade)
	local shortBlade = player:getPerkLevel(Perks.SmallBlade)
	local spear = player:getPerkLevel(Perks.Spear)
	local maintenance = player:getPerkLevel(Perks.Maintenance)
	local carpentry = player:getPerkLevel(Perks.Woodwork)
	local cooking = player:getPerkLevel(Perks.Cooking)
	local farming = player:getPerkLevel(Perks.Farming)
	local firstAid = player:getPerkLevel(Perks.Doctor)
	local electrical = player:getPerkLevel(Perks.Electricity)
	local metalworking = player:getPerkLevel(Perks.MetalWelding)
	local mechanics = player:getPerkLevel(Perks.Mechanics)
	local tailoring = player:getPerkLevel(Perks.Tailoring)
	local aiming = player:getPerkLevel(Perks.Aiming)
	local reloading = player:getPerkLevel(Perks.Reloading)
	local fishing = player:getPerkLevel(Perks.Fishing)
	local trapping = player:getPerkLevel(Perks.Trapping)
	local foraging = player:getPerkLevel(Perks.PlantScavenging)
	local husbandry = player:getPerkLevel(Perks.Husbandry)
	local carving = player:getPerkLevel(Perks.Carving)
	local blacksmith = player:getPerkLevel(Perks.Blacksmith)
	local knapping = player:getPerkLevel(Perks.FlintKnapping)

	-- locals for kills by category
	local killCountModData = player:getModData().KillCount.WeaponCategory
	local axeKills = killCountModData["Axe"].count
	local longBluntKills = killCountModData["Blunt"].count
	local shortBluntKills = killCountModData["SmallBlunt"].count
	local longBladeKills = killCountModData["LongBlade"].count
	local shortBladeKills = killCountModData["SmallBlade"].count
	local spearKills = killCountModData["Spear"].count
	local firearmKills = killCountModData["Firearm"].count

	if validHearingTriggers[trigger] and ETW_CommonLogicChecks.HearingSystemShouldExecute(player) then
		local levels = sprinting
			+ lightfooted
			+ nimble
			+ sneaking
			+ axe
			+ longBlunt
			+ shortBlunt
			+ longBlade
			+ shortBlade
			+ spear
		if
			player:hasTrait(CharacterTrait.HARD_OF_HEARING)
			and levels >= SBvars.HearingSystemSkill / 2
			and SBvars.TraitsLockSystemCanLoseNegative
		then
			if
				SBvars.DelayedTraitsSystem
				and not CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, CharacterTrait.HARD_OF_HEARING)
			then
				CommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = CharacterTrait.HARD_OF_HEARING,
					player = player,
					positiveTrait = false,
					gainingTrait = false,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (
					SBvars.DelayedTraitsSystem
					and CommonFunctions.checkDelayedTraits(player, CharacterTrait.HARD_OF_HEARING)
				)
			then
				CommonFunctions.removeTraitFromPlayer({
					player = player,
					trait = CharacterTrait.HARD_OF_HEARING,
					positiveTrait = false,
				})
			end
		elseif not player:hasTrait(CharacterTrait.HARD_OF_HEARING) and levels >= SBvars.HearingSystemSkill then
			if
				SBvars.DelayedTraitsSystem
				and not CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, CharacterTrait.KEEN_HEARING)
			then
				CommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = CharacterTrait.KEEN_HEARING,
					player = player,
					positiveTrait = true,
					gainingTrait = true,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (
					SBvars.DelayedTraitsSystem
					and CommonFunctions.checkDelayedTraits(player, CharacterTrait.KEEN_HEARING)
				)
			then
				CommonFunctions.addTraitToPlayer({
					player = player,
					trait = CharacterTrait.KEEN_HEARING,
					positiveTrait = true,
				})
			end
		end
	end
	if validHoarderTriggers[trigger] and ETW_CommonLogicChecks.HoarderShouldExecute(player) then
		if strength >= SBvars.HoarderSkill then
			if
				SBvars.DelayedTraitsSystem
				and not CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, ETWTraitsRegistry.HOARDER)
			then
				CommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = ETWTraitsRegistry.HOARDER,
					player = player,
					positiveTrait = true,
					gainingTrait = true,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (
					SBvars.DelayedTraitsSystem
					and CommonFunctions.checkDelayedTraits(player, ETWTraitsRegistry.HOARDER)
				)
			then
				CommonFunctions.addTraitToPlayer({
					player = player,
					trait = ETWTraitsRegistry.HOARDER,
					positiveTrait = true,
				})
				UnifiedCarryWeightFramework.recomputeAll(player)
			end
		end
	end
	if validGymRatTriggers[trigger] and ETW_CommonLogicChecks.GymRatShouldExecute(player) then
		if (strength + fitness) >= SBvars.GymRatSkill then
			if
				SBvars.DelayedTraitsSystem
				and not CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, ETWTraitsRegistry.GYM_RAT)
			then
				CommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = ETWTraitsRegistry.GYM_RAT,
					player = player,
					positiveTrait = true,
					gainingTrait = true,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (
					SBvars.DelayedTraitsSystem
					and CommonFunctions.checkDelayedTraits(player, ETWTraitsRegistry.GYM_RAT)
				)
			then
				CommonFunctions.addTraitToPlayer({
					player = player,
					trait = ETWTraitsRegistry.GYM_RAT,
					positiveTrait = true,
				})
			end
		end
	end
	if validRunnerTriggers[trigger] and ETW_CommonLogicChecks.RunnerShouldExecute(player) then
		if sprinting >= SBvars.RunnerSkill then
			if
				SBvars.DelayedTraitsSystem
				and not CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, CharacterTrait.JOGGER)
			then
				CommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = CharacterTrait.JOGGER,
					player = player,
					positiveTrait = true,
					gainingTrait = true,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (SBvars.DelayedTraitsSystem and CommonFunctions.checkDelayedTraits(player, CharacterTrait.JOGGER))
			then
				CommonFunctions.addTraitToPlayer({
					player = player,
					trait = CharacterTrait.JOGGER,
					positiveTrait = true,
				})
			end
		end
	end
	if validLightStepTriggers[trigger] and ETW_CommonLogicChecks.LightStepShouldExecute(player) then
		if lightfooted >= SBvars.LightStepSkill then
			if
				SBvars.DelayedTraitsSystem
				and not CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, ETWTraitsRegistry.LIGHTSTEP)
			then
				CommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = ETWTraitsRegistry.LIGHTSTEP,
					player = player,
					positiveTrait = true,
					gainingTrait = true,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (
					SBvars.DelayedTraitsSystem
					and CommonFunctions.checkDelayedTraits(player, ETWTraitsRegistry.LIGHTSTEP)
				)
			then
				CommonFunctions.addTraitToPlayer({
					player = player,
					trait = ETWTraitsRegistry.LIGHTSTEP,
					positiveTrait = true,
				})
			end
		end
	end
	if validGymnastTriggers[trigger] and ETW_CommonLogicChecks.GymnastShouldExecute(player) then
		if (lightfooted + nimble) >= SBvars.GymnastSkill then
			if
				SBvars.DelayedTraitsSystem
				and not CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, ETWTraitsRegistry.GYMNAST)
			then
				CommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = ETWTraitsRegistry.GYMNAST,
					player = player,
					positiveTrait = true,
					gainingTrait = true,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (
					SBvars.DelayedTraitsSystem
					and CommonFunctions.checkDelayedTraits(player, ETWTraitsRegistry.GYMNAST)
				)
			then
				CommonFunctions.addTraitToPlayer({
					player = player,
					trait = ETWTraitsRegistry.GYMNAST,
					positiveTrait = true,
				})
			end
		end
	end
	if validClumsyTriggers[trigger] and ETW_CommonLogicChecks.ClumsyShouldExecute(player) then
		if (lightfooted + sneaking) >= SBvars.ClumsySkill then
			if
				SBvars.DelayedTraitsSystem
				and not CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, CharacterTrait.CLUMSY)
			then
				CommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = CharacterTrait.CLUMSY,
					player = player,
					positiveTrait = false,
					gainingTrait = false,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (SBvars.DelayedTraitsSystem and CommonFunctions.checkDelayedTraits(player, CharacterTrait.CLUMSY))
			then
				CommonFunctions.removeTraitFromPlayer({
					player = player,
					trait = CharacterTrait.CLUMSY,
					positiveTrait = false,
				})
			end
		end
	end
	if validGracefulTriggers[trigger] and ETW_CommonLogicChecks.GracefulShouldExecute(player) then
		local levels = nimble + sneaking + lightfooted
		if levels >= SBvars.GracefulSkill then
			if
				SBvars.DelayedTraitsSystem
				and not CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, CharacterTrait.GRACEFUL)
			then
				CommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = CharacterTrait.GRACEFUL,
					player = player,
					positiveTrait = true,
					gainingTrait = true,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (SBvars.DelayedTraitsSystem and CommonFunctions.checkDelayedTraits(player, CharacterTrait.GRACEFUL))
			then
				CommonFunctions.addTraitToPlayer({
					player = player,
					trait = CharacterTrait.GRACEFUL,
					positiveTrait = true,
				})
			end
		end
	end
	if validBurglarTriggers[trigger] and ETW_CommonLogicChecks.BurglarShouldExecute(player) then
		local levels = nimble + mechanics + electrical
		if electrical >= 2 and mechanics >= 2 and levels >= SBvars.BurglarSkill then
			if
				SBvars.DelayedTraitsSystem
				and not CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, CharacterTrait.BURGLAR)
			then
				CommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = CharacterTrait.BURGLAR,
					player = player,
					positiveTrait = true,
					gainingTrait = true,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (SBvars.DelayedTraitsSystem and CommonFunctions.checkDelayedTraits(player, CharacterTrait.BURGLAR))
			then
				CommonFunctions.addTraitToPlayer({
					player = player,
					trait = CharacterTrait.BURGLAR,
					positiveTrait = true,
				})
			end
		end
	end
	if validLowProfileTriggers[trigger] and ETW_CommonLogicChecks.LowProfileShouldExecute(player) then
		if sneaking >= SBvars.LowProfileSkill then
			if
				SBvars.DelayedTraitsSystem
				and not CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, ETWTraitsRegistry.LOW_PROFILE)
			then
				CommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = ETWTraitsRegistry.LOW_PROFILE,
					player = player,
					positiveTrait = true,
					gainingTrait = true,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (
					SBvars.DelayedTraitsSystem
					and CommonFunctions.checkDelayedTraits(player, ETWTraitsRegistry.LOW_PROFILE)
				)
			then
				CommonFunctions.addTraitToPlayer({
					player = player,
					trait = ETWTraitsRegistry.LOW_PROFILE,
					positiveTrait = true,
				})
			end
		end
	end
	if validConspicuousTriggers[trigger] and ETW_CommonLogicChecks.ConspicuousShouldExecute(player) then
		if ETW_CommonLogicChecks.ConspicuousShouldExecute(player) and sneaking >= SBvars.ConspicuousSkill then
			if
				SBvars.DelayedTraitsSystem
				and not CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, CharacterTrait.CONSPICUOUS)
			then
				CommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = CharacterTrait.CONSPICUOUS,
					player = player,
					positiveTrait = false,
					gainingTrait = false,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (
					SBvars.DelayedTraitsSystem
					and CommonFunctions.checkDelayedTraits(player, CharacterTrait.CONSPICUOUS)
				)
			then
				CommonFunctions.removeTraitFromPlayer({
					player = player,
					trait = CharacterTrait.CONSPICUOUS,
					positiveTrait = false,
				})
			end
		elseif ETW_CommonLogicChecks.InconspicuousShouldExecute(player) and sneaking >= SBvars.InconspicuousSkill then
			if
				SBvars.DelayedTraitsSystem
				and not CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, CharacterTrait.INCONSPICUOUS)
			then
				CommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = CharacterTrait.INCONSPICUOUS,
					player = player,
					positiveTrait = true,
					gainingTrait = true,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (
					SBvars.DelayedTraitsSystem
					and CommonFunctions.checkDelayedTraits(player, CharacterTrait.INCONSPICUOUS)
				)
			then
				CommonFunctions.addTraitToPlayer({
					player = player,
					trait = CharacterTrait.INCONSPICUOUS,
					positiveTrait = true,
				})
			end
		end
	end
	if validHunterTriggers[trigger] and ETW_CommonLogicChecks.HunterShouldExecute(player) then
		local levels = sneaking + aiming + trapping + shortBlade
		if
			sneaking >= 2
			and aiming >= 2
			and trapping >= 2
			and shortBlade >= 2
			and levels >= SBvars.HunterSkill
			and (shortBladeKills + firearmKills) >= SBvars.HunterKills
		then
			if
				SBvars.DelayedTraitsSystem
				and not CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, CharacterTrait.HUNTER)
			then
				CommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = CharacterTrait.HUNTER,
					player = player,
					positiveTrait = true,
					gainingTrait = true,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (SBvars.DelayedTraitsSystem and CommonFunctions.checkDelayedTraits(player, CharacterTrait.HUNTER))
			then
				CommonFunctions.addTraitToPlayer({
					player = player,
					trait = CharacterTrait.HUNTER,
					positiveTrait = true,
				})
			end
		end
	end
	if validBrawlerTriggers[trigger] and ETW_CommonLogicChecks.BrawlerShouldExecute(player) then
		if (axe + longBlunt) >= SBvars.BrawlerSkill and (axeKills + longBluntKills) >= SBvars.BrawlerKills then
			if
				SBvars.DelayedTraitsSystem
				and not CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, CharacterTrait.BRAWLER)
			then
				CommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = CharacterTrait.BRAWLER,
					player = player,
					positiveTrait = true,
					gainingTrait = true,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (SBvars.DelayedTraitsSystem and CommonFunctions.checkDelayedTraits(player, CharacterTrait.BRAWLER))
			then
				CommonFunctions.addTraitToPlayer({
					player = player,
					trait = CharacterTrait.BRAWLER,
					positiveTrait = true,
				})
			end
		end
	end
	if validAxeThrowerTriggers[trigger] and ETW_CommonLogicChecks.AxeThrowerShouldExecute(player) then
		if axe >= SBvars.AxeThrowerSkill and axeKills >= SBvars.AxeThrowerKills then
			if
				SBvars.DelayedTraitsSystem
				and not CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, ETWTraitsRegistry.AXE_THROWER)
			then
				CommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = ETWTraitsRegistry.AXE_THROWER,
					player = player,
					positiveTrait = true,
					gainingTrait = true,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (
					SBvars.DelayedTraitsSystem
					and CommonFunctions.checkDelayedTraits(player, ETWTraitsRegistry.AXE_THROWER)
				)
			then
				CommonFunctions.addTraitToPlayer({
					player = player,
					trait = ETWTraitsRegistry.AXE_THROWER,
					positiveTrait = true,
				})
			end
		end
	end
	if validBaseballPlayerTriggers[trigger] and ETW_CommonLogicChecks.BaseballPlayerShouldExecute(player) then
		if longBlunt >= SBvars.BaseballPlayerSkill and longBluntKills >= SBvars.BaseballPlayerKills then
			if
				SBvars.DelayedTraitsSystem
				and not CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, CharacterTrait.BASEBALL_PLAYER)
			then
				CommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = CharacterTrait.BASEBALL_PLAYER,
					player = player,
					positiveTrait = true,
					gainingTrait = true,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (
					SBvars.DelayedTraitsSystem
					and CommonFunctions.checkDelayedTraits(player, CharacterTrait.BASEBALL_PLAYER)
				)
			then
				CommonFunctions.addTraitToPlayer({
					player = player,
					trait = CharacterTrait.BASEBALL_PLAYER,
					positiveTrait = true,
				})
			end
		end
	end
	if validStickFighterTriggers[trigger] and ETW_CommonLogicChecks.StickFighterShouldExecute(player) then
		if shortBlunt >= SBvars.StickFighterSkill and shortBluntKills >= SBvars.StickFighterKills then
			if
				SBvars.DelayedTraitsSystem
				and not CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, ETWTraitsRegistry.STICK_FIGHTER)
			then
				CommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = ETWTraitsRegistry.STICK_FIGHTER,
					player = player,
					positiveTrait = true,
					gainingTrait = true,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (
					SBvars.DelayedTraitsSystem
					and CommonFunctions.checkDelayedTraits(player, ETWTraitsRegistry.STICK_FIGHTER)
				)
			then
				CommonFunctions.addTraitToPlayer({
					player = player,
					trait = ETWTraitsRegistry.STICK_FIGHTER,
					positiveTrait = true,
				})
			end
		end
	end
	if validBladeEnthusiastTriggers[trigger] and ETW_CommonLogicChecks.BladeEnthusiastShouldExecute(player) then
		if longBlade >= SBvars.BladeEnthusiastSkill and longBladeKills >= SBvars.BladeEnthusiastKills then
			if
				SBvars.DelayedTraitsSystem
				and not CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, ETWTraitsRegistry.BLADE_ENTHUSIAST)
			then
				CommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = ETWTraitsRegistry.BLADE_ENTHUSIAST,
					player = player,
					positiveTrait = true,
					gainingTrait = true,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (
					SBvars.DelayedTraitsSystem
					and CommonFunctions.checkDelayedTraits(player, ETWTraitsRegistry.BLADE_ENTHUSIAST)
				)
			then
				CommonFunctions.addTraitToPlayer({
					player = player,
					trait = ETWTraitsRegistry.BLADE_ENTHUSIAST,
					positiveTrait = true,
				})
			end
		end
	end
	if validKnifeFighterTriggers[trigger] and ETW_CommonLogicChecks.KnifeFighterShouldExecute(player) then
		if shortBlade >= SBvars.KnifeFighterSkill and shortBladeKills >= SBvars.KnifeFighterKills then
			if
				SBvars.DelayedTraitsSystem
				and not CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, ETWTraitsRegistry.KNIFE_FIGHTER)
			then
				CommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = ETWTraitsRegistry.KNIFE_FIGHTER,
					player = player,
					positiveTrait = true,
					gainingTrait = true,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (
					SBvars.DelayedTraitsSystem
					and CommonFunctions.checkDelayedTraits(player, ETWTraitsRegistry.KNIFE_FIGHTER)
				)
			then
				CommonFunctions.addTraitToPlayer({
					player = player,
					trait = ETWTraitsRegistry.KNIFE_FIGHTER,
					positiveTrait = true,
				})
			end
		end
	end
	if validPolearmTriggers[trigger] and ETW_CommonLogicChecks.PolearmFighterShouldExecute(player) then
		if spear >= SBvars.PolearmFighterSkill and spearKills >= SBvars.PolearmFighterKills then
			if
				SBvars.DelayedTraitsSystem
				and not CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, ETWTraitsRegistry.POLEARM_FIGHTER)
			then
				CommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = ETWTraitsRegistry.POLEARM_FIGHTER,
					player = player,
					positiveTrait = true,
					gainingTrait = true,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (
					SBvars.DelayedTraitsSystem
					and CommonFunctions.checkDelayedTraits(player, ETWTraitsRegistry.POLEARM_FIGHTER)
				)
			then
				CommonFunctions.addTraitToPlayer({
					player = player,
					trait = ETWTraitsRegistry.POLEARM_FIGHTER,
					positiveTrait = true,
				})
			end
		end
	end
	if validRestorationExpertTriggers[trigger] and ETW_CommonLogicChecks.RestorationExpertShouldExecute(player) then
		if maintenance >= SBvars.RestorationExpertSkill then
			if
				SBvars.DelayedTraitsSystem
				and not CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, ETWTraitsRegistry.RESTORATION_EXPERT)
			then
				CommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = ETWTraitsRegistry.RESTORATION_EXPERT,
					player = player,
					positiveTrait = true,
					gainingTrait = true,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (
					SBvars.DelayedTraitsSystem
					and CommonFunctions.checkDelayedTraits(player, ETWTraitsRegistry.RESTORATION_EXPERT)
				)
			then
				CommonFunctions.addTraitToPlayer({
					player = player,
					trait = ETWTraitsRegistry.RESTORATION_EXPERT,
					positiveTrait = true,
				})
			end
		end
	end
	if validHandyTriggers[trigger] and ETW_CommonLogicChecks.HandyShouldExecute(player) then
		if (maintenance + carpentry) >= SBvars.HandySkill then
			if
				SBvars.DelayedTraitsSystem
				and not CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, CharacterTrait.HANDY)
			then
				CommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = CharacterTrait.HANDY,
					player = player,
					positiveTrait = true,
					gainingTrait = true,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (SBvars.DelayedTraitsSystem and CommonFunctions.checkDelayedTraits(player, CharacterTrait.HANDY))
			then
				CommonFunctions.addTraitToPlayer({
					player = player,
					trait = CharacterTrait.HANDY,
					positiveTrait = true,
				})
			end
		end
	end
	if validLearnerTriggers[trigger] and ETW_CommonLogicChecks.LearnerSystemShouldExecute(player) then
		local levels = maintenance
			+ carpentry
			+ farming
			+ firstAid
			+ electrical
			+ metalworking
			+ mechanics
			+ tailoring
			+ cooking
		if
			player:hasTrait(CharacterTrait.SLOW_LEARNER)
			and levels >= SBvars.LearnerSystemSkill / 2
			and SBvars.TraitsLockSystemCanLoseNegative
		then
			if
				SBvars.DelayedTraitsSystem
				and not CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, CharacterTrait.SLOW_LEARNER)
			then
				CommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = CharacterTrait.SLOW_LEARNER,
					player = player,
					positiveTrait = false,
					gainingTrait = false,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (
					SBvars.DelayedTraitsSystem
					and CommonFunctions.checkDelayedTraits(player, CharacterTrait.SLOW_LEARNER)
				)
			then
				CommonFunctions.removeTraitFromPlayer({
					player = player,
					trait = CharacterTrait.SLOW_LEARNER,
					positiveTrait = false,
				})
			end
		elseif
			not player:hasTrait(CharacterTrait.SLOW_LEARNER)
			and levels >= SBvars.LearnerSystemSkill
			and SBvars.TraitsLockSystemCanGainPositive
		then
			if
				SBvars.DelayedTraitsSystem
				and not CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, CharacterTrait.FAST_LEARNER)
			then
				CommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = CharacterTrait.FAST_LEARNER,
					player = player,
					positiveTrait = true,
					gainingTrait = true,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (
					SBvars.DelayedTraitsSystem
					and CommonFunctions.checkDelayedTraits(player, CharacterTrait.FAST_LEARNER)
				)
			then
				CommonFunctions.addTraitToPlayer({
					player = player,
					trait = CharacterTrait.FAST_LEARNER,
					positiveTrait = true,
				})
			end
		end
	end
	if validFurnitureAssemblerTriggers[trigger] and ETW_CommonLogicChecks.FurnitureAssemblerShouldExecute(player) then
		if carpentry >= SBvars.FurnitureAssemblerSkill then
			if
				SBvars.DelayedTraitsSystem
				and not CommonFunctions.checkIfTraitIsInDelayedTraitsTable(
					player,
					ETWTraitsRegistry.FURNITURE_ASSEMBLER
				)
			then
				CommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = ETWTraitsRegistry.FURNITURE_ASSEMBLER,
					player = player,
					positiveTrait = true,
					gainingTrait = true,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (
					SBvars.DelayedTraitsSystem
					and CommonFunctions.checkDelayedTraits(player, ETWTraitsRegistry.FURNITURE_ASSEMBLER)
				)
			then
				CommonFunctions.addTraitToPlayer({
					player = player,
					trait = ETWTraitsRegistry.FURNITURE_ASSEMBLER,
					positiveTrait = true,
				})
			end
		end
	end
	if validHomeCookTriggers[trigger] and ETW_CommonLogicChecks.HomeCookShouldExecute(player) then
		if cooking >= SBvars.HomeCookSkill then
			if
				SBvars.DelayedTraitsSystem
				and not CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, ETWTraitsRegistry.HOME_COOK)
			then
				CommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = ETWTraitsRegistry.HOME_COOK,
					player = player,
					positiveTrait = true,
					gainingTrait = true,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (
					SBvars.DelayedTraitsSystem
					and CommonFunctions.checkDelayedTraits(player, ETWTraitsRegistry.HOME_COOK)
				)
			then
				CommonFunctions.addTraitToPlayer({
					player = player,
					trait = ETWTraitsRegistry.HOME_COOK,
					positiveTrait = true,
				})
			end
		end
	end
	if validCookTriggers[trigger] and ETW_CommonLogicChecks.CookShouldExecute(player) then
		if cooking >= SBvars.CookSkill then
			if
				SBvars.DelayedTraitsSystem
				and not CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, CharacterTrait.COOK)
			then
				CommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = CharacterTrait.COOK,
					player = player,
					positiveTrait = true,
					gainingTrait = true,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (SBvars.DelayedTraitsSystem and CommonFunctions.checkDelayedTraits(player, CharacterTrait.COOK))
			then
				CommonFunctions.addTraitToPlayer({
					player = player,
					trait = CharacterTrait.COOK,
					positiveTrait = true,
				})
			end
		end
	end
	if validGardenerTriggers[trigger] and ETW_CommonLogicChecks.GardenerShouldExecute(player) then
		if farming >= SBvars.GardenerSkill then
			if
				SBvars.DelayedTraitsSystem
				and not CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, CharacterTrait.GARDENER)
			then
				CommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = CharacterTrait.GARDENER,
					player = player,
					positiveTrait = true,
					gainingTrait = true,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (SBvars.DelayedTraitsSystem and CommonFunctions.checkDelayedTraits(player, CharacterTrait.GARDENER))
			then
				CommonFunctions.addTraitToPlayer({
					player = player,
					trait = CharacterTrait.GARDENER,
					positiveTrait = true,
				})
			end
		end
	end
	if validPetTherapyTriggers[trigger] and ETW_CommonLogicChecks.PetTherapyShouldExecute(player) then
		if
			husbandry >= SBvars.PetTherapySkill
			and #modData.AnimalsSystem.UniqueAnimalsPetted >= SBvars.PetTherapyUniqueAnimalsPetted
		then
			if
				SBvars.DelayedTraitsSystem
				and not CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, ETWTraitsRegistry.PET_THERAPY)
			then
				CommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = ETWTraitsRegistry.PET_THERAPY,
					player = player,
					positiveTrait = true,
					gainingTrait = true,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (
					SBvars.DelayedTraitsSystem
					and CommonFunctions.checkDelayedTraits(player, ETWTraitsRegistry.PET_THERAPY)
				)
			then
				CommonFunctions.addTraitToPlayer({
					player = player,
					trait = ETWTraitsRegistry.PET_THERAPY,
					positiveTrait = true,
				})
			end
		end
	end
	if validWhittlerTriggers[trigger] and ETW_CommonLogicChecks.WhittlerShouldExecute(player) then
		if carving >= SBvars.WhittlerSkill then
			if
				SBvars.DelayedTraitsSystem
				and not CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, CharacterTrait.WHITTLER)
			then
				CommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = CharacterTrait.WHITTLER,
					player = player,
					positiveTrait = true,
					gainingTrait = true,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (SBvars.DelayedTraitsSystem and CommonFunctions.checkDelayedTraits(player, CharacterTrait.WHITTLER))
			then
				CommonFunctions.addTraitToPlayer({
					player = player,
					trait = CharacterTrait.WHITTLER,
					positiveTrait = true,
				})
			end
		end
	end
	if validBlacksmithTriggers[trigger] and ETW_CommonLogicChecks.BlacksmithShouldExecute(player) then
		if blacksmith + maintenance >= SBvars.BlacksmithSkill then
			if
				SBvars.DelayedTraitsSystem
				and not CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, CharacterTrait.BLACKSMITH)
			then
				CommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = CharacterTrait.BLACKSMITH,
					player = player,
					positiveTrait = true,
					gainingTrait = true,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (
					SBvars.DelayedTraitsSystem
					and CommonFunctions.checkDelayedTraits(player, CharacterTrait.BLACKSMITH)
				)
			then
				CommonFunctions.addTraitToPlayer({
					player = player,
					trait = CharacterTrait.BLACKSMITH,
					positiveTrait = true,
				})
			end
		end
	end
	if validWildernessKnowledgeTriggers[trigger] and ETW_CommonLogicChecks.WildernessKnowledgeShouldExecute(player) then
		if
			foraging >= 2
			and knapping >= 2
			and maintenance >= 2
			and carving >= 2
			and (foraging + knapping + maintenance + carving) >= SBvars.WildernessKnowledgeSkill
		then
			if
				SBvars.DelayedTraitsSystem
				and not CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, CharacterTrait.WILDERNESS_KNOWLEDGE)
			then
				CommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = CharacterTrait.WILDERNESS_KNOWLEDGE,
					player = player,
					positiveTrait = true,
					gainingTrait = true,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (
					SBvars.DelayedTraitsSystem
					and CommonFunctions.checkDelayedTraits(player, CharacterTrait.WILDERNESS_KNOWLEDGE)
				)
			then
				CommonFunctions.addTraitToPlayer({
					player = player,
					trait = CharacterTrait.WILDERNESS_KNOWLEDGE,
					positiveTrait = true,
				})
			end
		end
	end
	if validFirstAidTriggers[trigger] and ETW_CommonLogicChecks.FirstAidShouldExecute(player) then
		if firstAid >= SBvars.FirstAidSkill then
			if
				SBvars.DelayedTraitsSystem
				and not CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, CharacterTrait.FIRST_AID)
			then
				CommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = CharacterTrait.FIRST_AID,
					player = player,
					positiveTrait = true,
					gainingTrait = true,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (SBvars.DelayedTraitsSystem and CommonFunctions.checkDelayedTraits(player, CharacterTrait.FIRST_AID))
			then
				CommonFunctions.addTraitToPlayer({
					player = player,
					trait = CharacterTrait.FIRST_AID,
					positiveTrait = true,
				})
			end
		end
	end
	if validAVClubTriggers[trigger] and ETW_CommonLogicChecks.AVClubShouldExecute(player) then
		if electrical >= SBvars.AVClubSkill then
			if
				SBvars.DelayedTraitsSystem
				and not CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, ETWTraitsRegistry.AV_CLUB)
			then
				CommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = ETWTraitsRegistry.AV_CLUB,
					player = player,
					positiveTrait = true,
					gainingTrait = true,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (
					SBvars.DelayedTraitsSystem
					and CommonFunctions.checkDelayedTraits(player, ETWTraitsRegistry.AV_CLUB)
				)
			then
				CommonFunctions.addTraitToPlayer({
					player = player,
					trait = ETWTraitsRegistry.AV_CLUB,
					positiveTrait = true,
				})
			end
		end
	end
	if validBodyWorkEnthusiastTriggers[trigger] and ETW_CommonLogicChecks.BodyWorkEnthusiastShouldExecute(player) then
		CombinedTraitChecks.bodyworkEnthusiastCheck(player)
	end
	if validMechanicsTriggers[trigger] and ETW_CommonLogicChecks.MechanicsShouldExecute(player) then
		CombinedTraitChecks.mechanicsCheck(player)
	end
	if validSewerTriggers[trigger] and ETW_CommonLogicChecks.SewerShouldExecute(player) then
		CombinedTraitChecks.sewerCheck(player)
	end
	if validGunEnthusiastTriggers[trigger] and ETW_CommonLogicChecks.GunEnthusiastShouldExecute(player) then
		if (aiming + reloading) >= SBvars.GunEnthusiastSkill and firearmKills >= SBvars.GunEnthusiastKills then
			if
				SBvars.DelayedTraitsSystem
				and not CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, ETWTraitsRegistry.GUN_ENTHUSIAST)
			then
				CommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = ETWTraitsRegistry.GUN_ENTHUSIAST,
					player = player,
					positiveTrait = true,
					gainingTrait = true,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (
					SBvars.DelayedTraitsSystem
					and CommonFunctions.checkDelayedTraits(player, ETWTraitsRegistry.GUN_ENTHUSIAST)
				)
			then
				CommonFunctions.addTraitToPlayer({
					player = player,
					trait = ETWTraitsRegistry.GUN_ENTHUSIAST,
					positiveTrait = true,
				})
			end
		end
	end
	if validAnglerTriggers[trigger] and ETW_CommonLogicChecks.AnglerShouldExecute(player) then
		if fishing >= SBvars.FishingSkill then
			if
				SBvars.DelayedTraitsSystem
				and not CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, CharacterTrait.FISHING)
			then
				CommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = CharacterTrait.FISHING,
					player = player,
					positiveTrait = true,
					gainingTrait = true,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (SBvars.DelayedTraitsSystem and CommonFunctions.checkDelayedTraits(player, CharacterTrait.FISHING))
			then
				CommonFunctions.addTraitToPlayer({
					player = player,
					trait = CharacterTrait.FISHING,
					positiveTrait = true,
				})
			end
		end
	end
	if validHikerTriggers[trigger] and ETW_CommonLogicChecks.HikerShouldExecute(player) then
		if (trapping + foraging) >= SBvars.HikerSkill then
			if
				SBvars.DelayedTraitsSystem
				and not CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, CharacterTrait.HIKER)
			then
				CommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = CharacterTrait.HIKER,
					player = player,
					positiveTrait = true,
					gainingTrait = true,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (SBvars.DelayedTraitsSystem and CommonFunctions.checkDelayedTraits(player, CharacterTrait.HIKER))
			then
				CommonFunctions.addTraitToPlayer({
					player = player,
					trait = CharacterTrait.HIKER,
					positiveTrait = true,
				})
			end
		end
	end
	modData.DelayedStartingTraitsFilled = true
end

local random_instance = newrandom()

---Function responsible for hourly check on Delayed Traits system
local function progressDelayedTraits()
	local playersList = ETW_CommonFunctions.playersList()
	for i = 0, playerList:size() - 1 do
		local player = playerList:get(i)
		local modData = CommonFunctions.getETWModData(player)
		if not modData then
			logETW("ETW Logger | progressDelayedTraits(): modData is nil, returning early")
			return
		end
		local traitTable = modData.DelayedTraits
		logETW(
			"ETW Logger | Delayed Traits System: new progressDelayedTraits() execution for player "
				.. player:getUsername()
				.. " ----------"
		)
		for index = 1, #traitTable do
			local traitEntry = traitTable[index]
			local traitRegistryId, traitValue, gained = traitEntry[1], traitEntry[2], traitEntry[3]
			local trait = CharacterTrait.get(ResourceLocation.of(traitRegistryId))
			if not gained then
				local randomValue = random_instance:random(0, traitValue)
				if randomValue == 0 then
					traitTable[index][3] = true
					logETW(
						"ETW Logger | Delayed Traits System: rolled to get "
							.. traitRegistryId
							.. ": rolled 0 from 0-"
							.. traitTable[index][2],
						"ETW Logger | Delayed Traits System: "
							.. traitRegistryId
							.. " in traitTable["
							.. index
							.. "][3]"
							.. " set to "
							.. tostring(traitTable[index][3]),
						"ETW Logger | Delayed Traits System: running traitsGainsBySkill(player, "
							.. traitRegistryId
							.. ")"
					)
					ETW_BySkills.traitsGainsBySkill(player, trait)
				elseif randomValue > 0 then
					logETW(
						"ETW Logger | Delayed Traits System: rolled to get "
							.. traitRegistryId
							.. ": rolled "
							.. randomValue
							.. " from 0-"
							.. traitValue
					)
					traitTable[index][2] = traitValue - 1
				end
			end
		end
	end
	logETW("ETW Logger | Delayed Traits System: finished progressDelayedTraits() execution ----------")
end

---Function responsible for firing check on all kill-related traits
---@param zombie IsoZombie
local function OnZombieDeadETW(zombie)
	local player = zombie:getAttackedBy()
	---@cast player IsoPlayer
	if
		not player
		or not instanceof(player, "IsoPlayer")
		or (gameMode == CommonFunctions.GameMode.SP and not player:isLocalPlayer())
	then
		return
	else
		ETW_BySkills.traitsGainsBySkill(player, "kill")
	end
end

---Function responsible for setting up events
---@param playerIndex number
---@param player IsoPlayer
local function initializeEventsETW(playerIndex, player)
	if SBvars.TraitsLockSystemCanGainPositive or SBvars.TraitsLockSystemCanLoseNegative then
		if gameMode == CommonFunctions.GameMode.SP then
			ETW_BySkills.traitsGainsBySkill(player, "characterInitialization")
			Events.LevelPerk.Remove(ETW_BySkills.traitsGainsBySkill)
			Events.LevelPerk.Add(ETW_BySkills.traitsGainsBySkill)
		end
		Events.OnZombieDead.Remove(OnZombieDeadETW)
		if SBvars.TraitsLockSystemCanGainPositive then
			Events.OnZombieDead.Add(OnZombieDeadETW)
		end
	end
	if SBvars.DelayedTraitsSystem then
		Events.EveryHours.Add(progressDelayedTraits)
	end
	if gameMode == CommonFunctions.GameMode.MP_SERVER then
		Events.OnTick.Remove(initializeEventsETW)
	end
end

---Function responsible for clearing events
---@param character IsoPlayer
local function clearEventsETW(character)
	Events.LevelPerk.Remove(ETW_BySkills.traitsGainsBySkill)
	Events.EveryHours.Remove(progressDelayedTraits)
	Events.OnZombieDead.Remove(OnZombieDeadETW)
	logETW("ETW Logger | System: clearEventsETW in " .. FILENAME)
end

if gameMode == CommonFunctions.GameMode.SP then
	Events.OnCreatePlayer.Remove(initializeEventsETW)
	Events.OnCreatePlayer.Add(initializeEventsETW)
	Events.OnPlayerDeath.Remove(clearEventsETW)
	Events.OnPlayerDeath.Add(clearEventsETW)
elseif gameMode == CommonFunctions.GameMode.MP_SERVER then
	Events.OnTick.Add(initializeEventsETW)
end

function ETW_BySkills.fireLevelPerkEventOnServer(player, args)
	logETW(
		"ETW Logger | fireLevelPerkEventOnServer(): received call for player "
			.. player:getUsername()
			.. ", perk "
			.. tostring(args.perkName)
	)
	local perk = PerkFactory.getPerkFromName(args.perkName)
	ETW_BySkills.traitsGainsBySkill(player, perk)
end

local Commands = {}

Commands.OnClientCommand = function(module, command, player, args)
	if module == "ETW" and ETW_BySkills[command] then
		local argStr = ""
		args = args or {}
		for k, v in pairs(args) do
			argStr = argStr .. " " .. k .. "=" .. tostring(v)
		end
		logETW(
			"ETW Logger | OnClientCommand(): received "
				.. command
				.. " command from player "
				.. player:getUsername()
				.. argStr
		)
		ETW_BySkills[command](player, args)
	end
end

Events.OnClientCommand.Add(Commands.OnClientCommand)

return ETW_BySkills
