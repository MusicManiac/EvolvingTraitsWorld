ETWActionsOverride = {};

local ETWCommonFunctions = require "ETWCommonFunctions";
local ETWCommonLogicChecks = require "ETWCommonLogicChecks";

---@type EvolvingTraitsWorldSandboxVars
local SBvars = SandboxVars.EvolvingTraitsWorld;
local notification = function() return EvolvingTraitsWorld.settings.EnableNotifications end
local delayedNotification = function() return EvolvingTraitsWorld.settings.EnableDelayedNotifications end
local debug = function() return EvolvingTraitsWorld.settings.GatherDebug end
local detailedDebug = function() return EvolvingTraitsWorld.settings.GatherDetailedDebug end
local noTraitsLock = function() return (SBvars.TraitsLockSystemCanGainNegative or SBvars.TraitsLockSystemCanLoseNegative or SBvars.TraitsLockSystemCanGainPositive or SBvars.TraitsLockSystemCanLosePositive) end

---Function responsible for checking if player qualifies for Bodywork Enthusiast trait
function ETWActionsOverride.bodyworkEnthusiastCheck()
	local player = getPlayer();
	local modData = ETWCommonFunctions.getETWModData(player);
	local level = player:getPerkLevel(Perks.MetalWelding) + player:getPerkLevel(Perks.Mechanics);
	if level >= SBvars.BodyworkEnthusiastSkill and modData.VehiclePartRepairs >= SBvars.BodyworkEnthusiastRepairs then
		if not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("BodyWorkEnthusiast")) then
			player:getTraits():add("BodyWorkEnthusiast");
			ETWCommonFunctions.applyXPBoost(player, Perks.MetalWelding, 1);
			ETWCommonFunctions.applyXPBoost(player, Perks.Mechanics, 1);
			ETWCommonFunctions.addRecipe(player, "Make Metal Walls");
			ETWCommonFunctions.addRecipe(player, "Make Metal Fences");
			ETWCommonFunctions.addRecipe(player, "Make Metal Containers");
			ETWCommonFunctions.addRecipe(player, "Make Metal Sheet");
			ETWCommonFunctions.addRecipe(player, "Make Small Metal Sheet");
			ETWCommonFunctions.addRecipe(player, "Make Metal Roof");
			if notification == true then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_BodyWorkEnthusiast"), true, HaloTextHelper.getColorGreen()) end
		end
		if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("BodyWorkEnthusiast") then
			if delayedNotification() then HaloTextHelper.addTextWithArrow(player, getText("UI_ETW_DelayedNotificationsStringAdd")..getText("UI_trait_BodyWorkEnthusiast"), true, HaloTextHelper.getColorGreen()) end
			ETWCommonFunctions.addTraitToDelayTable(modData, "BodyWorkEnthusiast", player, true)
		end
	end
end

---Function responsible for checking if player qualifies for Mechanics trait
function ETWActionsOverride.mechanicsCheck()
	local player = getPlayer();
	local modData = ETWCommonFunctions.getETWModData(player);
	if player:getPerkLevel(Perks.Mechanics) >= SBvars.MechanicsSkill and modData.VehiclePartRepairs >= SBvars.MechanicsRepairs then
		if not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("Mechanics")) then
			player:getTraits():add("Mechanics");
			ETWCommonFunctions.applyXPBoost(player, Perks.Mechanics, 1);
			ETWCommonFunctions.addRecipe(player, "Basic Mechanics");
			ETWCommonFunctions.addRecipe(player, "Intermediate Mechanics");
			if notification == true then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Mechanics"), true, HaloTextHelper.getColorGreen()) end
		end
		if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("Mechanics") then
			if delayedNotification() then HaloTextHelper.addTextWithArrow(player, getText("UI_ETW_DelayedNotificationsStringAdd")..getText("UI_trait_Mechanics"), true, HaloTextHelper.getColorGreen()) end
			ETWCommonFunctions.addTraitToDelayTable(modData, "Mechanics", player, true)
		end
	end
end

