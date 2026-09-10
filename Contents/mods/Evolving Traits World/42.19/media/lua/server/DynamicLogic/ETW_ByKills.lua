local ETW_ModDataServer = require("ETW_ModDataServer")
local ETW_CommonFunctions = require("ETW_CommonFunctions")
local ETW_CommonLogicChecks = require("ETW_CommonLogicChecks")
local ETW_Moodles

local gameMode = ETW_CommonFunctions.gameMode()

if gameMode == ETW_CommonFunctions.GameMode.SP then
	ETW_Moodles = require("ETW_Moodles")
end

local ETW_Registry = require("ETW_Registry")
local ETWTraitsRegistry = ETW_Registry.traits

---@type EvolvingTraitsWorldSandboxVars
local SBvars = SandboxVars.EvolvingTraitsWorld

---@type fun(...: string)
local logETW = ETW_CommonFunctions.log
local FILENAME = "ETW_ByKills.lua"

if
	not ETW_CommonFunctions.gameModeSafeguard(
		FILENAME,
		{ ETW_CommonFunctions.GameMode.SP, ETW_CommonFunctions.GameMode.MP_SERVER }
	)
then
	return
end

local bloodlustMeterCapacity = 72

---Function responsible for checking % of bloodied clothes
---@param player IsoPlayer
---@return number -- percentage of bloodied clothes (0-1)
local function bloodiedClothesLevel(player)
	local wornItems = player:getWornItems()
	local totalBloodLevelPercentage = 0.0
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
			logETW(
				"ETW Logger | bloodlustKillETW(): distance between player "
					.. playerUsername
					.. " and zombie: "
					.. distance
			)
			if distance <= 10 then
				local modData = ETW_CommonFunctions.getETWModData(player)
				if modData then
					local bloodlust = modData.BloodlustSystem
					bloodlust.LastKillTimestamp = player:getHoursSurvived()
					if bloodlust.BloodlustMeter <= bloodlustMeterCapacity then
						bloodlust.BloodlustMeter = bloodlust.BloodlustMeter
							+ math.min(1.4 / distance, 1)
								* SBvars.BloodlustMeterFillMultiplier
								* (1 + bloodiedClothesLevel(player))
						logETW("ETW Logger | bloodlustKillETW(): BloodlustMeter=" .. bloodlust.BloodlustMeter)
					elseif bloodlust.BloodlustMeter < bloodlustMeterCapacity * SBvars.BloodlustMeterMaxCapMultiplier then
						bloodlust.BloodlustMeter = bloodlust.BloodlustMeter
							+ math.min(1.4 / distance, 1)
								* SBvars.BloodlustMeterFillMultiplier
								* (1 + bloodiedClothesLevel(player))
								* 0.5
						logETW("ETW Logger | bloodlustKillETW(): BloodlustMeter (soft-capped)=" .. bloodlust.BloodlustMeter)
					end
					if gameMode == ETW_CommonFunctions.GameMode.SP and ETW_Moodles then
						ETW_Moodles.bloodlustMoodleUpdate(player, { hide = false })
					elseif gameMode == ETW_CommonFunctions.GameMode.MP_SERVER then
						sendServerCommand(player, "ETW", "bloodlustMoodleUpdate", { hide = false })
					end
				end
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
		if modData then
			local bloodlustModData = modData.BloodlustSystem
			bloodlustModData.BloodlustMeter =
				math.min(bloodlustModData.BloodlustMeter, bloodlustMeterCapacity * SBvars.BloodlustMeterMaxCapMultiplier)
			bloodlustModData.BloodlustMeter = math.max(bloodlustModData.BloodlustMeter - 1, 0) -- hourly decay
			if gameMode == ETW_CommonFunctions.GameMode.SP and ETW_Moodles then
				ETW_Moodles.bloodlustMoodleUpdate(player, { hide = false })
			elseif gameMode == ETW_CommonFunctions.GameMode.MP_SERVER then
				sendServerCommand(player, "ETW", "bloodlustMoodleUpdate", { hide = false })
			end
			logETW("ETW Logger | bloodlustTimeETW(): Bloodlust Meter: " .. bloodlustModData.BloodlustMeter)
			if bloodlustModData.BloodlustMeter >= bloodlustMeterCapacity / 2 then -- gain if above 50%
				local bloodLustProgressIncrease = bloodlustModData.BloodlustMeter * 0.1 * (1 + bloodiedClothesLevel(player))
				bloodLustProgressIncrease = ETW_CommonFunctions.applyAffinityToDirectionalChange(
					modData,
					bloodLustProgressIncrease,
					nil,
					ETWTraitsRegistry.BLOODLUST
				)
				bloodlustModData.BloodlustProgress =
					math.min(SBvars.BloodlustProgress * 2, bloodlustModData.BloodlustProgress + bloodLustProgressIncrease)
				logETW(
					"ETW Logger | bloodlustTimeETW(): BloodlustMeter is above 50%, BloodlustProgress ="
						.. bloodlustModData.BloodlustProgress
				)
			else -- lose if below 50%
				local bloodLustProgressMitigation = bloodlustModData.BloodlustMeter
					* 0.1
					* (1 - bloodiedClothesLevel(player))
				local bloodLustProgressChange = ETW_CommonFunctions.applyAffinityToDirectionalChange(
					modData,
					-(bloodlustMeterCapacity / 10 - bloodLustProgressMitigation),
					nil,
					ETWTraitsRegistry.BLOODLUST
				)
				bloodlustModData.BloodlustProgress =
					math.max(0, bloodlustModData.BloodlustProgress + bloodLustProgressChange)
				logETW(
					"ETW Logger | bloodlustTimeETW(): BloodlustMeter is below 50%, BloodlustProgress ="
						.. bloodlustModData.BloodlustProgress
				)
			end
			if
				player:hasTrait(ETWTraitsRegistry.BLOODLUST)
				and bloodlustModData.BloodlustProgress <= SBvars.BloodlustProgress / 2
				and SBvars.TraitsLockSystemCanLosePositive
			then
				ETW_CommonFunctions.removeTraitFromPlayer({
					player = player,
					trait = ETWTraitsRegistry.BLOODLUST,
					positiveTrait = true,
				})
			elseif
				not player:hasTrait(ETWTraitsRegistry.BLOODLUST)
				and bloodlustModData.BloodlustProgress >= SBvars.BloodlustProgress
				and SBvars.TraitsLockSystemCanGainPositive
			then
				ETW_CommonFunctions.addTraitToPlayer({
					player = player,
					trait = ETWTraitsRegistry.BLOODLUST,
					positiveTrait = true,
				})
			end
		end
	end
