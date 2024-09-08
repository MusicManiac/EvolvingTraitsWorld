local ETWCombinedTraitChecks = {};

local ETWCommonFunctions = require "ETWCommonFunctions";

require "ETWModData";

---@type EvolvingTraitsWorldSandboxVars
local SBvars = SandboxVars.EvolvingTraitsWorld;
---@return boolean
local notification = function() return EvolvingTraitsWorld.settings.EnableNotifications end;
---@return boolean
local delayedNotification = function() return EvolvingTraitsWorld.settings.EnableDelayedNotifications end;
---@return boolean
local debug = function() return EvolvingTraitsWorld.settings.GatherDebug end;
---@return boolean
local detailedDebug = function() return EvolvingTraitsWorld.settings.GatherDetailedDebug end;

---Function responsible for checking if player qualifies for Bodywork Enthusiast trait
function ETWCombinedTraitChecks.bodyworkEnthusiastCheck()
	local player = getPlayer();
	local modData = ETWCommonFunctions.getETWModData(player);
	local level = player:getPerkLevel(Perks.MetalWelding) + player:getPerkLevel(Perks.Mechanics);
	if level >= SBvars.BodyworkEnthusiastSkill and modData.VehiclePartRepairs >= SBvars.BodyworkEnthusiastRepairs then
		if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("BodyWorkEnthusiast") then
			if delayedNotification() then HaloTextHelper.addTextWithArrow(player, getText("UI_ETW_DelayedNotificationsStringAdd") .. getText("UI_trait_BodyWorkEnthusiast"), true, HaloTextHelper.getColorGreen()) end;
			ETWCommonFunctions.traitSound(player);
			ETWCommonFunctions.addTraitToDelayTable(modData, "BodyWorkEnthusiast", player, true);
		elseif not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("BodyWorkEnthusiast")) then
			player:getTraits():add("BodyWorkEnthusiast");
			ETWCommonFunctions.applyXPBoost(player, Perks.MetalWelding, 1);
			ETWCommonFunctions.applyXPBoost(player, Perks.Mechanics, 1);
			ETWCommonFunctions.addRecipe(player, "Make Metal Walls");
			ETWCommonFunctions.addRecipe(player, "Make Metal Fences");
			ETWCommonFunctions.addRecipe(player, "Make Metal Containers");
			ETWCommonFunctions.addRecipe(player, "Make Metal Sheet");
			ETWCommonFunctions.addRecipe(player, "Make Small Metal Sheet");
			ETWCommonFunctions.addRecipe(player, "Make Metal Roof");
			if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_BodyWorkEnthusiast"), true, HaloTextHelper.getColorGreen()) end;
			ETWCommonFunctions.traitSound(player);
		end
	end
end

---Function responsible for checking if player qualifies for Mechanics trait
function ETWCombinedTraitChecks.mechanicsCheck()
	local player = getPlayer();
	local modData = ETWCommonFunctions.getETWModData(player);
	if player:getPerkLevel(Perks.Mechanics) >= SBvars.MechanicsSkill and modData.VehiclePartRepairs >= SBvars.MechanicsRepairs then
		if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("Mechanics") then
			if delayedNotification() then HaloTextHelper.addTextWithArrow(player, getText("UI_ETW_DelayedNotificationsStringAdd") .. getText("UI_trait_Mechanics"), true, HaloTextHelper.getColorGreen()) end;
			ETWCommonFunctions.traitSound(player);
			ETWCommonFunctions.addTraitToDelayTable(modData, "Mechanics", player, true);
		elseif not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("Mechanics")) then
			player:getTraits():add("Mechanics");
			ETWCommonFunctions.applyXPBoost(player, Perks.Mechanics, 1);
			ETWCommonFunctions.addRecipe(player, "Basic Mechanics");
			ETWCommonFunctions.addRecipe(player, "Intermediate Mechanics");
			if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Mechanics"), true, HaloTextHelper.getColorGreen()) end;
			ETWCommonFunctions.traitSound(player);
		end
	end
end

---Function responsible for checking if player qualifies for Sewer trait
function ETWCombinedTraitChecks.sewerCheck()
	local player = getPlayer();
	local modData = ETWCommonFunctions.getETWModData(player);
	if player:getPerkLevel(Perks.Tailoring) >= SBvars.SewerSkill and #modData.UniqueClothingRipped >= SBvars.SewerUniqueClothesRipped then
		if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("Tailor") then
			if delayedNotification then HaloTextHelper.addTextWithArrow(player, getText("UI_ETW_DelayedNotificationsStringAdd") .. getText("UI_trait_Tailor"), true, HaloTextHelper.getColorGreen()) end;
			ETWCommonFunctions.traitSound(player);
			ETWCommonFunctions.addTraitToDelayTable(modData, "Tailor", player, true);
		elseif not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("Tailor")) then
			player:getTraits():add("Tailor");
			ETWCommonFunctions.applyXPBoost(player, Perks.Tailoring, 1);
			if notification then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Tailor"), true, HaloTextHelper.getColorGreen()) end;
			ETWCommonFunctions.traitSound(player);
		end
	end
end

return ETWCombinedTraitChecks;
