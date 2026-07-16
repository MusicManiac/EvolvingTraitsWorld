---@class ETW_ModData
local ETW_ModData = {}

local ETW_CommonFunctions = require("ETW_CommonFunctions")

local gameMode = ETW_CommonFunctions.gameMode()

print("ETW_ModData | Detected " .. gameMode .. " environment, loading the file")

---@type EvolvingTraitsWorldSandboxVars
local SBvars = SandboxVars.EvolvingTraitsWorld

---@type EvolvingTraitsWorldRegistries
local ETW_Registry = require("ETW_Registry")
local ETWTraitsRegistry = ETW_Registry.traits

---Returns the midpoint between two numeric values.
---@param a number
---@param b number
---@return number
local function midpoint(a, b)
	return (a + b) / 2
end

---Builds a fixed-size samples array filled with the same value.
---@param value number
---@param sampleCount integer
---@return number[]
local function buildFilledSamples(value, sampleCount)
	local samples = {}
	for i = 1, sampleCount do
		samples[i] = value
	end
	return samples
end

---Seeds a rolling samples array for new saves and migrates legacy single-sample defaults.
---@param existingSamples number[]|nil
---@param initialValue number
---@param sampleCount integer
---@return number[]
local function initializeRollingSamples(existingSamples, initialValue, sampleCount)
	if type(existingSamples) ~= "table" or #existingSamples == 0 then
		return buildFilledSamples(initialValue, sampleCount)
	end
	if #existingSamples == 1 then
		return buildFilledSamples(tonumber(existingSamples[1]) or initialValue, sampleCount)
	end
	return existingSamples
end

---Checks if player has trait and adds it to modData.StartingTraits if it's not there
---@param startingTraits table
---@param player IsoPlayer
---@param trait CharacterTrait
function ETW_ModData.checkStartingTrait(startingTraits, player, trait)
	local traitRegistryId = trait:toString()
	if startingTraits[traitRegistryId] == nil then
		startingTraits[traitRegistryId] = player:hasTrait(trait)
	end
end

---Returns the initial long-term food average based on the player's starting food trait or sandbox neutral midpoint.
---@param startingTraits table<string, boolean>
---@return number
local function getInitialFoodAverage(startingTraits)
	if startingTraits[CharacterTrait.HEARTY_APPETITE:toString()] == true then
		return midpoint(SBvars.FoodSystemGainNegativeThreshold, 0)
	end
	if startingTraits[CharacterTrait.LIGHT_EATER:toString()] == true then
		return midpoint(1, SBvars.FoodSystemGainPositiveThreshold)
	end
	return midpoint(SBvars.FoodSystemGainNegativeThreshold, SBvars.FoodSystemGainPositiveThreshold)
end

---Returns the initial long-term thirst average based on the player's starting thirst trait or sandbox neutral midpoint.
---@param startingTraits table<string, boolean>
---@return number
local function getInitialThirstAverage(startingTraits)
	if startingTraits[CharacterTrait.HIGH_THIRST:toString()] == true then
		return midpoint(SBvars.ThirstSystemGainNegativeThreshold, 0)
	end
	if startingTraits[CharacterTrait.LOW_THIRST:toString()] == true then
		return midpoint(1, SBvars.ThirstSystemGainPositiveThreshold)
	end
	return midpoint(SBvars.ThirstSystemGainNegativeThreshold, SBvars.ThirstSystemGainPositiveThreshold)
end

