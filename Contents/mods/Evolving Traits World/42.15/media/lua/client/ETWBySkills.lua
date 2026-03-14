require("ETWModData")
require("ETWModOptions")
require("UnifiedCarryWeightFramework")
local ETWCombinedTraitChecks = require("ETWCombinedTraitChecks")
local ETWCommonFunctions = require("ETWCommonFunctions")
local ETWCommonLogicChecks = require("ETWCommonLogicChecks")

---@type EvolvingTraitsWorldRegistries
local ETWRegistries = require("ETWRegistry")
---@type EvolvingTraitsWorldTraitsRegistries
local ETWTraitsRegistry = ETWRegistries.traits

---@type EvolvingTraitsWorldSandboxVars
local SBvars = SandboxVars.EvolvingTraitsWorld

local modOptions

---Function responsible for setting up mod options on character load
---@param playerIndex number
---@param player IsoPlayer
local function initializeModOptions(playerIndex, player)
	modOptions = PZAPI.ModOptions:getOptions("ETWModOptions")
end

Events.OnCreatePlayer.Remove(initializeModOptions)
Events.OnCreatePlayer.Add(initializeModOptions)

---@return boolean
local notification = function()
	return modOptions:getOption("EnableNotifications"):getValue()
end
---@return boolean
local delayedNotification = function()
	return modOptions:getOption("EnableDelayedNotifications"):getValue()
end
---@return boolean
local detailedDebug = function()
	return modOptions:getOption("GatherDetailedDebug"):getValue()
end

---Prints out debugs inside console if detailedDebug is enabled
---@param ... string Strings to log
local logETW = function(...)
	ETWCommonFunctions.log(...)
end

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
	[ETWTraitsRegistry.GYMNAST] = true,
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

