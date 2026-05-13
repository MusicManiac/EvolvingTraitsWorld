local ETW_ModDataServer = require("ETW_ModDataServer")
local UCWF = require("UnifiedCarryWeightFramework")
local CombinedTraitChecks = require("ETWCombinedTraitChecks")
local CommonFunctions = require("ETW_CommonFunctions")
local CommonLogicChecks = require("ETW_CommonLogicChecks")

---@type EvolvingTraitsWorldRegistries
local ETWRegistries = require("ETW_Registry")
---@type EvolvingTraitsWorldTraitsRegistries
local ETWTraitsRegistry = ETWRegistries.traits

---@type EvolvingTraitsWorldSandboxVars
local SBvars = SandboxVars.EvolvingTraitsWorld

---Prints out debugs inside console if detailedDebug is enabled
---@param ... string Strings to log
local logETW = function(...)
	CommonFunctions.log(...)
end

local gameMode = CommonFunctions.gameMode()

-- TODO: give agent a job to rework all of thses names into Triggers intead of Perks
local validHearingPerks = {
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

local validHoarderPerks = {
	["characterInitialization"] = true,
	[Perks.Strength] = true,
	[ETWTraitsRegistry.HOARDER] = true,
}

local validGymRatPerks = {
	["characterInitialization"] = true,
	[Perks.Strength] = true,
	[Perks.Fitness] = true,
	[ETWTraitsRegistry.GYM_RAT] = true,
}

local validRunnerPerks = {
	["characterInitialization"] = true,
	[Perks.Sprinting] = true,
	[CharacterTrait.JOGGER] = true,
}

local validLightStepPerks = {
	["characterInitialization"] = true,
	[Perks.Lightfoot] = true,
	[ETWTraitsRegistry.LIGHTSTEP] = true,
}

local validGymnastPerks = {
	["characterInitialization"] = true,
	[Perks.Lightfoot] = true,
	[Perks.Nimble] = true,
	[CharacterTrait.GYMNAST] = true,
}

local validClumsyPerks = {
	["characterInitialization"] = true,
	[Perks.Lightfoot] = true,
	[Perks.Sneak] = true,
	[CharacterTrait.CLUMSY] = true,
}

local validGracefulPerks = {
	["characterInitialization"] = true,
	[Perks.Nimble] = true,
	[Perks.Sneak] = true,
	[Perks.Lightfoot] = true,
	[CharacterTrait.GRACEFUL] = true,
}

local validBurglarPerks = {
	["characterInitialization"] = true,
	[Perks.Nimble] = true,
	[Perks.Mechanics] = true,
	[Perks.Electricity] = true,
	[CharacterTrait.BURGLAR] = true,
}

local validLowProfilePerks = {
	["characterInitialization"] = true,
	[Perks.Sneak] = true,
	[ETWTraitsRegistry.LOW_PROFILE] = true,
}

local validConspicuousPerks = {
	["characterInitialization"] = true,
	[Perks.Sneak] = true,
	[CharacterTrait.CONSPICUOUS] = true,
	[CharacterTrait.INCONSPICUOUS] = true,
}

local validBrawlerPerks = {
	["characterInitialization"] = true,
	["kill"] = true,
	[Perks.Axe] = true,
	[Perks.Blunt] = true,
	[CharacterTrait.BRAWLER] = true,
}

local validAxeThrowerPerks = {
	["characterInitialization"] = true,
	["kill"] = true,
	[Perks.Axe] = true,
	[ETWTraitsRegistry.AXE_THROWER] = true,
}

local validBaseballPlayerPerks = {
	["characterInitialization"] = true,
	["kill"] = true,
	[Perks.Blunt] = true,
	[CharacterTrait.BASEBALL_PLAYER] = true,
}

local validHunterPerks = {
	["characterInitialization"] = true,
	["kill"] = true,
	[Perks.Sneak] = true,
	[Perks.Aiming] = true,
	[Perks.Trapping] = true,
	[Perks.SmallBlade] = true,
	[CharacterTrait.HUNTER] = true,
}

local validStickFighterPerks = {
	["characterInitialization"] = true,
	["kill"] = true,
	[Perks.SmallBlunt] = true,
	[ETWTraitsRegistry.STICK_FIGHTER] = true,
}

local validBladeEnthusiastPerks = {
	["characterInitialization"] = true,
	["kill"] = true,
	[Perks.LongBlade] = true,
	[ETWTraitsRegistry.BLADE_ENTHUSIAST] = true,
}

local validKnifeFighterPerks = {
	["characterInitialization"] = true,
	["kill"] = true,
	[Perks.SmallBlade] = true,
	[ETWTraitsRegistry.KNIFE_FIGHTER] = true,
}

local validPolearmPerks = {
	["characterInitialization"] = true,
	["kill"] = true,
	[Perks.Spear] = true,
	[ETWTraitsRegistry.POLEARM_FIGHTER] = true,
}

local validRestorationExpertPerks = {
	["characterInitialization"] = true,
	[Perks.Maintenance] = true,
	[ETWTraitsRegistry.RESTORATION_EXPERT] = true,
}

local validHandyPerks = {
	["characterInitialization"] = true,
	[Perks.Maintenance] = true,
	[Perks.Woodwork] = true,
	[CharacterTrait.HANDY] = true,
}

local validLearnerPerks = {
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

local validFurnitureAssemblerPerks = {
	["characterInitialization"] = true,
	[Perks.Woodwork] = true,
	[ETWTraitsRegistry.FURNITURE_ASSEMBLER] = true,
}

local validHomeCookPerks = {
	["characterInitialization"] = true,
	[Perks.Cooking] = true,
	[ETWTraitsRegistry.HOME_COOK] = true,
}

local validCookPerks = {
	["characterInitialization"] = true,
	[Perks.Cooking] = true,
	[CharacterTrait.COOK] = true,
}

local validGardenerPerks = {
	["characterInitialization"] = true,
	[Perks.Farming] = true,
	[CharacterTrait.GARDENER] = true,
}

local validPetTherapyPerks = {
	["characterInitialization"] = true,
	[Perks.Husbandry] = true,
	[ETWTraitsRegistry.PET_THERAPY] = true,
}

local validWhittlerPerks = {
	["characterInitialization"] = true,
	[Perks.Carving] = true,
	[CharacterTrait.WHITTLER] = true,
}

local validBlacksmithPerks = {
	["characterInitialization"] = true,
	[Perks.Blacksmith] = true,
	[CharacterTrait.BLACKSMITH] = true,
}

local validWildernessKnowledgePerks = {
	["characterInitialization"] = true,
	[Perks.PlantScavenging] = true,
	[Perks.FlintKnapping] = true,
	[Perks.Maintenance] = true,
	[Perks.Carving] = true,
	[CharacterTrait.WILDERNESS_KNOWLEDGE] = true,
}

local validFirstAidPerks = {
	["characterInitialization"] = true,
	[Perks.Doctor] = true,
	[CharacterTrait.FIRST_AID] = true,
}

local validAVClubPerks = {
	["characterInitialization"] = true,
	[Perks.Electricity] = true,
	[ETWTraitsRegistry.AV_CLUB] = true,
}

local validBodyWorkEnthusiastPerks = {
	["characterInitialization"] = true,
	[Perks.MetalWelding] = true,
	[Perks.Mechanics] = true,
	[ETWTraitsRegistry.BODYWORK_ENTHUSIAST] = true,
}

local validMechanicsPerks = {
	["characterInitialization"] = true,
	[Perks.Mechanics] = true,
	[CharacterTrait.MECHANICS] = true,
}

local validSewerPerks = {
	["characterInitialization"] = true,
	[Perks.Tailoring] = true,
	[CharacterTrait.TAILOR] = true,
}

local validGunEnthusiastPerks = {
	["characterInitialization"] = true,
	["kill"] = true,
	[Perks.Aiming] = true,
	[Perks.Reloading] = true,
	[ETWTraitsRegistry.GUN_ENTHUSIAST] = true,
}

local validAnglerPerks = {
	["characterInitialization"] = true,
	[Perks.Fishing] = true,
	[ETWTraitsRegistry.ANGLER] = true,
}

local validHikerPerks = {
	["characterInitialization"] = true,
	[Perks.Trapping] = true,
	[Perks.PlantScavenging] = true,
	[CharacterTrait.HIKER] = true,
}

local validFishingPerks = {
	["characterInitialization"] = true,
	[Perks.Fishing] = true,
	[CharacterTrait.FISHING] = true,
}

---Gain traits by skills (in majority cases)
---@param player IsoPlayer
---@param trigger PerkFactory.Perk|string|CharacterTrait
local function traitsGainsBySkill(player, trigger)
	if player ~= getPlayer() then
		logETW("ETW Logger | traitsGainsBySkill(player, perk) triggered not by a player, skipping")
		return
	end

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

	if validHearingPerks[trigger] and CommonLogicChecks.HearingSystemShouldExecute(player) then
		local levels = sprinting + lightfooted + nimble + sneaking + axe + longBlunt + shortBlunt + longBlade + shortBlade + spear
		if
			player:hasTrait(CharacterTrait.HARD_OF_HEARING)
			and levels >= SBvars.HearingSystemSkill / 2
			and SBvars.TraitsLockSystemCanLoseNegative
		then
			if
				SBvars.DelayedTraitsSystem and not CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, CharacterTrait.HARD_OF_HEARING)
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
				or (SBvars.DelayedTraitsSystem and CommonFunctions.checkDelayedTraits(player, CharacterTrait.HARD_OF_HEARING))
			then
				CommonFunctions.removeTraitFromPlayer(player, CharacterTrait.HARD_OF_HEARING)
				if notification then
					HaloTextHelper.addTextWithArrow(player, getText("UI_trait_hardhear"), false, HaloTextHelper.getColorGreen())
				end
			end
		elseif not player:hasTrait(CharacterTrait.HARD_OF_HEARING) and levels >= SBvars.HearingSystemSkill then
			if SBvars.DelayedTraitsSystem and not CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, CharacterTrait.KEEN_HEARING) then
				CommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = CharacterTrait.KEEN_HEARING,
					player = player,
					positiveTrait = true,
					gainingTrait = true,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (SBvars.DelayedTraitsSystem and CommonFunctions.checkDelayedTraits(player, CharacterTrait.KEEN_HEARING))
			then
				CommonFunctions.addTraitToPlayer(player, CharacterTrait.KEEN_HEARING)
				if notification then
					HaloTextHelper.addTextWithArrow(player, getText("UI_trait_keenhearing"), true, HaloTextHelper.getColorGreen())
				end
			end
		end
	end
	if validHoarderPerks[trigger] and CommonLogicChecks.HoarderShouldExecute(player) then
		if strength >= SBvars.HoarderSkill then
			if SBvars.DelayedTraitsSystem and not CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, ETWTraitsRegistry.HOARDER) then
				CommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = ETWTraitsRegistry.HOARDER,
					player = player,
					positiveTrait = true,
					gainingTrait = true,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (SBvars.DelayedTraitsSystem and CommonFunctions.checkDelayedTraits(player, ETWTraitsRegistry.HOARDER))
			then
				CommonFunctions.addTraitToPlayer(player, ETWTraitsRegistry.HOARDER)
				UnifiedCarryWeightFramework.recomputeAll(player)
				if notification then
					HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Hoarder"), true, HaloTextHelper.getColorGreen())
				end
			end
		end
	end
	if validGymRatPerks[trigger] and CommonLogicChecks.GymRatShouldExecute(player) then
		if (strength + fitness) >= SBvars.GymRatSkill then
			if SBvars.DelayedTraitsSystem and not CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, ETWTraitsRegistry.GYM_RAT) then
				CommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = ETWTraitsRegistry.GYM_RAT,
					player = player,
					positiveTrait = true,
					gainingTrait = true,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (SBvars.DelayedTraitsSystem and CommonFunctions.checkDelayedTraits(player, ETWTraitsRegistry.GYM_RAT))
			then
				CommonFunctions.addTraitToPlayer(player, ETWTraitsRegistry.GYM_RAT)
				if notification then
					HaloTextHelper.addTextWithArrow(player, getText("UI_trait_GymRat"), true, HaloTextHelper.getColorGreen())
				end
			end
		end
	end
	if validRunnerPerks[trigger] and CommonLogicChecks.RunnerShouldExecute(player) then
		if sprinting >= SBvars.RunnerSkill then
			if SBvars.DelayedTraitsSystem and not CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, CharacterTrait.JOGGER) then
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
				CommonFunctions.addTraitToPlayer(player, CharacterTrait.JOGGER)
				if notification then
					HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Jogger"), true, HaloTextHelper.getColorGreen())
				end
			end
		end
	end
	if validLightStepPerks[trigger] and CommonLogicChecks.LightStepShouldExecute(player) then
		if lightfooted >= SBvars.LightStepSkill then
			if SBvars.DelayedTraitsSystem and not CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, ETWTraitsRegistry.LIGHTSTEP) then
				CommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = ETWTraitsRegistry.LIGHTSTEP,
					player = player,
					positiveTrait = true,
					gainingTrait = true,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (SBvars.DelayedTraitsSystem and CommonFunctions.checkDelayedTraits(player, ETWTraitsRegistry.LIGHTSTEP))
			then
				CommonFunctions.addTraitToPlayer(player, ETWTraitsRegistry.LIGHTSTEP)
				if notification then
					HaloTextHelper.addTextWithArrow(player, getText("UI_trait_LightStep"), true, HaloTextHelper.getColorGreen())
				end
			end
		end
	end
	if validGymnastPerks[trigger] and CommonLogicChecks.GymnastShouldExecute(player) then
		if (lightfooted + nimble) >= SBvars.GymnastSkill then
			if SBvars.DelayedTraitsSystem and not CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, ETWTraitsRegistry.GYMNAST) then
				CommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = ETWTraitsRegistry.GYMNAST,
					player = player,
					positiveTrait = true,
					gainingTrait = true,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (SBvars.DelayedTraitsSystem and CommonFunctions.checkDelayedTraits(player, ETWTraitsRegistry.GYMNAST))
			then
				CommonFunctions.addTraitToPlayer(player, ETWTraitsRegistry.GYMNAST)
				if notification then
					HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Gymnast"), true, HaloTextHelper.getColorGreen())
				end
			end
		end
	end
	if validClumsyPerks[trigger] and CommonLogicChecks.ClumsyShouldExecute(player) then
		if (lightfooted + sneaking) >= SBvars.ClumsySkill then
			if SBvars.DelayedTraitsSystem and not CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, CharacterTrait.CLUMSY) then
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
				CommonFunctions.removeTraitFromPlayer(player, CharacterTrait.CLUMSY)
				if notification then
					HaloTextHelper.addTextWithArrow(player, getText("UI_trait_clumsy"), false, HaloTextHelper.getColorGreen())
				end
			end
		end
	end
	if validGracefulPerks[trigger] and CommonLogicChecks.GracefulShouldExecute(player) then
		local levels = nimble + sneaking + lightfooted
		if levels >= SBvars.GracefulSkill then
			if SBvars.DelayedTraitsSystem and not CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, CharacterTrait.GRACEFUL) then
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
				CommonFunctions.addTraitToPlayer(player, CharacterTrait.GRACEFUL)
				if notification then
					HaloTextHelper.addTextWithArrow(player, getText("UI_trait_graceful"), true, HaloTextHelper.getColorGreen())
				end
			end
		end
	end
	if validBurglarPerks[trigger] and CommonLogicChecks.BurglarShouldExecute(player) then
		local levels = nimble + mechanics + electrical
		if electrical >= 2 and mechanics >= 2 and levels >= SBvars.BurglarSkill then
			if SBvars.DelayedTraitsSystem and not CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, CharacterTrait.BURGLAR) then
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
				CommonFunctions.addTraitToPlayer(player, CharacterTrait.BURGLAR)
				if notification then
					HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Burglar"), true, HaloTextHelper.getColorGreen())
				end
			end
		end
	end
	if validLowProfilePerks[trigger] and CommonLogicChecks.LowProfileShouldExecute(player) then
		if sneaking >= SBvars.LowProfileSkill then
			if SBvars.DelayedTraitsSystem and not CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, ETWTraitsRegistry.LOW_PROFILE) then
				CommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = ETWTraitsRegistry.LOW_PROFILE,
					player = player,
					positiveTrait = true,
					gainingTrait = true,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (SBvars.DelayedTraitsSystem and CommonFunctions.checkDelayedTraits(player, ETWTraitsRegistry.LOW_PROFILE))
			then
				CommonFunctions.addTraitToPlayer(player, ETWTraitsRegistry.LOW_PROFILE)
				if notification then
					HaloTextHelper.addTextWithArrow(player, getText("UI_trait_LowProfile"), true, HaloTextHelper.getColorGreen())
				end
			end
		end
	end
	if validConspicuousPerks[trigger] and CommonLogicChecks.ConspicuousShouldExecute(player) then
		if CommonLogicChecks.ConspicuousShouldExecute(player) and sneaking >= SBvars.ConspicuousSkill then
			if SBvars.DelayedTraitsSystem and not CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, CharacterTrait.CONSPICUOUS) then
				CommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = CharacterTrait.CONSPICUOUS,
					player = player,
					positiveTrait = false,
					gainingTrait = false,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (SBvars.DelayedTraitsSystem and CommonFunctions.checkDelayedTraits(player, CharacterTrait.CONSPICUOUS))
			then
				CommonFunctions.removeTraitFromPlayer(player, CharacterTrait.CONSPICUOUS)
				if notification then
					HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Conspicuous"), false, HaloTextHelper.getColorGreen())
				end
			end
		elseif CommonLogicChecks.InconspicuousShouldExecute(player) and sneaking >= SBvars.InconspicuousSkill then
			if SBvars.DelayedTraitsSystem and not CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, CharacterTrait.INCONSPICUOUS) then
				CommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = CharacterTrait.INCONSPICUOUS,
					player = player,
					positiveTrait = true,
					gainingTrait = true,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (SBvars.DelayedTraitsSystem and CommonFunctions.checkDelayedTraits(player, CharacterTrait.INCONSPICUOUS))
			then
				CommonFunctions.addTraitToPlayer(player, CharacterTrait.INCONSPICUOUS)
				if notification then
					HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Inconspicuous"), true, HaloTextHelper.getColorGreen())
				end
			end
		end
	end
	if validHunterPerks[trigger] and CommonLogicChecks.HunterShouldExecute(player) then
		local levels = sneaking + aiming + trapping + shortBlade
		if
			sneaking >= 2
			and aiming >= 2
			and trapping >= 2
			and shortBlade >= 2
			and levels >= SBvars.HunterSkill
			and (shortBladeKills + firearmKills) >= SBvars.HunterKills
		then
			if SBvars.DelayedTraitsSystem and not CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, CharacterTrait.HUNTER) then
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
				CommonFunctions.addTraitToPlayer(player, CharacterTrait.HUNTER)
				if notification then
					HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Hunter"), true, HaloTextHelper.getColorGreen())
				end
			end
		end
	end
	if validBrawlerPerks[trigger] and CommonLogicChecks.BrawlerShouldExecute(player) then
		if (axe + longBlunt) >= SBvars.BrawlerSkill and (axeKills + longBluntKills) >= SBvars.BrawlerKills then
			if SBvars.DelayedTraitsSystem and not CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, CharacterTrait.BRAWLER) then
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
				CommonFunctions.addTraitToPlayer(player, CharacterTrait.BRAWLER)
				if notification then
					HaloTextHelper.addTextWithArrow(player, getText("UI_trait_BarFighter"), true, HaloTextHelper.getColorGreen())
				end
			end
		end
	end
	if validAxeThrowerPerks[trigger] and CommonLogicChecks.AxeThrowerShouldExecute(player) then
		if axe >= SBvars.AxeThrowerSkill and axeKills >= SBvars.AxeThrowerKills then
			if SBvars.DelayedTraitsSystem and not CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, ETWTraitsRegistry.AXE_THROWER) then
				CommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = ETWTraitsRegistry.AXE_THROWER,
					player = player,
					positiveTrait = true,
					gainingTrait = true,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (SBvars.DelayedTraitsSystem and CommonFunctions.checkDelayedTraits(player, ETWTraitsRegistry.AXE_THROWER))
			then
				CommonFunctions.addTraitToPlayer(player, ETWTraitsRegistry.AXE_THROWER)
				if notification then
					HaloTextHelper.addTextWithArrow(player, getText("UI_trait_AxeThrower"), true, HaloTextHelper.getColorGreen())
				end
			end
		end
	end
	if validBaseballPlayerPerks[trigger] and CommonLogicChecks.BaseballPlayerShouldExecute(player) then
		if longBlunt >= SBvars.BaseballPlayerSkill and longBluntKills >= SBvars.BaseballPlayerKills then
			if
				SBvars.DelayedTraitsSystem and not CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, CharacterTrait.BASEBALL_PLAYER)
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
				or (SBvars.DelayedTraitsSystem and CommonFunctions.checkDelayedTraits(player, CharacterTrait.BASEBALL_PLAYER))
			then
				CommonFunctions.addTraitToPlayer(player, CharacterTrait.BASEBALL_PLAYER)
				if notification then
					HaloTextHelper.addTextWithArrow(player, getText("UI_trait_PlaysBaseball"), true, HaloTextHelper.getColorGreen())
				end
			end
		end
	end
	if validStickFighterPerks[trigger] and CommonLogicChecks.StickFighterShouldExecute(player) then
		if shortBlunt >= SBvars.StickFighterSkill and shortBluntKills >= SBvars.StickFighterKills then
			if
				SBvars.DelayedTraitsSystem and not CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, ETWTraitsRegistry.STICK_FIGHTER)
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
				or (SBvars.DelayedTraitsSystem and CommonFunctions.checkDelayedTraits(player, ETWTraitsRegistry.STICK_FIGHTER))
			then
				CommonFunctions.addTraitToPlayer(player, ETWTraitsRegistry.STICK_FIGHTER)
				if notification then
					HaloTextHelper.addTextWithArrow(player, getText("UI_trait_StickFighter"), true, HaloTextHelper.getColorGreen())
				end
			end
		end
	end
	if validBladeEnthusiastPerks[trigger] and CommonLogicChecks.BladeEnthusiastShouldExecute(player) then
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
				or (SBvars.DelayedTraitsSystem and CommonFunctions.checkDelayedTraits(player, ETWTraitsRegistry.BLADE_ENTHUSIAST))
			then
				CommonFunctions.addTraitToPlayer(player, ETWTraitsRegistry.BLADE_ENTHUSIAST)
				if notification then
					HaloTextHelper.addTextWithArrow(player, getText("UI_trait_BladeEnthusiast"), true, HaloTextHelper.getColorGreen())
				end
			end
		end
	end
	if validKnifeFighterPerks[trigger] and CommonLogicChecks.KnifeFighterShouldExecute(player) then
		if shortBlade >= SBvars.KnifeFighterSkill and shortBladeKills >= SBvars.KnifeFighterKills then
			if
				SBvars.DelayedTraitsSystem and not CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, ETWTraitsRegistry.KNIFE_FIGHTER)
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
				or (SBvars.DelayedTraitsSystem and CommonFunctions.checkDelayedTraits(player, ETWTraitsRegistry.KNIFE_FIGHTER))
			then
				CommonFunctions.addTraitToPlayer(player, ETWTraitsRegistry.KNIFE_FIGHTER)
				if notification then
					HaloTextHelper.addTextWithArrow(player, getText("UI_trait_KnifeFighter"), true, HaloTextHelper.getColorGreen())
				end
			end
		end
	end
	if validPolearmPerks[trigger] and CommonLogicChecks.PolearmFighterShouldExecute(player) then
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
				or (SBvars.DelayedTraitsSystem and CommonFunctions.checkDelayedTraits(player, ETWTraitsRegistry.POLEARM_FIGHTER))
			then
				CommonFunctions.addTraitToPlayer(player, ETWTraitsRegistry.POLEARM_FIGHTER)
				if notification then
					HaloTextHelper.addTextWithArrow(player, getText("UI_trait_PolearmFighter"), true, HaloTextHelper.getColorGreen())
				end
			end
		end
	end
	if validRestorationExpertPerks[trigger] and CommonLogicChecks.RestorationExpertShouldExecute(player) then
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
				or (SBvars.DelayedTraitsSystem and CommonFunctions.checkDelayedTraits(player, ETWTraitsRegistry.RESTORATION_EXPERT))
			then
				CommonFunctions.addTraitToPlayer(player, ETWTraitsRegistry.RESTORATION_EXPERT)
				if notification then
					HaloTextHelper.addTextWithArrow(player, getText("UI_trait_RestorationExpert"), true, HaloTextHelper.getColorGreen())
				end
			end
		end
	end
	if validHandyPerks[trigger] and CommonLogicChecks.HandyShouldExecute(player) then
		if (maintenance + carpentry) >= SBvars.HandySkill then
			if SBvars.DelayedTraitsSystem and not CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, CharacterTrait.HANDY) then
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
				CommonFunctions.addTraitToPlayer(player, CharacterTrait.HANDY)
				if notification then
					HaloTextHelper.addTextWithArrow(player, getText("UI_trait_handy"), true, HaloTextHelper.getColorGreen())
				end
			end
		end
	end
	if validLearnerPerks[trigger] and CommonLogicChecks.LearnerSystemShouldExecute(player) then
		local levels = maintenance + carpentry + farming + firstAid + electrical + metalworking + mechanics + tailoring + cooking
		if
			player:hasTrait(CharacterTrait.SLOW_LEARNER)
			and levels >= SBvars.LearnerSystemSkill / 2
			and SBvars.TraitsLockSystemCanLoseNegative
		then
			if SBvars.DelayedTraitsSystem and not CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, CharacterTrait.SLOW_LEARNER) then
				CommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = CharacterTrait.SLOW_LEARNER,
					player = player,
					positiveTrait = false,
					gainingTrait = false,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (SBvars.DelayedTraitsSystem and CommonFunctions.checkDelayedTraits(player, CharacterTrait.SLOW_LEARNER))
			then
				CommonFunctions.removeTraitFromPlayer(player, CharacterTrait.SLOW_LEARNER)
				if notification then
					HaloTextHelper.addTextWithArrow(player, getText("UI_trait_SlowLearner"), false, HaloTextHelper.getColorGreen())
				end
			end
		elseif
			not player:hasTrait(CharacterTrait.SLOW_LEARNER)
			and levels >= SBvars.LearnerSystemSkill
			and SBvars.TraitsLockSystemCanGainPositive
		then
			if SBvars.DelayedTraitsSystem and not CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, CharacterTrait.FAST_LEARNER) then
				CommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = CharacterTrait.FAST_LEARNER,
					player = player,
					positiveTrait = true,
					gainingTrait = true,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (SBvars.DelayedTraitsSystem and CommonFunctions.checkDelayedTraits(player, CharacterTrait.FAST_LEARNER))
			then
				CommonFunctions.addTraitToPlayer(player, CharacterTrait.FAST_LEARNER)
				if notification then
					HaloTextHelper.addTextWithArrow(player, getText("UI_trait_FastLearner"), true, HaloTextHelper.getColorGreen())
				end
			end
		end
	end
	if validFurnitureAssemblerPerks[trigger] and CommonLogicChecks.FurnitureAssemblerShouldExecute(player) then
		if carpentry >= SBvars.FurnitureAssemblerSkill then
			if
				SBvars.DelayedTraitsSystem
				and not CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, ETWTraitsRegistry.FURNITURE_ASSEMBLER)
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
				or (SBvars.DelayedTraitsSystem and CommonFunctions.checkDelayedTraits(player, ETWTraitsRegistry.FURNITURE_ASSEMBLER))
			then
				CommonFunctions.addTraitToPlayer(player, ETWTraitsRegistry.FURNITURE_ASSEMBLER)
				if notification then
					HaloTextHelper.addTextWithArrow(player, getText("UI_trait_FurnitureAssembler"), true, HaloTextHelper.getColorGreen())
				end
			end
		end
	end
	if validHomeCookPerks[trigger] and CommonLogicChecks.HomeCookShouldExecute(player) then
		if cooking >= SBvars.HomeCookSkill then
			if SBvars.DelayedTraitsSystem and not CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, ETWTraitsRegistry.HOME_COOK) then
				CommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = ETWTraitsRegistry.HOME_COOK,
					player = player,
					positiveTrait = true,
					gainingTrait = true,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (SBvars.DelayedTraitsSystem and CommonFunctions.checkDelayedTraits(player, ETWTraitsRegistry.HOME_COOK))
			then
				CommonFunctions.addTraitToPlayer(player, ETWTraitsRegistry.HOME_COOK)
				if notification then
					HaloTextHelper.addTextWithArrow(player, getText("UI_trait_HomeCook"), true, HaloTextHelper.getColorGreen())
				end
			end
		end
	end
	if validCookPerks[trigger] and CommonLogicChecks.CookShouldExecute(player) then
		if cooking >= SBvars.CookSkill then
			if SBvars.DelayedTraitsSystem and not CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, CharacterTrait.COOK) then
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
				CommonFunctions.addTraitToPlayer(player, CharacterTrait.COOK)
				if notification then
					HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Cook"), true, HaloTextHelper.getColorGreen())
				end
			end
		end
	end
	if validGardenerPerks[trigger] and CommonLogicChecks.GardenerShouldExecute(player) then
		if farming >= SBvars.GardenerSkill then
			if SBvars.DelayedTraitsSystem and not CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, CharacterTrait.GARDENER) then
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
				CommonFunctions.addTraitToPlayer(player, CharacterTrait.GARDENER)
				if notification then
					HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Gardener"), true, HaloTextHelper.getColorGreen())
				end
			end
		end
	end
	if validPetTherapyPerks[trigger] and CommonLogicChecks.PetTherapyShouldExecute(player) then
		if husbandry >= SBvars.PetTherapySkill and #modData.AnimalsSystem.UniqueAnimalsPetted >= SBvars.PetTherapyUniqueAnimalsPetted then
			if SBvars.DelayedTraitsSystem and not CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, ETWTraitsRegistry.PET_THERAPY) then
				CommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = ETWTraitsRegistry.PET_THERAPY,
					player = player,
					positiveTrait = true,
					gainingTrait = true,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (SBvars.DelayedTraitsSystem and CommonFunctions.checkDelayedTraits(player, ETWTraitsRegistry.PET_THERAPY))
			then
				CommonFunctions.addTraitToPlayer(player, ETWTraitsRegistry.PET_THERAPY)
				if notification then
					HaloTextHelper.addTextWithArrow(player, getText("UI_trait_PetTherapy"), true, HaloTextHelper.getColorGreen())
				end
			end
		end
	end
	if validWhittlerPerks[trigger] and CommonLogicChecks.WhittlerShouldExecute(player) then
		if carving >= SBvars.WhittlerSkill then
			if SBvars.DelayedTraitsSystem and not CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, CharacterTrait.WHITTLER) then
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
				CommonFunctions.addTraitToPlayer(player, CharacterTrait.WHITTLER)
				if notification then
					HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Whittler"), true, HaloTextHelper.getColorGreen())
				end
			end
		end
	end
	if validBlacksmithPerks[trigger] and CommonLogicChecks.BlacksmithShouldExecute(player) then
		if blacksmith + maintenance >= SBvars.BlacksmithSkill then
			if SBvars.DelayedTraitsSystem and not CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, CharacterTrait.BLACKSMITH) then
				CommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = CharacterTrait.BLACKSMITH,
					player = player,
					positiveTrait = true,
					gainingTrait = true,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (SBvars.DelayedTraitsSystem and CommonFunctions.checkDelayedTraits(player, CharacterTrait.BLACKSMITH))
			then
				CommonFunctions.addTraitToPlayer(player, CharacterTrait.BLACKSMITH)
				if notification then
					HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Blacksmith"), true, HaloTextHelper.getColorGreen())
				end
			end
		end
	end
	if validWildernessKnowledgePerks[trigger] and CommonLogicChecks.WildernessKnowledgeShouldExecute(player) then
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
				or (SBvars.DelayedTraitsSystem and CommonFunctions.checkDelayedTraits(player, CharacterTrait.WILDERNESS_KNOWLEDGE))
			then
				CommonFunctions.addTraitToPlayer(player, CharacterTrait.WILDERNESS_KNOWLEDGE)
				if notification then
					HaloTextHelper.addTextWithArrow(player, getText("UI_trait_WildernessKnowledge"), true, HaloTextHelper.getColorGreen())
				end
			end
		end
	end
	if validFirstAidPerks[trigger] and CommonLogicChecks.FirstAidShouldExecute(player) then
		if firstAid >= SBvars.FirstAidSkill then
			if SBvars.DelayedTraitsSystem and not CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, CharacterTrait.FIRST_AID) then
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
				CommonFunctions.addTraitToPlayer(player, CharacterTrait.FIRST_AID)
				if notification then
					HaloTextHelper.addTextWithArrow(player, getText("UI_trait_FirstAid"), true, HaloTextHelper.getColorGreen())
				end
			end
		end
	end
	if validAVClubPerks[trigger] and CommonLogicChecks.AVClubShouldExecute(player) then
		if electrical >= SBvars.AVClubSkill then
			if SBvars.DelayedTraitsSystem and not CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, ETWTraitsRegistry.AV_CLUB) then
				CommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = ETWTraitsRegistry.AV_CLUB,
					player = player,
					positiveTrait = true,
					gainingTrait = true,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (SBvars.DelayedTraitsSystem and CommonFunctions.checkDelayedTraits(player, ETWTraitsRegistry.AV_CLUB))
			then
				CommonFunctions.addTraitToPlayer(player, ETWTraitsRegistry.AV_CLUB)
				if notification then
					HaloTextHelper.addTextWithArrow(player, getText("UI_trait_AVClub"), true, HaloTextHelper.getColorGreen())
				end
			end
		end
	end
	if validBodyWorkEnthusiastPerks[trigger] and CommonLogicChecks.BodyWorkEnthusiastShouldExecute(player) then
		CombinedTraitChecks.bodyworkEnthusiastCheck(player)
	end
	if validMechanicsPerks[trigger] and CommonLogicChecks.MechanicsShouldExecute(player) then
		CombinedTraitChecks.mechanicsCheck(player)
	end
	if validSewerPerks[trigger] and CommonLogicChecks.SewerShouldExecute(player) then
		CombinedTraitChecks.sewerCheck(player)
	end
	if validGunEnthusiastPerks[trigger] and CommonLogicChecks.GunEnthusiastShouldExecute(player) then
		if (aiming + reloading) >= SBvars.GunEnthusiastSkill and firearmKills >= SBvars.GunEnthusiastKills then
			if
				SBvars.DelayedTraitsSystem and not CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, ETWTraitsRegistry.GUN_ENTHUSIAST)
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
				or (SBvars.DelayedTraitsSystem and CommonFunctions.checkDelayedTraits(player, ETWTraitsRegistry.GUN_ENTHUSIAST))
			then
				CommonFunctions.addTraitToPlayer(player, ETWTraitsRegistry.GUN_ENTHUSIAST)
				if notification then
					HaloTextHelper.addTextWithArrow(player, getText("UI_trait_GunEnthusiast"), true, HaloTextHelper.getColorGreen())
				end
			end
		end
	end
	if validAnglerPerks[trigger] and CommonLogicChecks.AnglerShouldExecute(player) then
		if fishing >= SBvars.FishingSkill then
			if SBvars.DelayedTraitsSystem and not CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, CharacterTrait.FISHING) then
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
				CommonFunctions.addTraitToPlayer(player, CharacterTrait.FISHING)
				if notification then
					HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Fishing"), true, HaloTextHelper.getColorGreen())
				end
			end
		end
	end
	if validHikerPerks[trigger] and CommonLogicChecks.HikerShouldExecute(player) then
		if (trapping + foraging) >= SBvars.HikerSkill then
			if SBvars.DelayedTraitsSystem and not CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, CharacterTrait.HIKER) then
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
				CommonFunctions.addTraitToPlayer(player, CharacterTrait.HIKER)
				if notification then
					HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Hiker"), true, HaloTextHelper.getColorGreen())
				end
			end
		end
	end
	modData.DelayedStartingTraitsFilled = true
