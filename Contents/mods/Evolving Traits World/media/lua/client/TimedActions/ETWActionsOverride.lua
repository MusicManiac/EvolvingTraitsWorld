ETWActionsOverride = {};

local ETWCommonFunctions = require "ETWCommonFunctions";

local SBvars = SandboxVars.EvolvingTraitsWorld;
local notification = function() return EvolvingTraitsWorld.settings.EnableNotifications end
local delayedNotification = function() return EvolvingTraitsWorld.settings.EnableDelayedNotifications end
local debug = function() return EvolvingTraitsWorld.settings.GatherDebug end
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

function ETWActionsOverride.bodyworkEnthusiastCheck()
	local player = getPlayer();
	local modData = player:getModData().EvolvingTraitsWorld;
	local level = player:getPerkLevel(Perks.MetalWelding) + player:getPerkLevel(Perks.Mechanics);
	if level >= SBvars.BodyworkEnthusiastSkill and modData.VehiclePartRepairs >= SBvars.BodyworkEnthusiastRepairs then
		if not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("BodyWorkEnthusiast")) then
			player:getTraits():add("BodyWorkEnthusiast");
			applyXPBoost(player, Perks.MetalWelding, 1);
			applyXPBoost(player, Perks.Mechanics, 1);
			addRecipe(player, "Make Metal Walls");
			addRecipe(player, "Make Metal Fences");
			addRecipe(player, "Make Metal Containers");
			addRecipe(player, "Make Metal Sheet");
			addRecipe(player, "Make Small Metal Sheet");
			addRecipe(player, "Make Metal Roof");
			if notification == true then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_BodyWorkEnthusiast"), true, HaloTextHelper.getColorGreen()) end
		end
		if SBvars.DelayedTraitsSystem then
			ETWCommonFunctions.addTraitToDelayTable(modData, "BodyWorkEnthusiast", player, true)
		end
	end
end

function ETWActionsOverride.mechanicsCheck()
	local player = getPlayer();
	local modData = player:getModData().EvolvingTraitsWorld;
	if player:getPerkLevel(Perks.Mechanics) >= SBvars.MechanicsSkill and modData.VehiclePartRepairs >= SBvars.MechanicsRepairs then
		if not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("Mechanics")) then
			player:getTraits():add("Mechanics");
			applyXPBoost(player, Perks.Mechanics, 1);
			addRecipe(player, "Basic Mechanics");
			addRecipe(player, "Intermediate Mechanics");
			if notification == true then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Mechanics"), true, HaloTextHelper.getColorGreen()) end
		end
		if SBvars.DelayedTraitsSystem then
			ETWCommonFunctions.addTraitToDelayTable(modData, "Mechanics", player, true)
		end
	end
end

local original_fix_perform = ISFixAction.perform;
function ISFixAction:perform()
	local player = self.character;
	local modData = player:getModData().EvolvingTraitsWorld;
	local vehiclePartCondition = 0;
	if detailedDebug() then print("ETW Logger | ISFixAction:perform(): caught") end
	if self.vehiclePart then
		local part = self.vehiclePart;
		vehiclePartCondition = part:getCondition();
	end
	original_fix_perform(self);
	if self.vehiclePart and ((SBvars.Mechanics == true and not player:HasTrait("Mechanics")) or (SBvars.BodyWorkEnthusiast == true and not player:HasTrait("BodyWorkEnthusiast"))) then
		if detailedDebug() then print("ETW Logger | ISFixAction.perform(): car part") end
		modData.VehiclePartRepairs = modData.VehiclePartRepairs + (self.vehiclePart:getCondition() - vehiclePartCondition);
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
function ISChopTreeAction:perform()
	if detailedDebug() then print("ETW Logger | ISChopTreeAction.perform(): caught") end
	local player = self.character;
	local modData = player:getModData().EvolvingTraitsWorld;
	modData.TreesChopped = modData.TreesChopped + 1;
	if debug() then print("ETW Logger | ISChopTreeAction.perform(): modData.TreesChopped = "..modData.TreesChopped) end
	if not player:HasTrait("Axeman") and modData.TreesChopped >= SBvars.AxemanTrees then
		if not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("Axeman")) then
			player:getTraits():add("Axeman");
			local notification = EvolvingTraitsWorld.settings.EnableNotifications;
			if notification == true then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_axeman"), true, HaloTextHelper.getColorGreen()) end
		end
		if SBvars.DelayedTraitsSystem then
			ETWCommonFunctions.addTraitToDelayTable(modData, "Axeman", player, true)
		end
	end
	original_chop_perform(self);
end

