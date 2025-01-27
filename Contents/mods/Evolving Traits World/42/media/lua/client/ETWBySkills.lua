require "ETWModData";
require "ETWModOptions";
local ETWCombinedTraitChecks = require "ETWCombinedTraitChecks";
local ETWCommonFunctions = require "ETWCommonFunctions";
local ETWCommonLogicChecks = require "ETWCommonLogicChecks";

---@type EvolvingTraitsWorldSandboxVars
local SBvars = SandboxVars.EvolvingTraitsWorld;

local modOptions;

---Function responsible for setting up mod options on character load
---@param playerIndex number
---@param player IsoPlayer
local function initializeModOptions(playerIndex, player)
	modOptions = PZAPI.ModOptions:getOptions("ETWModOptions");
end

Events.OnCreatePlayer.Remove(initializeModOptions);
Events.OnCreatePlayer.Add(initializeModOptions);

---@return boolean
local notification = function() return modOptions:getOption("EnableNotifications"):getValue() end
---@return boolean
local delayedNotification = function() return modOptions:getOption("EnableDelayedNotifications"):getValue() end
---@return boolean
local detailedDebug = function() return modOptions:getOption("GatherDetailedDebug"):getValue() end

---Prints out debugs inside console if detailedDebug is enabled
---@param ... string Strings to log
local logETW = function(...) ETWCommonFunctions.log(...) end

