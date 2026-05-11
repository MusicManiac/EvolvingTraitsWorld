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

local function sumContextValues(ctx, keys)
	local total = 0
	for i = 1, #keys do
		total = total + ctx[keys[i]]
	end
	return total
end

local function hasRequiredLevels(ctx, requirements)
	for key, minimum in pairs(requirements) do
		if ctx[key] < minimum then
			return false
		end
	end
	return true
end

local function applyTraitChange(ctx, trait, positiveTrait, gainingTrait, onApply)
	if SBvars.DelayedTraitsSystem and not CommonFunctions.checkIfTraitIsInDelayedTraitsTable(ctx.player, trait) then
		CommonFunctions.addTraitToDelayTable({
			modData = ctx.modData,
			trait = trait,
			player = ctx.player,
			positiveTrait = positiveTrait,
			gainingTrait = gainingTrait,
		})
		return
	end

	if not SBvars.DelayedTraitsSystem or CommonFunctions.checkDelayedTraits(ctx.player, trait) then
		local action = gainingTrait and CommonFunctions.addTraitToPlayer or CommonFunctions.removeTraitFromPlayer
		action({
			player = ctx.player,
			trait = trait,
			positiveTrait = positiveTrait,
		})

		if onApply then
			onApply(ctx)
		end
	end
end

local function executeTraitRule(ctx, rule, trigger)
	if not rule.triggers[trigger] or not rule.shouldExecute(ctx.player) then
		return
	end

	if rule.run then
		rule.run(ctx)
		return
	end

	if not rule.condition(ctx) then
		return
	end

	applyTraitChange(ctx, rule.trait, rule.positiveTrait, rule.gainingTrait, rule.onApply)
end

