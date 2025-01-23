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
			ETWCommonFunctions.addTraitToDelayTable(modData, "BodyWorkEnthusiast", player, true);
			if DebugAndNotificationArgs.delayedNotification then
				HaloTextHelper.addTextWithArrow(
					player,
					getText("UI_ETW_DelayedNotificationsStringAdd") .. getText("UI_trait_BodyWorkEnthusiast"),
					true,
					HaloTextHelper.getColorGreen()
				)
			end
		elseif not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("BodyWorkEnthusiast")) then
			ETWCommonFunctions.addTraitToPlayer("BodyWorkEnthusiast");
			if DebugAndNotificationArgs.notification then
				HaloTextHelper.addTextWithArrow(
					player,
					getText("UI_trait_BodyWorkEnthusiast"),
					true,
					HaloTextHelper.getColorGreen()
				);
			end
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
			ETWCommonFunctions.addTraitToDelayTable(modData, "Mechanics", player, true);
			if DebugAndNotificationArgs.delayedNotification then
				HaloTextHelper.addTextWithArrow(
					player,
					getText("UI_ETW_DelayedNotificationsStringAdd") .. getText("UI_trait_Mechanics"),
					true,
					HaloTextHelper.getColorGreen()
				);
			end
		elseif not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("Mechanics")) then
			ETWCommonFunctions.addTraitToPlayer("Mechanics");
			if DebugAndNotificationArgs.notification then
				HaloTextHelper.addTextWithArrow(
					player,
					getText("UI_trait_Mechanics"),
					true,
					HaloTextHelper.getColorGreen()
				);
			end
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
			ETWCommonFunctions.addTraitToDelayTable(modData, "Tailor", player, true);
			if DebugAndNotificationArgs.delayedNotification then
				HaloTextHelper.addTextWithArrow(
					player,
					getText("UI_ETW_DelayedNotificationsStringAdd") .. getText("UI_trait_Tailor"),
					true,
					HaloTextHelper.getColorGreen()
				);
			end
		elseif not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("Tailor")) then
			ETWCommonFunctions.addTraitToPlayer("Tailor");
			if DebugAndNotificationArgs.notification then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Tailor"), true, HaloTextHelper.getColorGreen()) end
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
	    table.insert(modData.UniqueClothingRipped, itemName);
	    ETWCombinedTraitChecks.sewerCheck(DebugAndNotificationArgs);
	end
end

return ETWCombinedTraitChecks;
