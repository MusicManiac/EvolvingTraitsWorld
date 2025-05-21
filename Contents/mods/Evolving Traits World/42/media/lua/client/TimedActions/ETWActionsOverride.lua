local ETWCombinedTraitChecks = require "ETWCombinedTraitChecks";
local ETWCommonFunctions = require "ETWCommonFunctions";
local ETWCommonLogicChecks = require "ETWCommonLogicChecks";
require "ETWModOptions";

---@type EvolvingTraitsWorldSandboxVars
local SBvars = SandboxVars.EvolvingTraitsWorld;

local modOptions;

---Function responsible for setting up mod options on character load
---@param playerIndex number
---@param player IsoPlayer
local function initializeModOptions(playerIndex, player)
	modOptions = PZAPI.ModOptions:getOptions("ETWModOptions");
end

Events.OnMainMenuEnter.Remove(initializeModOptions);
Events.OnMainMenuEnter.Add(initializeModOptions);
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

local carPartStartingCondition;

local original_ISFixVehiclePartAction_perform = ISFixVehiclePartAction.perform;
---Overwriting ISFixVehiclePartAction:perform() here to insert ETW logic catching player doing any kind of repairs
---@diagnostic disable-next-line: duplicate-set-field
function ISFixVehiclePartAction:perform()
	local player = self.character;
	local modData = ETWCommonFunctions.getETWModData(player);
	---@type DebugAndNotificationArgs
	logETW("ETW Logger | ISFixVehiclePartAction:perform(): caught");
	local conditionBefore = self.item:getCondition();
	carPartStartingCondition = conditionBefore;
	logETW("ETW Logger | ISFixVehiclePartAction.perform(): car part conditon: " .. conditionBefore .. " VehiclePartRepairs=" .. modData.VehiclePartRepairs);
	original_ISFixVehiclePartAction_perform(self);
end

local original_ISFixVehiclePartAction_complete = ISFixVehiclePartAction.complete;
function ISFixVehiclePartAction:complete()
	logETW("ETW Logger | ISFixVehiclePartAction:complete(): caught");
	original_ISFixVehiclePartAction_complete(self);
	local player = self.character;
	local modData = ETWCommonFunctions.getETWModData(player);
	local conditionAfter = self.item:getCondition();
	local mechanicsShouldExecute = ETWCommonLogicChecks.MechanicsShouldExecute();
	local bodyWorkEnthusiastShouldExecute = ETWCommonLogicChecks.BodyWorkEnthusiastShouldExecute();
	if conditionAfter > carPartStartingCondition and (mechanicsShouldExecute or bodyWorkEnthusiastShouldExecute) then
		modData.VehiclePartRepairs = modData.VehiclePartRepairs + (conditionAfter - carPartStartingCondition);
		local DebugAndNotificationArgs = {detailedDebug = detailedDebug(), notification = notification(), delayedNotification = delayedNotification()};
		logETW(
			"ETW Logger | ISFixVehiclePartAction.complete(): car part " .. carPartStartingCondition .. "->" .. conditionAfter ..
			" VehiclePartRepairs=" .. modData.VehiclePartRepairs
		);
		if bodyWorkEnthusiastShouldExecute then ETWCombinedTraitChecks.bodyworkEnthusiastCheck(DebugAndNotificationArgs) end
		if mechanicsShouldExecute then ETWCombinedTraitChecks.mechanicsCheck(DebugAndNotificationArgs) end
	end
	if player:HasTrait("RestorationExpert") then
		logETW("ETW Logger | ISFixVehiclePartAction.complete(): RestorationExpert present");
		local chance = SBvars.RestorationExpertChance - 1;
		if ZombRand(100) <= chance then
			self.item:setHaveBeenRepaired(self.item:getHaveBeenRepaired() - 1);
		end
	end
	carPartStartingCondition = nil;
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