end

local random_instance = newrandom()

---Function responsible for hourly check on Delayed Traits system
local function progressDelayedTraits()
	local player = getPlayer()
	local modData = CommonFunctions.getETWModData(player)
	if not modData then
		logETW("ETW Logger | progressDelayedTraits(): modData is nil, returning early")
		return
	end
	local traitTable = modData.DelayedTraits
	logETW("ETW Logger | Delayed Traits System: new progressDelayedTraits() execution ----------")
	for index = 1, #traitTable do
		local traitEntry = traitTable[index]
		local traitRegistryId, traitValue, gained = traitEntry[1], traitEntry[2], traitEntry[3]
		local trait = CharacterTrait.get(ResourceLocation.of(traitRegistryId))
		if not gained then
			local randomValue = random_instance:random(0, traitValue)
			if randomValue == 0 then
				traitTable[index][3] = true
				logETW(
					"ETW Logger | Delayed Traits System: rolled to get " .. traitRegistryId .. ": rolled 0 from 0-" .. traitTable[index][2],
					"ETW Logger | Delayed Traits System: "
						.. traitRegistryId
						.. " in traitTable["
						.. index
						.. "][3]"
						.. " set to "
						.. tostring(traitTable[index][3]),
					"ETW Logger | Delayed Traits System: running traitsGainsBySkill(player, " .. traitRegistryId .. ")"
				)
				traitsGainsBySkill(player, trait)
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
	logETW("ETW Logger | Delayed Traits System: finished progressDelayedTraits() execution ----------")