---Creates modData for player if it doesn't exist and fills it with default values if they don't exist. Should be ran on character creation and loading.
---@param playerIndex number -- The index of the player
---@param player IsoPlayer   -- The player object
function ETW_ModData.createETWModData(playerIndex, player)
	local playerModData = player:getModData()
	print("ETW Logger | System: initializing modData for player " .. player:getUsername())
	playerModData.EvolvingTraitsWorld = playerModData.EvolvingTraitsWorld or {}
	---@type EvolvingTraitsWorldModData
	local modData = playerModData.EvolvingTraitsWorld

	modData.VehiclePartRepairs = modData.VehiclePartRepairs or 0
	modData.EagleEyedKills = modData.EagleEyedKills or 0
	modData.CatEyesCounter = modData.CatEyesCounter or 0
	modData.FoodSicknessWeathered = modData.FoodSicknessWeathered or 0
	modData.TreesChopped = modData.TreesChopped or 0
	modData.PainToleranceCounter = modData.PainToleranceCounter or 0
	modData.UniqueClothingRipped = modData.UniqueClothingRipped or {}
	modData.ImmunitySystemCounter = modData.ImmunitySystemCounter or 0
	modData.PagesReadCounter = modData.PagesReadCounter or 0

	modData.MentalStateInLast60Min = modData.MentalStateInLast60Min or { 0.75 }
	modData.MentalStateInLast24Hours = modData.MentalStateInLast24Hours or { 0.75 }
	modData.MentalStateInLast31Days = modData.MentalStateInLast31Days or { 0.75 }
	modData.RecentAverageMental = modData.RecentAverageMental or 0.75

	modData.StartingTraits = modData.StartingTraits or {}
	local startingTraits = modData.StartingTraits
	ETW_ModData.checkStartingTrait(startingTraits, player, CharacterTrait.CLAUSTROPHOBIC)
	ETW_ModData.checkStartingTrait(startingTraits, player, CharacterTrait.AGORAPHOBIC)
	ETW_ModData.checkStartingTrait(startingTraits, player, CharacterTrait.ASTHMATIC)
	ETW_ModData.checkStartingTrait(startingTraits, player, CharacterTrait.NEEDS_LESS_SLEEP)
	ETW_ModData.checkStartingTrait(startingTraits, player, CharacterTrait.NEEDS_MORE_SLEEP)
	ETW_ModData.checkStartingTrait(startingTraits, player, ETWTraitsRegistry.BLOODLUST)
	ETW_ModData.checkStartingTrait(startingTraits, player, CharacterTrait.SMOKER)
	ETW_ModData.checkStartingTrait(startingTraits, player, CharacterTrait.OUTDOORSMAN)
	ETW_ModData.checkStartingTrait(startingTraits, player, CharacterTrait.HERBALIST)
	ETW_ModData.checkStartingTrait(startingTraits, player, ETWTraitsRegistry.PLUVIOPHILE)
	ETW_ModData.checkStartingTrait(startingTraits, player, ETWTraitsRegistry.PLUVIOPHOBIA)
	ETW_ModData.checkStartingTrait(startingTraits, player, ETWTraitsRegistry.HOMICHLOPHOBIA)
	ETW_ModData.checkStartingTrait(startingTraits, player, ETWTraitsRegistry.HOMICHLOPHILE)
	ETW_ModData.checkStartingTrait(startingTraits, player, CharacterTrait.HEARTY_APPETITE)
	ETW_ModData.checkStartingTrait(startingTraits, player, CharacterTrait.LIGHT_EATER)
	ETW_ModData.checkStartingTrait(startingTraits, player, CharacterTrait.HIGH_THIRST)
	ETW_ModData.checkStartingTrait(startingTraits, player, CharacterTrait.LOW_THIRST)

	local initialFoodAverage = getInitialFoodAverage(startingTraits)
	modData.FoodStateInLast60Min = initializeRollingSamples(modData.FoodStateInLast60Min, initialFoodAverage, 60)
	modData.FoodStateInLast24Hours = initializeRollingSamples(modData.FoodStateInLast24Hours, initialFoodAverage, 24)
	modData.FoodStateInLast31Days = initializeRollingSamples(modData.FoodStateInLast31Days, initialFoodAverage, 31)
	modData.RecentAverageFood = modData.RecentAverageFood or initialFoodAverage

	local initialThirstAverage = getInitialThirstAverage(startingTraits)
	modData.ThirstStateInLast60Min = initializeRollingSamples(modData.ThirstStateInLast60Min, initialThirstAverage, 60)
	modData.ThirstStateInLast24Hours =
		initializeRollingSamples(modData.ThirstStateInLast24Hours, initialThirstAverage, 24)
	modData.ThirstStateInLast31Days =
		initializeRollingSamples(modData.ThirstStateInLast31Days, initialThirstAverage, 31)
	modData.RecentAverageThirst = modData.RecentAverageThirst or initialThirstAverage

	modData.DelayedStartingTraitsFilled = modData.DelayedStartingTraitsFilled or false
	modData.DelayedTraits = modData.DelayedTraits or {}
	for i = #modData.DelayedTraits, 1, -1 do
		local entry = modData.DelayedTraits[i]
		if modData.DelayedTraits[i][1] == nil then
			print("ETW Logger | System: trait in modData.DelayedTraits at index " .. i .. " is nil, deleting it.")
			table.remove(modData.DelayedTraits, i)
		elseif not modData.DelayedTraits[i][1]:match("^[A-Za-z]+:[A-Za-z]+$") then
			print(
				"ETW Logger | System: trait "
					.. modData.DelayedTraits[i][1]
					.. " in modData.DelayedTraits at index "
					.. i
					.. " doesn't match expected format, deleting it."
			)
			table.remove(modData.DelayedTraits, i)
		end
	end

	if modData.AsthmaticCounter == nil and startingTraits[CharacterTrait.ASTHMATIC:toString()] == true then -- start at full counter if they start with the trait
		modData.AsthmaticCounter = SBvars.AsthmaticCounter * -2
	end
	modData.AsthmaticCounter = modData.AsthmaticCounter or 0

	if modData.HerbsPickedUp == nil and startingTraits[CharacterTrait.HERBALIST:toString()] == true then -- start at full counter if they start with the trait
		modData.HerbsPickedUp = SBvars.HerbalistHerbsPicked
	end
	modData.HerbsPickedUp = modData.HerbsPickedUp or 0

	if modData.RainCounter == nil and startingTraits[ETWTraitsRegistry.PLUVIOPHILE:toString()] == true then -- start at full counter if they start with the trait
		modData.RainCounter = SBvars.RainSystemCounter * 2
	elseif modData.RainCounter == nil and startingTraits[ETWTraitsRegistry.PLUVIOPHOBIA:toString()] == true then
		modData.RainCounter = SBvars.RainSystemCounter * -2
	end
	modData.RainCounter = modData.RainCounter or 0

	if modData.FogCounter == nil and startingTraits[ETWTraitsRegistry.HOMICHLOPHILE:toString()] == true then -- start at full counter if they start with the trait
		modData.FogCounter = SBvars.FogSystemCounter * 2
	elseif modData.FogCounter == nil and startingTraits[ETWTraitsRegistry.HOMICHLOPHOBIA:toString()] == true then
		modData.FogCounter = SBvars.FogSystemCounter * -2
	end
	modData.FogCounter = modData.FogCounter or 0

	modData.OutdoorsmanSystem = modData.OutdoorsmanSystem or {}
	local outdoorsmanSystem = modData.OutdoorsmanSystem
	if
		outdoorsmanSystem.OutdoorsmanCounter == nil
		and startingTraits[CharacterTrait.OUTDOORSMAN:toString()] == true
	then -- start at full counter if they start with the trait
		outdoorsmanSystem.OutdoorsmanCounter = SBvars.OutdoorsmanCounter * 2
	end
	outdoorsmanSystem.OutdoorsmanCounter = outdoorsmanSystem.OutdoorsmanCounter or 0
	outdoorsmanSystem.MinutesSinceOutside = outdoorsmanSystem.MinutesSinceOutside or 0

	modData.LocationFearSystem = modData.LocationFearSystem or {}
	local locationFearSystem = modData.LocationFearSystem
	if locationFearSystem.FearOfInside == nil and startingTraits[CharacterTrait.CLAUSTROPHOBIC:toString()] == true then -- start at full counter if they start with the trait
		locationFearSystem.FearOfInside = SBvars.FearOfLocationsSystemCounter * -2
	end
	if locationFearSystem.FearOfOutside == nil and startingTraits[CharacterTrait.AGORAPHOBIC:toString()] == true then -- start at full counter if they start with the trait
		locationFearSystem.FearOfOutside = SBvars.FearOfLocationsSystemCounter * -2
	end
	locationFearSystem.FearOfInside = locationFearSystem.FearOfInside or 0
	locationFearSystem.FearOfOutside = locationFearSystem.FearOfOutside or 0

	modData.SleepSystem = modData.SleepSystem or {}
	local sleepSystem = modData.SleepSystem
	if sleepSystem.CurrentlySleeping == nil then
		sleepSystem.CurrentlySleeping = false
	end
	sleepSystem.HoursSinceLastSleep = sleepSystem.HoursSinceLastSleep or 0
	sleepSystem.LastMidpoint = sleepSystem.LastMidpoint or 4
	sleepSystem.WentToSleepAt = sleepSystem.WentToSleepAt or 21
	if
		sleepSystem.SleepHealthinessBar == nil
		and startingTraits[CharacterTrait.NEEDS_LESS_SLEEP:toString()] == true
	then
		sleepSystem.SleepHealthinessBar = 200
	elseif
		sleepSystem.SleepHealthinessBar == nil
		and startingTraits[CharacterTrait.NEEDS_MORE_SLEEP:toString()] == true
	then
		sleepSystem.SleepHealthinessBar = sleepSystem.SleepHealthinessBar or -200
	else
		sleepSystem.SleepHealthinessBar = sleepSystem.SleepHealthinessBar or 0
	end

	modData.SmokeSystem = modData.SmokeSystem or {}
	local smokeSystem = modData.SmokeSystem
	if smokeSystem.SmokingAddiction == nil and startingTraits[CharacterTrait.SMOKER:toString()] == true then
		smokeSystem.SmokingAddiction = SBvars.SmokerCounter * 2
	else
		smokeSystem.SmokingAddiction = smokeSystem.SmokingAddiction or 0
	end
	smokeSystem.MinutesSinceLastSmoke = smokeSystem.MinutesSinceLastSmoke or 0

	modData.TransferSystem = modData.TransferSystem or {}
	local transferSystem = modData.TransferSystem
	transferSystem.ItemsTransferred = transferSystem.ItemsTransferred or 0
	transferSystem.WeightTransferred = transferSystem.WeightTransferred or 0

	modData.BloodlustSystem = modData.BloodlustSystem or {}
	local bloodlustSystem = modData.BloodlustSystem
	bloodlustSystem.LastKillTimestamp = bloodlustSystem.LastKillTimestamp or 0
	if bloodlustSystem.BloodlustProgress == nil and startingTraits[ETWTraitsRegistry.BLOODLUST:toString()] == true then
		bloodlustSystem.BloodlustProgress = SBvars.BloodlustProgress
		bloodlustSystem.BloodlustMeter = 18
	else
		bloodlustSystem.BloodlustProgress = bloodlustSystem.BloodlustProgress or SBvars.BloodlustProgress * 0.75
		bloodlustSystem.BloodlustMeter = bloodlustSystem.BloodlustMeter or 0
	end

	modData.AnimalsSystem = modData.AnimalsSystem or {}
	local AnimalsSystem = modData.AnimalsSystem
	AnimalsSystem.UniqueAnimalsPetted = AnimalsSystem.UniqueAnimalsPetted or {}
	AnimalsSystem.LastMinuteTimestampWhenPettedWithBoost = AnimalsSystem.LastMinuteTimestampWhenPettedWithBoost or 0

	playerModData.KillCount = playerModData.KillCount or {}
	playerModData.KillCount.WeaponCategory = playerModData.KillCount.WeaponCategory or {}
	local killCount = playerModData.KillCount.WeaponCategory
	killCount["Axe"] = killCount["Axe"] or { count = 0, WeaponType = {} }
	killCount["Blunt"] = killCount["Blunt"] or { count = 0, WeaponType = {} }
	killCount["SmallBlunt"] = killCount["SmallBlunt"] or { count = 0, WeaponType = {} }
	killCount["LongBlade"] = killCount["LongBlade"] or { count = 0, WeaponType = {} }
	killCount["SmallBlade"] = killCount["SmallBlade"] or { count = 0, WeaponType = {} }
	killCount["Spear"] = killCount["Spear"] or { count = 0, WeaponType = {} }
	killCount["Firearm"] = killCount["Firearm"] or { count = 0, WeaponType = {} }
	killCount["Fire"] = killCount["Fire"] or { count = 0, WeaponType = {} }
	killCount["Vehicles"] = killCount["Vehicles"] or { count = 0, WeaponType = {} }
	killCount["Unarmed"] = killCount["Unarmed"] or { count = 0, WeaponType = {} }
	killCount["Explosives"] = killCount["Explosives"] or { count = 0, WeaponType = {} }
end

---Function responsible for resetting modData on character death
---@param character IsoPlayer
function ETW_ModData.clearETWModData(character)
	print("ETW Logger | System: character " .. character:getUsername() .. " died, clearing its ETW modData")
	character:getModData().EvolvingTraitsWorld = nil
end

return ETW_ModData