local original_ISFixAction_perform = ISFixAction.perform;
---Overwriting ISFixAction:perform() here to insert ETW logic catching player doing any kind of repairs
---@diagnostic disable-next-line: duplicate-set-field
function ISFixAction:perform()
	local player = self.character;
	local modData = ETWCommonFunctions.getETWModData(player);
	---@type DebugAndNotificationArgs
	local DebugAndNotificationArgs = {detailedDebug = detailedDebug(), notification = notification(), delayedNotification = delayedNotification()};
	logETW("ETW Logger | ISFixAction:perform(): caught");
	local conditionBefore = self.item:getCondition();
	original_ISFixAction_perform(self);
	local conditionAfter = self.item:getCondition();
	local mechanicsShouldExecute = ETWCommonLogicChecks.MechanicsShouldExecute();
	local bodyWorkEnthusiastShouldExecute = ETWCommonLogicChecks.BodyWorkEnthusiastShouldExecute();
	if conditionAfter > conditionBefore and isVehiclePart(self) and (mechanicsShouldExecute or bodyWorkEnthusiastShouldExecute) then
		modData.VehiclePartRepairs = modData.VehiclePartRepairs + (conditionAfter - conditionBefore);
		logETW(
			"ETW Logger | ISFixAction.perform(): car part " .. conditionBefore .. "->" .. conditionAfter ..
			" VehiclePartRepairs=" .. modData.VehiclePartRepairs
		);
		if bodyWorkEnthusiastShouldExecute then ETWCombinedTraitChecks.bodyworkEnthusiastCheck(DebugAndNotificationArgs) end
		if mechanicsShouldExecute then ETWCombinedTraitChecks.mechanicsCheck(DebugAndNotificationArgs) end
	end
	if player:HasTrait("RestorationExpert") then
		logETW("ETW Logger | ISFixAction.perform(): RestorationExpert present");
		local chance = SBvars.RestorationExpertChance - 1;
		if ZombRand(100) <= chance then
			self.item:setHaveBeenRepaired(self.item:getHaveBeenRepaired() - 1);
		end
	end
end

local original_ISRepairEngine_perform = ISRepairEngine.perform;
---Overwriting ISRepairEngine:perform() here to insert ETW logic catching player doing engine repairs
---@diagnostic disable-next-line: duplicate-set-field
function ISRepairEngine:perform()
	local conditionBefore = self.part:getCondition();
	logETW("ETW Logger | ISRepairEngine:perform(): caught. conditionBefore " .. conditionBefore);
	original_ISRepairEngine_perform(self);
	---@type DebugAndNotificationArgs
	local DebugAndNotificationArgs = {detailedDebug = detailedDebug(), notification = notification(), delayedNotification = delayedNotification()};
	local args = { vehicleID = self.vehicle:getId() , conditionBefore = conditionBefore, DebugAndNotificationArgs = DebugAndNotificationArgs};
	sendClientCommand(self.character, 'ETW', 'checkEngineCondition', args);
end

local original_ISChopTreeAction_perform = ISChopTreeAction.perform;
---Overwriting ISChopTreeAction:perform() here to insert ETW logic catching player cutting down trees
---@diagnostic disable-next-line: duplicate-set-field
function ISChopTreeAction:perform()
	if ETWCommonLogicChecks.AxemanShouldExecute() then
		logETW("ETW Logger | ISChopTreeAction.perform(): caught");
		local player = self.character;
		local modData = ETWCommonFunctions.getETWModData(player);
		modData.TreesChopped = modData.TreesChopped + 1;
		logETW("ETW Logger | ISChopTreeAction.perform(): modData.TreesChopped = " .. modData.TreesChopped);
		if modData.TreesChopped >= SBvars.AxemanTrees then
			if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("Axeman") then
				if delayedNotification() then
					HaloTextHelper.addTextWithArrow(
						player,
						getText("UI_ETW_DelayedNotificationsStringAdd") .. getText("UI_trait_axeman"),
						true,
						HaloTextHelper.getColorGreen()
					);
				end
				ETWCommonFunctions.traitSound(player);
				ETWCommonFunctions.addTraitToDelayTable(modData, "Axeman", player, true);
			elseif not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("Axeman")) then
				player:getTraits():add("Axeman");
				if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_axeman"), true, HaloTextHelper.getColorGreen()) end
				ETWCommonFunctions.traitSound(player);
			end
		end
	end
	original_ISChopTreeAction_perform(self);
end