end

---Function responsible for managing Eagle Eyed trait
---@param player IsoPlayer
---@param distance number
local function grantEagleEyedKill(player, distance)
	local modData = ETW_CommonFunctions.getETWModData(player)
	if not modData then
		return
	end

	modData.EagleEyedKills = modData.EagleEyedKills + 1
	logETW(
		"ETW Logger | eagleEyedETW(): Caught a kill on following distance: "
			.. distance
			.. ", current eagle eyed kills:"
			.. modData.EagleEyedKills
	)

	if modData.EagleEyedKills < SBvars.EagleEyedKills then
		return
	end

	if
		SBvars.DelayedTraitsSystem
		and not ETW_CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, CharacterTrait.EAGLE_EYED)
	then
		ETW_CommonFunctions.addTraitToDelayTable({
			modData = modData,
			trait = CharacterTrait.EAGLE_EYED,
			player = player,
			positiveTrait = true,
			gainingTrait = true,
		})
	elseif
		not SBvars.DelayedTraitsSystem
		or (SBvars.DelayedTraitsSystem and ETW_CommonFunctions.checkDelayedTraits(player, CharacterTrait.EAGLE_EYED))
	then
		ETW_CommonFunctions.addTraitToPlayer({
			player = player,
			trait = CharacterTrait.EAGLE_EYED,
			positiveTrait = true,
		})
	end
end

---Resolves Eagle Eyed kill credit when a zombie dies.
---@param zombie IsoZombie
local function eagleEyedETW(zombie)
	local attacker = zombie:getAttackedBy()
	if not attacker or not instanceof(attacker, "IsoPlayer") then
		return
	end
	---@cast attacker IsoPlayer
	if not ETW_CommonLogicChecks.EagleEyedShouldExecute(attacker) then
		logETW(
			"ETW Logger | eagleEyedETW(): attacker "
				.. tostring(attacker:getUsername())
				.. " does not qualify for Eagle Eyed processing"
		)
		return
	end

	local distance = attacker:DistTo(zombie)
	if distance >= SBvars.EagleEyedDistance then
		grantEagleEyedKill(attacker, distance)
	end
