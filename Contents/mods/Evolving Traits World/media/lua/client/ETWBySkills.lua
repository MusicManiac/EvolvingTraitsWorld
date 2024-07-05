require "ETWModData";
local ETWActionsOverride = require "TimedActions/ETWActionsOverride";
local ETWCommonFunctions = require "ETWCommonFunctions";
local ETWCommonLogicChecks = require "ETWCommonLogicChecks";

local SBvars = SandboxVars.EvolvingTraitsWorld;
local notification = function() return EvolvingTraitsWorld.settings.EnableNotifications end
local delayedNotification = function() return EvolvingTraitsWorld.settings.EnableDelayedNotifications end
local detailedDebug = function() return EvolvingTraitsWorld.settings.GatherDetailedDebug end

local function applyXPBoost(player, perk, boostLevel)
	local newBoost = player:getXp():getPerkBoost(perk) + boostLevel;
	if newBoost > 3 then
		player:getXp():setPerkBoost(perk, 3);
	else
		player:getXp():setPerkBoost(perk, newBoost);
	end
end

local function addRecipe(player, recipe)
	local playerRecipes = player:getKnownRecipes();
	if not playerRecipes:contains(recipe) then
		playerRecipes:add(recipe);
	end
end

local function traitsGainsBySkill(player, perk)
	if player:getModData().EvolvingTraitsWorld == nil then return end
	player = getPlayer();
	local modData = player:getModData().EvolvingTraitsWorld;
	local activatedMods = getActivatedMods();

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


	-- locals for kills by category
	local killCountModData = player:getModData().KillCount.WeaponCategory;
	local axeKills = killCountModData["Axe"].count;
	local longBluntKills = killCountModData["Blunt"].count;
	local shortBluntKills = killCountModData["SmallBlunt"].count;
	local longBladeKills = killCountModData["LongBlade"].count;
	local shortBladeKills = killCountModData["SmallBlade"].count;
	local spearKills = killCountModData["Spear"].count;
	local firearmKills = killCountModData["Firearm"].count;

	-- All Perks
		-- Unlucky/Lucky
				if ETWCommonLogicChecks.LuckSystemShouldExecute() then
					local totalPerkLevel = 0
					local totalMaxPerkLevel = 0;
					for i = 1, Perks.getMaxIndex() - 1 do
						local selectedPerk = Perks.fromIndex(i)
						if selectedPerk:getParent():getName() ~= "None" then
							if detailedDebug() then print("ETW Logger | Lucky/Unlucky perks pickup: Perk: "..selectedPerk:getName()..", parent: "..selectedPerk:getParent():getName()) end
							local perkLevel = player:getPerkLevel(selectedPerk)
							totalPerkLevel = totalPerkLevel + perkLevel;
							totalMaxPerkLevel = totalMaxPerkLevel + 10;
						end
					end
					local percentageOfSkillLevels = totalPerkLevel / totalMaxPerkLevel * 100;
					if player:HasTrait("Unlucky") and percentageOfSkillLevels >= SBvars.LuckSystemSkill / 2 and SBvars.TraitsLockSystemCanLoseNegative then
						if not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("Unlucky")) then
							player:getTraits():remove("Unlucky");
							if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_unlucky"), false, HaloTextHelper.getColorGreen()) end
						end
						if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("Unlucky") then
							if delayedNotification() then HaloTextHelper.addTextWithArrow(player, getText("UI_ETW_DelayedNotificationsStringRemove")..getText("UI_trait_unlucky"), true, HaloTextHelper.getColorGreen()) end
							ETWCommonFunctions.addTraitToDelayTable(modData, "Unlucky", player, false)
						end
					elseif not player:HasTrait("Unlucky") and not player:HasTrait("Lucky") and percentageOfSkillLevels >= SBvars.LuckSystemSkill and SBvars.TraitsLockSystemCanGainPositive then
						if not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("Lucky")) then
							player:getTraits():add("Lucky");
							if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_lucky"), true, HaloTextHelper.getColorGreen()) end
						end
						if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("Lucky") then
							if delayedNotification() then HaloTextHelper.addTextWithArrow(player, getText("UI_ETW_DelayedNotificationsStringAdd")..getText("UI_trait_lucky"), true, HaloTextHelper.getColorGreen()) end
							ETWCommonFunctions.addTraitToDelayTable(modData, "Lucky", player, true)
						end
					end
				end
	-- Passive
		-- Strength
			-- Hoarder
				if (perk == "characterInitialization" or perk == Perks.Strength or perk =="Hoarder") and ETWCommonLogicChecks.HoarderShouldExecute() then
					if strength >= SBvars.HoarderSkill then
						if not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("Hoarder")) then
							player:getTraits():add("Hoarder");
							if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Hoarder"), true, HaloTextHelper.getColorGreen()) end
						end
						if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("Hoarder") then
							if delayedNotification() then HaloTextHelper.addTextWithArrow(player, getText("UI_ETW_DelayedNotificationsStringAdd")..getText("UI_trait_Hoarder"), true, HaloTextHelper.getColorGreen()) end
							ETWCommonFunctions.addTraitToDelayTable(modData, "Hoarder", player, true)
						end
					end
				end
			-- Gym Rat
				if (perk == "characterInitialization" or perk == Perks.Strength or perk == Perks.Fitness or perk =="GymRat") and ETWCommonLogicChecks.GymRatShouldExecute() then
					if (strength + fitness) >= SBvars.GymRatSkill then
						if not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("GymRat")) then
							player:getTraits():add("GymRat");
							if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_GymRat"), true, HaloTextHelper.getColorGreen()) end
						end
						if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("GymRat") then
							if delayedNotification() then HaloTextHelper.addTextWithArrow(player, getText("UI_ETW_DelayedNotificationsStringAdd")..getText("UI_trait_GymRat"), true, HaloTextHelper.getColorGreen()) end
							ETWCommonFunctions.addTraitToDelayTable(modData, "GymRat", player, true)
						end
					end
				end
	-- Agility
		-- Springing
			-- Runner
				if (perk == "characterInitialization" or perk == Perks.Sprinting or perk =="Jogger") and ETWCommonLogicChecks.RunnerShouldExecute() then
					if sprinting >= SBvars.RunnerSkill then
						if not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("Jogger")) then
							player:getTraits():add("Jogger");
							applyXPBoost(player, Perks.Sprinting, 1);
							if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Jogger"), true, HaloTextHelper.getColorGreen()) end
						end
						if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("Jogger") then
							if delayedNotification() then HaloTextHelper.addTextWithArrow(player, getText("UI_ETW_DelayedNotificationsStringAdd")..getText("UI_trait_Jogger"), true, HaloTextHelper.getColorGreen()) end
							ETWCommonFunctions.addTraitToDelayTable(modData, "Jogger", player, true)
						end
					end
				end
			-- Hard of Hearing / Keen Hearing
				if (perk == "characterInitialization" or perk == Perks.Sprinting or perk == Perks.Lightfoot or perk == Perks.Nimble or perk == Perks.Sneak or perk == Perks.Axe or perk == Perks.Blunt or perk == Perks.SmallBlunt or perk == Perks.LongBlade or perk == Perks.SmallBlade or perk == Perks.Spear or perk =="HardOfHearing" or perk =="KeenHearing") and ETWCommonLogicChecks.HearingSystemShouldExecute() then
					local levels = sprinting + lightfooted + nimble + sneaking + axe + longBlunt + shortBlunt + longBlade + shortBlade + spear;
					if player:HasTrait("HardOfHearing") and levels >= SBvars.HearingSystemSkill / 2 and SBvars.TraitsLockSystemCanLoseNegative then
						if not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("HardOfHearing")) then
							player:getTraits():remove("HardOfHearing");
							if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_hardhear"), false, HaloTextHelper.getColorGreen()) end
						end
						if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("HardOfHearing") then
							if delayedNotification() then HaloTextHelper.addTextWithArrow(player, getText("UI_ETW_DelayedNotificationsStringRemove")..getText("UI_trait_hardhear"), true, HaloTextHelper.getColorGreen()) end
							ETWCommonFunctions.addTraitToDelayTable(modData, "HardOfHearing", player, false)
						end
					elseif not player:HasTrait("HardOfHearing") and levels >= SBvars.HearingSystemSkill then
						if not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("KeenHearing")) then
							player:getTraits():add("KeenHearing");
							if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_keenhearing"), true, HaloTextHelper.getColorGreen()) end
						end
						if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("KeenHearing") then
							if delayedNotification() then HaloTextHelper.addTextWithArrow(player, getText("UI_ETW_DelayedNotificationsStringAdd")..getText("UI_trait_keenhearing"), true, HaloTextHelper.getColorGreen()) end
							ETWCommonFunctions.addTraitToDelayTable(modData, "KeenHearing", player, true)
						end
					end
				end
		-- Lightfooted
			-- Light Step
				if (perk == "characterInitialization" or perk == Perks.Lightfoot or perk == "LightStep") and ETWCommonLogicChecks.LightStepShouldExecute() then
					if lightfooted >= SBvars.LightStepSkill then
						if not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("LightStep")) then
							player:getTraits():add("LightStep");
							applyXPBoost(player, Perks.Lightfoot, 1);
							if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_LightStep"), true, HaloTextHelper.getColorGreen()) end
						end
						if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("LightStep") then
							if delayedNotification() then HaloTextHelper.addTextWithArrow(player, getText("UI_ETW_DelayedNotificationsStringAdd")..getText("UI_trait_LightStep"), true, HaloTextHelper.getColorGreen()) end
							ETWCommonFunctions.addTraitToDelayTable(modData, "LightStep", player, true)
						end
					end
				end
			-- Gymnast
				if (perk == "characterInitialization" or perk == Perks.Lightfoot or perk == Perks.Nimble or perk == "Gymnast") and ETWCommonLogicChecks.GymnastShouldExecute() then
					if (lightfooted + nimble) >= SBvars.GymnastSkill then
						if not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("Gymnast")) then
							player:getTraits():add("Gymnast");
							applyXPBoost(player, Perks.Lightfoot, 1);
							applyXPBoost(player, Perks.Nimble, 1);
							if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Gymnast"), true, HaloTextHelper.getColorGreen()) end
						end
						if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("Gymnast") then
							if delayedNotification() then HaloTextHelper.addTextWithArrow(player, getText("UI_ETW_DelayedNotificationsStringAdd")..getText("UI_trait_Gymnast"), true, HaloTextHelper.getColorGreen()) end
							ETWCommonFunctions.addTraitToDelayTable(modData, "Gymnast", player, true)
						end
					end
				end
			-- Clumsy
				if (perk == "characterInitialization" or perk == Perks.Lightfoot or perk == Perks.Sneak or perk == "Clumsy") and ETWCommonLogicChecks.ClumsyShouldExecute() then
					if (lightfooted + sneaking) >= SBvars.ClumsySkill then
						if not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("Clumsy")) then
							player:getTraits():remove("Clumsy");
							if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_clumsy"), false, HaloTextHelper.getColorGreen()) end
						end
						if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("Clumsy") then
							if delayedNotification() then HaloTextHelper.addTextWithArrow(player, getText("UI_ETW_DelayedNotificationsStringRemove")..getText("UI_trait_clumsy"), true, HaloTextHelper.getColorGreen()) end
							ETWCommonFunctions.addTraitToDelayTable(modData, "Clumsy", player, false)
						end
					end
				end
	-- Graceful
		if (perk == "characterInitialization" or perk == Perks.Nimble or perk == Perks.Sneak or perk == Perks.Lightfoot or perk == "Graceful") and ETWCommonLogicChecks.GracefulShouldExecute() then
			local levels = nimble + sneaking + lightfooted;
			if levels >= SBvars.GracefulSkill then
				if not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("Graceful")) then
					player:getTraits():add("Graceful");
					if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_graceful"), true, HaloTextHelper.getColorGreen()) end
				end
				if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("Graceful") then
					if delayedNotification() then HaloTextHelper.addTextWithArrow(player, getText("UI_ETW_DelayedNotificationsStringAdd")..getText("UI_trait_graceful"), true, HaloTextHelper.getColorGreen()) end
					ETWCommonFunctions.addTraitToDelayTable(modData, "Graceful", player, true)
				end
			end
		end
	-- Nimble
		if (perk == "characterInitialization" or perk == Perks.Nimble or perk == Perks.Mechanics or perk == Perks.Electricity or perk == "Burglar") and ETWCommonLogicChecks.BurglarShouldExecute() then
			local levels = nimble + mechanics + electrical;
			if electrical >= 2 and mechanics >= 2 and levels >= SBvars.BurglarSkill then
				if not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("Burglar")) then
					player:getTraits():add("Burglar");
					if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Burglar"), true, HaloTextHelper.getColorGreen()) end
				end
				if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("Burglar") then
					if delayedNotification() then HaloTextHelper.addTextWithArrow(player, getText("UI_ETW_DelayedNotificationsStringAdd")..getText("UI_prof_Burglar"), true, HaloTextHelper.getColorGreen()) end
					ETWCommonFunctions.addTraitToDelayTable(modData, "Burglar", player, true)
				end
			end
		end
		-- Sneaking
			-- Low Profile
				if (perk == "characterInitialization" or perk == Perks.Sneak or perk == "LowProfile") and ETWCommonLogicChecks.LowProfileShouldExecute() then
					if sneaking >= SBvars.LowProfileSkill then
						if not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("LowProfile")) then
							player:getTraits():add("LowProfile");
							applyXPBoost(player, Perks.Sneak, 1);
							if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_LowProfile"), true, HaloTextHelper.getColorGreen()) end
						end
						if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("LowProfile") then
							if delayedNotification() then HaloTextHelper.addTextWithArrow(player, getText("UI_ETW_DelayedNotificationsStringAdd")..getText("UI_trait_LowProfile"), true, HaloTextHelper.getColorGreen()) end
							ETWCommonFunctions.addTraitToDelayTable(modData, "LowProfile", player, true)
						end
					end
				end
			-- Conspicuous/Inconspicuous
				if perk == "characterInitialization" or perk == Perks.Sneak or perk == "Conspicuous" or perk == "Inconspicuous" then
					if ETWCommonLogicChecks.ConspicuousShouldExecute() and sneaking >= SBvars.ConspicuousSkill then
						if not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("Conspicuous")) then
							player:getTraits():remove("Conspicuous");
							if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Conspicuous"), false, HaloTextHelper.getColorGreen()) end
						end
						if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("Conspicuous") then
							if delayedNotification() then HaloTextHelper.addTextWithArrow(player, getText("UI_ETW_DelayedNotificationsStringRemove")..getText("UI_trait_Conspicuous"), true, HaloTextHelper.getColorGreen()) end
							ETWCommonFunctions.addTraitToDelayTable(modData, "Conspicuous", player, false)
						end
					elseif ETWCommonLogicChecks.InconspicuousShouldExecute() and sneaking >= SBvars.InconspicuousSkill then
						if not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("Inconspicuous")) then
							player:getTraits():add("Inconspicuous");
							if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Inconspicuous"), true, HaloTextHelper.getColorGreen()) end
						end
						if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("Inconspicuous") then
							if delayedNotification() then HaloTextHelper.addTextWithArrow(player, getText("UI_ETW_DelayedNotificationsStringAdd")..getText("UI_trait_Inconspicuous"), true, HaloTextHelper.getColorGreen()) end
							ETWCommonFunctions.addTraitToDelayTable(modData, "Inconspicuous", player, true)
						end
					end
				end
			-- Hunter
				if (perk == "characterInitialization" or perk == "kill" or perk == Perks.Sneak or perk == Perks.Aiming or perk == Perks.Trapping or perk == Perks.SmallBlade or perk == "Hunter") and ETWCommonLogicChecks.HunterShouldExecute() then
					local levels = sneaking + aiming + trapping + shortBlade;
					if sneaking >= 2 and aiming >= 2 and trapping >= 2 and shortBlade >= 2 and levels >= SBvars.HunterSkill and (shortBladeKills + firearmKills) >= SBvars.HunterKills then
						if not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("Hunter")) then
							player:getTraits():add("Hunter");
							applyXPBoost(player, Perks.Aiming, 1);
							applyXPBoost(player, Perks.Trapping, 1);
							applyXPBoost(player, Perks.Sneak, 1);
							applyXPBoost(player, Perks.SmallBlade, 1);
							addRecipe(player, "Make Stick Trap");
							addRecipe(player, "Make Snare Trap");
							addRecipe(player, "Make Wooden Box Trap");
							addRecipe(player, "Make Trap Box");
							addRecipe(player, "Make Cage Trap");
							if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Hunter"), true, HaloTextHelper.getColorGreen()) end
						end
						if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("Hunter") then
							if delayedNotification() then HaloTextHelper.addTextWithArrow(player, getText("UI_ETW_DelayedNotificationsStringAdd")..getText("UI_trait_Hunter"), true, HaloTextHelper.getColorGreen()) end
							ETWCommonFunctions.addTraitToDelayTable(modData, "Hunter", player, true)
						end
					end
				end
	-- Combat
		-- Axe
			-- Brawler
				if (perk == "characterInitialization" or perk == "kill" or perk == Perks.Axe or perk == Perks.Blunt or perk == "Brawler") and ETWCommonLogicChecks.BrawlerShouldExecute() then
					if (axe + longBlunt) >= SBvars.BrawlerSkill and (axeKills + longBluntKills) >= SBvars.BrawlerKills then
						if not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("Brawler")) then
							player:getTraits():add("Brawler");
							applyXPBoost(player, Perks.Axe, 1);
							applyXPBoost(player, Perks.Blunt, 1);
							if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_BarFighter"), true, HaloTextHelper.getColorGreen()) end
						end
						if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("Brawler") then
							if delayedNotification() then HaloTextHelper.addTextWithArrow(player, getText("UI_ETW_DelayedNotificationsStringAdd")..getText("UI_trait_BarFighter"), true, HaloTextHelper.getColorGreen()) end
							ETWCommonFunctions.addTraitToDelayTable(modData, "Brawler", player, true)
						end
					end
				end
			-- Axe Thrower
				if (perk == "characterInitialization" or perk == "kill" or perk == Perks.Axe or perk == "AxeThrower") and ETWCommonLogicChecks.AxeThrowerShouldExecute() then
					if axe >= SBvars.AxeThrowerSkill and axeKills >= SBvars.AxeThrowerKills then
						if not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("AxeThrower")) then
							player:getTraits():add("AxeThrower");
							applyXPBoost(player, Perks.Axe, 1);
							if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_AxeThrower"), true, HaloTextHelper.getColorGreen()) end
						end
						if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("AxeThrower") then
							if delayedNotification() then HaloTextHelper.addTextWithArrow(player, getText("UI_ETW_DelayedNotificationsStringAdd")..getText("UI_trait_AxeThrower"), true, HaloTextHelper.getColorGreen()) end
							ETWCommonFunctions.addTraitToDelayTable(modData, "AxeThrower", player, true)
						end
					end
				end
		-- Long Blunt
			-- Baseball Player
				if (perk == "characterInitialization" or perk == "kill" or perk == Perks.Blunt or perk == "BaseballPlayer") and ETWCommonLogicChecks.BaseballPlayerShouldExecute() then
					if longBlunt >= SBvars.BaseballPlayerSkill and longBluntKills >= SBvars.BaseballPlayerKills then
						if not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("BaseballPlayer")) then
							player:getTraits():add("BaseballPlayer");
							applyXPBoost(player, Perks.Blunt, 1);
							if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_PlaysBaseball"), true, HaloTextHelper.getColorGreen()) end
						end
						if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("BaseballPlayer") then
							if delayedNotification() then HaloTextHelper.addTextWithArrow(player, getText("UI_ETW_DelayedNotificationsStringAdd")..getText("UI_trait_PlaysBaseball"), true, HaloTextHelper.getColorGreen()) end
							ETWCommonFunctions.addTraitToDelayTable(modData, "BaseballPlayer", player, true)
						end
					end
				end
		-- Short Blunt
			-- Stick Fighter
				if (perk == "characterInitialization" or perk == "kill" or perk == Perks.SmallBlunt or perk == "StickFighter") and ETWCommonLogicChecks.StickFighterShouldExecute() then
					if shortBlunt >= SBvars.StickFighterSkill and shortBluntKills >= SBvars.StickFighterKills then
						if not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("StickFighter")) then
							player:getTraits():add("StickFighter");
							applyXPBoost(player, Perks.SmallBlunt, 1);
							if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_StickFighter"), true, HaloTextHelper.getColorGreen()) end
						end
						if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("StickFighter") then
							if delayedNotification() then HaloTextHelper.addTextWithArrow(player, getText("UI_ETW_DelayedNotificationsStringAdd")..getText("UI_trait_StickFighter"), true, HaloTextHelper.getColorGreen()) end
							ETWCommonFunctions.addTraitToDelayTable(modData, "StickFighter", player, true)
						end
					end
				end
		-- Long Blade
			-- Kenshi
				if (perk == "characterInitialization" or perk == "kill" or perk == Perks.LongBlade or perk == "Kenshi") and ETWCommonLogicChecks.KenshiShouldExecute() then
					if longBlade >= SBvars.KenshiSkill and longBladeKills >= SBvars.KenshiKills then
						if not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("Kenshi")) then
							player:getTraits():add("Kenshi");
							applyXPBoost(player, Perks.LongBlade, 1);
							if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Kenshi"), true, HaloTextHelper.getColorGreen()) end
						end
						if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("Kenshi") then
							if delayedNotification() then HaloTextHelper.addTextWithArrow(player, getText("UI_ETW_DelayedNotificationsStringAdd")..getText("UI_trait_Kenshi"), true, HaloTextHelper.getColorGreen()) end
							ETWCommonFunctions.addTraitToDelayTable(modData, "Kenshi", player, true)
						end
					end
				end
		-- Short Blade
			-- Knife Fighter
				if (perk == "characterInitialization" or perk == "kill" or perk == Perks.ShortBlade or perk == "KnifeFighter") and ETWCommonLogicChecks.KnifeFighterShouldExecute() then
					if shortBlade >= SBvars.KnifeFighterSkill and shortBladeKills >= SBvars.KnifeFighterKills then
						if not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("KnifeFighter")) then
							player:getTraits():add("KnifeFighter");
							applyXPBoost(player, Perks.SmallBlade, 1);
							if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_KnifeFighter"), true, HaloTextHelper.getColorGreen()) end
						end
						if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("KnifeFighter") then
							if delayedNotification() then HaloTextHelper.addTextWithArrow(player, getText("UI_ETW_DelayedNotificationsStringAdd")..getText("UI_trait_KnifeFighter"), true, HaloTextHelper.getColorGreen()) end
							ETWCommonFunctions.addTraitToDelayTable(modData, "KnifeFighter", player, true)
						end
					end
				end
		-- Spear
			-- Sojutsu
				if (perk == "characterInitialization" or perk == "kill" or perk == Perks.Spear or perk == "Sojutsu") and ETWCommonLogicChecks.SojutsuShouldExecute() then
					if spear >= SBvars.SojutsuSkill and spearKills >= SBvars.SojutsuKills then
						if not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("Sojutsu")) then
							player:getTraits():add("Sojutsu");
							applyXPBoost(player, Perks.Spear, 1);
							if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Sojutsu"), true, HaloTextHelper.getColorGreen()) end
						end
						if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("Sojutsu") then
							if delayedNotification() then HaloTextHelper.addTextWithArrow(player, getText("UI_ETW_DelayedNotificationsStringAdd")..getText("UI_trait_Sojutsu"), true, HaloTextHelper.getColorGreen()) end
							ETWCommonFunctions.addTraitToDelayTable(modData, "Sojutsu", player, true)
						end
					end
				end
		-- Maintenance
			-- Restoration Expert
				if (perk == "characterInitialization" or perk == Perks.Maintenance or perk == "RestorationExpert") and ETWCommonLogicChecks.RestorationExpertShouldExecute() then
					if maintenance >= SBvars.RestorationExpertSkill then
						if not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("RestorationExpert")) then
							player:getTraits():add("RestorationExpert");
							applyXPBoost(player, Perks.Maintenance, 1);
							if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_RestorationExpert"), true, HaloTextHelper.getColorGreen()) end
						end
						if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("RestorationExpert") then
							if delayedNotification() then HaloTextHelper.addTextWithArrow(player, getText("UI_ETW_DelayedNotificationsStringAdd")..getText("UI_trait_RestorationExpert"), true, HaloTextHelper.getColorGreen()) end
							ETWCommonFunctions.addTraitToDelayTable(modData, "RestorationExpert", player, true)
						end
					end
				end
			-- Handy
				if (perk == "characterInitialization" or perk == Perks.Maintenance or perk == Perks.Woodwork or perk == "Handy") and ETWCommonLogicChecks.HandyShouldExecute() then
					if (maintenance + carpentry) >= SBvars.HandySkill then
						if not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("Handy")) then
							player:getTraits():add("Handy");
							applyXPBoost(player, Perks.Maintenance, 1);
							applyXPBoost(player, Perks.Woodwork, 1);
							if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_handy"), true, HaloTextHelper.getColorGreen()) end
						end
						if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("Handy") then
							if delayedNotification() then HaloTextHelper.addTextWithArrow(player, getText("UI_ETW_DelayedNotificationsStringAdd")..getText("UI_trait_handy"), true, HaloTextHelper.getColorGreen()) end
							ETWCommonFunctions.addTraitToDelayTable(modData, "Handy", player, true)
						end
					end
				end
			-- Slow/Fast Learner
				if (perk == "characterInitialization" or perk == Perks.Maintenance or perk == Perks.Woodwork or perk == Perks.Cooking or perk == Perks.Farming or perk == Perks.Doctor or perk == Perks.Electricity or perk == Perks.MetalWelding or perk == Perks.Mechanics or perk == Perks.Tailoring or perk == "SlowLearner" or perk == "FastLearner") and ETWCommonLogicChecks.LearnerSystemShouldExecute() then
					local levels = maintenance + carpentry + farming + firstAid + electrical + metalworking + mechanics + tailoring + cooking;
					if levels >= SBvars.LearnerSystemSkill / 2 and SBvars.TraitsLockSystemCanLoseNegative then
						if not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("SlowLearner")) then
							player:getTraits():remove("SlowLearner");
							if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_SlowLearner"), false, HaloTextHelper.getColorGreen()) end
						end
						if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("SlowLearner") then
							if delayedNotification() then HaloTextHelper.addTextWithArrow(player, getText("UI_ETW_DelayedNotificationsStringRemove")..getText("UI_trait_SlowLearner"), true, HaloTextHelper.getColorGreen()) end
							ETWCommonFunctions.addTraitToDelayTable(modData, "SlowLearner", player, false)
						end
					elseif not player:HasTrait("SlowLearner") and levels >= SBvars.LearnerSystemSkill and SBvars.TraitsLockSystemCanGainPositive then
						if not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("FastLearner")) then
							player:getTraits():add("FastLearner");
							if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_FastLearner"), true, HaloTextHelper.getColorGreen()) end
						end
						if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("FastLearner") then
							if delayedNotification() then HaloTextHelper.addTextWithArrow(player, getText("UI_ETW_DelayedNotificationsStringAdd")..getText("UI_trait_FastLearner"), true, HaloTextHelper.getColorGreen()) end
							ETWCommonFunctions.addTraitToDelayTable(modData, "FastLearner", player, true)
						end
					end
				end
	-- Crafting
		-- Carpentry
			-- Furniture Assembler
				if (perk == "characterInitialization" or perk == Perks.Woodwork or perk == "FurnitureAssembler") and ETWCommonLogicChecks.FurnitureAssemblerShouldExecute() then
					if carpentry >= SBvars.FurnitureAssemblerSkill then
						if not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("FurnitureAssembler")) then
							player:getTraits():add("FurnitureAssembler");
							applyXPBoost(player, Perks.Woodwork, 1);
							if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_FurnitureAssembler"), true, HaloTextHelper.getColorGreen()) end
						end
						if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("FurnitureAssembler") then
							if delayedNotification() then HaloTextHelper.addTextWithArrow(player, getText("UI_ETW_DelayedNotificationsStringAdd")..getText("UI_trait_FurnitureAssembler"), true, HaloTextHelper.getColorGreen()) end
							ETWCommonFunctions.addTraitToDelayTable(modData, "FurnitureAssembler", player, true)
						end
					end
				end
		-- Cooking
			-- Home Cook
				if (perk == "characterInitialization" or perk == Perks.Cooking or perk == "HomeCook") and ETWCommonLogicChecks.HomeCookShouldExecute() then
					if cooking >= SBvars.HomeCookSkill then
						if not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("HomeCook")) then
							player:getTraits():add("HomeCook");
							addRecipe(player, "Make Cake Batter");
							applyXPBoost(player, Perks.Cooking, 1);
							if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_HomeCook"), true, HaloTextHelper.getColorGreen()) end
						end
						if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("HomeCook") then
							if delayedNotification() then HaloTextHelper.addTextWithArrow(player, getText("UI_ETW_DelayedNotificationsStringAdd")..getText("UI_trait_HomeCook"), true, HaloTextHelper.getColorGreen()) end
							ETWCommonFunctions.addTraitToDelayTable(modData, "HomeCook", player, true)
						end
					end
				end
			-- Cook
				if (perk == "characterInitialization" or perk == Perks.Cooking or perk == "Cook") and ETWCommonLogicChecks.CookShouldExecute() then
					if cooking >= SBvars.CookSkill then
						if not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("Cook")) then
							player:getTraits():add("Cook");
							addRecipe(player, "Make Cake Batter");
							addRecipe(player, "Make Pie Dough");
							addRecipe(player, "Make Bread Dough");
							addRecipe(player, "Make Biscuits");
							addRecipe(player, "Make Cookie Dough");
							addRecipe(player, "Make Chocolate Chip Cookie Dough");
							addRecipe(player, "Make Oatmeal Cookie Dough");
							addRecipe(player, "Make Shortbread Cookie Dough");
							addRecipe(player, "Make Sugar Cookie Dough");
							addRecipe(player, "Make Pizza");
							applyXPBoost(player, Perks.Cooking, 1);
							if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Cook"), true, HaloTextHelper.getColorGreen()) end
						end
						if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("Cook") then
							if delayedNotification() then HaloTextHelper.addTextWithArrow(player, getText("UI_ETW_DelayedNotificationsStringAdd")..getText("UI_trait_Cook"), true, HaloTextHelper.getColorGreen()) end
							ETWCommonFunctions.addTraitToDelayTable(modData, "Cook", player, true)
						end
					end
				end
		-- Farming
			-- Gardener
				if (perk == "characterInitialization" or perk == Perks.Farming or perk == "Gardener") and ETWCommonLogicChecks.GardenerShouldExecute() then
					if farming >= SBvars.GardenerSkill then
						if not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("Gardener")) then
							player:getTraits():add("Gardener");
							applyXPBoost(player, Perks.Farming, 1);
							addRecipe(player, "Make Mildew Cure");
							addRecipe(player, "Make Flies Cure");
							if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Gardener"), true, HaloTextHelper.getColorGreen()) end
						end
						if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("Gardener") then
							if delayedNotification() then HaloTextHelper.addTextWithArrow(player, getText("UI_ETW_DelayedNotificationsStringAdd")..getText("UI_trait_Gardener"), true, HaloTextHelper.getColorGreen()) end
							ETWCommonFunctions.addTraitToDelayTable(modData, "Gardener", player, true)
						end
					end
				end
		-- First Aid
			-- First Aider
				if (perk == "characterInitialization" or perk == Perks.Doctor or perk == "FirstAid") and ETWCommonLogicChecks.FirstAidShouldExecute() then
					if firstAid >= SBvars.FirstAidSkill then
						if not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("FirstAid")) then
							player:getTraits():add("FirstAid");
							applyXPBoost(player, Perks.Doctor, 1);
							if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_FirstAid"), true, HaloTextHelper.getColorGreen()) end
						end
						if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("FirstAid") then
							if delayedNotification() then HaloTextHelper.addTextWithArrow(player, getText("UI_ETW_DelayedNotificationsStringAdd")..getText("UI_trait_FirstAid"), true, HaloTextHelper.getColorGreen()) end
							ETWCommonFunctions.addTraitToDelayTable(modData, "FirstAid", player, true)
						end
					end
				end
		-- Electrical
			-- AVClub
				if (perk == "characterInitialization" or perk == Perks.Electricity or perk == "AVClub") and ETWCommonLogicChecks.AVClubShouldExecute() then
					if electrical >= SBvars.AVClubSkill then
						if not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("AVClub")) then
							player:getTraits():add("AVClub");
							addRecipe(player, "Make Remote Controller V1");
							addRecipe(player, "Make Remote Controller V2");
							addRecipe(player, "Make Remote Controller V3");
							addRecipe(player, "Make Remote Trigger");
							addRecipe(player, "Make Timer");
							addRecipe(player, "Craft Makeshift Radio");
							addRecipe(player, "Craft Makeshift HAM Radio");
							addRecipe(player, "Craft Makeshift Walkie Talkie");
							addRecipe(player, "Make Noise generator");
							applyXPBoost(player, Perks.Electricity, 1);
							if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_AVClub"), true, HaloTextHelper.getColorGreen()) end
						end
						if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("AVClub") then
							if delayedNotification() then HaloTextHelper.addTextWithArrow(player, getText("UI_ETW_DelayedNotificationsStringAdd")..getText("UI_trait_AVClub"), true, HaloTextHelper.getColorGreen()) end
							ETWCommonFunctions.addTraitToDelayTable(modData, "AVClub", player, true)
						end
					end
				end
		-- Metalworking
			-- Bodywork Enthusiast
				if (perk == "characterInitialization" or perk == Perks.MetalWelding  or perk == Perks.Mechanics or perk == "BodyWorkEnthusiast") and ETWCommonLogicChecks.BodyWorkEnthusiastShouldExecute() then
					ETWActionsOverride.bodyworkEnthusiastCheck();
				end
		-- Mechanics
			-- Amateur Mechanic
				if (perk == "characterInitialization" or perk == Perks.Mechanics or perk == "Mechanics") and ETWCommonLogicChecks.MechanicsShouldExecute() then
					ETWActionsOverride.mechanicsCheck();
				end
		-- Tailoring
			-- Sewer
				if (perk == "characterInitialization" or perk == Perks.Tailoring or perk == "Tailor") and ETWCommonLogicChecks.TailorShouldExecute() then
					if tailoring >= SBvars.SewerSkill then
						if not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("Tailor")) then
							player:getTraits():add("Tailor");
							applyXPBoost(player, Perks.Tailoring, 1);
							if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Tailor"), true, HaloTextHelper.getColorGreen()) end
						end
						if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("Tailor") then
							if delayedNotification() then HaloTextHelper.addTextWithArrow(player, getText("UI_ETW_DelayedNotificationsStringAdd")..getText("UI_trait_Tailor"), true, HaloTextHelper.getColorGreen()) end
							ETWCommonFunctions.addTraitToDelayTable(modData, "Tailor", player, true)
						end
					end
				end
	-- Firearms
		-- Aiming
			-- Gun Enthusiast
				if (perk == "characterInitialization" or perk == "kill" or perk == Perks.Aiming or perk == Perks.Reloading or perk == "GunEnthusiast") and ETWCommonLogicChecks.GunEnthusiastShouldExecute() then
					if (aiming + reloading) >= SBvars.GunEnthusiastSkill and firearmKills >= SBvars.GunEnthusiastKills then
						if not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("GunEnthusiast")) then
							player:getTraits():add("GunEnthusiast");
							applyXPBoost(player, Perks.Aiming, 1);
							applyXPBoost(player, Perks.Reloading, 1);
							if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_GunEnthusiast"), true, HaloTextHelper.getColorGreen()) end
						end
						if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("GunEnthusiast") then
							if delayedNotification() then HaloTextHelper.addTextWithArrow(player, getText("UI_ETW_DelayedNotificationsStringAdd")..getText("UI_trait_GunEnthusiast"), true, HaloTextHelper.getColorGreen()) end
							ETWCommonFunctions.addTraitToDelayTable(modData, "GunEnthusiast", player, true)
						end
					end
				end
	-- Survival
		-- Fishing
			-- Angler
				if (perk == "characterInitialization" or perk == "kill" or perk == Perks.Fishing or perk == "Fishing") and ETWCommonLogicChecks.AnglerShouldExecute() then
					if fishing >= SBvars.FishingSkill then
						if not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("Fishing")) then
							player:getTraits():add("Fishing");
							addRecipe(player, "Make Fishing Rod");
							addRecipe(player, "Fix Fishing Rod");
							applyXPBoost(player, Perks.Fishing, 1);
							if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Fishing"), true, HaloTextHelper.getColorGreen()) end
						end
						if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("Fishing") then
							if delayedNotification() then HaloTextHelper.addTextWithArrow(player, getText("UI_ETW_DelayedNotificationsStringAdd")..getText("UI_trait_Fishing"), true, HaloTextHelper.getColorGreen()) end
							ETWCommonFunctions.addTraitToDelayTable(modData, "Fishing", player, true)
						end
					end
				end
		-- Trapping
			-- Hiker
				if (perk == "characterInitialization" or perk == Perks.Trapping or perk == Perks.PlantScavenging or perk == "Hiker") and ETWCommonLogicChecks.HikerShouldExecute() then
					if (trapping + foraging) >= SBvars.HikerSkill then
						if not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("Hiker")) then
							player:getTraits():add("Hiker");
							addRecipe(player, "Make Stick Trap");
							addRecipe(player, "Make Snare Trap");
							addRecipe(player, "Make Wooden Box Trap");
							applyXPBoost(player, Perks.PlantScavenging, 1);
							applyXPBoost(player, Perks.Trapping, 1);
							if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Hiker"), true, HaloTextHelper.getColorGreen()) end
						end
						if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("Hiker") then
							if delayedNotification() then HaloTextHelper.addTextWithArrow(player, getText("UI_ETW_DelayedNotificationsStringAdd")..getText("UI_trait_Hiker"), true, HaloTextHelper.getColorGreen()) end
							ETWCommonFunctions.addTraitToDelayTable(modData, "Hiker", player, true)
						end
					end
				end
	modData.DelayedStartingTraitsFilled = true;