local skillTraitRules = {
	{
		triggers = validHearingTriggers,
		shouldExecute = ETW_CommonLogicChecks.HearingSystemShouldExecute,
		run = function(ctx)
			local levels = sumContextValues(ctx, {
				"sprinting",
				"lightfooted",
				"nimble",
				"sneaking",
				"axe",
				"longBlunt",
				"shortBlunt",
				"longBlade",
				"shortBlade",
				"spear",
			})

			if
				ctx.player:hasTrait(CharacterTrait.HARD_OF_HEARING)
				and levels >= SBvars.HearingSystemSkill / 2
				and SBvars.TraitsLockSystemCanLoseNegative
			then
				applyTraitChange(ctx, CharacterTrait.HARD_OF_HEARING, false, false)
			elseif not ctx.player:hasTrait(CharacterTrait.HARD_OF_HEARING) and levels >= SBvars.HearingSystemSkill then
				applyTraitChange(ctx, CharacterTrait.KEEN_HEARING, true, true)
			end
		end,
	},
	{
		triggers = validHoarderTriggers,
		shouldExecute = ETW_CommonLogicChecks.HoarderShouldExecute,
		condition = function(ctx)
			return ctx.strength >= SBvars.HoarderSkill
		end,
		trait = ETWTraitsRegistry.HOARDER,
		positiveTrait = true,
		gainingTrait = true,
		onApply = function(ctx)
			UnifiedCarryWeightFramework.recomputeAll(ctx.player)
		end,
	},
	{
		triggers = validGymRatTriggers,
		shouldExecute = ETW_CommonLogicChecks.GymRatShouldExecute,
		condition = function(ctx)
			return sumContextValues(ctx, { "strength", "fitness" }) >= SBvars.GymRatSkill
		end,
		trait = ETWTraitsRegistry.GYM_RAT,
		positiveTrait = true,
		gainingTrait = true,
	},
	{
		triggers = validRunnerTriggers,
		shouldExecute = ETW_CommonLogicChecks.RunnerShouldExecute,
		condition = function(ctx)
			return ctx.sprinting >= SBvars.RunnerSkill
		end,
		trait = CharacterTrait.JOGGER,
		positiveTrait = true,
		gainingTrait = true,
	},
	{
		triggers = validLightStepTriggers,
		shouldExecute = ETW_CommonLogicChecks.LightStepShouldExecute,
		condition = function(ctx)
			return ctx.lightfooted >= SBvars.LightStepSkill
		end,
		trait = ETWTraitsRegistry.LIGHTSTEP,
		positiveTrait = true,
		gainingTrait = true,
	},
	{
		triggers = validGymnastTriggers,
		shouldExecute = ETW_CommonLogicChecks.GymnastShouldExecute,
		condition = function(ctx)
			return sumContextValues(ctx, { "lightfooted", "nimble" }) >= SBvars.GymnastSkill
		end,
		trait = ETWTraitsRegistry.GYMNAST,
		positiveTrait = true,
		gainingTrait = true,
	},
	{
		triggers = validClumsyTriggers,
		shouldExecute = ETW_CommonLogicChecks.ClumsyShouldExecute,
		condition = function(ctx)
			return sumContextValues(ctx, { "lightfooted", "sneaking" }) >= SBvars.ClumsySkill
		end,
		trait = CharacterTrait.CLUMSY,
		positiveTrait = false,
		gainingTrait = false,
	},
	{
		triggers = validGracefulTriggers,
		shouldExecute = ETW_CommonLogicChecks.GracefulShouldExecute,
		condition = function(ctx)
			return sumContextValues(ctx, { "nimble", "sneaking", "lightfooted" }) >= SBvars.GracefulSkill
		end,
		trait = CharacterTrait.GRACEFUL,
		positiveTrait = true,
		gainingTrait = true,
	},
	{
		triggers = validBurglarTriggers,
		shouldExecute = ETW_CommonLogicChecks.BurglarShouldExecute,
		condition = function(ctx)
			return ctx.electrical >= 2
				and ctx.mechanics >= 2
				and sumContextValues(ctx, { "nimble", "mechanics", "electrical" }) >= SBvars.BurglarSkill
		end,
		trait = CharacterTrait.BURGLAR,
		positiveTrait = true,
		gainingTrait = true,
	},
	{
		triggers = validLowProfileTriggers,
		shouldExecute = ETW_CommonLogicChecks.LowProfileShouldExecute,
		condition = function(ctx)
			return ctx.sneaking >= SBvars.LowProfileSkill
		end,
		trait = ETWTraitsRegistry.LOW_PROFILE,
		positiveTrait = true,
		gainingTrait = true,
	},
	{
		triggers = validConspicuousTriggers,
		shouldExecute = ETW_CommonLogicChecks.ConspicuousShouldExecute,
		run = function(ctx)
			if ETW_CommonLogicChecks.ConspicuousShouldExecute(ctx.player) and ctx.sneaking >= SBvars.ConspicuousSkill then
				applyTraitChange(ctx, CharacterTrait.CONSPICUOUS, false, false)
			elseif ETW_CommonLogicChecks.InconspicuousShouldExecute(ctx.player) and ctx.sneaking >= SBvars.InconspicuousSkill then
				applyTraitChange(ctx, CharacterTrait.INCONSPICUOUS, true, true)
			end
		end,
	},
	{
		triggers = validHunterTriggers,
		shouldExecute = ETW_CommonLogicChecks.HunterShouldExecute,
		condition = function(ctx)
			return hasRequiredLevels(ctx, {
				sneaking = 2,
				aiming = 2,
				trapping = 2,
				shortBlade = 2,
			})
				and sumContextValues(ctx, { "sneaking", "aiming", "trapping", "shortBlade" }) >= SBvars.HunterSkill
				and (ctx.shortBladeKills + ctx.firearmKills) >= SBvars.HunterKills
		end,
		trait = CharacterTrait.HUNTER,
		positiveTrait = true,
		gainingTrait = true,
	},
	{
		triggers = validBrawlerTriggers,
		shouldExecute = ETW_CommonLogicChecks.BrawlerShouldExecute,
		condition = function(ctx)
			return sumContextValues(ctx, { "axe", "longBlunt" }) >= SBvars.BrawlerSkill
				and (ctx.axeKills + ctx.longBluntKills) >= SBvars.BrawlerKills
		end,
		trait = CharacterTrait.BRAWLER,
		positiveTrait = true,
		gainingTrait = true,
	},
	{
		triggers = validAxeThrowerTriggers,
		shouldExecute = ETW_CommonLogicChecks.AxeThrowerShouldExecute,
		condition = function(ctx)
			return ctx.axe >= SBvars.AxeThrowerSkill and ctx.axeKills >= SBvars.AxeThrowerKills
		end,
		trait = ETWTraitsRegistry.AXE_THROWER,
		positiveTrait = true,
		gainingTrait = true,
	},
	{
		triggers = validBaseballPlayerTriggers,
		shouldExecute = ETW_CommonLogicChecks.BaseballPlayerShouldExecute,
		condition = function(ctx)
			return ctx.longBlunt >= SBvars.BaseballPlayerSkill
				and ctx.longBluntKills >= SBvars.BaseballPlayerKills
		end,
		trait = CharacterTrait.BASEBALL_PLAYER,
		positiveTrait = true,
		gainingTrait = true,
	},
	{
		triggers = validStickFighterTriggers,
		shouldExecute = ETW_CommonLogicChecks.StickFighterShouldExecute,
		condition = function(ctx)
			return ctx.shortBlunt >= SBvars.StickFighterSkill
				and ctx.shortBluntKills >= SBvars.StickFighterKills
		end,
		trait = ETWTraitsRegistry.STICK_FIGHTER,
		positiveTrait = true,
		gainingTrait = true,
	},
	{
		triggers = validBladeEnthusiastTriggers,
		shouldExecute = ETW_CommonLogicChecks.BladeEnthusiastShouldExecute,
		condition = function(ctx)
			return ctx.longBlade >= SBvars.BladeEnthusiastSkill
				and ctx.longBladeKills >= SBvars.BladeEnthusiastKills
		end,
		trait = ETWTraitsRegistry.BLADE_ENTHUSIAST,
		positiveTrait = true,
		gainingTrait = true,
	},
	{
		triggers = validKnifeFighterTriggers,
		shouldExecute = ETW_CommonLogicChecks.KnifeFighterShouldExecute,
		condition = function(ctx)
			return ctx.shortBlade >= SBvars.KnifeFighterSkill
				and ctx.shortBladeKills >= SBvars.KnifeFighterKills
		end,
		trait = ETWTraitsRegistry.KNIFE_FIGHTER,
		positiveTrait = true,
		gainingTrait = true,
	},
	{
		triggers = validPolearmTriggers,
		shouldExecute = ETW_CommonLogicChecks.PolearmFighterShouldExecute,
		condition = function(ctx)
			return ctx.spear >= SBvars.PolearmFighterSkill and ctx.spearKills >= SBvars.PolearmFighterKills
		end,
		trait = ETWTraitsRegistry.POLEARM_FIGHTER,
		positiveTrait = true,
		gainingTrait = true,
	},
	{
		triggers = validRestorationExpertTriggers,
		shouldExecute = ETW_CommonLogicChecks.RestorationExpertShouldExecute,
		condition = function(ctx)
			return ctx.maintenance >= SBvars.RestorationExpertSkill
		end,
		trait = ETWTraitsRegistry.RESTORATION_EXPERT,
		positiveTrait = true,
		gainingTrait = true,
	},
	{
		triggers = validHandyTriggers,
		shouldExecute = ETW_CommonLogicChecks.HandyShouldExecute,
		condition = function(ctx)
			return sumContextValues(ctx, { "maintenance", "carpentry" }) >= SBvars.HandySkill
		end,
		trait = CharacterTrait.HANDY,
		positiveTrait = true,
		gainingTrait = true,
	},
	{
		triggers = validLearnerTriggers,
		shouldExecute = ETW_CommonLogicChecks.LearnerSystemShouldExecute,
		run = function(ctx)
			local levels = sumContextValues(ctx, {
				"maintenance",
				"carpentry",
				"farming",
				"firstAid",
				"electrical",
				"metalworking",
				"mechanics",
				"tailoring",
				"cooking",
			})

			if
				ctx.player:hasTrait(CharacterTrait.SLOW_LEARNER)
				and levels >= SBvars.LearnerSystemSkill / 2
				and SBvars.TraitsLockSystemCanLoseNegative
			then
				applyTraitChange(ctx, CharacterTrait.SLOW_LEARNER, false, false)
			elseif
				not ctx.player:hasTrait(CharacterTrait.SLOW_LEARNER)
				and levels >= SBvars.LearnerSystemSkill
				and SBvars.TraitsLockSystemCanGainPositive
			then
				applyTraitChange(ctx, CharacterTrait.FAST_LEARNER, true, true)
			end
		end,
	},
	{
		triggers = validFurnitureAssemblerTriggers,
		shouldExecute = ETW_CommonLogicChecks.FurnitureAssemblerShouldExecute,
		condition = function(ctx)
			return ctx.carpentry >= SBvars.FurnitureAssemblerSkill
		end,
		trait = ETWTraitsRegistry.FURNITURE_ASSEMBLER,
		positiveTrait = true,
		gainingTrait = true,
	},
	{
		triggers = validHomeCookTriggers,
		shouldExecute = ETW_CommonLogicChecks.HomeCookShouldExecute,
		condition = function(ctx)
			return ctx.cooking >= SBvars.HomeCookSkill
		end,
		trait = ETWTraitsRegistry.HOME_COOK,
		positiveTrait = true,
		gainingTrait = true,
	},
	{
		triggers = validCookTriggers,
		shouldExecute = ETW_CommonLogicChecks.CookShouldExecute,
		condition = function(ctx)
			return ctx.cooking >= SBvars.CookSkill
		end,
		trait = CharacterTrait.COOK,
		positiveTrait = true,
		gainingTrait = true,
	},
	{
		triggers = validGardenerTriggers,
		shouldExecute = ETW_CommonLogicChecks.GardenerShouldExecute,
		condition = function(ctx)
			return ctx.farming >= SBvars.GardenerSkill
		end,
		trait = CharacterTrait.GARDENER,
		positiveTrait = true,
		gainingTrait = true,
	},
	{
		triggers = validPetTherapyTriggers,
		shouldExecute = ETW_CommonLogicChecks.PetTherapyShouldExecute,
		condition = function(ctx)
			return ctx.husbandry >= SBvars.PetTherapySkill
				and #ctx.modData.AnimalsSystem.UniqueAnimalsPetted >= SBvars.PetTherapyUniqueAnimalsPetted
		end,
		trait = ETWTraitsRegistry.PET_THERAPY,
		positiveTrait = true,
		gainingTrait = true,
	},
	{
		triggers = validWhittlerTriggers,
		shouldExecute = ETW_CommonLogicChecks.WhittlerShouldExecute,
		condition = function(ctx)
			return ctx.carving >= SBvars.WhittlerSkill
		end,
		trait = CharacterTrait.WHITTLER,
		positiveTrait = true,
		gainingTrait = true,
	},
	{
		triggers = validBlacksmithTriggers,
		shouldExecute = ETW_CommonLogicChecks.BlacksmithShouldExecute,
		condition = function(ctx)
			return sumContextValues(ctx, { "blacksmith", "maintenance" }) >= SBvars.BlacksmithSkill
		end,
		trait = CharacterTrait.BLACKSMITH,
		positiveTrait = true,
		gainingTrait = true,
	},
	{
		triggers = validWildernessKnowledgeTriggers,
		shouldExecute = ETW_CommonLogicChecks.WildernessKnowledgeShouldExecute,
		condition = function(ctx)
			return hasRequiredLevels(ctx, {
				foraging = 2,
				knapping = 2,
				maintenance = 2,
				carving = 2,
			}) and sumContextValues(ctx, { "foraging", "knapping", "maintenance", "carving" }) >= SBvars.WildernessKnowledgeSkill
		end,
		trait = CharacterTrait.WILDERNESS_KNOWLEDGE,
		positiveTrait = true,
		gainingTrait = true,
	},
	{
		triggers = validFirstAidTriggers,
		shouldExecute = ETW_CommonLogicChecks.FirstAidShouldExecute,
		condition = function(ctx)
			return ctx.firstAid >= SBvars.FirstAidSkill
		end,
		trait = CharacterTrait.FIRST_AID,
		positiveTrait = true,
		gainingTrait = true,
	},
	{
		triggers = validAVClubTriggers,
		shouldExecute = ETW_CommonLogicChecks.AVClubShouldExecute,
		condition = function(ctx)
			return ctx.electrical >= SBvars.AVClubSkill
		end,
		trait = ETWTraitsRegistry.AV_CLUB,
		positiveTrait = true,
		gainingTrait = true,
	},
	{
		triggers = validBodyWorkEnthusiastTriggers,
		shouldExecute = ETW_CommonLogicChecks.BodyWorkEnthusiastShouldExecute,
		run = function(ctx)
			CombinedTraitChecks.bodyworkEnthusiastCheck(ctx.player)
		end,
	},
	{
		triggers = validMechanicsTriggers,
		shouldExecute = ETW_CommonLogicChecks.MechanicsShouldExecute,
		run = function(ctx)
			CombinedTraitChecks.mechanicsCheck(ctx.player)
		end,
	},
	{
		triggers = validSewerTriggers,
		shouldExecute = ETW_CommonLogicChecks.SewerShouldExecute,
		run = function(ctx)
			CombinedTraitChecks.sewerCheck(ctx.player)
		end,
	},
	{
		triggers = validGunEnthusiastTriggers,
		shouldExecute = ETW_CommonLogicChecks.GunEnthusiastShouldExecute,
		condition = function(ctx)
			return sumContextValues(ctx, { "aiming", "reloading" }) >= SBvars.GunEnthusiastSkill
				and ctx.firearmKills >= SBvars.GunEnthusiastKills
		end,
		trait = ETWTraitsRegistry.GUN_ENTHUSIAST,
		positiveTrait = true,
		gainingTrait = true,
	},
	{
		triggers = validAnglerTriggers,
		shouldExecute = ETW_CommonLogicChecks.AnglerShouldExecute,
		condition = function(ctx)
			return ctx.fishing >= SBvars.FishingSkill
		end,
		trait = CharacterTrait.FISHING,
		positiveTrait = true,
		gainingTrait = true,
	},
	{
		triggers = validHikerTriggers,
		shouldExecute = ETW_CommonLogicChecks.HikerShouldExecute,
		condition = function(ctx)
			return sumContextValues(ctx, { "trapping", "foraging" }) >= SBvars.HikerSkill
		end,
		trait = CharacterTrait.HIKER,
		positiveTrait = true,
		gainingTrait = true,
	},
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

	local ctx = {
		player = player,
		modData = modData,
		strength = strength,
		fitness = fitness,
		sprinting = sprinting,
		lightfooted = lightfooted,
		nimble = nimble,
		sneaking = sneaking,
		axe = axe,
		longBlunt = longBlunt,
		shortBlunt = shortBlunt,
		longBlade = longBlade,
		shortBlade = shortBlade,
		spear = spear,
		maintenance = maintenance,
		carpentry = carpentry,
		cooking = cooking,
		farming = farming,
		firstAid = firstAid,
		electrical = electrical,
		metalworking = metalworking,
		mechanics = mechanics,
		tailoring = tailoring,
		aiming = aiming,
		reloading = reloading,
		fishing = fishing,
		trapping = trapping,
		foraging = foraging,
		husbandry = husbandry,
		carving = carving,
		blacksmith = blacksmith,
		knapping = knapping,
		axeKills = axeKills,
		longBluntKills = longBluntKills,
		shortBluntKills = shortBluntKills,
		longBladeKills = longBladeKills,
		shortBladeKills = shortBladeKills,
		spearKills = spearKills,
		firearmKills = firearmKills,
	}

	for i = 1, #skillTraitRules do
		executeTraitRule(ctx, skillTraitRules[i], trigger)
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