---Gain traits by skills (in majority cases)
---@param player IsoPlayer
---@param perk Perk|string
local function traitsGainsBySkill(player, perk)
	local modData = ETWCommonFunctions.getETWModData(player);

	-- locals for perk levels
	local strength = player:getPerkLevel(Perks.Strength);
	local fitness = player:getPerkLevel(Perks.Fitness);
	local sprinting = player:getPerkLevel(Perks.Sprinting);
	local lightfooted = player:getPerkLevel(Perks.Lightfoot);
	local nimble = player:getPerkLevel(Perks.Nimble);
	local sneaking = player:getPerkLevel(Perks.Sneak);
	local axe = player:getPerkLevel(Perks.Axe);
	local longBlunt = player:getPerkLevel(Perks.Blunt);
	local shortBlunt = player:getPerkLevel(Perks.SmallBlunt);
	local longBlade = player:getPerkLevel(Perks.LongBlade);
	local shortBlade = player:getPerkLevel(Perks.SmallBlade);
	local spear = player:getPerkLevel(Perks.Spear);
	local maintenance = player:getPerkLevel(Perks.Maintenance);
	local carpentry = player:getPerkLevel(Perks.Woodwork);
	local cooking = player:getPerkLevel(Perks.Cooking);
	local farming = player:getPerkLevel(Perks.Farming);
	local firstAid = player:getPerkLevel(Perks.Doctor);
	local electrical = player:getPerkLevel(Perks.Electricity);
	local metalworking = player:getPerkLevel(Perks.MetalWelding);
	local mechanics = player:getPerkLevel(Perks.Mechanics);
	local tailoring = player:getPerkLevel(Perks.Tailoring);
	local aiming = player:getPerkLevel(Perks.Aiming);
	local reloading = player:getPerkLevel(Perks.Reloading);
	local fishing = player:getPerkLevel(Perks.Fishing);
	local trapping = player:getPerkLevel(Perks.Trapping);
	local foraging = player:getPerkLevel(Perks.PlantScavenging);
	local husbandry = player:getPerkLevel(Perks.Husbandry);
	local carving = player:getPerkLevel(Perks.Carving);
	local blacksmith = player:getPerkLevel(Perks.Blacksmith);
	local knapping = player:getPerkLevel(Perks.FlintKnapping);


	-- locals for kills by category
	---@diagnostic disable-next-line: undefined-field
	local killCountModData = player:getModData().KillCount.WeaponCategory;
	local axeKills = killCountModData["Axe"].count;
	local longBluntKills = killCountModData["Blunt"].count;
	local shortBluntKills = killCountModData["SmallBlunt"].count;
	local longBladeKills = killCountModData["LongBlade"].count;
	local shortBladeKills = killCountModData["SmallBlade"].count;
	local spearKills = killCountModData["Spear"].count;
	local firearmKills = killCountModData["Firearm"].count;

	local detailedDebug = detailedDebug();
	local notification = notification();
	local delayedNotification = delayedNotification();

	---@type DebugAndNotificationArgs
	local DebugAndNotificationArgs = {detailedDebug = detailedDebug, notification = notification, delayedNotification = delayedNotification};

	if perk ~= "kill" and ETWCommonLogicChecks.LuckSystemShouldExecute() then
		local totalPerkLevel = 0;
		local totalMaxPerkLevel = 0;
		for i = 1, Perks.getMaxIndex() - 1 do
			local selectedPerk = Perks.fromIndex(i);
			if selectedPerk:getParent():getName() ~= "None" then
				logETW("ETW Logger | Lucky/Unlucky perks pickup: Perk: " .. selectedPerk:getName() .. ", parent: " .. selectedPerk:getParent():getName());
				local perkLevel = player:getPerkLevel(selectedPerk);
				totalPerkLevel = totalPerkLevel + perkLevel;
				totalMaxPerkLevel = totalMaxPerkLevel + 10;
			end
		end
		local percentageOfSkillLevels = totalPerkLevel / totalMaxPerkLevel * 100;
		if player:HasTrait("Unlucky") and percentageOfSkillLevels >= SBvars.LuckSystemSkill / 2 and SBvars.TraitsLockSystemCanLoseNegative then
			if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("Unlucky") then
				ETWCommonFunctions.addTraitToDelayTable(modData, "Unlucky", player, false);
			elseif not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("Unlucky")) then
				ETWCommonFunctions.removeTraitFromPlayer("Unlucky");
				if notification then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_unlucky"), false, HaloTextHelper.getColorGreen()) end
			end
		elseif not player:HasTrait("Unlucky") and not player:HasTrait("Lucky") and percentageOfSkillLevels >= SBvars.LuckSystemSkill and SBvars.TraitsLockSystemCanGainPositive then
			if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("Lucky") then
				ETWCommonFunctions.addTraitToDelayTable(modData, "Lucky", player, true);
				if delayedNotification then
					HaloTextHelper.addTextWithArrow(
						player,
						getText("UI_ETW_DelayedNotificationsStringAdd") .. getText("UI_trait_lucky"),
						true,
						HaloTextHelper.getColorGreen()
					);
				end
			elseif not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("Lucky")) then
				ETWCommonFunctions.addTraitToPlayer("Lucky");
				if notification then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_lucky"), true, HaloTextHelper.getColorGreen()) end
			end
		end
	end
	if (perk == "characterInitialization" or perk == Perks.Sprinting or perk == Perks.Lightfoot or perk == Perks.Nimble or perk == Perks.Sneak or perk == Perks.Axe or perk == Perks.Blunt or perk == Perks.SmallBlunt or perk == Perks.LongBlade or perk == Perks.SmallBlade or perk == Perks.Spear or perk =="HardOfHearing" or perk =="KeenHearing") and ETWCommonLogicChecks.HearingSystemShouldExecute() then
		local levels = sprinting + lightfooted + nimble + sneaking + axe + longBlunt + shortBlunt + longBlade + shortBlade + spear;
		if player:HasTrait("HardOfHearing") and levels >= SBvars.HearingSystemSkill / 2 and SBvars.TraitsLockSystemCanLoseNegative then
			if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("HardOfHearing") then
				ETWCommonFunctions.addTraitToDelayTable(modData, "HardOfHearing", player, false);
				if delayedNotification then
					HaloTextHelper.addTextWithArrow(
						player,
						getText("UI_ETW_DelayedNotificationsStringRemove") .. getText("UI_trait_hardhear"),
						true,
						HaloTextHelper.getColorGreen()
					);
				end
			elseif not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("HardOfHearing")) then
				ETWCommonFunctions.removeTraitFromPlayer("HardOfHearing");
				if notification then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_hardhear"), false, HaloTextHelper.getColorGreen()) end
			end
		elseif not player:HasTrait("HardOfHearing") and levels >= SBvars.HearingSystemSkill then
			if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("KeenHearing") then
				ETWCommonFunctions.addTraitToDelayTable(modData, "KeenHearing", player, true);
				if delayedNotification then
					HaloTextHelper.addTextWithArrow(
						player,
						getText("UI_ETW_DelayedNotificationsStringAdd") .. getText("UI_trait_keenhearing"),
						true,
						HaloTextHelper.getColorGreen()
					);
				end
			elseif not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("KeenHearing")) then
				ETWCommonFunctions.addTraitToPlayer("KeenHearing");
				if notification then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_keenhearing"), true, HaloTextHelper.getColorGreen()) end
			end
		end
	end
	if (perk == "characterInitialization" or perk == Perks.Strength or perk =="Hoarder") and ETWCommonLogicChecks.HoarderShouldExecute() then
		if strength >= SBvars.HoarderSkill then
			if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("Hoarder") then
				ETWCommonFunctions.addTraitToDelayTable(modData, "Hoarder", player, true);
				if delayedNotification then
					HaloTextHelper.addTextWithArrow(
						player,
						getText("UI_ETW_DelayedNotificationsStringAdd") .. getText("UI_trait_Hoarder"),
						true,
						HaloTextHelper.getColorGreen()
					);
				end
			elseif not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("Hoarder")) then
				ETWCommonFunctions.addTraitToPlayer("Hoarder");
				if notification then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Hoarder"), true, HaloTextHelper.getColorGreen()) end
			end
		end
	end
	if (perk == "characterInitialization" or perk == Perks.Strength or perk == Perks.Fitness or perk =="GymRat") and ETWCommonLogicChecks.GymRatShouldExecute() then
		if (strength + fitness) >= SBvars.GymRatSkill then
			if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("GymRat") then
				ETWCommonFunctions.addTraitToDelayTable(modData, "GymRat", player, true);
				if delayedNotification then
					HaloTextHelper.addTextWithArrow(
						player,
						getText("UI_ETW_DelayedNotificationsStringAdd") .. getText("UI_trait_GymRat"),
						true,
						HaloTextHelper.getColorGreen()
					);
				end
			elseif not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("GymRat")) then
				ETWCommonFunctions.addTraitToPlayer("GymRat");
				if notification then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_GymRat"), true, HaloTextHelper.getColorGreen()) end
			end
		end
	end
	if (perk == "characterInitialization" or perk == Perks.Sprinting or perk =="Jogger") and ETWCommonLogicChecks.RunnerShouldExecute() then
		if sprinting >= SBvars.RunnerSkill then
			if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("Jogger") then
				ETWCommonFunctions.addTraitToDelayTable(modData, "Jogger", player, true);
				if delayedNotification then
					HaloTextHelper.addTextWithArrow(
						player,
						getText("UI_ETW_DelayedNotificationsStringAdd") .. getText("UI_trait_Jogger"),
						true,
						HaloTextHelper.getColorGreen()
					);
				end
			elseif not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("Jogger")) then
				ETWCommonFunctions.addTraitToPlayer("Jogger");
				if notification then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Jogger"), true, HaloTextHelper.getColorGreen()) end
			end
		end
	end
	if (perk == "characterInitialization" or perk == Perks.Lightfoot or perk == "LightStep") and ETWCommonLogicChecks.LightStepShouldExecute() then
		if lightfooted >= SBvars.LightStepSkill then
			if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("LightStep") then
				ETWCommonFunctions.addTraitToDelayTable(modData, "LightStep", player, true);
				if delayedNotification then
					HaloTextHelper.addTextWithArrow(
						player,
						getText("UI_ETW_DelayedNotificationsStringAdd") .. getText("UI_trait_LightStep"),
						true,
						HaloTextHelper.getColorGreen()
					);
				end
			elseif not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("LightStep")) then
				ETWCommonFunctions.addTraitToPlayer("LightStep");
				if notification then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_LightStep"), true, HaloTextHelper.getColorGreen()) end
			end
		end
	end
	if (perk == "characterInitialization" or perk == Perks.Lightfoot or perk == Perks.Nimble or perk == "Gymnast") and ETWCommonLogicChecks.GymnastShouldExecute() then
		if (lightfooted + nimble) >= SBvars.GymnastSkill then
			if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("Gymnast") then
				ETWCommonFunctions.addTraitToDelayTable(modData, "Gymnast", player, true);
				if delayedNotification then
					HaloTextHelper.addTextWithArrow(
						player,
						getText("UI_ETW_DelayedNotificationsStringAdd") .. getText("UI_trait_Gymnast"),
						true,
						HaloTextHelper.getColorGreen()
					);
				end
			elseif not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("Gymnast")) then
				ETWCommonFunctions.addTraitToPlayer("Gymnast");
				if notification then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Gymnast"), true, HaloTextHelper.getColorGreen()) end
			end
		end
	end
	if (perk == "characterInitialization" or perk == Perks.Lightfoot or perk == Perks.Sneak or perk == "Clumsy") and ETWCommonLogicChecks.ClumsyShouldExecute() then
		if (lightfooted + sneaking) >= SBvars.ClumsySkill then
			if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("Clumsy") then
				ETWCommonFunctions.addTraitToDelayTable(modData, "Clumsy", player, false);
				if delayedNotification then
					HaloTextHelper.addTextWithArrow(
						player,
						getText("UI_ETW_DelayedNotificationsStringRemove") .. getText("UI_trait_clumsy"),
						true,
						HaloTextHelper.getColorGreen()
					);
				end
			elseif not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("Clumsy")) then
				ETWCommonFunctions.removeTraitFromPlayer("Clumsy");
				if notification then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_clumsy"), false, HaloTextHelper.getColorGreen()) end
			end
		end
	end
	if (perk == "characterInitialization" or perk == Perks.Nimble or perk == Perks.Sneak or perk == Perks.Lightfoot or perk == "Graceful")
	and ETWCommonLogicChecks.GracefulShouldExecute() then
		local levels = nimble + sneaking + lightfooted;
		if levels >= SBvars.GracefulSkill then
			if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("Graceful") then
				ETWCommonFunctions.addTraitToDelayTable(modData, "Graceful", player, true);
				if delayedNotification then
					HaloTextHelper.addTextWithArrow(
						player,
						getText("UI_ETW_DelayedNotificationsStringAdd") .. getText("UI_trait_graceful"),
						true,
						HaloTextHelper.getColorGreen()
					);
				end
			elseif not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("Graceful")) then
				ETWCommonFunctions.addTraitToPlayer("Graceful");
				if notification then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_graceful"), true, HaloTextHelper.getColorGreen()) end
			end
		end
	end
	if (perk == "characterInitialization" or perk == Perks.Nimble or perk == Perks.Mechanics or perk == Perks.Electricity or perk == "Burglar")
	and ETWCommonLogicChecks.BurglarShouldExecute() then
		local levels = nimble + mechanics + electrical;
		if electrical >= 2 and mechanics >= 2 and levels >= SBvars.BurglarSkill then
			if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("Burglar") then
				ETWCommonFunctions.addTraitToDelayTable(modData, "Burglar", player, true);
				if delayedNotification then
					HaloTextHelper.addTextWithArrow(
						player,
						getText("UI_ETW_DelayedNotificationsStringAdd") .. getText("UI_prof_Burglar"),
						true,
						HaloTextHelper.getColorGreen()
					);
				end
			elseif not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("Burglar")) then
				ETWCommonFunctions.addTraitToPlayer("Burglar");
				if notification then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Burglar"), true, HaloTextHelper.getColorGreen()) end
			end
		end
	end
	if (perk == "characterInitialization" or perk == Perks.Sneak or perk == "LowProfile") and ETWCommonLogicChecks.LowProfileShouldExecute() then
		if sneaking >= SBvars.LowProfileSkill then
			if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("LowProfile") then
				ETWCommonFunctions.addTraitToDelayTable(modData, "LowProfile", player, true);
				if delayedNotification then
					HaloTextHelper.addTextWithArrow(
						player,
						getText("UI_ETW_DelayedNotificationsStringAdd") .. getText("UI_trait_LowProfile"),
						true,
						HaloTextHelper.getColorGreen()
					);
				end
			elseif not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("LowProfile")) then
				ETWCommonFunctions.addTraitToPlayer("LowProfile");
				if notification then HaloTextHelper.addTextWithArrow(
					player,
					getText("UI_trait_LowProfile"),
					true,
					HaloTextHelper.getColorGreen()
					);
				end
			end
		end
	end
	if perk == "characterInitialization" or perk == Perks.Sneak or perk == "Conspicuous" or perk == "Inconspicuous" then
		if ETWCommonLogicChecks.ConspicuousShouldExecute() and sneaking >= SBvars.ConspicuousSkill then
			if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("Conspicuous") then
				ETWCommonFunctions.addTraitToDelayTable(modData, "Conspicuous", player, false);
				if delayedNotification then
					HaloTextHelper.addTextWithArrow(
						player,
						getText("UI_ETW_DelayedNotificationsStringRemove") .. getText("UI_trait_Conspicuous"),
						true,
						HaloTextHelper.getColorGreen()
					);
				end
			elseif not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("Conspicuous")) then
				ETWCommonFunctions.removeTraitFromPlayer("Conspicuous");
				if notification then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Conspicuous"), false, HaloTextHelper.getColorGreen()) end
			end
		elseif ETWCommonLogicChecks.InconspicuousShouldExecute() and sneaking >= SBvars.InconspicuousSkill then
			if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("Inconspicuous") then
				ETWCommonFunctions.addTraitToDelayTable(modData, "Inconspicuous", player, true);
				if delayedNotification then
					HaloTextHelper.addTextWithArrow(
						player,
						getText("UI_ETW_DelayedNotificationsStringAdd") .. getText("UI_trait_Inconspicuous"),
						true,
						HaloTextHelper.getColorGreen()
					);
				end
			elseif not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("Inconspicuous")) then
				ETWCommonFunctions.addTraitToPlayer("Inconspicuous");
				if notification then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Inconspicuous"), true, HaloTextHelper.getColorGreen()) end
			end
		end
	end
	if (perk == "characterInitialization" or perk == "kill" or perk == Perks.Sneak or perk == Perks.Aiming or perk == Perks.Trapping or perk == Perks.SmallBlade or perk == "Hunter")
	and ETWCommonLogicChecks.HunterShouldExecute() then
		local levels = sneaking + aiming + trapping + shortBlade;
		if sneaking >= 2 and aiming >= 2 and trapping >= 2 and shortBlade >= 2
		and levels >= SBvars.HunterSkill and (shortBladeKills + firearmKills) >= SBvars.HunterKills then
			if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("Hunter") then
				ETWCommonFunctions.addTraitToDelayTable(modData, "Hunter", player, true);
				if delayedNotification then
					HaloTextHelper.addTextWithArrow(
						player,
						getText("UI_ETW_DelayedNotificationsStringAdd") .. getText("UI_trait_Hunter"),
						true,
						HaloTextHelper.getColorGreen()
					);
				end
			elseif not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("Hunter")) then
				ETWCommonFunctions.addTraitToPlayer("Hunter");
				if notification then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Hunter"), true, HaloTextHelper.getColorGreen()) end
			end
		end
	end
	if (perk == "characterInitialization" or perk == "kill" or perk == Perks.Axe or perk == Perks.Blunt or perk == "Brawler")
	and ETWCommonLogicChecks.BrawlerShouldExecute() then
		if (axe + longBlunt) >= SBvars.BrawlerSkill and (axeKills + longBluntKills) >= SBvars.BrawlerKills then
			if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("Brawler") then
				ETWCommonFunctions.addTraitToDelayTable(modData, "Brawler", player, true);
				if delayedNotification then
					HaloTextHelper.addTextWithArrow(
						player,
						getText("UI_ETW_DelayedNotificationsStringAdd") .. getText("UI_trait_BarFighter"),
						true,
						HaloTextHelper.getColorGreen()
					);
				end
			elseif not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("Brawler")) then
				ETWCommonFunctions.addTraitToPlayer("Brawler");
				if notification then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_BarFighter"), true, HaloTextHelper.getColorGreen()) end
			end
		end
	end
	if (perk == "characterInitialization" or perk == "kill" or perk == Perks.Axe or perk == "AxeThrower") and ETWCommonLogicChecks.AxeThrowerShouldExecute() then
		if axe >= SBvars.AxeThrowerSkill and axeKills >= SBvars.AxeThrowerKills then
			if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("AxeThrower") then
				ETWCommonFunctions.addTraitToDelayTable(modData, "AxeThrower", player, true);
				if delayedNotification then
					HaloTextHelper.addTextWithArrow(
						player,
						getText("UI_ETW_DelayedNotificationsStringAdd") .. getText("UI_trait_AxeThrower"),
						true,
						HaloTextHelper.getColorGreen()
					);
				end
			elseif not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("AxeThrower")) then
				ETWCommonFunctions.addTraitToPlayer("AxeThrower");
				if notification then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_AxeThrower"), true, HaloTextHelper.getColorGreen()) end
			end
		end
	end
	if (perk == "characterInitialization" or perk == "kill" or perk == Perks.Blunt or perk == "BaseballPlayer")
	and ETWCommonLogicChecks.BaseballPlayerShouldExecute() then
		if longBlunt >= SBvars.BaseballPlayerSkill and longBluntKills >= SBvars.BaseballPlayerKills then
			if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("BaseballPlayer") then
				ETWCommonFunctions.addTraitToDelayTable(modData, "BaseballPlayer", player, true);
				if delayedNotification then
					HaloTextHelper.addTextWithArrow(
						player,
						getText("UI_ETW_DelayedNotificationsStringAdd") .. getText("UI_trait_PlaysBaseball"),
						true,
						HaloTextHelper.getColorGreen()
					);
				end
			elseif not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("BaseballPlayer")) then
				ETWCommonFunctions.addTraitToPlayer("BaseballPlayer");
				if notification then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_PlaysBaseball"), true, HaloTextHelper.getColorGreen()) end
			end
		end
	end
	if (perk == "characterInitialization" or perk == "kill" or perk == Perks.SmallBlunt or perk == "StickFighter")
	and ETWCommonLogicChecks.StickFighterShouldExecute() then
		if shortBlunt >= SBvars.StickFighterSkill and shortBluntKills >= SBvars.StickFighterKills then
			if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("StickFighter") then
				ETWCommonFunctions.addTraitToDelayTable(modData, "StickFighter", player, true);
				if delayedNotification then
					HaloTextHelper.addTextWithArrow(
						player,
						getText("UI_ETW_DelayedNotificationsStringAdd") .. getText("UI_trait_StickFighter"),
						true,
						HaloTextHelper.getColorGreen()
					);
				end
			elseif not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("StickFighter")) then
				ETWCommonFunctions.addTraitToPlayer("StickFighter");
				if notification then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_StickFighter"), true, HaloTextHelper.getColorGreen()) end
			end
		end
	end
	if (perk == "characterInitialization" or perk == "kill" or perk == Perks.LongBlade or perk == "BladeEnthusiast")
	and ETWCommonLogicChecks.BladeEnthusiastShouldExecute() then
		if longBlade >= SBvars.BladeEnthusiastSkill and longBladeKills >= SBvars.BladeEnthusiastKills then
			if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("BladeEnthusiast") then
				ETWCommonFunctions.addTraitToDelayTable(modData, "BladeEnthusiast", player, true);
				if delayedNotification then
					HaloTextHelper.addTextWithArrow(
						player,
						getText("UI_ETW_DelayedNotificationsStringAdd") .. getText("UI_trait_BladeEnthusiast"),
						true,
						HaloTextHelper.getColorGreen()
					);
				end
			elseif not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("BladeEnthusiast")) then
				ETWCommonFunctions.addTraitToPlayer("BladeEnthusiast");
				if notification then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_BladeEnthusiast"), true, HaloTextHelper.getColorGreen()) end
			end
		end
	end
	if (perk == "characterInitialization" or perk == "kill" or perk == Perks.SmallBlade or perk == "KnifeFighter") and ETWCommonLogicChecks.KnifeFighterShouldExecute() then
		if shortBlade >= SBvars.KnifeFighterSkill and shortBladeKills >= SBvars.KnifeFighterKills then
			if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("KnifeFighter") then
				ETWCommonFunctions.addTraitToDelayTable(modData, "KnifeFighter", player, true);
				if delayedNotification then
					HaloTextHelper.addTextWithArrow(
						player,
						getText("UI_ETW_DelayedNotificationsStringAdd") .. getText("UI_trait_KnifeFighter"),
						true,
						HaloTextHelper.getColorGreen()
					);
				end
			elseif not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("KnifeFighter")) then
				ETWCommonFunctions.addTraitToPlayer("KnifeFighter");
				if notification then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_KnifeFighter"), true, HaloTextHelper.getColorGreen()) end
			end
		end
	end
	if (perk == "characterInitialization" or perk == "kill" or perk == Perks.Spear or perk == "PolearmFighter") and ETWCommonLogicChecks.PolearmFighterShouldExecute() then
		if spear >= SBvars.PolearmFighterSkill and spearKills >= SBvars.PolearmFighterKills then
			if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("PolearmFighter") then
				ETWCommonFunctions.addTraitToDelayTable(modData, "PolearmFighter", player, true);
				if delayedNotification then
					HaloTextHelper.addTextWithArrow(
						player,
						getText("UI_ETW_DelayedNotificationsStringAdd") .. getText("UI_trait_PolearmFighter"),
						true,
						HaloTextHelper.getColorGreen()
					);
				end
			elseif not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("PolearmFighter")) then
				ETWCommonFunctions.addTraitToPlayer("PolearmFighter");
				if notification then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_PolearmFighter"), true, HaloTextHelper.getColorGreen()) end
			end
		end
	end
	if (perk == "characterInitialization" or perk == Perks.Maintenance or perk == "RestorationExpert") and ETWCommonLogicChecks.RestorationExpertShouldExecute() then
		if maintenance >= SBvars.RestorationExpertSkill then
			if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("RestorationExpert") then
				ETWCommonFunctions.addTraitToDelayTable(modData, "RestorationExpert", player, true);
				if delayedNotification then
					HaloTextHelper.addTextWithArrow(
						player,
						getText("UI_ETW_DelayedNotificationsStringAdd") .. getText("UI_trait_RestorationExpert"),
						true,
						HaloTextHelper.getColorGreen()
					);
				end;
			elseif not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("RestorationExpert")) then
				ETWCommonFunctions.addTraitToPlayer("RestorationExpert");
				if notification then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_RestorationExpert"), true, HaloTextHelper.getColorGreen()) end
			end
		end
	end
	if (perk == "characterInitialization" or perk == Perks.Maintenance or perk == Perks.Woodwork or perk == "Handy") and ETWCommonLogicChecks.HandyShouldExecute() then
		if (maintenance + carpentry) >= SBvars.HandySkill then
			if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("Handy") then
				ETWCommonFunctions.addTraitToDelayTable(modData, "Handy", player, true);
				if delayedNotification then
					HaloTextHelper.addTextWithArrow(
						player,
						getText("UI_ETW_DelayedNotificationsStringAdd") .. getText("UI_trait_handy"),
						true,
						HaloTextHelper.getColorGreen()
					);
				end
			elseif not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("Handy")) then
				ETWCommonFunctions.addTraitToPlayer("Handy");
				if notification then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_handy"), true, HaloTextHelper.getColorGreen()) end
			end
		end
	end
	if (perk == "characterInitialization" or perk == Perks.Maintenance or perk == Perks.Woodwork or perk == Perks.Cooking
	or perk == Perks.Farming or perk == Perks.Doctor or perk == Perks.Electricity or perk == Perks.MetalWelding or perk == Perks.Mechanics
	or perk == Perks.Tailoring or perk == "SlowLearner" or perk == "FastLearner") and ETWCommonLogicChecks.LearnerSystemShouldExecute() then
		local levels = maintenance + carpentry + farming + firstAid + electrical + metalworking + mechanics + tailoring + cooking;
		if player:HasTrait("SlowLearner") and levels >= SBvars.LearnerSystemSkill / 2 and SBvars.TraitsLockSystemCanLoseNegative then
			if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("SlowLearner") then
				ETWCommonFunctions.addTraitToDelayTable(modData, "SlowLearner", player, false);
				if delayedNotification then
					HaloTextHelper.addTextWithArrow(
						player,
						getText("UI_ETW_DelayedNotificationsStringRemove") .. getText("UI_trait_SlowLearner"),
						true,
						HaloTextHelper.getColorGreen()
					);
				end
			elseif not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("SlowLearner")) then
				ETWCommonFunctions.removeTraitFromPlayer("SlowLearner");
				if notification then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_SlowLearner"), false, HaloTextHelper.getColorGreen()) end
			end
		elseif not player:HasTrait("SlowLearner") and levels >= SBvars.LearnerSystemSkill and SBvars.TraitsLockSystemCanGainPositive then
			if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("FastLearner") then
				ETWCommonFunctions.addTraitToDelayTable(modData, "FastLearner", player, true);
				if delayedNotification then
					HaloTextHelper.addTextWithArrow(
						player,
						getText("UI_ETW_DelayedNotificationsStringAdd") .. getText("UI_trait_FastLearner"),
						true,
						HaloTextHelper.getColorGreen()
					);
				end
			elseif not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("FastLearner")) then
				ETWCommonFunctions.addTraitToPlayer("FastLearner");
				if notification then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_FastLearner"), true, HaloTextHelper.getColorGreen()) end
			end
		end
	end
	if (perk == "characterInitialization" or perk == Perks.Woodwork or perk == "FurnitureAssembler") and ETWCommonLogicChecks.FurnitureAssemblerShouldExecute() then
		if carpentry >= SBvars.FurnitureAssemblerSkill then
			if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("FurnitureAssembler") then
				ETWCommonFunctions.addTraitToDelayTable(modData, "FurnitureAssembler", player, true);
				if delayedNotification then
					HaloTextHelper.addTextWithArrow(
						player,
						getText("UI_ETW_DelayedNotificationsStringAdd") .. getText("UI_trait_FurnitureAssembler"),
						true,
						HaloTextHelper.getColorGreen()
					);
				end
			elseif not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("FurnitureAssembler")) then
				ETWCommonFunctions.addTraitToPlayer("FurnitureAssembler");
				if notification then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_FurnitureAssembler"), true, HaloTextHelper.getColorGreen()) end
			end
		end
	end
	if (perk == "characterInitialization" or perk == Perks.Cooking or perk == "HomeCook") and ETWCommonLogicChecks.HomeCookShouldExecute() then
		if cooking >= SBvars.HomeCookSkill then
			if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("HomeCook") then
				ETWCommonFunctions.addTraitToDelayTable(modData, "HomeCook", player, true);
				if delayedNotification then
					HaloTextHelper.addTextWithArrow(
						player,
						getText("UI_ETW_DelayedNotificationsStringAdd") .. getText("UI_trait_HomeCook"),
						true,
						HaloTextHelper.getColorGreen()
					);
				end
			elseif not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("HomeCook")) then
				ETWCommonFunctions.addTraitToPlayer("HomeCook");
				if notification then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_HomeCook"), true, HaloTextHelper.getColorGreen()) end
			end
		end
	end
	if (perk == "characterInitialization" or perk == Perks.Cooking or perk == "Cook") and ETWCommonLogicChecks.CookShouldExecute() then
		if cooking >= SBvars.CookSkill then
			if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("Cook") then
				ETWCommonFunctions.addTraitToDelayTable(modData, "Cook", player, true);
				if delayedNotification then
					HaloTextHelper.addTextWithArrow(
						player,
						getText("UI_ETW_DelayedNotificationsStringAdd") .. getText("UI_trait_Cook"),
						true,
						HaloTextHelper.getColorGreen()
					);
				end
			elseif not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("Cook")) then
				ETWCommonFunctions.addTraitToPlayer("Cook");
				if notification then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Cook"), true, HaloTextHelper.getColorGreen()) end
			end
		end
	end
	if (perk == "characterInitialization" or perk == Perks.Farming or perk == "Gardener") and ETWCommonLogicChecks.GardenerShouldExecute() then
		if farming >= SBvars.GardenerSkill then
			if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("Gardener") then
				ETWCommonFunctions.addTraitToDelayTable(modData, "Gardener", player, true);
				if delayedNotification then
					HaloTextHelper.addTextWithArrow(
						player,
						getText("UI_ETW_DelayedNotificationsStringAdd") .. getText("UI_trait_Gardener"),
						true,
						HaloTextHelper.getColorGreen()
					);
				end
			elseif not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("Gardener")) then
				ETWCommonFunctions.addTraitToPlayer("Gardener");
				if notification then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Gardener"), true, HaloTextHelper.getColorGreen()) end
			end
		end
	end
	if (perk == "characterInitialization" or perk == Perks.Husbandry or perk == "PetTherapy") and ETWCommonLogicChecks.PetTherapyShouldExecute() then
		if husbandry >= SBvars.PetTherapySkill and #modData.AnimalsSystem.UniqueAnimalsPetted >= SBvars.PetTherapyUniqueAnimalsPetted then
			if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("PetTherapy") then
				ETWCommonFunctions.addTraitToDelayTable(modData, "PetTherapy", player, true);
				if delayedNotification then
					HaloTextHelper.addTextWithArrow(
						player,
						getText("UI_ETW_DelayedNotificationsStringAdd") .. getText("UI_trait_PetTherapy"),
						true,
						HaloTextHelper.getColorGreen()
					);
				end
			elseif not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("PetTherapy")) then
				ETWCommonFunctions.addTraitToPlayer("PetTherapy");
				if notification then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_PetTherapy"), true, HaloTextHelper.getColorGreen()) end
			end
		end
	end
	if (perk == "characterInitialization" or perk == Perks.Carving or perk == "Whittler") and ETWCommonLogicChecks.WhittlerShouldExecute() then
		if carving >= SBvars.WhittlerSkill then
			if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("Whittler") then
				ETWCommonFunctions.addTraitToDelayTable(modData, "Whittler", player, true);
				if delayedNotification then
					HaloTextHelper.addTextWithArrow(
						player,
						getText("UI_ETW_DelayedNotificationsStringAdd") .. getText("UI_trait_Whittler"),
						true,
						HaloTextHelper.getColorGreen()
					);
				end
			elseif not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("Whittler")) then
				ETWCommonFunctions.addTraitToPlayer("Whittler");
				if notification then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Whittler"), true, HaloTextHelper.getColorGreen()) end
			end
		end
	end
	if (perk == "characterInitialization" or perk == Perks.Blacksmith or perk == Perks.Maintenance or perk == "Blacksmith") and ETWCommonLogicChecks.BlacksmithShouldExecute() then
		if blacksmith + maintenance >= SBvars.BlacksmithSkill then
			if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("Blacksmith") then
				ETWCommonFunctions.addTraitToDelayTable(modData, "Blacksmith", player, true);
				if delayedNotification then
					HaloTextHelper.addTextWithArrow(
						player,
						getText("UI_ETW_DelayedNotificationsStringAdd") .. getText("UI_trait_Blacksmith"),
						true,
						HaloTextHelper.getColorGreen()
					);
				end
			elseif not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("Blacksmith")) then
				ETWCommonFunctions.addTraitToPlayer("Blacksmith");
				if notification then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Blacksmith"), true, HaloTextHelper.getColorGreen()) end
			end
		end
	end
	if (perk == "characterInitialization" or perk == Perks.PlantScavenging or perk == Perks.FlintKnapping or perk == Perks.Maintenance
	or perk == Perks.Carving or perk == "WildernessKnowledge") and ETWCommonLogicChecks.WildernessKnowledgeShouldExecute() then
    		if foraging >= 2 and knapping >= 2 and maintenance >= 2 and carving >= 2
    		and (foraging + knapping + maintenance + carving) >= SBvars.WildernessKnowledge then
    			if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("WildernessKnowledge") then
    				ETWCommonFunctions.addTraitToDelayTable(modData, "WildernessKnowledge", player, true);
    				if delayedNotification then
    					HaloTextHelper.addTextWithArrow(
    						player,
    						getText("UI_ETW_DelayedNotificationsStringAdd") .. getText("UI_trait_WildernessKnowledge"),
    						true,
    						HaloTextHelper.getColorGreen()
    					);
    				end
    			elseif not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("WildernessKnowledge")) then
    				ETWCommonFunctions.addTraitToPlayer("WildernessKnowledge");
    				if notification then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_WildernessKnowledge"), true, HaloTextHelper.getColorGreen()) end
    			end
    		end
    	end
	if (perk == "characterInitialization" or perk == Perks.Doctor or perk == "FirstAid") and ETWCommonLogicChecks.FirstAidShouldExecute() then
		if firstAid >= SBvars.FirstAidSkill then
			if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("FirstAid") then
				ETWCommonFunctions.addTraitToDelayTable(modData, "FirstAid", player, true);
				if delayedNotification then
					HaloTextHelper.addTextWithArrow(
						player,
						getText("UI_ETW_DelayedNotificationsStringAdd") .. getText("UI_trait_FirstAid"),
						true,
						HaloTextHelper.getColorGreen()
					);
				end
			elseif not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("FirstAid")) then
				ETWCommonFunctions.addTraitToPlayer("FirstAid");
				if notification then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_FirstAid"), true, HaloTextHelper.getColorGreen()) end
			end
		end
	end
	if (perk == "characterInitialization" or perk == Perks.Electricity or perk == "AVClub") and ETWCommonLogicChecks.AVClubShouldExecute() then
		if electrical >= SBvars.AVClubSkill then
			if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("AVClub") then
				ETWCommonFunctions.addTraitToDelayTable(modData, "AVClub", player, true);
				if delayedNotification then
					HaloTextHelper.addTextWithArrow(
						player,
						getText("UI_ETW_DelayedNotificationsStringAdd") .. getText("UI_trait_AVClub"),
						true,
						HaloTextHelper.getColorGreen()
					);
				end
			elseif not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("AVClub")) then
				ETWCommonFunctions.addTraitToPlayer("AVClub");
				if notification then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_AVClub"), true, HaloTextHelper.getColorGreen()) end
			end
		end
	end
	if (perk == "characterInitialization" or perk == Perks.MetalWelding  or perk == Perks.Mechanics or perk == "BodyWorkEnthusiast")
	and ETWCommonLogicChecks.BodyWorkEnthusiastShouldExecute() then
		ETWCombinedTraitChecks.bodyworkEnthusiastCheck(DebugAndNotificationArgs);
	end
	if (perk == "characterInitialization" or perk == Perks.Mechanics or perk == "Mechanics")
	and ETWCommonLogicChecks.MechanicsShouldExecute() then
		ETWCombinedTraitChecks.mechanicsCheck(DebugAndNotificationArgs);
	end
	if (perk == "characterInitialization" or perk == Perks.Tailoring or perk == "Tailor")
	and ETWCommonLogicChecks.SewerShouldExecute() then
		ETWCombinedTraitChecks.sewerCheck(DebugAndNotificationArgs);
	end
	if (perk == "characterInitialization" or perk == "kill" or perk == Perks.Aiming or perk == Perks.Reloading or perk == "GunEnthusiast")
	and ETWCommonLogicChecks.GunEnthusiastShouldExecute() then
		if (aiming + reloading) >= SBvars.GunEnthusiastSkill and firearmKills >= SBvars.GunEnthusiastKills then
			if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("GunEnthusiast") then
				ETWCommonFunctions.addTraitToDelayTable(modData, "GunEnthusiast", player, true);
				if delayedNotification then
					HaloTextHelper.addTextWithArrow(
						player,
						getText("UI_ETW_DelayedNotificationsStringAdd") .. getText("UI_trait_GunEnthusiast"),
						true,
						HaloTextHelper.getColorGreen()
					);
				end
			elseif not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("GunEnthusiast")) then
				ETWCommonFunctions.addTraitToPlayer("GunEnthusiast");
				if notification then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_GunEnthusiast"), true, HaloTextHelper.getColorGreen()) end
			end
		end
	end
	if (perk == "characterInitialization" or perk == "kill" or perk == Perks.Fishing or perk == "Fishing") and ETWCommonLogicChecks.AnglerShouldExecute() then
		if fishing >= SBvars.FishingSkill then
			if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("Fishing") then
				ETWCommonFunctions.addTraitToDelayTable(modData, "Fishing", player, true);
				if delayedNotification then
					HaloTextHelper.addTextWithArrow(
						player,
						getText("UI_ETW_DelayedNotificationsStringAdd") .. getText("UI_trait_Fishing"),
						true,
						HaloTextHelper.getColorGreen()
					);
				end
			elseif not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("Fishing")) then
				ETWCommonFunctions.addTraitToPlayer("Fishing");
				if notification then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Fishing"), true, HaloTextHelper.getColorGreen()) end
			end
		end
	end
	if (perk == "characterInitialization" or perk == Perks.Trapping or perk == Perks.PlantScavenging or perk == "Hiker") and ETWCommonLogicChecks.HikerShouldExecute() then
		if (trapping + foraging) >= SBvars.HikerSkill then
			if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("Hiker") then
				ETWCommonFunctions.addTraitToDelayTable(modData, "Hiker", player, true);
				if delayedNotification then
					HaloTextHelper.addTextWithArrow(
						player,
						getText("UI_ETW_DelayedNotificationsStringAdd") .. getText("UI_trait_Hiker"),
						true,
						HaloTextHelper.getColorGreen()
					);
				end
			elseif not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("Hiker")) then
				ETWCommonFunctions.addTraitToPlayer("Hiker");
				if notification then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Hiker"), true, HaloTextHelper.getColorGreen()) end
			end
		end
	end
	modData.DelayedStartingTraitsFilled = true;