---Gain traits by skills (in majority cases)
---@param player IsoPlayer
---@param perk Perk|string|CharacterTrait
local function traitsGainsBySkill(player, perk)
	if player ~= getPlayer() then
		logETW("ETW Logger | traitsGainsBySkill(player, perk) triggered not by a player, skipping")
		return
	end

	local modData = ETWCommonFunctions.getETWModData(player)

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

	local detailedDebug = detailedDebug()
	local notification = notification()
	local delayedNotification = delayedNotification()

	---@type DebugAndNotificationArgs
	local DebugAndNotificationArgs =
		{ detailedDebug = detailedDebug, notification = notification, delayedNotification = delayedNotification }

	if validHearingPerks[perk] and ETWCommonLogicChecks.HearingSystemShouldExecute() then
		local levels = sprinting + lightfooted + nimble + sneaking + axe + longBlunt + shortBlunt + longBlade + shortBlade + spear
		if
			player:hasTrait(CharacterTrait.HARD_OF_HEARING)
			and levels >= SBvars.HearingSystemSkill / 2
			and SBvars.TraitsLockSystemCanLoseNegative
		then
			if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable(CharacterTrait.HARD_OF_HEARING) then
				ETWCommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = CharacterTrait.HARD_OF_HEARING,
					player = player,
					positiveTrait = false,
					gainingTrait = false,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits(CharacterTrait.HARD_OF_HEARING))
			then
				ETWCommonFunctions.removeTraitFromPlayer(CharacterTrait.HARD_OF_HEARING)
				if notification then
					HaloTextHelper.addTextWithArrow(player, getText("UI_trait_hardhear"), false, HaloTextHelper.getColorGreen())
				end
			end
		elseif not player:hasTrait(CharacterTrait.HARD_OF_HEARING) and levels >= SBvars.HearingSystemSkill then
			if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable(CharacterTrait.KEEN_HEARING) then
				ETWCommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = CharacterTrait.KEEN_HEARING,
					player = player,
					positiveTrait = true,
					gainingTrait = true,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits(CharacterTrait.KEEN_HEARING))
			then
				ETWCommonFunctions.addTraitToPlayer(CharacterTrait.KEEN_HEARING)
				if notification then
					HaloTextHelper.addTextWithArrow(player, getText("UI_trait_keenhearing"), true, HaloTextHelper.getColorGreen())
				end
			end
		end
	end
	if validHoarderPerks[perk] and ETWCommonLogicChecks.HoarderShouldExecute() then
		if strength >= SBvars.HoarderSkill then
			if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable(ETWTraitsRegistry.HOARDER) then
				ETWCommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = ETWTraitsRegistry.HOARDER,
					player = player,
					positiveTrait = true,
					gainingTrait = true,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits(ETWTraitsRegistry.HOARDER))
			then
				ETWCommonFunctions.addTraitToPlayer(ETWTraitsRegistry.HOARDER)
				UnifiedCarryWeightFramework.recomputeAll(player)
				if notification then
					HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Hoarder"), true, HaloTextHelper.getColorGreen())
				end
			end
		end
	end
	if validGymRatPerks[perk] and ETWCommonLogicChecks.GymRatShouldExecute() then
		if (strength + fitness) >= SBvars.GymRatSkill then
			if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable(ETWTraitsRegistry.GYM_RAT) then
				ETWCommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = ETWTraitsRegistry.GYM_RAT,
					player = player,
					positiveTrait = true,
					gainingTrait = true,
				})
				if delayedNotification then
					HaloTextHelper.addTextWithArrow(
						player,
						getText("UI_ETW_DelayedNotificationsStringAdd") .. getText("UI_trait_GymRat"),
						true,
						HaloTextHelper.getColorGreen()
					)
				end
			elseif
				not SBvars.DelayedTraitsSystem
				or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits(ETWTraitsRegistry.GYM_RAT))
			then
				ETWCommonFunctions.addTraitToPlayer(ETWTraitsRegistry.GYM_RAT)
				if notification then
					HaloTextHelper.addTextWithArrow(player, getText("UI_trait_GymRat"), true, HaloTextHelper.getColorGreen())
				end
			end
		end
	end
	if validRunnerPerks[perk] and ETWCommonLogicChecks.RunnerShouldExecute() then
		if sprinting >= SBvars.RunnerSkill then
			if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable(CharacterTrait.JOGGER) then
				ETWCommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = CharacterTrait.JOGGER,
					player = player,
					positiveTrait = true,
					gainingTrait = true,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits(CharacterTrait.JOGGER))
			then
				ETWCommonFunctions.addTraitToPlayer(CharacterTrait.JOGGER)
				if notification then
					HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Jogger"), true, HaloTextHelper.getColorGreen())
				end
			end
		end
	end
	if validLightStepPerks[perk] and ETWCommonLogicChecks.LightStepShouldExecute() then
		if lightfooted >= SBvars.LightStepSkill then
			if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable(ETWTraitsRegistry.LIGHTSTEP) then
				ETWCommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = ETWTraitsRegistry.LIGHTSTEP,
					player = player,
					positiveTrait = true,
					gainingTrait = true,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits(ETWTraitsRegistry.LIGHTSTEP))
			then
				ETWCommonFunctions.addTraitToPlayer(ETWTraitsRegistry.LIGHTSTEP)
				if notification then
					HaloTextHelper.addTextWithArrow(player, getText("UI_trait_LightStep"), true, HaloTextHelper.getColorGreen())
				end
			end
		end
	end
	if validGymnastPerks[perk] and ETWCommonLogicChecks.GymnastShouldExecute() then
		if (lightfooted + nimble) >= SBvars.GymnastSkill then
			if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable(ETWTraitsRegistry.GYMNAST) then
				ETWCommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = ETWTraitsRegistry.GYMNAST,
					player = player,
					positiveTrait = true,
					gainingTrait = true,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits(ETWTraitsRegistry.GYMNAST))
			then
				ETWCommonFunctions.addTraitToPlayer(ETWTraitsRegistry.GYMNAST)
				if notification then
					HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Gymnast"), true, HaloTextHelper.getColorGreen())
				end
			end
		end
	end
	if validClumsyPerks[perk] and ETWCommonLogicChecks.ClumsyShouldExecute() then
		if (lightfooted + sneaking) >= SBvars.ClumsySkill then
			if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable(CharacterTrait.CLUMSY) then
				ETWCommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = CharacterTrait.CLUMSY,
					player = player,
					positiveTrait = false,
					gainingTrait = false,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits(CharacterTrait.CLUMSY))
			then
				ETWCommonFunctions.removeTraitFromPlayer(CharacterTrait.CLUMSY)
				if notification then
					HaloTextHelper.addTextWithArrow(player, getText("UI_trait_clumsy"), false, HaloTextHelper.getColorGreen())
				end
			end
		end
	end
	if validGracefulPerks[perk] and ETWCommonLogicChecks.GracefulShouldExecute() then
		local levels = nimble + sneaking + lightfooted
		if levels >= SBvars.GracefulSkill then
			if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable(CharacterTrait.GRACEFUL) then
				ETWCommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = CharacterTrait.GRACEFUL,
					player = player,
					positiveTrait = true,
					gainingTrait = true,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits(CharacterTrait.GRACEFUL))
			then
				ETWCommonFunctions.addTraitToPlayer(CharacterTrait.GRACEFUL)
				if notification then
					HaloTextHelper.addTextWithArrow(player, getText("UI_trait_graceful"), true, HaloTextHelper.getColorGreen())
				end
			end
		end
	end
	if validBurglarPerks[perk] and ETWCommonLogicChecks.BurglarShouldExecute() then
		local levels = nimble + mechanics + electrical
		if electrical >= 2 and mechanics >= 2 and levels >= SBvars.BurglarSkill then
			if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable(CharacterTrait.BURGLAR) then
				ETWCommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = CharacterTrait.BURGLAR,
					player = player,
					positiveTrait = true,
					gainingTrait = true,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits(CharacterTrait.BURGLAR))
			then
				ETWCommonFunctions.addTraitToPlayer(CharacterTrait.BURGLAR)
				if notification then
					HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Burglar"), true, HaloTextHelper.getColorGreen())
				end
			end
		end
	end
	if validLowProfilePerks[perk] and ETWCommonLogicChecks.LowProfileShouldExecute() then
		if sneaking >= SBvars.LowProfileSkill then
			if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable(ETWTraitsRegistry.LOW_PROFILE) then
				ETWCommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = ETWTraitsRegistry.LOW_PROFILE,
					player = player,
					positiveTrait = true,
					gainingTrait = true,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits(ETWTraitsRegistry.LOW_PROFILE))
			then
				ETWCommonFunctions.addTraitToPlayer(ETWTraitsRegistry.LOW_PROFILE)
				if notification then
					HaloTextHelper.addTextWithArrow(player, getText("UI_trait_LowProfile"), true, HaloTextHelper.getColorGreen())
				end
			end
		end
	end
	if validConspicuousPerks[perk] and ETWCommonLogicChecks.ConspicuousShouldExecute() then
		if ETWCommonLogicChecks.ConspicuousShouldExecute() and sneaking >= SBvars.ConspicuousSkill then
			if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable(CharacterTrait.CONSPICUOUS) then
				ETWCommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = CharacterTrait.CONSPICUOUS,
					player = player,
					positiveTrait = false,
					gainingTrait = false,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits(CharacterTrait.CONSPICUOUS))
			then
				ETWCommonFunctions.removeTraitFromPlayer(CharacterTrait.CONSPICUOUS)
				if notification then
					HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Conspicuous"), false, HaloTextHelper.getColorGreen())
				end
			end
		elseif ETWCommonLogicChecks.InconspicuousShouldExecute() and sneaking >= SBvars.InconspicuousSkill then
			if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable(CharacterTrait.INCONSPICUOUS) then
				ETWCommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = CharacterTrait.INCONSPICUOUS,
					player = player,
					positiveTrait = true,
					gainingTrait = true,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits(CharacterTrait.INCONSPICUOUS))
			then
				ETWCommonFunctions.addTraitToPlayer(CharacterTrait.INCONSPICUOUS)
				if notification then
					HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Inconspicuous"), true, HaloTextHelper.getColorGreen())
				end
			end
		end
	end
	if validHunterPerks[perk] and ETWCommonLogicChecks.HunterShouldExecute() then
		local levels = sneaking + aiming + trapping + shortBlade
		if
			sneaking >= 2
			and aiming >= 2
			and trapping >= 2
			and shortBlade >= 2
			and levels >= SBvars.HunterSkill
			and (shortBladeKills + firearmKills) >= SBvars.HunterKills
		then
			if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable(CharacterTrait.HUNTER) then
				ETWCommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = CharacterTrait.HUNTER,
					player = player,
					positiveTrait = true,
					gainingTrait = true,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits(CharacterTrait.HUNTER))
			then
				ETWCommonFunctions.addTraitToPlayer(CharacterTrait.HUNTER)
				if notification then
					HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Hunter"), true, HaloTextHelper.getColorGreen())
				end
			end
		end
	end
	if validBrawlerPerks[perk] and ETWCommonLogicChecks.BrawlerShouldExecute() then
		if (axe + longBlunt) >= SBvars.BrawlerSkill and (axeKills + longBluntKills) >= SBvars.BrawlerKills then
			if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable(CharacterTrait.BRAWLER) then
				ETWCommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = CharacterTrait.BRAWLER,
					player = player,
					positiveTrait = true,
					gainingTrait = true,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits(CharacterTrait.BRAWLER))
			then
				ETWCommonFunctions.addTraitToPlayer(CharacterTrait.BRAWLER)
				if notification then
					HaloTextHelper.addTextWithArrow(player, getText("UI_trait_BarFighter"), true, HaloTextHelper.getColorGreen())
				end
			end
		end
	end
	if validAxeThrowerPerks[perk] and ETWCommonLogicChecks.AxeThrowerShouldExecute() then
		if axe >= SBvars.AxeThrowerSkill and axeKills >= SBvars.AxeThrowerKills then
			if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable(ETWTraitsRegistry.AXE_THROWER) then
				ETWCommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = ETWTraitsRegistry.AXE_THROWER,
					player = player,
					positiveTrait = true,
					gainingTrait = true,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits(ETWTraitsRegistry.AXE_THROWER))
			then
				ETWCommonFunctions.addTraitToPlayer(ETWTraitsRegistry.AXE_THROWER)
				if notification then
					HaloTextHelper.addTextWithArrow(player, getText("UI_trait_AxeThrower"), true, HaloTextHelper.getColorGreen())
				end
			end
		end
	end
	if validBaseballPlayerPerks[perk] and ETWCommonLogicChecks.BaseballPlayerShouldExecute() then
		if longBlunt >= SBvars.BaseballPlayerSkill and longBluntKills >= SBvars.BaseballPlayerKills then
			if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable(CharacterTrait.BASEBALL_PLAYER) then
				ETWCommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = CharacterTrait.BASEBALL_PLAYER,
					player = player,
					positiveTrait = true,
					gainingTrait = true,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits(CharacterTrait.BASEBALL_PLAYER))
			then
				ETWCommonFunctions.addTraitToPlayer(CharacterTrait.BASEBALL_PLAYER)
				if notification then
					HaloTextHelper.addTextWithArrow(player, getText("UI_trait_PlaysBaseball"), true, HaloTextHelper.getColorGreen())
				end
			end
		end
	end
	if
		(perk == "characterInitialization" or perk == "kill" or perk == Perks.SmallBlunt or perk == ETWTraitsRegistry.STICK_FIGHTER)
		and ETWCommonLogicChecks.StickFighterShouldExecute()
	then
		if shortBlunt >= SBvars.StickFighterSkill and shortBluntKills >= SBvars.StickFighterKills then
			if
				SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable(ETWTraitsRegistry.STICK_FIGHTER)
			then
				ETWCommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = ETWTraitsRegistry.STICK_FIGHTER,
					player = player,
					positiveTrait = true,
					gainingTrait = true,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits(ETWTraitsRegistry.STICK_FIGHTER))
			then
				ETWCommonFunctions.addTraitToPlayer(ETWTraitsRegistry.STICK_FIGHTER)
				if notification then
					HaloTextHelper.addTextWithArrow(player, getText("UI_trait_StickFighter"), true, HaloTextHelper.getColorGreen())
				end
			end
		end
	end
	if
		(perk == "characterInitialization" or perk == "kill" or perk == Perks.LongBlade or perk == ETWTraitsRegistry.BLADE_ENTHUSIAST)
		and ETWCommonLogicChecks.BladeEnthusiastShouldExecute()
	then
		if longBlade >= SBvars.BladeEnthusiastSkill and longBladeKills >= SBvars.BladeEnthusiastKills then
			if
				SBvars.DelayedTraitsSystem
				and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable(ETWTraitsRegistry.BLADE_ENTHUSIAST)
			then
				ETWCommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = ETWTraitsRegistry.BLADE_ENTHUSIAST,
					player = player,
					positiveTrait = true,
					gainingTrait = true,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits(ETWTraitsRegistry.BLADE_ENTHUSIAST))
			then
				ETWCommonFunctions.addTraitToPlayer(ETWTraitsRegistry.BLADE_ENTHUSIAST)
				if notification then
					HaloTextHelper.addTextWithArrow(player, getText("UI_trait_BladeEnthusiast"), true, HaloTextHelper.getColorGreen())
				end
			end
		end
	end
	if
		(perk == "characterInitialization" or perk == "kill" or perk == Perks.SmallBlade or perk == ETWTraitsRegistry.KNIFE_FIGHTER)
		and ETWCommonLogicChecks.KnifeFighterShouldExecute()
	then
		if shortBlade >= SBvars.KnifeFighterSkill and shortBladeKills >= SBvars.KnifeFighterKills then
			if
				SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable(ETWTraitsRegistry.KNIFE_FIGHTER)
			then
				ETWCommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = ETWTraitsRegistry.KNIFE_FIGHTER,
					player = player,
					positiveTrait = true,
					gainingTrait = true,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits(ETWTraitsRegistry.KNIFE_FIGHTER))
			then
				ETWCommonFunctions.addTraitToPlayer(ETWTraitsRegistry.KNIFE_FIGHTER)
				if notification then
					HaloTextHelper.addTextWithArrow(player, getText("UI_trait_KnifeFighter"), true, HaloTextHelper.getColorGreen())
				end
			end
		end
	end
	if
		(perk == "characterInitialization" or perk == "kill" or perk == Perks.Spear or perk == ETWTraitsRegistry.POLEARM_FIGHTER)
		and ETWCommonLogicChecks.PolearmFighterShouldExecute()
	then
		if spear >= SBvars.PolearmFighterSkill and spearKills >= SBvars.PolearmFighterKills then
			if
				SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable(ETWTraitsRegistry.POLEARM_FIGHTER)
			then
				ETWCommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = ETWTraitsRegistry.POLEARM_FIGHTER,
					player = player,
					positiveTrait = true,
					gainingTrait = true,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits(ETWTraitsRegistry.POLEARM_FIGHTER))
			then
				ETWCommonFunctions.addTraitToPlayer(ETWTraitsRegistry.POLEARM_FIGHTER)
				if notification then
					HaloTextHelper.addTextWithArrow(player, getText("UI_trait_PolearmFighter"), true, HaloTextHelper.getColorGreen())
				end
			end
		end
	end
	if
		(perk == "characterInitialization" or perk == Perks.Maintenance or perk == ETWTraitsRegistry.RESTORATION_EXPERT)
		and ETWCommonLogicChecks.RestorationExpertShouldExecute()
	then
		if maintenance >= SBvars.RestorationExpertSkill then
			if
				SBvars.DelayedTraitsSystem
				and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable(ETWTraitsRegistry.RESTORATION_EXPERT)
			then
				ETWCommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = ETWTraitsRegistry.RESTORATION_EXPERT,
					player = player,
					positiveTrait = true,
					gainingTrait = true,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits(ETWTraitsRegistry.RESTORATION_EXPERT))
			then
				ETWCommonFunctions.addTraitToPlayer(ETWTraitsRegistry.RESTORATION_EXPERT)
				if notification then
					HaloTextHelper.addTextWithArrow(player, getText("UI_trait_RestorationExpert"), true, HaloTextHelper.getColorGreen())
				end
			end
		end
	end
	if
		(perk == "characterInitialization" or perk == Perks.Maintenance or perk == Perks.Woodwork or perk == CharacterTrait.HANDY)
		and ETWCommonLogicChecks.HandyShouldExecute()
	then
		if (maintenance + carpentry) >= SBvars.HandySkill then
			if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable(CharacterTrait.HANDY) then
				ETWCommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = CharacterTrait.HANDY,
					player = player,
					positiveTrait = true,
					gainingTrait = true,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits(CharacterTrait.HANDY))
			then
				ETWCommonFunctions.addTraitToPlayer(CharacterTrait.HANDY)
				if notification then
					HaloTextHelper.addTextWithArrow(player, getText("UI_trait_handy"), true, HaloTextHelper.getColorGreen())
				end
			end
		end
	end
	if
		(
			perk == "characterInitialization"
			or perk == Perks.Maintenance
			or perk == Perks.Woodwork
			or perk == Perks.Cooking
			or perk == Perks.Farming
			or perk == Perks.Doctor
			or perk == Perks.Electricity
			or perk == Perks.MetalWelding
			or perk == Perks.Mechanics
			or perk == Perks.Tailoring
			or perk == CharacterTrait.SLOW_LEARNER
			or perk == CharacterTrait.FAST_LEARNER
		) and ETWCommonLogicChecks.LearnerSystemShouldExecute()
	then
		local levels = maintenance + carpentry + farming + firstAid + electrical + metalworking + mechanics + tailoring + cooking
		if
			player:hasTrait(CharacterTrait.SLOW_LEARNER)
			and levels >= SBvars.LearnerSystemSkill / 2
			and SBvars.TraitsLockSystemCanLoseNegative
		then
			if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable(CharacterTrait.SLOW_LEARNER) then
				ETWCommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = CharacterTrait.SLOW_LEARNER,
					player = player,
					positiveTrait = false,
					gainingTrait = false,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits(CharacterTrait.SLOW_LEARNER))
			then
				ETWCommonFunctions.removeTraitFromPlayer(CharacterTrait.SLOW_LEARNER)
				if notification then
					HaloTextHelper.addTextWithArrow(player, getText("UI_trait_SlowLearner"), false, HaloTextHelper.getColorGreen())
				end
			end
		elseif
			not player:hasTrait(CharacterTrait.SLOW_LEARNER)
			and levels >= SBvars.LearnerSystemSkill
			and SBvars.TraitsLockSystemCanGainPositive
		then
			if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable(CharacterTrait.FAST_LEARNER) then
				ETWCommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = CharacterTrait.FAST_LEARNER,
					player = player,
					positiveTrait = true,
					gainingTrait = true,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits(CharacterTrait.FAST_LEARNER))
			then
				ETWCommonFunctions.addTraitToPlayer(CharacterTrait.FAST_LEARNER)
				if notification then
					HaloTextHelper.addTextWithArrow(player, getText("UI_trait_FastLearner"), true, HaloTextHelper.getColorGreen())
				end
			end
		end
	end
	if
		(perk == "characterInitialization" or perk == Perks.Woodwork or perk == ETWTraitsRegistry.FURNITURE_ASSEMBLER)
		and ETWCommonLogicChecks.FurnitureAssemblerShouldExecute()
	then
		if carpentry >= SBvars.FurnitureAssemblerSkill then
			if
				SBvars.DelayedTraitsSystem
				and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable(ETWTraitsRegistry.FURNITURE_ASSEMBLER)
			then
				ETWCommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = ETWTraitsRegistry.FURNITURE_ASSEMBLER,
					player = player,
					positiveTrait = true,
					gainingTrait = true,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits(ETWTraitsRegistry.FURNITURE_ASSEMBLER))
			then
				ETWCommonFunctions.addTraitToPlayer(ETWTraitsRegistry.FURNITURE_ASSEMBLER)
				if notification then
					HaloTextHelper.addTextWithArrow(player, getText("UI_trait_FurnitureAssembler"), true, HaloTextHelper.getColorGreen())
				end
			end
		end
	end
	if
		(perk == "characterInitialization" or perk == Perks.Cooking or perk == ETWTraitsRegistry.HOME_COOK)
		and ETWCommonLogicChecks.HomeCookShouldExecute()
	then
		if cooking >= SBvars.HomeCookSkill then
			if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable(ETWTraitsRegistry.HOME_COOK) then
				ETWCommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = ETWTraitsRegistry.HOME_COOK,
					player = player,
					positiveTrait = true,
					gainingTrait = true,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits(ETWTraitsRegistry.HOME_COOK))
			then
				ETWCommonFunctions.addTraitToPlayer(ETWTraitsRegistry.HOME_COOK)
				if notification then
					HaloTextHelper.addTextWithArrow(player, getText("UI_trait_HomeCook"), true, HaloTextHelper.getColorGreen())
				end
			end
		end
	end
	if
		(perk == "characterInitialization" or perk == Perks.Cooking or perk == CharacterTrait.COOK)
		and ETWCommonLogicChecks.CookShouldExecute()
	then
		if cooking >= SBvars.CookSkill then
			if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable(CharacterTrait.COOK) then
				ETWCommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = CharacterTrait.COOK,
					player = player,
					positiveTrait = true,
					gainingTrait = true,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits(CharacterTrait.COOK))
			then
				ETWCommonFunctions.addTraitToPlayer(CharacterTrait.COOK)
				if notification then
					HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Cook"), true, HaloTextHelper.getColorGreen())
				end
			end
		end
	end
	if
		(perk == "characterInitialization" or perk == Perks.Farming or perk == CharacterTrait.GARDENER)
		and ETWCommonLogicChecks.GardenerShouldExecute()
	then
		if farming >= SBvars.GardenerSkill then
			if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable(CharacterTrait.GARDENER) then
				ETWCommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = CharacterTrait.GARDENER,
					player = player,
					positiveTrait = true,
					gainingTrait = true,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits(CharacterTrait.GARDENER))
			then
				ETWCommonFunctions.addTraitToPlayer(CharacterTrait.GARDENER)
				if notification then
					HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Gardener"), true, HaloTextHelper.getColorGreen())
				end
			end
		end
	end
	if
		(perk == "characterInitialization" or perk == Perks.Husbandry or perk == ETWTraitsRegistry.PET_THERAPY)
		and ETWCommonLogicChecks.PetTherapyShouldExecute()
	then
		if husbandry >= SBvars.PetTherapySkill and #modData.AnimalsSystem.UniqueAnimalsPetted >= SBvars.PetTherapyUniqueAnimalsPetted then
			if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable(ETWTraitsRegistry.PET_THERAPY) then
				ETWCommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = ETWTraitsRegistry.PET_THERAPY,
					player = player,
					positiveTrait = true,
					gainingTrait = true,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits(ETWTraitsRegistry.PET_THERAPY))
			then
				ETWCommonFunctions.addTraitToPlayer(ETWTraitsRegistry.PET_THERAPY)
				if notification then
					HaloTextHelper.addTextWithArrow(player, getText("UI_trait_PetTherapy"), true, HaloTextHelper.getColorGreen())
				end
			end
		end
	end
	if
		(perk == "characterInitialization" or perk == Perks.Carving or perk == CharacterTrait.WHITTLER)
		and ETWCommonLogicChecks.WhittlerShouldExecute()
	then
		if carving >= SBvars.WhittlerSkill then
			if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable(CharacterTrait.WHITTLER) then
				ETWCommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = CharacterTrait.WHITTLER,
					player = player,
					positiveTrait = true,
					gainingTrait = true,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits(CharacterTrait.WHITTLER))
			then
				ETWCommonFunctions.addTraitToPlayer(CharacterTrait.WHITTLER)
				if notification then
					HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Whittler"), true, HaloTextHelper.getColorGreen())
				end
			end
		end
	end
	if
		(perk == "characterInitialization" or perk == Perks.Blacksmith or perk == Perks.Maintenance or perk == "Blacksmith")
		and ETWCommonLogicChecks.BlacksmithShouldExecute()
	then
		if blacksmith + maintenance >= SBvars.BlacksmithSkill then
			if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable(CharacterTrait.BLACKSMITH) then
				ETWCommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = CharacterTrait.BLACKSMITH,
					player = player,
					positiveTrait = true,
					gainingTrait = true,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits(CharacterTrait.BLACKSMITH))
			then
				ETWCommonFunctions.addTraitToPlayer(CharacterTrait.BLACKSMITH)
				if notification then
					HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Blacksmith"), true, HaloTextHelper.getColorGreen())
				end
			end
		end
	end
	if
		(
			perk == "characterInitialization"
			or perk == Perks.PlantScavenging
			or perk == Perks.FlintKnapping
			or perk == Perks.Maintenance
			or perk == Perks.Carving
			or perk == CharacterTrait.WILDERNESS_KNOWLEDGE
		) and ETWCommonLogicChecks.WildernessKnowledgeShouldExecute()
	then
		if
			foraging >= 2
			and knapping >= 2
			and maintenance >= 2
			and carving >= 2
			and (foraging + knapping + maintenance + carving) >= SBvars.WildernessKnowledgeSkill
		then
			if
				SBvars.DelayedTraitsSystem
				and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable(CharacterTrait.WILDERNESS_KNOWLEDGE)
			then
				ETWCommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = CharacterTrait.WILDERNESS_KNOWLEDGE,
					player = player,
					positiveTrait = true,
					gainingTrait = true,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits(CharacterTrait.WILDERNESS_KNOWLEDGE))
			then
				ETWCommonFunctions.addTraitToPlayer(CharacterTrait.WILDERNESS_KNOWLEDGE)
				if notification then
					HaloTextHelper.addTextWithArrow(player, getText("UI_trait_WildernessKnowledge"), true, HaloTextHelper.getColorGreen())
				end
			end
		end
	end
	if
		(perk == "characterInitialization" or perk == Perks.Doctor or perk == CharacterTrait.FIRST_AID)
		and ETWCommonLogicChecks.FirstAidShouldExecute()
	then
		if firstAid >= SBvars.FirstAidSkill then
			if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable(CharacterTrait.FIRST_AID) then
				ETWCommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = CharacterTrait.FIRST_AID,
					player = player,
					positiveTrait = true,
					gainingTrait = true,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits(CharacterTrait.FIRST_AID))
			then
				ETWCommonFunctions.addTraitToPlayer(CharacterTrait.FIRST_AID)
				if notification then
					HaloTextHelper.addTextWithArrow(player, getText("UI_trait_FirstAid"), true, HaloTextHelper.getColorGreen())
				end
			end
		end
	end
	if
		(perk == "characterInitialization" or perk == Perks.Electricity or perk == ETWTraitsRegistry.AV_CLUB)
		and ETWCommonLogicChecks.AVClubShouldExecute()
	then
		if electrical >= SBvars.AVClubSkill then
			if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable(ETWTraitsRegistry.AV_CLUB) then
				ETWCommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = ETWTraitsRegistry.AV_CLUB,
					player = player,
					positiveTrait = true,
					gainingTrait = true,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits(ETWTraitsRegistry.AV_CLUB))
			then
				ETWCommonFunctions.addTraitToPlayer(ETWTraitsRegistry.AV_CLUB)
				if notification then
					HaloTextHelper.addTextWithArrow(player, getText("UI_trait_AVClub"), true, HaloTextHelper.getColorGreen())
				end
			end
		end
	end
	if
		(
			perk == "characterInitialization"
			or perk == Perks.MetalWelding
			or perk == Perks.Mechanics
			or perk == ETWTraitsRegistry.BODYWORK_ENTHUSIAST
		) and ETWCommonLogicChecks.BodyWorkEnthusiastShouldExecute()
	then
		ETWCombinedTraitChecks.bodyworkEnthusiastCheck(DebugAndNotificationArgs)
	end
	if
		(perk == "characterInitialization" or perk == Perks.Mechanics or perk == CharacterTrait.MECHANICS)
		and ETWCommonLogicChecks.MechanicsShouldExecute()
	then
		ETWCombinedTraitChecks.mechanicsCheck(DebugAndNotificationArgs)
	end
	if
		(perk == "characterInitialization" or perk == Perks.Tailoring or perk == CharacterTrait.TAILORED)
		and ETWCommonLogicChecks.SewerShouldExecute()
	then
		ETWCombinedTraitChecks.sewerCheck(DebugAndNotificationArgs)
	end
	if
		(
			perk == "characterInitialization"
			or perk == "kill"
			or perk == Perks.Aiming
			or perk == Perks.Reloading
			or perk == ETWTraitsRegistry.GUN_ENTHUSIAST
		) and ETWCommonLogicChecks.GunEnthusiastShouldExecute()
	then
		if (aiming + reloading) >= SBvars.GunEnthusiastSkill and firearmKills >= SBvars.GunEnthusiastKills then
			if
				SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable(ETWTraitsRegistry.GUN_ENTHUSIAST)
			then
				ETWCommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = ETWTraitsRegistry.GUN_ENTHUSIAST,
					player = player,
					positiveTrait = true,
					gainingTrait = true,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits(ETWTraitsRegistry.GUN_ENTHUSIAST))
			then
				ETWCommonFunctions.addTraitToPlayer(ETWTraitsRegistry.GUN_ENTHUSIAST)
				if notification then
					HaloTextHelper.addTextWithArrow(player, getText("UI_trait_GunEnthusiast"), true, HaloTextHelper.getColorGreen())
				end
			end
		end
	end
	if
		(perk == "characterInitialization" or perk == "kill" or perk == Perks.Fishing or perk == CharacterTrait.FISHING)
		and ETWCommonLogicChecks.AnglerShouldExecute()
	then
		if fishing >= SBvars.FishingSkill then
			if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable(CharacterTrait.FISHING) then
				ETWCommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = CharacterTrait.Fishing,
					player = player,
					positiveTrait = true,
					gainingTrait = true,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits(CharacterTrait.Fishing))
			then
				ETWCommonFunctions.addTraitToPlayer(CharacterTrait.Fishing)
				if notification then
					HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Fishing"), true, HaloTextHelper.getColorGreen())
				end
			end
		end
	end
	if
		(perk == "characterInitialization" or perk == Perks.Trapping or perk == Perks.PlantScavenging or perk == CharacterTrait.HIKER)
		and ETWCommonLogicChecks.HikerShouldExecute()
	then
		if (trapping + foraging) >= SBvars.HikerSkill then
			if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable(CharacterTrait.HIKER) then
				ETWCommonFunctions.addTraitToDelayTable({
					modData = modData,
					trait = CharacterTrait.HIKER,
					player = player,
					positiveTrait = true,
					gainingTrait = true,
				})
			elseif
				not SBvars.DelayedTraitsSystem
				or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits(CharacterTrait.HIKER))
			then
				ETWCommonFunctions.addTraitToPlayer(CharacterTrait.HIKER)
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
	local modData = ETWCommonFunctions.getETWModData(player)
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
	local player = getPlayer()
	traitsGainsBySkill(player, "kill")
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
end

---Function responsible for clearing events
---@param character IsoPlayer
local function clearEventsETW(character)
	Events.LevelPerk.Remove(traitsGainsBySkill)
	Events.EveryHours.Remove(progressDelayedTraits)
	Events.OnZombieDead.Remove(OnZombieDeadETW)
	if detailedDebug() then
		print("ETW Logger | System: clearEventsETW in ETWBySkills.lua")
	end
end

Events.OnCreatePlayer.Remove(initializeEventsETW)
Events.OnCreatePlayer.Add(initializeEventsETW)
Events.OnPlayerDeath.Remove(clearEventsETW)
Events.OnPlayerDeath.Add(clearEventsETW)
