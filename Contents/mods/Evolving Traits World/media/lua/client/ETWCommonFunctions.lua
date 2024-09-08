require "ETWModData";
local ETWCommonFunctions = {};

---@type EvolvingTraitsWorldSandboxVars
local SBvars = SandboxVars.EvolvingTraitsWorld;
---@return boolean
local debug = function() return EvolvingTraitsWorld.settings.GatherDebug end;
---@return boolean
local detailedDebug = function() return EvolvingTraitsWorld.settings.GatherDetailedDebug end;

---Function responsible for finding index of delayed trait in Delayed Traits Table
---@param tbl table
---@param value any
---@return integer
local function indexOfDelayedTrait(tbl, value)
	for i = 1, #tbl do
		local subTable = tbl[i]
		if subTable[1] == value then
			return i
		end
	end
	return -1
end

---Function responsible for finding index of a specific item in a flat table
---@param tbl table
---@param value any
---@return integer
local function indexOf(tbl, value)
    for i = 1, #tbl do
        if tbl[i] == value then
            return i
        end
    end
    return -1
end

---Plays a sound if enabled in settings
---@param player IsoPlayer
function ETWCommonFunctions.traitSound(player)
	if EvolvingTraitsWorld.settings.EnableSoundNotifications then
		player:playSoundLocal("ETWGainTrait");
	end
end

---Returns ETW mod data with correct type (for IDE)
---@param player IsoPlayer|IsoGameCharacter
---@return EvolvingTraitsWorldModData
function ETWCommonFunctions.getETWModData(player)
	return player:getModData().EvolvingTraitsWorld
end

---Function responsible printing whole Delayed Traits table into console
function ETWCommonFunctions.delayedTraitsDataDump()
	if SBvars.DelayedTraitsSystem then
		local traitTable = getPlayer():getModData().EvolvingTraitsWorld.DelayedTraits;
		for index = 1, #traitTable do
			local traitEntry = traitTable[index]
			local traitName, roll, gained = traitEntry[1], traitEntry[2], traitEntry[3]
			print("ETW Logger | Delayed Traits System | Data Dump: " .. traitName.. ", " .. roll .. ", " .. tostring(gained))
		end
	end
end

---Set new XP boost
---@param player IsoPlayer
---@param perk Perk
---@param boostLevel number
function ETWCommonFunctions.applyXPBoost(player, perk, boostLevel)
	local newBoost = player:getXp():getPerkBoost(perk) + boostLevel;
	if newBoost > 3 then
		player:getXp():setPerkBoost(perk, 3);
	else
		player:getXp():setPerkBoost(perk, newBoost);
	end
end

---Add recipe to a player
---@param player IsoPlayer
---@param recipe string
function ETWCommonFunctions.addRecipe(player, recipe)
	local playerRecipes = player:getKnownRecipes();
	if not playerRecipes:contains(recipe) then
		playerRecipes:add(recipe);
	end
end

---Function responsible for adding a trait to a Delayed Traits System
---@param modData EvolvingTraitsWorldModData
---@param traitName string
---@param player IsoPlayer|IsoGameCharacter
---@param positiveTrait boolean
function ETWCommonFunctions.addTraitToDelayTable(modData, traitName, player, positiveTrait)
	if not SBvars.DelayedTraitsSystem then return end;
	if detailedDebug() then print("ETW Logger | Delayed Traits System: modData.DelayedStartingTraitsFilled =  " .. tostring(modData.DelayedStartingTraitsFilled)) end;
	if not modData.DelayedStartingTraitsFilled then
		if debug() then print("ETW Logger | Delayed Traits System: player qualifies for " .. traitName .. " from the start of the game, adding it to delayed traits table") end;
		table.insert(modData.DelayedTraits, {traitName, SBvars.DelayedTraitsSystemDefaultDelay + SBvars.DelayedTraitsSystemDefaultStartingDelay, false})
	elseif indexOfDelayedTrait(modData.DelayedTraits, traitName) == -1 and not player:HasTrait(traitName) and positiveTrait then
		if debug() then print("ETW Logger | Delayed Traits System: player qualifies for positive trait " .. traitName .. ", adding it to delayed traits table") end;
		table.insert(modData.DelayedTraits, {traitName, SBvars.DelayedTraitsSystemDefaultDelay, false})
	elseif indexOfDelayedTrait(modData.DelayedTraits, traitName) == -1 and player:HasTrait(traitName) and not positiveTrait then
		if debug() then print("ETW Logger | Delayed Traits System: player qualifies for removing negative trait " .. traitName .. ", adding it to delayed traits table") end;
		table.insert(modData.DelayedTraits, {traitName, SBvars.DelayedTraitsSystemDefaultDelay, false})
	else
		if debug() then print("ETW Logger | Delayed Traits System: player qualifies for " .. traitName .. ", but it's already in delayed traits table or player already has the trait") end;
	end
	if detailedDebug() then
		print("ETW Logger | Delayed Traits System | Data Dump after ETWCommonFunctions.addTraitToDelayTable(); ------------");
		ETWCommonFunctions.delayedTraitsDataDump();
		print("ETW Logger | Delayed Traits System | Data Dump after ETWCommonFunctions.addTraitToDelayTable(); done --------------");
	end
end

---Function responsible for checking if specific trait should be gained/lost, returns true if yes and removes it from the table. Otherwise, returns false.
---@param name string
---@return boolean
function ETWCommonFunctions.checkDelayedTraits(name)
	if not SBvars.DelayedTraitsSystem then return true end;
	local player = getPlayer();
	local modData = ETWCommonFunctions.getETWModData(player);
	local traitTable = modData.DelayedTraits;
	for index = 1, #traitTable do
		local traitEntry = traitTable[index]
		local traitName, gained = traitEntry[1], traitEntry[3]
		if detailedDebug() then print("ETW Logger | Delayed Traits System: caught check on " .. traitName) end;
		if traitName == name and gained then
			if detailedDebug() then print("ETW Logger | Delayed Traits System: caught check on " .. traitName .. ": player qualifies for it; removing it from the table") end;
			table.remove(traitTable, index);
			return true;
		end
	end
	return false;
end

---Function responsible for checking if specific trait is already in Delayed Traits System
---@param name string
---@return boolean
function ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable(name)
	local player = getPlayer();
	local modData = ETWCommonFunctions.getETWModData(player);
	local traitTable = modData.DelayedTraits;
	for index = 1, #traitTable do
		local traitEntry = traitTable[index]
		local traitName = traitEntry[1]
		if traitName == name then
			if detailedDebug() then print("ETW Logger | Delayed Traits System: checking if " .. name .. " is already in the table, it is.") end;
			return true;
		end
	end
	if detailedDebug() then print("ETW Logger | Delayed Traits System: checking if " .. name .. " is already in the table, it is not.") end;
	return false;
end

---Adds item name to the table of unique ripped clothes
---@param player IsoPlayer
---@param item Clothing
function ETWCommonFunctions.addClothingToUniqueRippedClothingList(player, item)
	local itemName = item:getName();
	local modData = ETWCommonFunctions.getETWModData(player);
	if detailedDebug() then print("ETW Logger | ETWCommonFunctions.addClothingToUniqueRippedClothingList() item: " .. itemName) end;
	if indexOf(modData.UniqueClothingRipped, itemName) == -1 then
	    table.insert(modData.UniqueClothingRipped, itemName)
	end
end

return ETWCommonFunctions;
