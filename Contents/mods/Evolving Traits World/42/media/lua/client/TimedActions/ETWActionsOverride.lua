local ETWCombinedTraitChecks = require "ETWCombinedTraitChecks";
local ETWCommonFunctions = require "ETWCommonFunctions";
local ETWCommonLogicChecks = require "ETWCommonLogicChecks";
require "ETWModOptions";

---@type EvolvingTraitsWorldSandboxVars
local SBvars = SandboxVars.EvolvingTraitsWorld;

local modOptions;

---@return boolean
local notification = function() return modOptions:getOption("EnableNotifications"):getValue() end;
---@return boolean
local delayedNotification = function() return modOptions:getOption("EnableDelayedNotifications"):getValue() end;
---@return boolean
local debug = function() return modOptions:getOption("GatherDebug"):getValue() end;
---@return boolean
local detailedDebug = function() return modOptions:getOption("GatherDetailedDebug"):getValue() end;

local carPartStartingCondition;

local original_ISFixVehiclePartAction_perform = ISFixVehiclePartAction.perform;
---Overwriting ISFixVehiclePartAction:perform() here to insert ETW logic catching player doing any kind of repairs
---@diagnostic disable-next-line: duplicate-set-field
function ISFixVehiclePartAction:perform()
	local player = self.character;
	local modData = ETWCommonFunctions.getETWModData(player);
	---@type DebugAndNotificationArgs
	if detailedDebug() then print("ETW Logger | ISFixVehiclePartAction:perform(): caught") end;
	local conditionBefore = self.item:getCondition();
	carPartStartingCondition = conditionBefore;
	if detailedDebug() then print("ETW Logger | ISFixVehiclePartAction.perform(): car part conditon: " .. conditionBefore .. " VehiclePartRepairs=" .. modData.VehiclePartRepairs) end;
	original_ISFixVehiclePartAction_perform(self);
end