end

---Function responsible for hourly check on Delayed Traits system
local function progressDelayedTraits()
	local player = getPlayer();
	local modData = ETWCommonFunctions.getETWModData(player);
	local traitTable = modData.DelayedTraits;
	logETW("ETW Logger | Delayed Traits System: new progressDelayedTraits() execution ----------");
	for index, traitEntry in ipairs(traitTable) do
		local traitName, traitValue, gained = traitEntry[1], traitEntry[2], traitEntry[3];
		if not gained then
			local randomValue = ZombRand(traitValue + 1);
			if randomValue == 0 then
				traitTable[index][3] = true;
				logETW("ETW Logger | Delayed Traits System: rolled to get " .. traitName .. ": rolled 0 from 0-" .. traitTable[index][2],
					"ETW Logger | Delayed Traits System: " .. traitName .. " in traitTable[" .. index .. "][3]" .. " set to " .. tostring(traitTable[index][3]),
					"ETW Logger | Delayed Traits System: running traitsGainsBySkill(player, " .. traitName .. ")"
				);
				traitsGainsBySkill(player, traitName);
			elseif randomValue > 0 then
				logETW("ETW Logger | Delayed Traits System: rolled to get " .. traitName .. ": rolled " .. randomValue .. " from 0-" .. traitTable[index][2]);
				traitTable[index][2] = traitValue - 1;
			end
		end
	end
	logETW("ETW Logger | Delayed Traits System: finished progressDelayedTraits() execution ----------");