local original_transfer_perform = ISInventoryTransferAction.perform;
function ISInventoryTransferAction:perform()
	if SBvars.InventoryTransferSystem == true then
		if self.character:isLocalPlayer() == false then -- checks if it's NPC doing stuff
			if detailedDebug() then print("ETW Logger | ISInventoryTransferAction.perform(): NPC") end
			original_transfer_perform(self);
		elseif self.character == getPlayer() then
			if detailedDebug() then print("ETW Logger | ISInventoryTransferAction.perform(): Player") end
			local player = self.character;
			local item = self.item;
			local itemWeight = item:getWeight();
			local modData = player:getModData().EvolvingTraitsWorld;
			local transferModData = modData.TransferSystem;
			transferModData.ItemsTransferred = transferModData.ItemsTransferred + 1;
			transferModData.WeightTransferred = transferModData.WeightTransferred + itemWeight;
			if detailedDebug() then print("ETW Logger | ISInventoryTransferAction.perform(): Moving an item with weight of "..itemWeight) end
			if debug() then print("ETW Logger | ISInventoryTransferAction.perform(): Moved weight: "..transferModData.WeightTransferred..", Moved Items: "..transferModData.ItemsTransferred) end
			original_transfer_perform(self);
			if player:HasTrait("Disorganized") and transferModData.WeightTransferred >= SBvars.InventoryTransferSystemWeight * 0.6 and transferModData.ItemsTransferred >= SBvars.InventoryTransferSystemItems * 0.3 then
				if not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("Disorganized")) then
					player:getTraits():remove("Disorganized");
					if notification == true then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Disorganized"), false, HaloTextHelper.getColorGreen()) end
				end
				if SBvars.DelayedTraitsSystem then
					ETWCommonFunctions.addTraitToDelayTable(modData, "Disorganized", player, false)
				end
			end
			if not player:HasTrait("Disorganized") and not player:HasTrait("Organized") and transferModData.WeightTransferred >= SBvars.InventoryTransferSystemWeight and transferModData.ItemsTransferred >= SBvars.InventoryTransferSystemItems * 0.6 then
				if not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("Organized")) then
					player:getTraits():add("Organized");
					if notification == true then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Packmule"), true, HaloTextHelper.getColorGreen()) end
				end
				if SBvars.DelayedTraitsSystem then
					ETWCommonFunctions.addTraitToDelayTable(modData, "Organized", player, true)
				end
			end
			if player:HasTrait("AllThumbs") and transferModData.WeightTransferred >= SBvars.InventoryTransferSystemWeight * 0.3 and transferModData.ItemsTransferred >= SBvars.InventoryTransferSystemItems * 0.6 then
				if not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("AllThumbs")) then
					player:getTraits():remove("AllThumbs");
					if notification == true then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_AllThumbs"), false, HaloTextHelper.getColorGreen()) end
				end
				if SBvars.DelayedTraitsSystem then
					ETWCommonFunctions.addTraitToDelayTable(modData, "AllThumbs", player, false)
				end
			end
			if not player:HasTrait("Dextrous") and transferModData.WeightTransferred >= SBvars.InventoryTransferSystemWeight * 0.6 and transferModData.ItemsTransferred >= SBvars.InventoryTransferSystemItems then
				if not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("Dextrous")) then
					player:getTraits():add("Dextrous");
					if notification == true then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Dexterous"), true, HaloTextHelper.getColorGreen()) end
				end
				if SBvars.DelayedTraitsSystem then
					ETWCommonFunctions.addTraitToDelayTable(modData, "Dextrous", player, true)
				end
			end
			if player:HasTrait("butterfingers") and transferModData.WeightTransferred >= SBvars.InventoryTransferSystemWeight * 1.5 and transferModData.ItemsTransferred >= SBvars.InventoryTransferSystemItems * 1.5 then
				if not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("butterfingers")) then
					player:getTraits():remove("butterfingers");
					if notification == true then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_AllThumbs"), false, HaloTextHelper.getColorGreen()) end
				end
				if SBvars.DelayedTraitsSystem then
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
function forageSystem.addOrDropItems(_character, _inventory, _items, _discardItems)
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
					local modData = player:getModData().EvolvingTraitsWorld;
					modData.HerbsPickedUp = modData.HerbsPickedUp + ((SBvars.AffinitySystem and modData.StartingTraits.Herbalist) and 1 * SBvars.AffinitySystemGainMultiplier or 1);
					if debug() then print("ETW Logger | forageSystem.addOrDropItems(): modData.HerbsPickedUp: "..modData.HerbsPickedUp) end
					if not player:HasTrait("Herbalist") and modData.HerbsPickedUp >= SBvars.HerbalistHerbsPicked then
						local notification = EvolvingTraitsWorld.settings.EnableNotifications;
						player:getTraits():add("Herbalist");
						addRecipe(player, "Herbalist");
						if notification == true then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Herbalist"), true, HaloTextHelper.getColorGreen()) end
					end
				end
			end
		end
	end
	return (original_forageSystem_addOrDropItems(_character, _inventory, _items, _discardItems));
end

return ETWActionsOverride;