local original_ISFixVehiclePartAction_complete = ISFixVehiclePartAction.complete;
function ISFixVehiclePartAction:complete()
	if detailedDebug() then print("ETW Logger | ISFixVehiclePartAction:complete(): caught") end;
	original_ISFixVehiclePartAction_complete(self);
	local player = self.character;
	local modData = ETWCommonFunctions.getETWModData(player);
	local conditionAfter = self.item:getCondition();
	local mechanicsShouldExecute = ETWCommonLogicChecks.MechanicsShouldExecute();
	local bodyWorkEnthusiastShouldExecute = ETWCommonLogicChecks.BodyWorkEnthusiastShouldExecute();
	if conditionAfter > carPartStartingCondition and (mechanicsShouldExecute or bodyWorkEnthusiastShouldExecute) then
		modData.VehiclePartRepairs = modData.VehiclePartRepairs + (conditionAfter - carPartStartingCondition);
		local DebugAndNotificationArgs = {debug = debug(), detailedDebug = detailedDebug(), notification = notification(), delayedNotification = delayedNotification()};
		if detailedDebug() then print("ETW Logger | ISFixVehiclePartAction.complete(): car part " .. carPartStartingCondition .. "->" .. conditionAfter .. " VehiclePartRepairs=" .. modData.VehiclePartRepairs) end;
		if bodyWorkEnthusiastShouldExecute then ETWCombinedTraitChecks.bodyworkEnthusiastCheck(DebugAndNotificationArgs) end;
		if mechanicsShouldExecute then ETWCombinedTraitChecks.mechanicsCheck(DebugAndNotificationArgs) end;
	end
	if player:HasTrait("RestorationExpert") then
		if detailedDebug() then print("ETW Logger | ISFixVehiclePartAction.complete(): RestorationExpert present") end;
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
	local DebugAndNotificationArgs = {debug = debug(), detailedDebug = detailedDebug(), notification = notification(), delayedNotification = delayedNotification()};
	if detailedDebug() then print("ETW Logger | ISFixAction:perform(): caught") end;
	local conditionBefore = self.item:getCondition();
	original_ISFixAction_perform(self);
	local conditionAfter = self.item:getCondition();
	local mechanicsShouldExecute = ETWCommonLogicChecks.MechanicsShouldExecute();
	local bodyWorkEnthusiastShouldExecute = ETWCommonLogicChecks.BodyWorkEnthusiastShouldExecute();
	if conditionAfter > conditionBefore and isVehiclePart(self) and (mechanicsShouldExecute or bodyWorkEnthusiastShouldExecute) then
		modData.VehiclePartRepairs = modData.VehiclePartRepairs + (conditionAfter - conditionBefore);
		if detailedDebug() then print("ETW Logger | ISFixAction.perform(): car part " .. conditionBefore .. "->" .. conditionAfter .. " VehiclePartRepairs=" .. modData.VehiclePartRepairs) end;
		if bodyWorkEnthusiastShouldExecute then ETWCombinedTraitChecks.bodyworkEnthusiastCheck(DebugAndNotificationArgs) end;
		if mechanicsShouldExecute then ETWCombinedTraitChecks.mechanicsCheck(DebugAndNotificationArgs) end;
	end
	if player:HasTrait("RestorationExpert") then
		if detailedDebug() then print("ETW Logger | ISFixAction.perform(): RestorationExpert present") end;
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
	local detailedDebugOn = detailedDebug();
	if detailedDebugOn then print("ETW Logger | ISRepairEngine:perform(): caught") end;
	local conditionBefore = self.part:getCondition();
	if detailedDebugOn then print("ETW Logger | ISRepairEngine:perform(): conditionBefore " .. conditionBefore) end;
	original_ISRepairEngine_perform(self);
	---@type DebugAndNotificationArgs
	local DebugAndNotificationArgs = {debug = debug(), detailedDebug = detailedDebug(), notification = notification(), delayedNotification = delayedNotification()};
	local args = { vehicleID = self.vehicle:getId() , conditionBefore = conditionBefore, DebugAndNotificationArgs = DebugAndNotificationArgs};
	sendClientCommand(self.character, 'ETW', 'checkEngineCondition', args);
end