---Function responsible for checking if current ISFixAction performed on a vehicle part
---@param action ISFixAction
---@return boolean
local function isVehiclePart(action)
	if action.vehiclePart then
		return true;
	end
	local skills = action.fixer:getFixerSkills();
	if skills then
		for i = 0, skills:size() - 1 do
			if skills:get(i):getSkillName() == "Mechanics" then
				return true;
			end
		end
	end
	return false;
end

local original_fix_perform = ISFixAction.perform;

---Overwriting ISFixAction:perform() here so insert ETW logic catching player doing any kind of repairs
---@diagnostic disable-next-line: duplicate-set-field
function ISFixAction:perform()
	local player = self.character;
	local modData = ETWCommonFunctions.getETWModData(player);
	if detailedDebug() then print("ETW Logger | ISFixAction:perform(): caught") end
	local conditionBefore = self.item:getCondition();
	original_fix_perform(self);
	local conditionAfter = self.item:getCondition(); -- calculated by FixingManager locally
	if conditionAfter > conditionBefore and isVehiclePart(self) and (ETWCommonLogicChecks.MechanicsShouldExecute() or ETWCommonLogicChecks.BodyWorkEnthusiastShouldExecute()) then
		modData.VehiclePartRepairs = modData.VehiclePartRepairs + (conditionAfter - conditionBefore);
		if detailedDebug() then print("ETW Logger | ISFixAction.perform(): car part "..conditionBefore.."->"..conditionAfter.." VehiclePartRepairs="..modData.VehiclePartRepairs) end
		if not getActivatedMods():contains("EvolvingTraitsWorldDisableBodyWorkEnthusiast") then ETWActionsOverride.bodyworkEnthusiastCheck() end
		ETWActionsOverride.mechanicsCheck();
	end
	if player:HasTrait("RestorationExpert") then
		if detailedDebug() then print("ETW Logger | ISFixAction.perform(): RestorationExpert present") end
		local chance = SBvars.RestorationExpertChance - 1;
		if ZombRand(100) <= chance then
			self.item:setHaveBeenRepaired(self.item:getHaveBeenRepaired() - 1);
		end
	end
end

local original_chop_perform = ISChopTreeAction.perform;
---Overwriting ISChopTreeAction:perform() here so insert ETW logic catching player cutting down trees
---@diagnostic disable-next-line: duplicate-set-field
function ISChopTreeAction:perform()
	if ETWCommonLogicChecks.AxemanShouldExecute() then
		if detailedDebug() then print("ETW Logger | ISChopTreeAction.perform(): caught") end
		local player = self.character;
		local modData = ETWCommonFunctions.getETWModData(player);
		modData.TreesChopped = modData.TreesChopped + 1;
		if debug() then print("ETW Logger | ISChopTreeAction.perform(): modData.TreesChopped = "..modData.TreesChopped) end
		if modData.TreesChopped >= SBvars.AxemanTrees then
			if not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("Axeman")) then
				player:getTraits():add("Axeman");
				if notification == true then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_axeman"), true, HaloTextHelper.getColorGreen()) end
			end
			if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("Axeman") then
				if delayedNotification() then HaloTextHelper.addTextWithArrow(player, getText("UI_ETW_DelayedNotificationsStringAdd")..getText("UI_trait_axeman"), true, HaloTextHelper.getColorGreen()) end
				ETWCommonFunctions.addTraitToDelayTable(modData, "Axeman", player, true)
			end
		end
	end
	original_chop_perform(self);
end

