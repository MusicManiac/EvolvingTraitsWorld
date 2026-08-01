local ETW_CommonFunctions = require("ETW_CommonFunctions")
local ETW_CommonLogicChecks = require("ETW_CommonLogicChecks")

---@type EvolvingTraitsWorldSandboxVars
local SBvars = SandboxVars.EvolvingTraitsWorld

local FILENAME = "ETW_forageSystemOverrideServer.lua"
if
	not ETW_CommonFunctions.gameModeSafeguard(
		FILENAME,
		{ ETW_CommonFunctions.GameMode.SP, ETW_CommonFunctions.GameMode.MP_SERVER }
	)
then
	return
end

---@type fun(...: string)
local logETW = ETW_CommonFunctions.log

---Creates an iterator for a list-like table, allowing iteration over its elements.
---@param _list table
---@return function
local function iterList(_list)
	local list = _list
	local size = list:size() - 1
	local i = -1
	return function()
		i = i + 1
		if i <= size and not list:isEmpty() then
			return list:get(i), i
		end
	end
end

local filteredForageHashMap

---Generates a set of herb types from the valid forage categories.
local function generateHerbsList()
	local validCategories = { WildHerbs = true, WildPlants = true, MedicinalPlants = true }
	local filteredTypesMap = {}

	for _, defTable in pairs(forageSystem.forageDefinitions or {}) do
		if type(defTable) == "table" and defTable.type and defTable.categories then
			for _, category in ipairs(defTable.categories) do
				if validCategories[category] then
					filteredTypesMap[defTable.type] = true
					break
				end
			end
		end
	end

	logETW("ETW Logger | Filtered Types Map:")
	for herbType in pairs(filteredTypesMap) do
		logETW(herbType)
	end

	filteredForageHashMap = filteredTypesMap
end

Events.onAddForageDefs.Remove(generateHerbsList)
Events.onAddForageDefs.Add(generateHerbsList)

local original_forageSystem_addOrDropItems = forageSystem.addOrDropItems
---Decorates forageSystem.addOrDropItems() to catch players picking up herbs while foraging.
function forageSystem.addOrDropItems(_character, _inventory, _items)
	if ETW_CommonLogicChecks.HerbalistShouldExecute(_character) and SBvars.TraitsLockSystemCanGainPositive then
		for item in iterList(_items) do
			logETW("ETW Logger | forageSystem.addOrDropItems(): picking up foraging item: " .. item:getFullType())
			if filteredForageHashMap[item:getFullType()] then
				local modData = ETW_CommonFunctions.getETWModData(_character)
				modData.HerbsPickedUp = modData.HerbsPickedUp + 1
				logETW("ETW Logger | forageSystem.addOrDropItems(): modData.HerbsPickedUp: " .. modData.HerbsPickedUp)
				if
					not _character:hasTrait(CharacterTrait.HERBALIST)
					and modData.HerbsPickedUp >= SBvars.HerbalistHerbsPicked
					and SBvars.TraitsLockSystemCanGainPositive
				then
					ETW_CommonFunctions.addTraitToPlayer({
						player = _character,
						trait = CharacterTrait.HERBALIST,
						positiveTrait = true,
					})
				end
			end
		end
	end
	return original_forageSystem_addOrDropItems(_character, _inventory, _items)
end