local original_ISChopTreeAction_perform = ISChopTreeAction.perform;
---Overwriting ISChopTreeAction:perform() here to insert ETW logic catching player cutting down trees
---@diagnostic disable-next-line: duplicate-set-field
function ISChopTreeAction:perform()
	if ETWCommonLogicChecks.AxemanShouldExecute() then
		if detailedDebug() then print("ETW Logger | ISChopTreeAction.perform(): caught") end;
		local player = self.character;
		local modData = ETWCommonFunctions.getETWModData(player);
		modData.TreesChopped = modData.TreesChopped + 1;
		if debug() then print("ETW Logger | ISChopTreeAction.perform(): modData.TreesChopped = " .. modData.TreesChopped) end;
		if modData.TreesChopped >= SBvars.AxemanTrees then
			if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("Axeman") then
				if delayedNotification() then HaloTextHelper.addTextWithArrow(player, getText("UI_ETW_DelayedNotificationsStringAdd") .. getText("UI_trait_axeman"), true, HaloTextHelper.getColorGreen()) end;
				ETWCommonFunctions.traitSound(player);
				ETWCommonFunctions.addTraitToDelayTable(modData, "Axeman", player, true);
			elseif not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("Axeman")) then
				player:getTraits():add("Axeman");
				if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_axeman"), true, HaloTextHelper.getColorGreen()) end;
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
	if ETWCommonLogicChecks.InventoryTransferSystemShouldExecute() then
		if self.character:isLocalPlayer() == false then -- checks if it's NPC doing stuff
			if detailedDebug() then print("ETW Logger | ISInventoryTransferAction.perform(): NPC") end;
			original_ISInventoryTransferAction_perform(self);
		elseif self.character == getPlayer() then
			if detailedDebug() then print("ETW Logger | ISInventoryTransferAction.perform(): Player") end;
			local player = self.character;
			local item = self.item;
			local itemWeight = math.max(0, item:getWeight());
			local modData = ETWCommonFunctions.getETWModData(player);
			local transferModData = modData.TransferSystem;
			transferModData.ItemsTransferred = transferModData.ItemsTransferred + 1;
			transferModData.WeightTransferred = transferModData.WeightTransferred + itemWeight;
			if detailedDebug() then print("ETW Logger | ISInventoryTransferAction.perform(): Moving an item with weight of " .. itemWeight) end;
			if debug() then print("ETW Logger | ISInventoryTransferAction.perform(): Moved weight: " .. transferModData.WeightTransferred .. ", Moved Items: " .. transferModData.ItemsTransferred) end;
			original_ISInventoryTransferAction_perform(self);
			if player:HasTrait("Disorganized") and transferModData.WeightTransferred >= SBvars.InventoryTransferSystemWeight * 0.66 and transferModData.ItemsTransferred >= SBvars.InventoryTransferSystemItems * 0.33 and SBvars.TraitsLockSystemCanLoseNegative then
				if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("Disorganized") then
					if delayedNotification() then HaloTextHelper.addTextWithArrow(player, getText("UI_ETW_DelayedNotificationsStringRemove") .. getText("UI_trait_Disorganized"), false, HaloTextHelper.getColorGreen()) end;
					ETWCommonFunctions.traitSound(player);
					ETWCommonFunctions.addTraitToDelayTable(modData, "Disorganized", player, false);
				elseif not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("Disorganized")) then
					player:getTraits():remove("Disorganized");
					if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Disorganized"), false, HaloTextHelper.getColorGreen()) end;
					ETWCommonFunctions.traitSound(player);
				end
			end
			if not player:HasTrait("Disorganized") and not player:HasTrait("Organized") and transferModData.WeightTransferred >= SBvars.InventoryTransferSystemWeight and transferModData.ItemsTransferred >= SBvars.InventoryTransferSystemItems * 0.66 and SBvars.TraitsLockSystemCanGainPositive then
				if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("Organized") then
					-- UI_trait_Packmule is internal string name
					if delayedNotification() then HaloTextHelper.addTextWithArrow(player, getText("UI_ETW_DelayedNotificationsStringAdd") .. getText("UI_trait_Packmule"), true, HaloTextHelper.getColorGreen()) end;
					ETWCommonFunctions.traitSound(player);
					ETWCommonFunctions.addTraitToDelayTable(modData, "Organized", player, true);
				elseif not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("Organized")) then
					player:getTraits():add("Organized");
					-- UI_trait_Packmule is internal string name
					if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Packmule"), true, HaloTextHelper.getColorGreen()) end;
					ETWCommonFunctions.traitSound(player);
				end
			end
			if player:HasTrait("AllThumbs") and transferModData.WeightTransferred >= SBvars.InventoryTransferSystemWeight * 0.33 and transferModData.ItemsTransferred >= SBvars.InventoryTransferSystemItems * 0.66 and SBvars.TraitsLockSystemCanLoseNegative then
				if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("AllThumbs") then
					if delayedNotification() then HaloTextHelper.addTextWithArrow(player, getText("UI_ETW_DelayedNotificationsStringRemove") .. getText("UI_trait_AllThumbs"), false, HaloTextHelper.getColorGreen()) end;
					ETWCommonFunctions.traitSound(player);
					ETWCommonFunctions.addTraitToDelayTable(modData, "AllThumbs", player, false);
				elseif not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("AllThumbs")) then
					player:getTraits():remove("AllThumbs");
					if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_AllThumbs"), false, HaloTextHelper.getColorGreen()) end;
					ETWCommonFunctions.traitSound(player);
				end
			end
            if not player:HasTrait("Dextrous") and transferModData.WeightTransferred >= SBvars.InventoryTransferSystemWeight * 0.66 and transferModData.ItemsTransferred >= SBvars.InventoryTransferSystemItems and SBvars.TraitsLockSystemCanGainPositive then
                if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("Dextrous") then
					if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_ETW_DelayedNotificationsStringAdd") .. getText("UI_trait_Dexterous"), true, HaloTextHelper.getColorGreen()) end;
					ETWCommonFunctions.addTraitToDelayTable(modData, "Dextrous", player, true);
					ETWCommonFunctions.traitSound(player);
				elseif not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("Dextrous")) then
					player:getTraits():add("Dextrous");
					if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Dexterous"), true, HaloTextHelper.getColorGreen()) end;
					ETWCommonFunctions.traitSound(player);
				end
			end
			if player:HasTrait("butterfingers") and transferModData.WeightTransferred >= SBvars.InventoryTransferSystemWeight * 1.5 and transferModData.ItemsTransferred >= SBvars.InventoryTransferSystemItems * 1.5 and SBvars.TraitsLockSystemCanLoseNegative then
				if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("butterfingers") then
					if delayedNotification() then HaloTextHelper.addTextWithArrow(player, getText("UI_ETW_DelayedNotificationsStringAdd") .. getText("UI_trait_AllThumbs"), false, HaloTextHelper.getColorGreen()) end;
					ETWCommonFunctions.traitSound(player);
					ETWCommonFunctions.addTraitToDelayTable(modData, "butterfingers", player, false);
				elseif not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("butterfingers")) then
					player:getTraits():remove("butterfingers");
					if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_AllThumbs"), false, HaloTextHelper.getColorGreen()) end;
					ETWCommonFunctions.traitSound(player);
				end
			end
		else
			if detailedDebug() then print("ETW Logger | ISInventoryTransferAction.perform(): not NPC or player?") end;
			original_ISInventoryTransferAction_perform(self);
		end
	else
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