local original_transfer_perform = ISInventoryTransferAction.perform;
---Overwriting ISInventoryTransferAction:perform() here so insert ETW logic catching player transferring items
---@diagnostic disable-next-line: duplicate-set-field
function ISInventoryTransferAction:perform()
	if SBvars.InventoryTransferSystem == true and noTraitsLock then
		if self.character:isLocalPlayer() == false then -- checks if it's NPC doing stuff
			if detailedDebug() then print("ETW Logger | ISInventoryTransferAction.perform(): NPC") end
			original_transfer_perform(self);
		elseif self.character == getPlayer() then
			if detailedDebug() then print("ETW Logger | ISInventoryTransferAction.perform(): Player") end
			local player = self.character;
			local item = self.item;
			local itemWeight = item:getWeight();
			local modData = ETWCommonFunctions.getETWModData(player);
			local transferModData = modData.TransferSystem;
			transferModData.ItemsTransferred = transferModData.ItemsTransferred + 1;
			transferModData.WeightTransferred = transferModData.WeightTransferred + itemWeight;
			if detailedDebug() then print("ETW Logger | ISInventoryTransferAction.perform(): Moving an item with weight of "..itemWeight) end
			if debug() then print("ETW Logger | ISInventoryTransferAction.perform(): Moved weight: "..transferModData.WeightTransferred..", Moved Items: "..transferModData.ItemsTransferred) end
			original_transfer_perform(self);
			if player:HasTrait("Disorganized") and transferModData.WeightTransferred >= SBvars.InventoryTransferSystemWeight * 0.66 and transferModData.ItemsTransferred >= SBvars.InventoryTransferSystemItems * 0.33 and SBvars.TraitsLockSystemCanLoseNegative then
				if not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("Disorganized")) then
					player:getTraits():remove("Disorganized");
					if notification == true then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Disorganized"), false, HaloTextHelper.getColorGreen()) end
				end
				if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("Disorganized") then
					if delayedNotification() then HaloTextHelper.addTextWithArrow(player, getText("UI_ETW_DelayedNotificationsStringRemove")..getText("UI_trait_Disorganized"), false, HaloTextHelper.getColorGreen()) end
					ETWCommonFunctions.addTraitToDelayTable(modData, "Disorganized", player, false)
				end
			end
			if not player:HasTrait("Disorganized") and not player:HasTrait("Organized") and transferModData.WeightTransferred >= SBvars.InventoryTransferSystemWeight and transferModData.ItemsTransferred >= SBvars.InventoryTransferSystemItems * 0.66 and SBvars.TraitsLockSystemCanGainPositive then
				if not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("Organized")) then
					player:getTraits():add("Organized");
					-- UI_trait_Packmule is internal string name
					if notification == true then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Packmule"), true, HaloTextHelper.getColorGreen()) end
				end
				if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("Organized") then
					-- UI_trait_Packmule is internal string name
					if delayedNotification() then HaloTextHelper.addTextWithArrow(player, getText("UI_ETW_DelayedNotificationsStringAdd")..getText("UI_trait_Packmule"), true, HaloTextHelper.getColorGreen()) end
					ETWCommonFunctions.addTraitToDelayTable(modData, "Organized", player, true)
				end
			end
			if player:HasTrait("AllThumbs") and transferModData.WeightTransferred >= SBvars.InventoryTransferSystemWeight * 0.33 and transferModData.ItemsTransferred >= SBvars.InventoryTransferSystemItems * 0.66 and SBvars.TraitsLockSystemCanLoseNegative then
				if not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("AllThumbs")) then
					player:getTraits():remove("AllThumbs");
					if notification == true then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_AllThumbs"), false, HaloTextHelper.getColorGreen()) end
				end
				if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("AllThumbs") then
					if delayedNotification() then HaloTextHelper.addTextWithArrow(player, getText("UI_ETW_DelayedNotificationsStringRemove")..getText("UI_trait_AllThumbs"), false, HaloTextHelper.getColorGreen()) end
					ETWCommonFunctions.addTraitToDelayTable(modData, "AllThumbs", player, false)
				end
			end
			if not player:HasTrait("Dextrous") and transferModData.WeightTransferred >= SBvars.InventoryTransferSystemWeight * 0.66 and transferModData.ItemsTransferred >= SBvars.InventoryTransferSystemItems and SBvars.TraitsLockSystemCanGainPositive then
				if not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("Dextrous")) then
					player:getTraits():add("Dextrous");
					if notification == true then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Dexterous"), true, HaloTextHelper.getColorGreen()) end
				end
				if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("Dextrous") then
					ETWCommonFunctions.addTraitToDelayTable(modData, "Dextrous", player, true)
				end
			end
			if player:HasTrait("butterfingers") and transferModData.WeightTransferred >= SBvars.InventoryTransferSystemWeight * 1.5 and transferModData.ItemsTransferred >= SBvars.InventoryTransferSystemItems * 1.5 and SBvars.TraitsLockSystemCanLoseNegative then
				if not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("butterfingers")) then
					player:getTraits():remove("butterfingers");
					if notification == true then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_AllThumbs"), false, HaloTextHelper.getColorGreen()) end
				end
				if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("butterfingers") then
					if delayedNotification() then HaloTextHelper.addTextWithArrow(player, getText("UI_ETW_DelayedNotificationsStringAdd")..getText("UI_trait_AllThumbs"), false, HaloTextHelper.getColorGreen()) end
					ETWCommonFunctions.addTraitToDelayTable(modData, "butterfingers", player, false)
				end
			end
		else
			if detailedDebug() then print("ETW Logger | ISInventoryTransferAction.perform(): not NPC or player?") end
			original_transfer_perform(self);
		end
	else
		original_transfer_perform(self);
	end
