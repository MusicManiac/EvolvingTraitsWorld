require("ETWModData")
require("ETWModOptions")
local ETWMoodles = require("ETWMoodles")
local ETWCommonFunctions = require("ETWCommonFunctions")
local ETWCommonLogicChecks = require("ETWCommonLogicChecks")

---@type EvolvingTraitsWorldRegistries
local ETWRegistries = require("ETWRegistry")
---@type EvolvingTraitsWorldTraitsRegistries
local ETWTraitsRegistry = ETWRegistries.traits

---@type EvolvingTraitsWorldSandboxVars
local SBvars = SandboxVars.EvolvingTraitsWorld

local modOptions

---Function responsible for setting up mod options on character load
---@param playerIndex number
---@param player IsoPlayer
local function initializeModOptions(playerIndex, player)
	modOptions = PZAPI.ModOptions:getOptions("ETWModOptions")
end

Events.OnCreatePlayer.Remove(initializeModOptions)
Events.OnCreatePlayer.Add(initializeModOptions)

---@return boolean
local notification = function()
	return modOptions:getOption("EnableNotifications"):getValue()
end
---@return boolean
local delayedNotification = function()
	return modOptions:getOption("EnableDelayedNotifications"):getValue()
end
---@return boolean
local detailedDebug = function()
	return modOptions:getOption("GatherDetailedDebug"):getValue()
end

---Prints out debugs inside console if detailedDebug is enabled
---@param ... string Strings to log
local logETW = function(...)
	ETWCommonFunctions.log(...)
end

local bloodlustMeterCapacity = 72

---Function responsible for checking % of bloodied clothes
---@param player IsoPlayer
---@return number -- percentage of bloodied clothes (0-1)
local function bloodiedClothesLevel(player)
	local wornItems = player:getWornItems()
	local totalBloodLevelPercentage = 0
	local amountOfWornItems = 0
	local detailedDebug = detailedDebug()
	if wornItems ~= nil and wornItems:size() > 1 then
		for i = 0, wornItems:size() - 1, 1 do
			local item = wornItems:getItemByIndex(i)
			if instanceof(item, "Clothing") then
				---@cast item Clothing
				if item:getBloodClothingType() ~= nil then
					local bloodLevel = item:getBloodLevel() or 0
					amountOfWornItems = amountOfWornItems + 1
					totalBloodLevelPercentage = totalBloodLevelPercentage + bloodLevel
					logETW(
						"ETW Logger | bloodiedClothesLevel(): Clothing = "
							.. item:getClothingItemName()
							.. " | blood clothing type = "
							.. tostring(item:getBloodClothingType())
							.. " | blood level = "
							.. bloodLevel
					)
				end
			end
		end
		if amountOfWornItems == 0 then
			return 0
		end
		local avg = totalBloodLevelPercentage / 100 / amountOfWornItems
		logETW("ETW Logger | bloodiedClothesLevel(): avg = " .. avg)
		return avg
	end
	return 0
end

---Function responsible for managing Bloodlust meter
---@param zombie IsoZombie
local function bloodlustKillETW(zombie)
	local player = getPlayer()
	if player:isLocalPlayer() == false then -- checks if it's NPC doing stuff
		logETW("ETW Logger | bloodlustKillETW(): kill by NPC")
	else
		local distance = player:DistTo(zombie)
		logETW("ETW Logger | bloodlustKillETW(): kill by player", "ETW Logger | bloodlustKillETW(): distance=" .. distance)
		if distance <= 10 then
			local modData = ETWCommonFunctions.getETWModData(player)
			local bloodlust = modData.BloodlustSystem
			bloodlust.LastKillTimestamp = player:getHoursSurvived()
			if bloodlust.BloodlustMeter <= bloodlustMeterCapacity then
				bloodlust.BloodlustMeter = bloodlust.BloodlustMeter
					+ math.min(1.4 / distance, 1) * SBvars.BloodlustMeterFillMultiplier * (1 + bloodiedClothesLevel(player))
				logETW("ETW Logger | bloodlustKillETW(): BloodlustMeter=" .. bloodlust.BloodlustMeter)
			elseif bloodlust.BloodlustMeter < bloodlustMeterCapacity * SBvars.BloodlustMeterMaxCapMultiplier then
				bloodlust.BloodlustMeter = bloodlust.BloodlustMeter
					+ math.min(1.4 / distance, 1) * SBvars.BloodlustMeterFillMultiplier * (1 + bloodiedClothesLevel(player)) * 0.5
				logETW("ETW Logger | bloodlustKillETW(): BloodlustMeter (soft-capped)=" .. bloodlust.BloodlustMeter)
			end
			ETWMoodles.bloodlustMoodleUpdate(player, false)
		end
	end
