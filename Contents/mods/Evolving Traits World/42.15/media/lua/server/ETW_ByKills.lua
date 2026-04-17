local ETW_ModData = require("ETW_ModData")
local ETWMoodles = require("ETWMoodles")
local ETW_CommonFunctions = require("ETW_CommonFunctions")
local ETW_CommonLogicChecks = require("ETW_CommonLogicChecks")

local gameMode = ETW_CommonFunctions.gameMode()

local ETWRegistries = require("ETW_Registry")
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
	if modOptions then
		return modOptions:getOption("EnableNotifications"):getValue()
	end
	return false
end

---Prints out debugs inside console if detailedDebug is enabled
---@param ... string Strings to log
local logETW = function(...)
	ETW_CommonFunctions.log(...)
end

local bloodlustMeterCapacity = 72

---Function responsible for checking % of bloodied clothes
---@param player IsoPlayer
---@return number -- percentage of bloodied clothes (0-1)
local function bloodiedClothesLevel(player)
	local wornItems = player:getWornItems()
	local totalBloodLevelPercentage = 0
	local amountOfWornItems = 0
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
	if gameMode == ETW_CommonFunctions.GameMode.SP and getPlayer():isLocalPlayer() == false then -- checks if it's NPC doing stuff
		logETW("ETW Logger | bloodlustKillETW(): zombie kill by NPC")
	else
		logETW("ETW Logger | bloodlustKillETW(): zombie kill by player")
		local playersList = ETW_CommonFunctions.playersList()
		for i = 0, playersList:size() - 1 do
			local player = playersList:get(i)
			local distance = player:DistTo(zombie)
			local playerUsername = player:getUsername()
			logETW("ETW Logger | bloodlustKillETW(): distance between player " .. playerUsername .. " and zombie: " .. distance)
			if distance <= 10 then
				local modData = ETW_CommonFunctions.getETWModData(player)
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
				-- this file was on client side before, need to check what to do with moodle
				-- ETWMoodles.bloodlustMoodleUpdate(player, false)
			end
		end
	end
end

---Function responsible for managing Bloodlust meter with flow of time
local function bloodlustTimeETW()
	local playersList = ETW_CommonFunctions.playersList()
	for i = 0, playersList:size() - 1 do
		local player = playersList:get(i)
		logETW("ETW Logger | bloodlustTimeETW(): Processing player: " .. player:getUsername())
		local modData = ETW_CommonFunctions.getETWModData(player)
		local bloodlustModData = modData.BloodlustSystem
		bloodlustModData.BloodlustMeter =
			math.min(bloodlustModData.BloodlustMeter, bloodlustMeterCapacity * SBvars.BloodlustMeterMaxCapMultiplier)
		bloodlustModData.BloodlustMeter = math.max(bloodlustModData.BloodlustMeter - 1, 0) -- hourly decay
		-- this file was on client side before, need to check what to do with moodle
		-- ETWMoodles.bloodlustMoodleUpdate(player, false)
		logETW("ETW Logger | bloodlustTimeETW(): Bloodlust Meter: " .. bloodlustModData.BloodlustMeter)
		if bloodlustModData.BloodlustMeter >= bloodlustMeterCapacity / 2 then -- gain if above 50%
			local bloodLustProgressIncrease = bloodlustModData.BloodlustMeter
				* 0.1
				* (1 + bloodiedClothesLevel(player))
				* ((SBvars.AffinitySystem and modData.StartingTraits.Bloodlust) and SBvars.AffinitySystemGainMultiplier or 1)
			bloodlustModData.BloodlustProgress =
				math.min(SBvars.BloodlustProgress * 2, bloodlustModData.BloodlustProgress + bloodLustProgressIncrease)
			logETW(
				"ETW Logger | bloodlustTimeETW(): BloodlustMeter is above 50%, BloodlustProgress =" .. bloodlustModData.BloodlustProgress
			)
		else -- lose if below 50%
			local bloodLustProgressDecrease = bloodlustModData.BloodlustMeter
				* 0.1
				* (1 - bloodiedClothesLevel(player))
				/ ((SBvars.AffinitySystem and modData.StartingTraits.Bloodlust) and SBvars.AffinitySystemLoseDivider or 1)
			bloodlustModData.BloodlustProgress =
				math.max(0, bloodlustModData.BloodlustProgress - (bloodlustMeterCapacity / 10 - bloodLustProgressDecrease))
			logETW(
				"ETW Logger | bloodlustTimeETW(): BloodlustMeter is below 50%, BloodlustProgress =" .. bloodlustModData.BloodlustProgress
			)
		end
		if
			player:hasTrait(ETWTraitsRegistry.BLOODLUST)
			and bloodlustModData.BloodlustProgress <= SBvars.BloodlustProgress / 2
			and SBvars.TraitsLockSystemCanLosePositive
		then
			ETW_CommonFunctions.removeTraitFromPlayer(player, ETWTraitsRegistry.BLOODLUST)
			ETW_CommonFunctions.displayTraitNotification(getText("UI_trait_Bloodlust"), false, HaloTextHelper.getColorRed())
		elseif
			not player:hasTrait(ETWTraitsRegistry.BLOODLUST)
			and bloodlustModData.BloodlustProgress >= SBvars.BloodlustProgress
			and SBvars.TraitsLockSystemCanGainPositive
		then
			ETW_CommonFunctions.addTraitToPlayer(player, ETWTraitsRegistry.BLOODLUST)
			ETW_CommonFunctions.displayTraitNotification(getText("UI_trait_Bloodlust"), true, HaloTextHelper.getColorGreen())
		end
	end
