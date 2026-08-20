require("ETW_ModDataServer")

local ETW_CommonFunctions = require("ETW_CommonFunctions")
local ETW_Registry = require("ETW_Registry")
local ETW_FightingTraits = require("TraitsLogic/ETW_FightingTraits")
local ETW_HealthTraits = require("TraitsLogic/ETW_HealthTraits")
local ETW_MentalTraits = require("TraitsLogic/ETW_MentalTraits")
local ETW_WeatherTraits = require("TraitsLogic/ETW_WeatherTraits")

---@type EvolvingTraitsWorldTraitsRegistries
local ETWTraitsRegistry = ETW_Registry.traits
local gameMode = ETW_CommonFunctions.gameMode()
local logETW = ETW_CommonFunctions.log
local FILENAME = "ETW_EventsOrchestrator.lua"

if
	not ETW_CommonFunctions.gameModeSafeguard(
		FILENAME,
		{ ETW_CommonFunctions.GameMode.SP, ETW_CommonFunctions.GameMode.MP_SERVER }
	)
then
	return
end

---Processes every-minute trait effects while sharing one player traversal.
local function oneMinuteUpdate()
	local climateManager = getClimateManager()
	local rainIntensity = climateManager:getRainIntensity()
	local fogIntensity = climateManager:getFogIntensity()
	local playersList = ETW_CommonFunctions.playersList()
	for i = 0, playersList:size() - 1 do
		local player = playersList:get(i)
		if rainIntensity > 0 then
			ETW_WeatherTraits.rainTraits(player, rainIntensity)
		end
		if fogIntensity > 0 then
			ETW_WeatherTraits.fogTraits(player, fogIntensity)
		end
		local hasAnemic = player:hasTrait(ETWTraitsRegistry.ANEMIC)
		local hasThickBlooded = player:hasTrait(ETWTraitsRegistry.THICK_BLOODED)
		if hasAnemic or hasThickBlooded then
			local bodyDamage = player:getBodyDamage()
			if hasAnemic then
				ETW_HealthTraits.anemicTrait(bodyDamage)
			end
			if hasThickBlooded then
				ETW_HealthTraits.thickBloodedTrait(bodyDamage)
			end
		end
		if player:hasTrait(ETWTraitsRegistry.BLISSFUL) then
			ETW_MentalTraits.blissfulTrait(player)
		end
		local modData = ETW_CommonFunctions.getETWModData(player)
		if modData then
			ETW_MentalTraits.depressiveTrait(player, modData, false)
			ETW_HealthTraits.hardyTrait(player, modData)
			modData.QuickRestLastEndurance = player:getStats():get(CharacterStat.ENDURANCE)
			ETW_HealthTraits.idealWeightTrait(player, modData)
		end
	end
end

---Rolls hourly trait effects.
local function oneHourUpdate()
	local playersList = ETW_CommonFunctions.playersList()
	for i = 0, playersList:size() - 1 do
		local player = playersList:get(i)
		local modData = ETW_CommonFunctions.getETWModData(player)
		if modData then
			ETW_MentalTraits.depressiveTrait(player, modData, true)
		end
	end
end

---Processes tick-level trait effects while sharing one player traversal.
local function everyTickUpdate()
	local playersList = ETW_CommonFunctions.playersList()
	for i = 0, playersList:size() - 1 do
		local player = playersList:get(i)
		if player:hasTrait(ETWTraitsRegistry.PAIN_TOLERANCE) then
			ETW_HealthTraits.painToleranceTrait(player)
		end
		local modData = ETW_CommonFunctions.getETWModData(player)
		if modData and player:hasTrait(ETWTraitsRegistry.QUICK_REST) then
			ETW_HealthTraits.quickRestTrait(player, modData)
		end
	end
end

---@param playerIndex number
---@param player IsoPlayer
local function initializeTraitsLogic(playerIndex, player)
	Events.OnZombieDead.Remove(ETW_FightingTraits.onZombieDead)
	Events.OnZombieDead.Add(ETW_FightingTraits.onZombieDead)
	Events.EveryOneMinute.Remove(oneMinuteUpdate)
	Events.EveryOneMinute.Add(oneMinuteUpdate)
	Events.EveryHours.Remove(oneHourUpdate)
	Events.EveryHours.Add(oneHourUpdate)
	Events.OnTick.Remove(everyTickUpdate)
	Events.OnTick.Add(everyTickUpdate)
	if gameMode == ETW_CommonFunctions.GameMode.MP_SERVER then
		Events.OnTick.Remove(initializeTraitsLogic)
	end
end

local function clearEventsETW()
	Events.OnZombieDead.Remove(ETW_FightingTraits.onZombieDead)
	Events.EveryOneMinute.Remove(oneMinuteUpdate)
	Events.EveryHours.Remove(oneHourUpdate)
	Events.OnTick.Remove(everyTickUpdate)
	logETW("ETW Logger | System: clearEventsETW in " .. FILENAME)
end

if gameMode == ETW_CommonFunctions.GameMode.SP then
	Events.OnCreatePlayer.Remove(initializeTraitsLogic)
	Events.OnCreatePlayer.Add(initializeTraitsLogic)
	Events.OnPlayerDeath.Remove(clearEventsETW)
	Events.OnPlayerDeath.Add(clearEventsETW)
elseif gameMode == ETW_CommonFunctions.GameMode.MP_SERVER then
	Events.OnTick.Add(initializeTraitsLogic)
end
