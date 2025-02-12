local ETWCommonFunctions = {};

---@type EvolvingTraitsWorldSandboxVars
local SBvars = SandboxVars.EvolvingTraitsWorld;

local modOptions;

if not isClient() and not isServer() then
	---Function responsible for setting up mod options on character load
	---@param playerIndex number
	---@param player IsoPlayer
	local function initializeModOptions(playerIndex, player)
		modOptions = PZAPI.ModOptions:getOptions("ETWModOptions");
	end

	Events.OnCreatePlayer.Remove(initializeModOptions);
	Events.OnCreatePlayer.Add(initializeModOptions);
end

---@return boolean
local notification = function() return modOptions:getOption("EnableNotifications"):getValue() end
---@return boolean
local delayedNotification = function() return modOptions:getOption("EnableDelayedNotifications"):getValue() end
---@return boolean
local detailedDebug = function() return modOptions:getOption("GatherDetailedDebug"):getValue() end

---Prints out debugs inside console if detailedDebug is enabled
---@param ... any Optional boolean followed by strings to log
function ETWCommonFunctions.log(...)
	if detailedDebug() then
	    local args = { ... };
		if #args == 0 then
			return
		end
		if type(args[1]) == "boolean" then
			local singleLine = args[1];
			table.remove(args, 1);
			if singleLine then
				print(table.concat(args, " "))
			else
				for _, str in ipairs(args) do
					print(str);
				end
			end
		else
			for _, str in ipairs(args) do
				print(str);
			end
		end
	end
end

local logETW = function(...) ETWCommonFunctions.log(...) end

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
function ETWCommonFunctions.indexOf(tbl, value)
    for i = 1, #tbl do
        if tbl[i] == value then
            return i
        end
    end
    return -1
end