local original_ISInventoryTransferAction_perform = ISInventoryTransferAction.perform;
---Overwriting ISInventoryTransferAction:perform() here to insert ETW logic catching player transferring items
---@diagnostic disable-next-line: duplicate-set-field
function ISInventoryTransferAction:perform()
	if ETWCommonLogicChecks.InventoryTransferSystemShouldExecute() and self.character == getPlayer() then
		logETW("ETW Logger | ISInventoryTransferAction.perform(): Player");
		local player = self.character;
		local item = self.item;
		local itemWeight = math.max(0, item:getWeight());
		local modData = ETWCommonFunctions.getETWModData(player);
		local transferModData = modData.TransferSystem;
		transferModData.ItemsTransferred = transferModData.ItemsTransferred + 1;
		transferModData.WeightTransferred = transferModData.WeightTransferred + itemWeight;
		logETW(
			"ETW Logger | ISInventoryTransferAction.perform(): Moving an item with weight of " .. itemWeight,
			"ETW Logger | ISInventoryTransferAction.perform(): Moved weight: " .. transferModData.WeightTransferred .. ", Moved Items: " .. transferModData.ItemsTransferred
		)
		original_ISInventoryTransferAction_perform(self);
		if player:HasTrait("Disorganized") and transferModData.WeightTransferred >= SBvars.InventoryTransferSystemWeight * 0.66
		and transferModData.ItemsTransferred >= SBvars.InventoryTransferSystemItems * 0.33 and SBvars.TraitsLockSystemCanLoseNegative then
			if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("Disorganized") then
				if delayedNotification() then
					HaloTextHelper.addTextWithArrow(
						player,
						getText("UI_ETW_DelayedNotificationsStringRemove") .. getText("UI_trait_Disorganized"),
						false,
						HaloTextHelper.getColorGreen()
					);
				end
				ETWCommonFunctions.addTraitToDelayTable(modData, "Disorganized", player, false);
			elseif not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("Disorganized")) then
				player:getTraits():remove("Disorganized");
				if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Disorganized"), false, HaloTextHelper.getColorGreen()) end
			end
		end
		if not player:HasTrait("Disorganized") and not player:HasTrait("Organized") and transferModData.WeightTransferred >= SBvars.InventoryTransferSystemWeight
		and transferModData.ItemsTransferred >= SBvars.InventoryTransferSystemItems * 0.66 and SBvars.TraitsLockSystemCanGainPositive then
			if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("Organized") then
				-- UI_trait_Packmule is internal string name
				ETWCommonFunctions.addTraitToDelayTable(modData, "Organized", player, true);
				if delayedNotification() then
					HaloTextHelper.addTextWithArrow(
						player,
						getText("UI_ETW_DelayedNotificationsStringAdd") .. getText("UI_trait_Packmule"),
						true,
						HaloTextHelper.getColorGreen()
					);
				end
			elseif not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("Organized")) then
				player:getTraits():add("Organized");
				-- UI_trait_Packmule is internal string name
				if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Packmule"), true, HaloTextHelper.getColorGreen()) end
			end
		end
		if player:HasTrait("AllThumbs") and transferModData.WeightTransferred >= SBvars.InventoryTransferSystemWeight * 0.33
		and transferModData.ItemsTransferred >= SBvars.InventoryTransferSystemItems * 0.66 and SBvars.TraitsLockSystemCanLoseNegative then
			if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("AllThumbs") then
				ETWCommonFunctions.addTraitToDelayTable(modData, "AllThumbs", player, false);
				if delayedNotification() then
					HaloTextHelper.addTextWithArrow(
						player,
						getText("UI_ETW_DelayedNotificationsStringRemove") .. getText("UI_trait_AllThumbs"),
						false,
						HaloTextHelper.getColorGreen()
					);
				end
			elseif not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("AllThumbs")) then
				player:getTraits():remove("AllThumbs");
				if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_AllThumbs"), false, HaloTextHelper.getColorGreen()) end
				ETWCommonFunctions.traitSound(player);
			end
		end
		if not player:HasTrait("Dextrous") and transferModData.WeightTransferred >= SBvars.InventoryTransferSystemWeight * 0.66
		and transferModData.ItemsTransferred >= SBvars.InventoryTransferSystemItems and SBvars.TraitsLockSystemCanGainPositive then
			if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("Dextrous") then
				if notification() then
					ETWCommonFunctions.addTraitToDelayTable(modData, "Dextrous", player, true);
					HaloTextHelper.addTextWithArrow(
						player,
						getText("UI_ETW_DelayedNotificationsStringAdd") .. getText("UI_trait_Dexterous"),
						true,
						HaloTextHelper.getColorGreen()
					);
				end
			elseif not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("Dextrous")) then
				player:getTraits():add("Dextrous");
				if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Dexterous"), true, HaloTextHelper.getColorGreen()) end
			end
		end
		if player:HasTrait("butterfingers") and transferModData.WeightTransferred >= SBvars.InventoryTransferSystemWeight * 1.5
		and transferModData.ItemsTransferred >= SBvars.InventoryTransferSystemItems * 1.5 and SBvars.TraitsLockSystemCanLoseNegative then
			if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("butterfingers") then
				if delayedNotification() then
					ETWCommonFunctions.addTraitToDelayTable(modData, "butterfingers", player, false);
					HaloTextHelper.addTextWithArrow(
						player,
						getText("UI_ETW_DelayedNotificationsStringAdd") .. getText("UI_trait_AllThumbs"),
						false,
						HaloTextHelper.getColorGreen()
					);
				end
			elseif not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("butterfingers")) then
				player:getTraits():remove("butterfingers");
				if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_AllThumbs"), false, HaloTextHelper.getColorGreen()) end
			end
		end
	else
		logETW("ETW Logger | ISInventoryTransferAction.perform(): not a player or not running ITS");
		original_ISInventoryTransferAction_perform(self);
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

