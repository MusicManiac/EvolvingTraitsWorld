local ETW_CombinedTraitChecks = require("ETW_CombinedTraitChecks")
local ETW_CommonFunctions = require("ETW_CommonFunctions")
local ETW_CommonLogicChecks = require("ETW_CommonLogicChecks")

---@type EvolvingTraitsWorldSandboxVars
local SBvars = SandboxVars.EvolvingTraitsWorld

---@type EvolvingTraitsWorldRegistries
local ETW_Registry = require("ETW_Registry")
---@type EvolvingTraitsWorldTraitsRegistries
local ETWTraitsRegistry = ETW_Registry.traits

---@type fun(...: string)
local logETW = ETW_CommonFunctions.log

local FILENAME = "ETW_ActionsOverrideServer.lua"

if
	not ETW_CommonFunctions.gameModeSafeguard(
		FILENAME,
		{ ETW_CommonFunctions.GameMode.SP, ETW_CommonFunctions.GameMode.MP_SERVER }
	)
then
	return
end

local random_instance = newrandom()

local original_ISFixVehiclePartAction_complete = ISFixVehiclePartAction.complete
function ISFixVehiclePartAction:complete()
	logETW("ETW Logger | ISFixVehiclePartAction:complete(): caught")
	local partConditionBeforeRepair = self.item:getCondition()
	local originalReturn = original_ISFixVehiclePartAction_complete(self)
	local modData = ETW_CommonFunctions.getETWModData(self.character)
	local conditionAfterRepair = self.item:getCondition()
	local mechanicsShouldExecute = ETW_CommonLogicChecks.MechanicsShouldExecute(self.character)
	local bodyWorkEnthusiastShouldExecute = ETW_CommonLogicChecks.BodyWorkEnthusiastShouldExecute(self.character)
	if
		conditionAfterRepair > partConditionBeforeRepair
		and (mechanicsShouldExecute or bodyWorkEnthusiastShouldExecute)
	then
		modData.VehiclePartRepairs = modData.VehiclePartRepairs + (conditionAfterRepair - partConditionBeforeRepair)
		logETW(
			"ETW Logger | ISFixVehiclePartAction.complete(): car part "
				.. partConditionBeforeRepair
				.. "->"
				.. conditionAfterRepair
				.. " VehiclePartRepairs="
				.. modData.VehiclePartRepairs
		)
		if bodyWorkEnthusiastShouldExecute then
			ETW_CombinedTraitChecks.bodyworkEnthusiastCheck(self.character)
		end
		if mechanicsShouldExecute then
			ETW_CombinedTraitChecks.mechanicsCheck(self.character)
		end
	end
	return originalReturn
end

local original_ISFixAction_complete = ISFixAction.complete
---Overwriting ISFixAction:perform() here to insert ETW logic catching player doing any kind of repairs and trigger RestorationExpert
function ISFixAction:complete()
	logETW("ETW Logger | ISFixAction.complete(): caught")
	local originalReturn = original_ISFixAction_complete(self)
	if self.character:hasTrait(ETWTraitsRegistry.RESTORATION_EXPERT) then
		logETW("ETW Logger | ISFixAction.complete(): RestorationExpert present")
		if random_instance:random(100) <= SBvars.RestorationExpertChance then
			self.item:setHaveBeenRepaired(math.max(0, self.item:getHaveBeenRepaired() - 1))
		end
	end
	return originalReturn
end