end

---Function responsible for managing Eagle Eyed trait
---@param zombie IsoZombie
---@param attacker IsoGameCharacter
---@param bodyPart BodyPartType
---@param weapon HandWeapon
local function eagleEyedETW(zombie, attacker, bodyPart, weapon)
	---@cast attacker IsoPlayer
	if ETW_CommonLogicChecks.EagleEyedShouldExecute(attacker) and zombie:isZombie() then
		local zHealth = zombie:getHealth()
		local distance = attacker:DistTo(zombie)
		local modData = ETW_CommonFunctions.getETWModData(attacker)
		if distance >= SBvars.EagleEyedDistance and zHealth <= damage then
			modData.EagleEyedKills = modData.EagleEyedKills + 1
			logETW(
				"ETW Logger | eagleEyedETW(): Caught a kill on following distance: "
					.. distance
					.. ", current eagle eyed kills:"
					.. modData.EagleEyedKills
			)
			if modData.EagleEyedKills >= SBvars.EagleEyedKills then
				if SBvars.DelayedTraitsSystem and not ETW_CommonFunctions.checkIfTraitIsInDelayedTraitsTable(attacker, CharacterTrait.EAGLE_EYED) then
					ETW_CommonFunctions.addTraitToDelayTable({
						modData = modData,
						trait = CharacterTrait.EAGLE_EYED,
						player = attacker,
						positiveTrait = true,
						gainingTrait = true,
					})
				elseif
					not SBvars.DelayedTraitsSystem
					or (SBvars.DelayedTraitsSystem and ETW_CommonFunctions.checkDelayedTraits(attacker, CharacterTrait.EAGLE_EYED))
				then
					ETW_CommonFunctions.addTraitToPlayer(attacker, CharacterTrait.EAGLE_EYED)
					if notification() then
						HaloTextHelper.addTextWithArrow(attacker, getText("UI_trait_eagleeyed"), true, HaloTextHelper.getColorGreen())
					end
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
	local playersList = ETW_CommonFunctions.playersList()

	for i = 0, playersList:size() - 1 do
		local player = playersList:get(i)
		local totalKills = player:getZombieKills()
		local modDataGlobal = player:getModData()
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
					if SBvars.DelayedTraitsSystem and not ETW_CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, trait) then
						ETW_CommonFunctions.addTraitToDelayTable({
							modData = ETWModData,
							trait = trait,
							player = player,
							positiveTrait = false,
							gainingTrait = false,
						})
					elseif not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETW_CommonFunctions.checkDelayedTraits(player, trait)) then
						ETW_CommonFunctions.removeTraitFromPlayer(player, trait)
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
					if SBvars.DelayedTraitsSystem and not ETW_CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, trait) then
						ETW_CommonFunctions.addTraitToDelayTable({
							modData = ETWModData,
							trait = trait,
							player = player,
							positiveTrait = true,
							gainingTrait = true,
						})
					elseif not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETW_CommonFunctions.checkDelayedTraits(player, trait)) then
						ETW_CommonFunctions.addTraitToPlayer(player, trait)
						if notification() then
							HaloTextHelper.addTextWithArrow(player, translationString, true, HaloTextHelper.getColorGreen())
						end
						if trait == CharacterTrait.DESENSITIZED then
							Events.OnZombieDead.Remove(braverySystemETW)
							if SBvars.BraverySystemRemovesOtherFearPerks == true and SBvars.TraitsLockSystemCanLoseNegative then
								if player:hasTrait(CharacterTrait.AGORAPHOBIC) then
									ETW_CommonFunctions.removeTraitFromPlayer(player, CharacterTrait.AGORAPHOBIC)
									if notification() then
										HaloTextHelper.addTextWithArrow(player, "UI_trait_agoraphobic", false, HaloTextHelper.getColorGreen())
									end
								end
								if player:hasTrait(CharacterTrait.CLAUSTROPHOBIC) then
									ETW_CommonFunctions.removeTraitFromPlayer(player, CharacterTrait.CLAUSTROPHOBIC)
									if notification() then
										HaloTextHelper.addTextWithArrow(player, "UI_trait_claustro", false, HaloTextHelper.getColorGreen())
									end
								end
								if player:hasTrait(ETWTraitsRegistry.PLUVIOPHOBIA) then
									ETW_CommonFunctions.removeTraitFromPlayer(player, ETWTraitsRegistry.PLUVIOPHOBIA)
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
									ETW_CommonFunctions.removeTraitFromPlayer(player, ETWTraitsRegistry.HOMICHLOPHOBIA)
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
end