end

---Creates an iterator for a list-like table, allowing to iterate over its elements
---@param _list table
---@return function
local function iterList(_list)
	local list = _list;
	local size = list:size() - 1;
	local i = -1;
	return function()
		i = i + 1;
		if i <= size and not list:isEmpty() then
			return list:get(i), i;
		end
	end
end

local original_forageSystem_addOrDropItems = forageSystem.addOrDropItems;
---Overwriting forageSystem.addOrDropItems() here so insert ETW logic catching player picking up herbs while foraging
---@diagnostic disable-next-line: duplicate-set-field
function forageSystem.addOrDropItems(_character, _inventory, _items, _discardItems)
	if ETWCommonLogicChecks.HerbalistShouldExecute() then
		local player = getPlayer();
		if not _discardItems then
			for item in iterList(_items) do
				if detailedDebug() then print("ETW Logger | forageSystem.addOrDropItems(): picking up foraging item: "..item:getFullType()) end
				local herbs = {
					-- Medical herbs
					"Base.Plantain",
					"Base.Comfrey",
					"Base.WildGarlic",
					"Base.CommonMallow",
					"Base.LemonGrass",
					"Base.BlackSage",
					"Base.Ginseng",
					-- Wild Plants
					"Base.Violets",
					"Base.GrapeLeaves",
					"Base.Rosehips",
					-- Wild Herbs
					"Base.Basil",
					"Base.Chives",
					"Base.Cilantro",
					"Base.Oregano",
					"Base.Parsley",
					"Base.Rosemary",
					"Base.Sage",
					"Base.Thyme",
					-- Testing
					--"Base.Twigs",
				}
				for _, herb in pairs(herbs) do
					if herb == item:getFullType() then
						if detailedDebug() then print("ETW Logger | forageSystem.addOrDropItems(): confirmed that it's a herb: "..item:getFullType()) end
						local modData = ETWCommonFunctions.getETWModData(player);
						modData.HerbsPickedUp = modData.HerbsPickedUp + ((SBvars.AffinitySystem and modData.StartingTraits.Herbalist) and 1 * SBvars.AffinitySystemGainMultiplier or 1);
						if debug() then print("ETW Logger | forageSystem.addOrDropItems(): modData.HerbsPickedUp: "..modData.HerbsPickedUp) end
						if not player:HasTrait("Herbalist") and modData.HerbsPickedUp >= SBvars.HerbalistHerbsPicked and SBvars.TraitsLockSystemCanGainPositive then
							player:getTraits():add("Herbalist");
							ETWCommonFunctions.addRecipe(player, "Herbalist");
							if notification == true then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Herbalist"), true, HaloTextHelper.getColorGreen()) end
						end
					end
				end
			end
		end
	end
	return (original_forageSystem_addOrDropItems(_character, _inventory, _items, _discardItems));
end

return ETWActionsOverride;