end

---Function responsible for managing Bloodlust meter with flow of time
local function bloodlustTimeETW()
	local player = getPlayer()
	local modData = ETWCommonFunctions.getETWModData(player)
	local bloodlustModData = modData.BloodlustSystem
	bloodlustModData.BloodlustMeter =
		math.min(bloodlustModData.BloodlustMeter, bloodlustMeterCapacity * SBvars.BloodlustMeterMaxCapMultiplier)
	bloodlustModData.BloodlustMeter = math.max(bloodlustModData.BloodlustMeter - 1, 0) -- hourly decay
	ETWMoodles.bloodlustMoodleUpdate(player, false)
	logETW("ETW Logger | bloodlustTimeETW(): Bloodlust Meter: " .. bloodlustModData.BloodlustMeter)
	if bloodlustModData.BloodlustMeter >= bloodlustMeterCapacity / 2 then -- gain if above 50%
		local bloodLustProgressIncrease = bloodlustModData.BloodlustMeter
			* 0.1
			* (1 + bloodiedClothesLevel(player))
			* ((SBvars.AffinitySystem and modData.StartingTraits.Bloodlust) and SBvars.AffinitySystemGainMultiplier or 1)
		bloodlustModData.BloodlustProgress =
			math.min(SBvars.BloodlustProgress * 2, bloodlustModData.BloodlustProgress + bloodLustProgressIncrease)
		logETW("ETW Logger | bloodlustTimeETW(): BloodlustMeter is above 50%, BloodlustProgress =" .. bloodlustModData.BloodlustProgress)
	else -- lose if below 50%
		local bloodLustProgressDecrease = bloodlustModData.BloodlustMeter
			* 0.1
			* (1 - bloodiedClothesLevel(player))
			/ ((SBvars.AffinitySystem and modData.StartingTraits.Bloodlust) and SBvars.AffinitySystemLoseDivider or 1)
		bloodlustModData.BloodlustProgress =
			math.max(0, bloodlustModData.BloodlustProgress - (bloodlustMeterCapacity / 10 - bloodLustProgressDecrease))
		logETW("ETW Logger | bloodlustTimeETW(): BloodlustMeter is below 50%, BloodlustProgress =" .. bloodlustModData.BloodlustProgress)
	end
	if
		player:hasTrait(ETWTraitsRegistry.BLOODLUST)
		and bloodlustModData.BloodlustProgress <= SBvars.BloodlustProgress / 2
		and SBvars.TraitsLockSystemCanLosePositive
	then
		ETWCommonFunctions.removeTraitFromPlayer(ETWTraitsRegistry.BLOODLUST)
		if notification() then
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Bloodlust"), false, HaloTextHelper.getColorRed())
		end
	elseif
		not player:hasTrait(ETWTraitsRegistry.BLOODLUST)
		and bloodlustModData.BloodlustProgress >= SBvars.BloodlustProgress
		and SBvars.TraitsLockSystemCanGainPositive
	then
		ETWCommonFunctions.addTraitToPlayer(ETWTraitsRegistry.BLOODLUST)
		if notification() then
			HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Bloodlust"), true, HaloTextHelper.getColorGreen())
		end
	end
end

---Function responsible for managing Eagle Eyed trait
---@param wielder IsoGameCharacter
---@param character IsoGameCharacter
---@param handWeapon HandWeapon
---@param damage number
local function eagleEyedETW(wielder, character, handWeapon, damage)
	if ETWCommonLogicChecks.EagleEyedShouldExecute() and wielder == getPlayer() and character:isZombie() then
		local player = wielder
		---@cast player IsoPlayer
		local zombie = character
		local zHealth = zombie:getHealth()
		local distance = player:DistTo(zombie)
		local modData = ETWCommonFunctions.getETWModData(player)
		if distance >= SBvars.EagleEyedDistance and zHealth <= damage then
			modData.EagleEyedKills = modData.EagleEyedKills + 1
			logETW(
				"ETW Logger | eagleEyedETW(): Caught a kill on following distance: "
					.. distance
					.. ", current eagle eyed kills:"
					.. modData.EagleEyedKills
			)
			if modData.EagleEyedKills >= SBvars.EagleEyedKills then
				if
					not SBvars.DelayedTraitsSystem
					or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits(CharacterTrait.EAGLE_EYED))
				then
					ETWCommonFunctions.addTraitToPlayer(CharacterTrait.EAGLE_EYED)
					if notification() then
						HaloTextHelper.addTextWithArrow(player, getText("UI_trait_eagleeyed"), true, HaloTextHelper.getColorGreen())
					end
				end
				if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable(CharacterTrait.EAGLE_EYED) then
					ETWCommonFunctions.addTraitToDelayTable({
						modData = modData,
						trait = CharacterTrait.EAGLE_EYED,
						player = player,
						positiveTrait = true,
						gainingTrait = true,
					})
				end
			end
		end
	end