local filteredForageHashMap;

---Generates a list of herb types based on valid categories
local function generateHerbsList()
	local validCategories = { WildHerbs = true, WildPlants = true, MedicinalPlants = true };
	local filteredTypesMap = {}

	for itemName, defTable in pairs(forageSystem.forageDefinitions or {}) do
		if type(defTable) == "table" and defTable.type and defTable.categories then
			for _, category in ipairs(defTable.categories) do
				if validCategories[category] then
					filteredTypesMap[defTable.type] = true
					break
				end
			end
		end
	end

	if detailedDebug() then
		print("ETW Logger | Filtered Types Map:")
		for herbType, _ in pairs(filteredTypesMap) do
			print(herbType)
		end
	end

	filteredForageHashMap = filteredTypesMap
end


Events.onAddForageDefs.Remove(generateHerbsList)
Events.onAddForageDefs.Add(generateHerbsList)

local original_forageSystem_addOrDropItems = forageSystem.addOrDropItems;
---Decorating forageSystem.addOrDropItems() here to insert ETW logic catching player picking up herbs while foraging
---@diagnostic disable-next-line: duplicate-set-field
function forageSystem.addOrDropItems(_character, _inventory, _items, _discardItems)
	if ETWCommonLogicChecks.HerbalistShouldExecute() and SBvars.TraitsLockSystemCanGainPositive then
		local player = getPlayer();
		local detailedDebug = detailedDebug();
		if not _discardItems then
			for item in iterList(_items) do
				logETW("ETW Logger | forageSystem.addOrDropItems(): picking up foraging item: " .. item:getFullType());
				if filteredForageHashMap[item:getFullType()] then
					local modData = ETWCommonFunctions.getETWModData(player);
					modData.HerbsPickedUp = modData.HerbsPickedUp +
						((SBvars.AffinitySystem and modData.StartingTraits.Herbalist) and 1 * SBvars.AffinitySystemGainMultiplier or 1);
					logETW("ETW Logger | forageSystem.addOrDropItems(): modData.HerbsPickedUp: " .. modData.HerbsPickedUp);
					if not player:HasTrait("Herbalist") and modData.HerbsPickedUp >= SBvars.HerbalistHerbsPicked and SBvars.TraitsLockSystemCanGainPositive then
						player:getTraits():add("Herbalist");
						ETWCommonFunctions.addRecipes("Herbalist");
						if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Herbalist"), true, HaloTextHelper.getColorGreen()) end
						ETWCommonFunctions.traitSound(player);
					end
				end
			end
		end
	end
	return (original_forageSystem_addOrDropItems(_character, _inventory, _items, _discardItems));
end
