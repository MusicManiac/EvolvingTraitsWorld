local ETWCombinedTraitChecks = {};

local ETWCommonFunctions = require "ETWCommonFunctions";

---@type EvolvingTraitsWorldSandboxVars
local SBvars = SandboxVars.EvolvingTraitsWorld;

-- local modOptions;

-- ---@return boolean
-- local notification = function() return modOptions:getOption("EnableNotifications"):getValue() end
-- ---@return boolean
-- local delayedNotification = function() return modOptions:getOption("EnableDelayedNotifications"):getValue() end
-- ---@return boolean
-- local detailedDebug = function() return modOptions:getOption("GatherDetailedDebug"):getValue() end

---Function responsible for checking if player qualifies for Bodywork Enthusiast trait
---@param DebugAndNotificationArgs DebugAndNotificationArgs
function ETWCombinedTraitChecks.bodyworkEnthusiastCheck(DebugAndNotificationArgs)
	local player = getPlayer();
	local modData = ETWCommonFunctions.getETWModData(player);
	local level = player:getPerkLevel(Perks.MetalWelding) + player:getPerkLevel(Perks.Mechanics);
	if level >= SBvars.BodyworkEnthusiastSkill and modData.VehiclePartRepairs >= SBvars.BodyworkEnthusiastRepairs then
		if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("BodyWorkEnthusiast") then
			if DebugAndNotificationArgs.delayedNotification then HaloTextHelper.addTextWithArrow(player, getText("UI_ETW_DelayedNotificationsStringAdd") .. getText("UI_trait_BodyWorkEnthusiast"), true, HaloTextHelper.getColorGreen()) end
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
			if DebugAndNotificationArgs.notification then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_BodyWorkEnthusiast"), true, HaloTextHelper.getColorGreen()) end
			ETWCommonFunctions.traitSound(player);
		end
	end
end

---Function responsible for checking if player qualifies for Mechanics trait
---@param DebugAndNotificationArgs DebugAndNotificationArgs
function ETWCombinedTraitChecks.mechanicsCheck(DebugAndNotificationArgs)
	local player = getPlayer();
	local modData = ETWCommonFunctions.getETWModData(player);
	if player:getPerkLevel(Perks.Mechanics) >= SBvars.MechanicsSkill and modData.VehiclePartRepairs >= SBvars.MechanicsRepairs then
		if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("Mechanics") then
			if DebugAndNotificationArgs.delayedNotification then HaloTextHelper.addTextWithArrow(player, getText("UI_ETW_DelayedNotificationsStringAdd") .. getText("UI_trait_Mechanics"), true, HaloTextHelper.getColorGreen()) end
			ETWCommonFunctions.traitSound(player);
			ETWCommonFunctions.addTraitToDelayTable(modData, "Mechanics", player, true);
		elseif not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("Mechanics")) then
			player:getTraits():add("Mechanics");
			ETWCommonFunctions.applyXPBoost(player, Perks.Mechanics, 1);
			ETWCommonFunctions.addRecipe(player, "Basic Mechanics");
			ETWCommonFunctions.addRecipe(player, "Intermediate Mechanics");
			if DebugAndNotificationArgs.notification then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Mechanics"), true, HaloTextHelper.getColorGreen()) end
			ETWCommonFunctions.traitSound(player);
		end
	end
end

---Function responsible for checking if player qualifies for Sewer trait
---@param DebugAndNotificationArgs DebugAndNotificationArgs
function ETWCombinedTraitChecks.sewerCheck(DebugAndNotificationArgs)
	local player = getPlayer();
	local modData = ETWCommonFunctions.getETWModData(player);
	if player:getPerkLevel(Perks.Tailoring) >= SBvars.SewerSkill and #modData.UniqueClothingRipped >= SBvars.SewerUniqueClothesRipped then
		if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("Tailor") then
			if DebugAndNotificationArgs.delayedNotification then HaloTextHelper.addTextWithArrow(player, getText("UI_ETW_DelayedNotificationsStringAdd") .. getText("UI_trait_Tailor"), true, HaloTextHelper.getColorGreen()) end
			ETWCommonFunctions.traitSound(player);
			ETWCommonFunctions.addTraitToDelayTable(modData, "Tailor", player, true);
		elseif not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("Tailor")) then
			player:getTraits():add("Tailor");
			ETWCommonFunctions.applyXPBoost(player, Perks.Tailoring, 1);
			if DebugAndNotificationArgs.notification then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Tailor"), true, HaloTextHelper.getColorGreen()) end
			ETWCommonFunctions.traitSound(player);
		end
	end
end

---Adds item name to the table of unique ripped clothes
---@param player IsoPlayer
---@param item Clothing
---@param DebugAndNotificationArgs DebugAndNotificationArgs
function ETWCombinedTraitChecks.addClothingToUniqueRippedClothingList(player, item, DebugAndNotificationArgs)
	local itemName = item:getName();
	local modData = ETWCommonFunctions.getETWModData(player);
	if DebugAndNotificationArgs.detailedDebug then print("ETW Logger | ETWCommonFunctions.addClothingToUniqueRippedClothingList() item: " .. itemName) end
	if ETWCommonFunctions.indexOf(modData.UniqueClothingRipped, itemName) == -1 then
	    table.insert(modData.UniqueClothingRipped, itemName)
	    ETWCombinedTraitChecks.sewerCheck(DebugAndNotificationArgs);
	end
end

return ETWCombinedTraitChecks;