end

local braverySystemTraitInfo = {
	{
		trait = CharacterTrait.COWARDLY,
		threshold = SBvars.BraverySystemKills * 0.1,
		remove = true,
		translationString = getText("UI_trait_cowardly"),
	},
	{
		trait = CharacterTrait.HEMOPHOBIC,
		threshold = SBvars.BraverySystemKills * 0.2,
		remove = true,
		cantHaveTrait = CharacterTrait.COWARDLY,
		translationString = getText("UI_trait_Hemophobic"),
	},
	{
		trait = CharacterTrait.PACIFIST,
		threshold = SBvars.BraverySystemKills * 0.3,
		remove = true,
		cantHaveTrait = CharacterTrait.HEMOPHOBIC,
		translationString = getText("UI_trait_Pacifist"),
	},
	{
		trait = CharacterTrait.ADRENALINE_JUNKIE,
		threshold = SBvars.BraverySystemKills * 0.4,
		add = true,
		cantHaveTrait = CharacterTrait.PACIFIST,
		translationString = getText("UI_trait_AdrenalineJunkie"),
	},
	{
		trait = CharacterTrait.BRAVE,
		threshold = SBvars.BraverySystemKills * 0.6,
		add = true,
		requiredTrait = CharacterTrait.ADRENALINE_JUNKIE,
		translationString = getText("UI_trait_brave"),
	},
	{
		trait = CharacterTrait.DESENSITIZED,
		threshold = SBvars.BraverySystemKills,
		add = true,
		requiredTrait = CharacterTrait.BRAVE,
		translationString = getText("UI_trait_Desensitized"),
	},
}