end

local function progressDelayedTraits()
	if not SBvars.DelayedTraitsSystem then return end;
	local traitTable = getPlayer():getModData().EvolvingTraitsWorld.DelayedTraits;
	if detailedDebug() then print("ETW Logger | Delayed Traits System: new progressDelayedTraits() execution ----------") end;
	for index, traitEntry in ipairs(traitTable) do
		local traitName, traitValue, gained = traitEntry[1], traitEntry[2], traitEntry[3];
		if not gained then
			local randomValue = ZombRand(traitValue + 1);
			if randomValue == 0 then
				if detailedDebug() then print("ETW Logger | Delayed Traits System: rolled to get "..traitName..": rolled 0 from 0-"..traitTable[index][2]) end;
				traitTable[index][3] = true;
				if detailedDebug() then print("ETW Logger | Delayed Traits System: "..traitName.." in traitTable["..index.."][3]".." set to "..tostring(traitTable[index][3])) end;
				if detailedDebug() then print("ETW Logger | Delayed Traits System: running traitsGainsBySkill(player, "..traitName..")") end;
				traitsGainsBySkill(getPlayer(), traitName);
			elseif randomValue > 0 then
				if detailedDebug() then print("ETW Logger | Delayed Traits System: rolled to get "..traitName..": rolled "..randomValue.." from 0-"..traitTable[index][2]) end;
				traitTable[index][2] = traitValue - 1;
			end
		end
	end
	if detailedDebug() then print("ETW Logger | Delayed Traits System: finished progressDelayedTraits() execution ----------") end;