---Plays a sound if enabled in settings
---@param player IsoPlayer|IsoGameCharacter
function ETWCommonFunctions.traitSound(player)
	if modOptions:getOption("EnableSoundNotifications"):getValue() then
		local soundTable = {"ETW_b42", "ETW_b41", "ETW_TLOU", "ETW_SkyrimSkill", "ETW_SkyrimLevel", "ETW_Oblivion", "ETW_Diablo2", "ETW_Witcher3", "ETW_FalloutNV", "ETW_AoE3", "ETW_WoW"};
		local filteredSoundTable = {};
		for index = 1, #soundTable do
			if modOptions:getOption("SoundNotificationSoundSelect"):getValue(index) then
				table.insert(filteredSoundTable, soundTable[index]);
			end
		end
		player:playSoundLocal(filteredSoundTable[ZombRand(#filteredSoundTable) + 1]);
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
			logETW("ETW Logger | Delayed Traits System | Data Dump: " .. traitName.. ", " .. roll .. ", " .. tostring(gained))
		end
	end
end

---Adds xp boosts from a trait to a player
---@param traitName string
local function addXPBoostsFromTrait(traitName)
	local player = getPlayer();
	local trait = TraitFactory.getTrait(traitName);
	local xpBoostMap = trait:getXPBoostMap();
	if xpBoostMap then
		local table = transformIntoKahluaTable(xpBoostMap);
		for perk, boostLevel in pairs(table) do
			logETW(true, "ETW Logger | ETWCommonFunctions.addXPBoostsFromTrait(): perk:", tostring(perk), ", boostLevel:", tostring(boostLevel));
			local oldBoost = player:getXp():getPerkBoost(perk);
			local newBoost = math.min(oldBoost + tonumber(tostring(boostLevel)), 3);
			---@cast newBoost integer
			player:getXp():setPerkBoost(perk, newBoost);
			logETW(true, "ETW Logger | ETWCommonFunctions.addXPBoostsFromTrait(): ", tostring(perk), "old/new boost level:", oldBoost, player:getXp():getPerkBoost(perk));
		end
	end
end

---Add recipes from a trait to player
---@param traitName string
local function addRecipes(traitName)
	local player = getPlayer();
	local trait = TraitFactory.getTrait(traitName);
	local freeRecipes = trait:getFreeRecipes();
	local playerRecipes = player:getKnownRecipes();
	if detailedDebug then print("ETW Logger | ETWCommonFunctions.addRecipes(): adding recipes for trait " .. traitName) end
	for i = 0, freeRecipes:size() - 1 do
		local recipe = freeRecipes:get(i);
		if not playerRecipes:contains(recipe) then
			if detailedDebug then print("ETW Logger | ETWCommonFunctions.addRecipes(): player doesn't have " .. recipe .. ", adding it to known recipes") end
			playerRecipes:add(recipe);
		end
	end
end

---Removes recipes from a trait from a player
---@param traitName string
local function removeRecipes(traitName)
	local player = getPlayer();
	local trait = TraitFactory.getTrait(traitName);
	local freeRecipes = trait:getFreeRecipes();
	local playerRecipes = player:getKnownRecipes();
	if detailedDebug then print("ETW Logger | ETWCommonFunctions.removeRecipes(): removing recipies for trait " .. traitName) end
	for i = 0, freeRecipes:size() - 1 do
		local recipe = freeRecipes:get(i);
		if playerRecipes:contains(recipe) then
			if detailedDebug then print("ETW Logger | ETWCommonFunctions.removeRecipes(): player has " .. recipe .. ", removing it from known recipies") end
			playerRecipes:remove(recipe);
		end
	end
end

---Adds trait to a player, it's exp boosts, recipes and plays the sound
---@param traitName string
function ETWCommonFunctions.addTraitToPlayer(traitName)
	local player = getPlayer();
	if detailedDebug then print("ETW Logger | addTraitToPlayer() : adding trait ", traitName) end
	player:getTraits():add(traitName);
	addRecipes(traitName);
	addXPBoostsFromTrait(traitName);
	ETWCommonFunctions.traitSound(player)
end

---Remvoes trait from a player, it's recipes and plays the sound
---@param traitName string
function ETWCommonFunctions.removeTraitFromPlayer(traitName)
	local player = getPlayer();
	if detailedDebug then print("ETW Logger | removeTraitFromPlayer() : removing trait ", traitName) end
	player:getTraits():remove(traitName);
	removeRecipes(traitName);
	ETWCommonFunctions.traitSound(player)
end

---Function responsible for adding a trait to a Delayed Traits System
---@param modData EvolvingTraitsWorldModData
---@param traitName string
---@param player IsoPlayer|IsoGameCharacter
---@param positiveTrait boolean
function ETWCommonFunctions.addTraitToDelayTable(modData, traitName, player, positiveTrait)
	---@cast player IsoPlayer
	ETWCommonFunctions.traitSound(player);
	if not SBvars.DelayedTraitsSystem then return end
	if detailedDebug() then print("ETW Logger | Delayed Traits System: modData.DelayedStartingTraitsFilled =  " .. tostring(modData.DelayedStartingTraitsFilled)) end
	if not modData.DelayedStartingTraitsFilled then
		if detailedDebug() then print("ETW Logger | Delayed Traits System: player qualifies for " .. traitName .. " from the start of the game, adding it to delayed traits table") end
		table.insert(modData.DelayedTraits, {traitName, SBvars.DelayedTraitsSystemDefaultDelay + SBvars.DelayedTraitsSystemDefaultStartingDelay, false})
	elseif indexOfDelayedTrait(modData.DelayedTraits, traitName) == -1 and not player:HasTrait(traitName) and positiveTrait then
		if detailedDebug() then print("ETW Logger | Delayed Traits System: player qualifies for positive trait " .. traitName .. ", adding it to delayed traits table") end
		table.insert(modData.DelayedTraits, {traitName, SBvars.DelayedTraitsSystemDefaultDelay, false})
	elseif indexOfDelayedTrait(modData.DelayedTraits, traitName) == -1 and player:HasTrait(traitName) and not positiveTrait then
		if detailedDebug() then print("ETW Logger | Delayed Traits System: player qualifies for removing negative trait " .. traitName .. ", adding it to delayed traits table") end
		table.insert(modData.DelayedTraits, {traitName, SBvars.DelayedTraitsSystemDefaultDelay, false})
	else
		if detailedDebug() then print("ETW Logger | Delayed Traits System: player qualifies for " .. traitName .. ", but it's already in delayed traits table or player already has the trait") end
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
	if not SBvars.DelayedTraitsSystem then return true end
	local player = getPlayer();
	local modData = ETWCommonFunctions.getETWModData(player);
	local traitTable = modData.DelayedTraits;
	for index = 1, #traitTable do
		local traitEntry = traitTable[index]
		local traitName, gained = traitEntry[1], traitEntry[3]
		if detailedDebug() then print("ETW Logger | Delayed Traits System: caught check on " .. traitName) end
		if traitName == name and gained then
			if detailedDebug() then print("ETW Logger | Delayed Traits System: caught check on " .. traitName .. ": player qualifies for it; removing it from the table") end
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
			if detailedDebug() then print("ETW Logger | Delayed Traits System: checking if " .. name .. " is already in the table, it is.") end
			return true;
		end
	end
	if detailedDebug() then print("ETW Logger | Delayed Traits System: checking if " .. name .. " is already in the table, it is not.") end
	return false;
end

return ETWCommonFunctions;
