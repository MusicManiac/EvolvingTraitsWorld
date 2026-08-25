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
		local bodyDamage
		local stats
		local modData
		if rainIntensity > 0 then
			stats = stats or player:getStats()
			ETW_WeatherTraits.rainTraits(player, stats, rainIntensity)
		end
		if fogIntensity > 0 then
			stats = stats or player:getStats()
			ETW_WeatherTraits.fogTraits(player, stats, fogIntensity)
		end
		if player:hasTrait(ETWTraitsRegistry.ANEMIC) then
			bodyDamage = bodyDamage or player:getBodyDamage()
			ETW_HealthTraits.anemicTrait(bodyDamage)
		end
		if player:hasTrait(ETWTraitsRegistry.THICK_BLOODED) then
			bodyDamage = bodyDamage or player:getBodyDamage()
			ETW_HealthTraits.thickBloodedTrait(bodyDamage)
		end
		if player:hasTrait(ETWTraitsRegistry.SUN_SENSITIVITY) then
			bodyDamage = bodyDamage or player:getBodyDamage()
			modData = modData or ETW_CommonFunctions.getETWModData(player)
			ETW_WeatherTraits.sunSensitivityTrait(player, bodyDamage, modData)
		end
		if player:hasTrait(ETWTraitsRegistry.UNWAVERING) then
			bodyDamage = bodyDamage or player:getBodyDamage()
			modData = modData or ETW_CommonFunctions.getETWModData(player)
			ETW_HealthTraits.unwaveringTrait(player, bodyDamage, modData)
		end
		if player:hasTrait(ETWTraitsRegistry.SUPER_IMMUNE) then
			bodyDamage = bodyDamage or player:getBodyDamage()
			ETW_HealthTraits.superImmuneTrait(player, bodyDamage)
		end
		if player:hasTrait(ETWTraitsRegistry.BLISSFUL) then
			stats = stats or player:getStats()
			ETW_MentalTraits.blissfulTrait(player, stats)
		end
		if
			-- server doesn't know when player is aiming, so in MP it's covered via command from MP Client, but in SP we can check it here
			gameMode == ETW_CommonFunctions.GameMode.SP
			and (
				player:hasTrait(ETWTraitsRegistry.ANTI_GUN_ACTIVIST)
				or player:hasTrait(ETWTraitsRegistry.TERMINATOR)
			)
			and player:isAiming()
		then
			local weapon = player:getPrimaryHandItem()
			stats = stats or player:getStats()
			if weapon and instanceof(weapon, "HandWeapon") and weapon:getSubCategory() == "Firearm" then
				if player:hasTrait(ETWTraitsRegistry.TERMINATOR) then
					ETW_CombatTraits.terminatorMentalTrait(player, stats)
				else
					ETW_CombatTraits.antiGunMentalTrait(player, stats)
				end
			end
		end
		if player:hasTrait(ETWTraitsRegistry.DEPRESSIVE) then
			stats = stats or player:getStats()
			ETW_MentalTraits.depressiveTrait(player, modData, stats, false)
		end
		if player:hasTrait(ETWTraitsRegistry.HARDY) then
			stats = stats or player:getStats()
			ETW_HealthTraits.hardyTrait(player, stats, modData)
		end
		if player:hasTrait(ETWTraitsRegistry.QUICK_REST) then
			modData = modData or ETW_CommonFunctions.getETWModData(player)
			modData.QuickRestLastEndurance = player:getStats():get(CharacterStat.ENDURANCE)
		end
		if player:hasTrait(ETWTraitsRegistry.IDEAL_WEIGHT) then
			modData = modData or ETW_CommonFunctions.getETWModData(player)
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
		local modData = ETW_CommonFunctions.getETWModData(player)
		local bodyDamage
		local stats
		if player:hasTrait(ETWTraitsRegistry.PAIN_TOLERANCE) then
			stats = stats or player:getStats()
			ETW_HealthTraits.painToleranceTrait(player, stats)
		end
		if player:hasTrait(ETWTraitsRegistry.NOODLE_LEGS) then
			ETW_HealthTraits.noodleLegsTrait(player)
		end
		if modData then
			if modData.IndefatigableProtectionExpiresAt then
				bodyDamage = player:getBodyDamage()
				ETW_HealthTraits.indefatigableProtection(player, bodyDamage, modData)
			end
			if player:hasTrait(ETWTraitsRegistry.INDEFATIGABLE) then
				bodyDamage = bodyDamage or player:getBodyDamage()
				ETW_HealthTraits.indefatigableTrait(player, bodyDamage, modData)
			end
			if player:hasTrait(ETWTraitsRegistry.BOUNCER) then
				ETW_CombatTraits.bouncerTrait(player, modData)
			end
			if modData.AntiGunAimingXPCheckPending and player:hasTrait(ETWTraitsRegistry.ANTI_GUN_ACTIVIST) then
				ETW_CombatTraits.antiGunAimingXPPenalty(player, modData)
			end
			if player:hasTrait(ETWTraitsRegistry.QUICK_REST) then
				stats = stats or player:getStats()
				ETW_HealthTraits.quickRestTrait(player, stats, modData)
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