end

local function onZombieKill(zombie)
	local player = getPlayer();
	traitsGainsBySkill(player, "kill");
end

local function initializeEvents(playerIndex, player)
	traitsGainsBySkill(player, "characterInitialization");
	Events.LevelPerk.Remove(traitsGainsBySkill);
	if SBvars.TraitsLockSystemCanGainPositive or SBvars.TraitsLockSystemCanLoseNegative then Events.LevelPerk.Add(traitsGainsBySkill) end;
	Events.EveryHours.Remove(progressDelayedTraits);
	Events.EveryHours.Add(progressDelayedTraits);
	Events.OnZombieDead.Remove(onZombieKill);
	if SBvars.TraitsLockSystemCanGainPositive then Events.OnZombieDead.Add(onZombieKill) end;
end

local function clearEvents(character)
	Events.LevelPerk.Remove(traitsGainsBySkill);
	Events.OnZombieDead.Remove(onZombieKill);
	if detailedDebug() then print("ETW Logger | System: clearEvents in ETWBySkills.lua") end
end

Events.OnCreatePlayer.Remove(initializeEvents);
Events.OnCreatePlayer.Add(initializeEvents);
Events.OnPlayerDeath.Remove(clearEvents);
Events.OnPlayerDeath.Add(clearEvents);