---Function responsible for setting up events
---@param playerIndex number
---@param player IsoPlayer
local function initializeEventsETW(playerIndex, player)
	if ETW_CommonLogicChecks.BloodlustShouldExecute(player) then
		ETWMoodles.bloodlustMoodleUpdate(player, true)
		Events.OnZombieDead.Remove(bloodlustKillETW)
		Events.OnZombieDead.Add(bloodlustKillETW)
		Events.EveryHours.Remove(bloodlustTimeETW)
		Events.EveryHours.Add(bloodlustTimeETW)
	end
	Events.OnHitZombie.Remove(eagleEyedETW)
	if ETW_CommonLogicChecks.EagleEyedShouldExecute(player) then
		Events.OnHitZombie.Add(eagleEyedETW)
	end
	Events.OnZombieDead.Remove(braverySystemETW)
	if ETW_CommonLogicChecks.BraverySystemShouldExecute(player) then
		Events.OnZombieDead.Add(braverySystemETW)
	end
	if gameMode == ETW_CommonFunctions.GameMode.MP_SERVER then
		Events.OnTick.Remove(initializeEventsETW)
	end
end

---Function responsible for clearing events
---@param character IsoPlayer
local function clearEventsETW(character)
	Events.OnZombieDead.Remove(bloodlustKillETW)
	Events.EveryHours.Remove(bloodlustTimeETW)
	Events.OnHitZombie.Remove(eagleEyedETW)
	Events.OnZombieDead.Remove(braverySystemETW)
	logETW("ETW Logger | System: clearEventsETW in ETWByKills.lua")
end

if gameMode == ETW_CommonFunctions.GameMode.SP then
	Events.OnCreatePlayer.Remove(initializeEventsETW)
	Events.OnCreatePlayer.Add(initializeEventsETW)
	Events.OnPlayerDeath.Remove(clearEventsETW)
	Events.OnPlayerDeath.Add(clearEventsETW)
elseif gameMode == ETW_CommonFunctions.GameMode.MP_SERVER then
	Events.OnTick.Add(initializeEventsETW)
end
