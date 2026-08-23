require("ETW_ModDataServer")

local ETW_CommonFunctions = require("ETW_CommonFunctions")
local ETW_Registry = require("ETW_Registry")
local ETW_CombatTraits = require("TraitsLogic/ETW_CombatTraits")
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
		local hasSunSensitivity = player:hasTrait(ETWTraitsRegistry.SUN_SENSITIVITY)
		local modData = ETW_CommonFunctions.getETWModData(player)
		local hasSunSensitivityState = modData
			and (modData.SunSensitivityExposure ~= nil or modData.SunSensitivityAppliedPain ~= nil)
		if hasAnemic or hasThickBlooded or hasSunSensitivity or hasSunSensitivityState then
			local bodyDamage = player:getBodyDamage()
			if hasAnemic then
				ETW_HealthTraits.anemicTrait(bodyDamage)
			end
			if hasThickBlooded then
				ETW_HealthTraits.thickBloodedTrait(bodyDamage)
			end
			if modData and (hasSunSensitivity or hasSunSensitivityState) then
				ETW_WeatherTraits.sunSensitivityTrait(player, bodyDamage, modData, hasSunSensitivity)
			end
		end
		if player:hasTrait(ETWTraitsRegistry.BLISSFUL) then
			ETW_MentalTraits.blissfulTrait(player)
		end
		if
			gameMode == ETW_CommonFunctions.GameMode.SP
			and player:hasTrait(ETWTraitsRegistry.ANTI_GUN_ACTIVIST)
			and player:isAiming()
		then
			local weapon = player:getPrimaryHandItem()
			if weapon and instanceof(weapon, "HandWeapon") and weapon:getSubCategory() == "Firearm" then
				ETW_CombatTraits.antiGunMentalTrait(player)
			end
		end
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
		if player:hasTrait(ETWTraitsRegistry.NOODLE_LEGS) then
			ETW_HealthTraits.noodleLegsTrait(player)
		end
		local modData = ETW_CommonFunctions.getETWModData(player)
		if modData then
			if player:hasTrait(ETWTraitsRegistry.BOUNCER) then
				ETW_CombatTraits.bouncerTrait(player, modData)
			end
			if modData.AntiGunAimingXPCheckPending and player:hasTrait(ETWTraitsRegistry.ANTI_GUN_ACTIVIST) then
				ETW_CombatTraits.antiGunAimingXPPenalty(player, modData)
			end
			if player:hasTrait(ETWTraitsRegistry.QUICK_REST) then
				ETW_HealthTraits.quickRestTrait(player, modData)
			end
		end
	end
end

---@param playerIndex number
---@param player IsoPlayer
local function initializeTraitsLogic(playerIndex, player)
	Events.OnZombieDead.Remove(ETW_CombatTraits.onZombieDead)
	Events.OnZombieDead.Add(ETW_CombatTraits.onZombieDead)
	Events.OnWeaponHitXp.Remove(ETW_CombatTraits.onWeaponHitXP)
	Events.OnWeaponHitXp.Add(ETW_CombatTraits.onWeaponHitXP)
	Events.OnWeaponSwing.Remove(ETW_CombatTraits.onWeaponSwing)
	Events.OnWeaponSwing.Add(ETW_CombatTraits.onWeaponSwing)
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
	Events.OnZombieDead.Remove(ETW_CombatTraits.onZombieDead)
	Events.OnWeaponHitXp.Remove(ETW_CombatTraits.onWeaponHitXP)
	Events.OnWeaponSwing.Remove(ETW_CombatTraits.onWeaponSwing)
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