end

local braverySystemTraitInfo = {
	{
		trait = CharacterTrait.COWARDLY,
		thresholdMultiplier = 0.1,
		remove = true,
		translationString = getText("UI_trait_cowardly"),
	},
	{
		trait = CharacterTrait.HEMOPHOBIC,
		thresholdMultiplier = 0.2,
		remove = true,
		cantHaveTrait = CharacterTrait.COWARDLY,
		translationString = getText("UI_trait_Hemophobic"),
	},
	{
		trait = CharacterTrait.PACIFIST,
		thresholdMultiplier = 0.3,
		remove = true,
		cantHaveTrait = CharacterTrait.HEMOPHOBIC,
		translationString = getText("UI_trait_Pacifist"),
	},
	{
		trait = CharacterTrait.ADRENALINE_JUNKIE,
		thresholdMultiplier = 0.4,
		add = true,
		cantHaveTrait = CharacterTrait.PACIFIST,
		translationString = getText("UI_trait_AdrenalineJunkie"),
	},
	{
		trait = CharacterTrait.BRAVE,
		thresholdMultiplier = 0.6,
		add = true,
		requiredTrait = CharacterTrait.ADRENALINE_JUNKIE,
		translationString = getText("UI_trait_brave"),
	},
	{
		trait = CharacterTrait.DESENSITIZED,
		thresholdMultiplier = 1,
		add = true,
		requiredTrait = CharacterTrait.BRAVE,
		translationString = getText("UI_trait_Desensitized"),
	},
}

---Function responsible for managing Bravery System traits
---@param zombie IsoZombie
local function braverySystemETW(zombie)
	logETW("ETW Logger | braverySystemETW(): Processing Bravery System for all players")
	local playersList = ETW_CommonFunctions.playersList()
	for playerListIndex = 0, playersList:size() - 1 do
		local player = playersList:get(playerListIndex)
		logETW("ETW Logger | braverySystemETW(): Processing player: " .. player:getUsername())
		local totalKills = player:getZombieKills()
		local modDataGlobal = player:getModData()
		local killCountModData = (modDataGlobal.KillCount or {}).WeaponCategory or {}
		local ETWModData = ETW_CommonFunctions.getETWModData(player)
		if ETWModData then
			local fireKills = (killCountModData["Fire"] or {}).count or 0
			local firearmsKills = (killCountModData["Firearm"] or {}).count or 0
			local vehiclesKills = (killCountModData["Vehicles"] or {}).count or 0
			local explosivesKills = (killCountModData["Explosives"] or {}).count or 0
			local otherKills = fireKills + vehiclesKills + explosivesKills
			local meleeKills = totalKills - firearmsKills - otherKills
			local braveryKills = meleeKills * SBvars.BraverySystemMeleeKillValue
				+ firearmsKills * SBvars.BraverySystemFirearmKillValue
				+ otherKills * SBvars.BraverySystemOtherKillValue

			for i = 1, #braverySystemTraitInfo do
				local info = braverySystemTraitInfo[i]
				local trait = info.trait
				local threshold = SBvars.BraverySystemKills * info.thresholdMultiplier
				local negativeTrait = info.remove
				local positiveTrait = info.add
				local cantHaveTrait = info.cantHaveTrait
				local requiredTrait = info.requiredTrait
				local translationString = info.translationString
				logETW(
					"ETW Logger | braverySystemETW(): Checking trait "
						.. translationString
						.. " ("
						.. trait:getName()
						.. ") for player "
						.. player:getUsername()
						.. " with totalKills="
						.. totalKills
						.. ", meleeKills="
						.. meleeKills
						.. ", braveryKills="
						.. braveryKills
						.. ", threshold="
						.. threshold
				)
				if braveryKills >= threshold then
					if
						player:hasTrait(trait)
						and negativeTrait
						and (not cantHaveTrait or not player:hasTrait(cantHaveTrait))
						and SBvars.TraitsLockSystemCanLoseNegative
					then
						if
							SBvars.DelayedTraitsSystem
							and not ETW_CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, trait)
						then
							ETW_CommonFunctions.addTraitToDelayTable({
								modData = ETWModData,
								trait = trait,
								player = player,
								positiveTrait = false,
								gainingTrait = false,
							})
						elseif
							not SBvars.DelayedTraitsSystem
							or (SBvars.DelayedTraitsSystem and ETW_CommonFunctions.checkDelayedTraits(player, trait))
						then
							ETW_CommonFunctions.removeTraitFromPlayer({
								player = player,
								trait = trait,
								positiveTrait = false,
							})
						end
						break
					elseif
						not player:hasTrait(trait)
						and positiveTrait
						and (not cantHaveTrait or not player:hasTrait(cantHaveTrait))
						and (not requiredTrait or player:hasTrait(requiredTrait))
						and SBvars.TraitsLockSystemCanGainPositive
					then
						if
							SBvars.DelayedTraitsSystem
							and not ETW_CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, trait)
						then
							ETW_CommonFunctions.addTraitToDelayTable({
								modData = ETWModData,
								trait = trait,
								player = player,
								positiveTrait = true,
								gainingTrait = true,
							})
						elseif
							not SBvars.DelayedTraitsSystem
							or (SBvars.DelayedTraitsSystem and ETW_CommonFunctions.checkDelayedTraits(player, trait))
						then
							ETW_CommonFunctions.addTraitToPlayer({
								player = player,
								trait = trait,
								positiveTrait = true,
							})
							if trait == CharacterTrait.DESENSITIZED then
								if gameMode == ETW_CommonFunctions.GameMode.SP then
									Events.OnZombieDead.Remove(braverySystemETW)
								end
								if
									SBvars.BraverySystemRemovesOtherFearPerks == true
									and SBvars.TraitsLockSystemCanLoseNegative
								then
									if player:hasTrait(CharacterTrait.AGORAPHOBIC) then
										ETW_CommonFunctions.removeTraitFromPlayer({
											player = player,
											trait = CharacterTrait.AGORAPHOBIC,
											positiveTrait = false,
										})
									end
									if player:hasTrait(CharacterTrait.CLAUSTROPHOBIC) then
										ETW_CommonFunctions.removeTraitFromPlayer({
											player = player,
											trait = CharacterTrait.CLAUSTROPHOBIC,
											positiveTrait = false,
										})
									end
									if player:hasTrait(ETWTraitsRegistry.PLUVIOPHOBIA) then
										ETW_CommonFunctions.removeTraitFromPlayer({
											player = player,
											trait = ETWTraitsRegistry.PLUVIOPHOBIA,
											positiveTrait = false,
										})
									end
									if player:hasTrait(ETWTraitsRegistry.HOMICHLOPHOBIA) then
										ETW_CommonFunctions.removeTraitFromPlayer({
											player = player,
											trait = ETWTraitsRegistry.HOMICHLOPHOBIA,
											positiveTrait = false,
										})
									end
								end
							end
						end
						break
					end
				end
			end
		end
	end