---Function responsible for managing Bravery System traits
---@param zombie IsoZombie
local function braverySystemETW(zombie)
	local player = getPlayer()
	local totalKills = player:getZombieKills()
	local modDataGlobal = player:getModData()
	if not modDataGlobal or not modDataGlobal.KillCount then
		logETW("ETW Logger | braverySystemETW: interrupting logic on this zombie death. Probably caused by NPC kill.")
		return
	end
	local killCountModData = modDataGlobal.KillCount.WeaponCategory
	local ETWModData = modDataGlobal.EvolvingTraitsWorld
	local fireKills = killCountModData["Fire"].count
	local firearmsKills = killCountModData["Firearm"].count
	local vehiclesKills = killCountModData["Vehicles"].count
	local explosivesKills = killCountModData["Explosives"].count
	local meleeKills = totalKills - firearmsKills - fireKills - vehiclesKills - explosivesKills

	for i = 1, #braverySystemTraitInfo do
		local info = braverySystemTraitInfo[i]
		local trait = info.trait
		local threshold = info.threshold
		local negativeTrait = info.remove
		local positiveTrait = info.add
		local cantHaveTrait = info.cantHaveTrait
		local requiredTrait = info.requiredTrait
		local translationString = info.translationString
		if (totalKills + meleeKills) >= threshold then -- melee kills counted double
			if
				player:hasTrait(trait)
				and negativeTrait
				and (not cantHaveTrait or not player:hasTrait(cantHaveTrait))
				and SBvars.TraitsLockSystemCanLoseNegative
			then
				if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable(trait) then
					ETWCommonFunctions.addTraitToDelayTable({
						modData = ETWModData,
						trait = trait,
						player = player,
						positiveTrait = false,
						gainingTrait = false,
					})
				elseif not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits(trait)) then
					ETWCommonFunctions.removeTraitFromPlayer(trait)
					if notification() then
						HaloTextHelper.addTextWithArrow(player, translationString, false, HaloTextHelper.getColorGreen())
					end
				end
				return
			elseif
				not player:hasTrait(trait)
				and positiveTrait
				and (not cantHaveTrait or not player:hasTrait(cantHaveTrait))
				and (not requiredTrait or player:hasTrait(requiredTrait))
				and SBvars.TraitsLockSystemCanGainPositive
			then
				if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable(trait) then
					ETWCommonFunctions.addTraitToDelayTable({
						modData = ETWModData,
						trait = trait,
						player = player,
						positiveTrait = true,
						gainingTrait = true,
					})
				elseif not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits(trait)) then
					ETWCommonFunctions.addTraitToPlayer(trait)
					if notification() then
						HaloTextHelper.addTextWithArrow(player, translationString, true, HaloTextHelper.getColorGreen())
					end
					if trait == CharacterTrait.DESENSITIZED then
						Events.OnZombieDead.Remove(braverySystemETW)
						if SBvars.BraverySystemRemovesOtherFearPerks == true and SBvars.TraitsLockSystemCanLoseNegative then
							if player:hasTrait(CharacterTrait.AGORAPHOBIC) then
								ETWCommonFunctions.removeTraitFromPlayer(CharacterTrait.AGORAPHOBIC)
								if notification() then
									HaloTextHelper.addTextWithArrow(player, "UI_trait_agoraphobic", false, HaloTextHelper.getColorGreen())
								end
							end
							if player:hasTrait(CharacterTrait.CLAUSTROPHOBIC) then
								ETWCommonFunctions.removeTraitFromPlayer(CharacterTrait.CLAUSTROPHOBIC)
								if notification() then
									HaloTextHelper.addTextWithArrow(player, "UI_trait_claustro", false, HaloTextHelper.getColorGreen())
								end
							end
							if player:hasTrait(ETWTraitsRegistry.PLUVIOPHOBIA) then
								ETWCommonFunctions.removeTraitFromPlayer(ETWTraitsRegistry.PLUVIOPHOBIA)
								if notification() then
									HaloTextHelper.addTextWithArrow(
										player,
										getText("UI_trait_Pluviophobia"),
										false,
										HaloTextHelper.getColorGreen()
									)
								end
							end
							if player:hasTrait(ETWTraitsRegistry.HOMICHLOPHOBIA) then
								ETWCommonFunctions.removeTraitFromPlayer(ETWTraitsRegistry.HOMICHLOPHOBIA)
								if notification() then
									HaloTextHelper.addTextWithArrow(
										player,
										getText("UI_trait_Homichlophobia"),
										false,
										HaloTextHelper.getColorGreen()
									)
								end
							end
						end
					end
				end
				return
			end
		end
	end
end

---Function responsible for setting up events
---@param playerIndex number
---@param player IsoPlayer
local function initializeEventsETW(playerIndex, player)
	modOptions = PZAPI.ModOptions:getOptions("ETWModOptions")
	if ETWCommonLogicChecks.BloodlustShouldExecute() then
		ETWMoodles.bloodlustMoodleUpdate(player, true)
		Events.OnZombieDead.Remove(bloodlustKillETW)
		Events.OnZombieDead.Add(bloodlustKillETW)
		Events.EveryHours.Remove(bloodlustTimeETW)
		Events.EveryHours.Add(bloodlustTimeETW)
	end
	Events.OnWeaponHitCharacter.Remove(eagleEyedETW)
	if ETWCommonLogicChecks.EagleEyedShouldExecute() then
		Events.OnWeaponHitCharacter.Add(eagleEyedETW)
	end
	Events.OnZombieDead.Remove(braverySystemETW)
	if ETWCommonLogicChecks.BraverySystemShouldExecute() then
		Events.OnZombieDead.Add(braverySystemETW)
	end
end

---Function responsible for clearing events
---@param character IsoPlayer
local function clearEventsETW(character)
	Events.OnZombieDead.Remove(bloodlustKillETW)
	Events.EveryHours.Remove(bloodlustTimeETW)
	Events.OnWeaponHitCharacter.Remove(eagleEyedETW)
	Events.OnZombieDead.Remove(braverySystemETW)
	logETW("ETW Logger | System: clearEventsETW in ETWByKills.lua")
end

Events.OnCreatePlayer.Remove(initializeEventsETW)
Events.OnCreatePlayer.Add(initializeEventsETW)
Events.OnPlayerDeath.Remove(clearEventsETW)
Events.OnPlayerDeath.Add(clearEventsETW)