local original_forageSystem_addOrDropItems = forageSystem.addOrDropItems;
---Overwriting forageSystem.addOrDropItems() here to insert ETW logic catching player picking up herbs while foraging
---@diagnostic disable-next-line: duplicate-set-field
function forageSystem.addOrDropItems(_character, _inventory, _items, _discardItems)
	if ETWCommonLogicChecks.HerbalistShouldExecute() then
		local player = getPlayer();
		local detailedDebug = detailedDebug();
		if not _discardItems then
			for item in iterList(_items) do
				if detailedDebug then print("ETW Logger | forageSystem.addOrDropItems(): picking up foraging item: " .. item:getFullType()) end;
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
						if detailedDebug then print("ETW Logger | forageSystem.addOrDropItems(): confirmed that it's a herb: " .. item:getFullType()) end;
						local modData = ETWCommonFunctions.getETWModData(player);
						modData.HerbsPickedUp = modData.HerbsPickedUp + ((SBvars.AffinitySystem and modData.StartingTraits.Herbalist) and 1 * SBvars.AffinitySystemGainMultiplier or 1);
						if debug() then print("ETW Logger | forageSystem.addOrDropItems(): modData.HerbsPickedUp: " .. modData.HerbsPickedUp) end;
						if not player:HasTrait("Herbalist") and modData.HerbsPickedUp >= SBvars.HerbalistHerbsPicked and SBvars.TraitsLockSystemCanGainPositive then
							player:getTraits():add("Herbalist");
							ETWCommonFunctions.addRecipe(player, "Herbalist");
							if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Herbalist"), true, HaloTextHelper.getColorGreen()) end;
							ETWCommonFunctions.traitSound(player);
						end
					end
				end
			end
		end
	end
	return (original_forageSystem_addOrDropItems(_character, _inventory, _items, _discardItems));
end

---Function responsible for setting up events
---@param playerIndex number
---@param player IsoPlayer
local function initializeModOptions(playerIndex, player)
	modOptions = PZAPI.ModOptions:getOptions("ETWModOptions");
end

Events.OnCreatePlayer.Remove(initializeModOptions);
Events.OnCreatePlayer.Add(initializeModOptions);