end

---Function responsible for setting up events
---@param playerIndex number
---@param player IsoPlayer
local function initializeEventsETW(playerIndex, player)
	if SBvars.DisableAllDynamicTraits == true then
		if gameMode == ETW_CommonFunctions.GameMode.MP_SERVER then
			Events.OnTick.Remove(initializeEventsETW)
		end
		return
	end
	if ETW_CommonLogicChecks.BloodlustShouldExecute(player) then
		Events.OnZombieDead.Remove(bloodlustKillETW)
		Events.OnZombieDead.Add(bloodlustKillETW)
		Events.EveryHours.Remove(bloodlustTimeETW)
		Events.EveryHours.Add(bloodlustTimeETW)
	end
	if ETW_CommonLogicChecks.EagleEyedShouldExecute(player) then
		if gameMode == ETW_CommonFunctions.GameMode.SP then
			Events.OnZombieDead.Remove(eagleEyedETW)
			Events.OnZombieDead.Add(eagleEyedETW)
		end
	else
		Events.OnZombieDead.Remove(eagleEyedETW)
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
	Events.OnZombieDead.Remove(eagleEyedETW)
	Events.OnZombieDead.Remove(braverySystemETW)
	logETW("ETW Logger | System: clearEventsETW in " .. FILENAME)
end

if gameMode == ETW_CommonFunctions.GameMode.SP then
	Events.OnCreatePlayer.Remove(initializeEventsETW)
	Events.OnCreatePlayer.Add(initializeEventsETW)
	Events.OnPlayerDeath.Remove(clearEventsETW)
	Events.OnPlayerDeath.Add(clearEventsETW)
elseif gameMode == ETW_CommonFunctions.GameMode.MP_SERVER then
	Events.OnTick.Add(initializeEventsETW)
end