end

---Function responsible for firing check on all kill-related traits
---@param zombie IsoZombie
local function OnZombieDeadETW(zombie)
	local player = zombie:getAttackedBy()
	---@cast player IsoPlayer
	if not player or not instanceof(player, "IsoPlayer") or (gameMode == CommonFunctions.GameMode.SP and not player:isLocalPlayer()) then
		return
	else
		traitsGainsBySkill(player, "kill")
	end
end

---Function responsible for setting up events
---@param playerIndex number
---@param player IsoPlayer
local function initializeEventsETW(playerIndex, player)
	if SBvars.TraitsLockSystemCanGainPositive or SBvars.TraitsLockSystemCanLoseNegative then
		traitsGainsBySkill(player, "characterInitialization")
		Events.LevelPerk.Remove(traitsGainsBySkill)
		Events.LevelPerk.Add(traitsGainsBySkill)
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
	-- TODO: check if LEveLPerk fires on server, if not - need to make client send command to server
	Events.LevelPerk.Remove(traitsGainsBySkill)
	Events.EveryHours.Remove(progressDelayedTraits)
	Events.OnZombieDead.Remove(OnZombieDeadETW)
	logETW("ETW Logger | System: clearEventsETW in ETWBySkills.lua")
end

if gameMode == CommonFunctions.GameMode.SP then
	Events.OnCreatePlayer.Remove(initializeEventsETW)
	Events.OnCreatePlayer.Add(initializeEventsETW)
	Events.OnPlayerDeath.Remove(clearEventsETW)
	Events.OnPlayerDeath.Add(clearEventsETW)
elseif gameMode == CommonFunctions.GameMode.MP_SERVER then
	Events.OnTick.Add(initializeEventsETW)
end