end

---Function responsible for firing check on all kill-related traits
---@param zombie IsoZombie
local function OnZombieDeadETW(zombie)
	local player = getPlayer();
	traitsGainsBySkill(player, "kill");
end

---Function responsible for setting up events
---@param playerIndex number
---@param player IsoPlayer
local function initializeEventsETW(playerIndex, player)
	if SBvars.TraitsLockSystemCanGainPositive or SBvars.TraitsLockSystemCanLoseNegative then
		traitsGainsBySkill(player, "characterInitialization");
		Events.LevelPerk.Remove(traitsGainsBySkill);
		Events.LevelPerk.Add(traitsGainsBySkill);
		Events.EveryHours.Remove(progressDelayedTraits);
		if SBvars.DelayedTraitsSystem then Events.EveryHours.Add(progressDelayedTraits) end
		Events.OnZombieDead.Remove(OnZombieDeadETW);
		if SBvars.TraitsLockSystemCanGainPositive then Events.OnZombieDead.Add(OnZombieDeadETW) end
	end
end

---Function responsible for clearing events
---@param character IsoPlayer
local function clearEventsETW(character)
	Events.LevelPerk.Remove(traitsGainsBySkill);
	Events.EveryHours.Remove(progressDelayedTraits);
	Events.OnZombieDead.Remove(OnZombieDeadETW);
	if detailedDebug() then print("ETW Logger | System: clearEventsETW in ETWBySkills.lua") end
end

Events.OnCreatePlayer.Remove(initializeEventsETW);
Events.OnCreatePlayer.Add(initializeEventsETW);
Events.OnPlayerDeath.Remove(clearEventsETW);
Events.OnPlayerDeath.Add(clearEventsETW);