local original_ISChopTreeAction_complete = ISChopTreeAction.complete
---Overwriting ISChopTreeAction:perform() here to insert ETW logic catching player doing any kind of repairs and trigger RestorationExpert
function ISChopTreeAction:complete()
	local modData = ETW_CommonFunctions.getETWModData(self.character)
	modData.TreesChopped = modData.TreesChopped + 1
	logETW("ETW Logger | ISChopTreeAction.perform(): modData.TreesChopped = " .. modData.TreesChopped)
	if modData.TreesChopped >= SBvars.AxemanTrees then
		if
			SBvars.DelayedTraitsSystem
			and not ETW_CommonFunctions.checkIfTraitIsInDelayedTraitsTable(self.character, CharacterTrait.AXEMAN)
		then
			ETW_CommonFunctions.addTraitToDelayTable({
				modData = modData,
				trait = CharacterTrait.AXEMAN,
				player = self.character,
				positiveTrait = true,
				gainingTrait = true,
			})
		elseif
			not SBvars.DelayedTraitsSystem
			or (
				SBvars.DelayedTraitsSystem
				and ETW_CommonFunctions.checkDelayedTraits(self.character, CharacterTrait.AXEMAN)
			)
		then
			ETW_CommonFunctions.addTraitToPlayer({
				player = self.character,
				trait = CharacterTrait.AXEMAN,
				positiveTrait = true,
			})
		end
	end
	return originalReturn
end

local original_ISRepairEngine_complete = ISRepairEngine.complete
---Overwriting ISRepairEngine:perform() here to insert ETW logic catching player doing engine repairs
function ISRepairEngine:complete()
	logETW("ETW Logger | ISRepairEngine:complete(): caught.")
	local conditionBefore = self.part:getCondition()
	local modData = ETW_CommonFunctions.getETWModData(self.character)
	local originalReturn = original_ISRepairEngine_complete(self)
	local conditionAfterRepair = self.part:getCondition()
	local mechanicsShouldExecute = ETW_CommonLogicChecks.MechanicsShouldExecute(self.character)
	local bodyWorkEnthusiastShouldExecute = ETW_CommonLogicChecks.BodyWorkEnthusiastShouldExecute(self.character)
	if conditionAfterRepair > conditionBefore and (mechanicsShouldExecute or bodyWorkEnthusiastShouldExecute) then
		modData.VehiclePartRepairs = modData.VehiclePartRepairs + (conditionAfterRepair - conditionBefore)
		logETW(
			"ETW Logger | ISRepairEngine.complete(): car part "
				.. conditionBefore
				.. "->"
				.. conditionAfterRepair
				.. " VehiclePartRepairs="
				.. modData.VehiclePartRepairs
		)
		if bodyWorkEnthusiastShouldExecute then
			ETW_CombinedTraitChecks.bodyworkEnthusiastCheck(self.character)
		end
		if mechanicsShouldExecute then
			ETW_CombinedTraitChecks.mechanicsCheck(self.character)
		end
	end
	return originalReturn
end

---Creates an iterator for a list-like table, allowing to iterate over its elements
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

---Generates a list of herb types based on valid categories
local function generateHerbsList()
	local validCategories = { WildHerbs = true, WildPlants = true, MedicinalPlants = true }
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

	ETW_CommonFunctions.log("ETW Logger | Filtered Types Map:")
	for herbType, _ in pairs(filteredTypesMap) do
		ETW_CommonFunctions.log(herbType)
	end

	filteredForageHashMap = filteredTypesMap
end

Events.onAddForageDefs.Remove(generateHerbsList)
Events.onAddForageDefs.Add(generateHerbsList)

local original_forageSystem_addOrDropItems = forageSystem.addOrDropItems
---Decorating forageSystem.addOrDropItems() here to insert ETW logic catching player picking up herbs while foraging
function forageSystem.addOrDropItems(_character, _inventory, _items)
	if ETW_CommonLogicChecks.HerbalistShouldExecute(_character) and SBvars.TraitsLockSystemCanGainPositive then
		for item in iterList(_items) do
			logETW("ETW Logger | forageSystem.addOrDropItems(): picking up foraging item: " .. item:getFullType())
			if filteredForageHashMap[item:getFullType()] then
				local modData = ETW_CommonFunctions.getETWModData(_character)
				modData.HerbsPickedUp = modData.HerbsPickedUp
					+ (
						(SBvars.AffinitySystem and modData.StartingTraits[CharacterTrait.HERBALIST:toString()])
							and 1 * SBvars.AffinitySystemGainMultiplier
						or 1
					)
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
	return (original_forageSystem_addOrDropItems(_character, _inventory, _items))
end
