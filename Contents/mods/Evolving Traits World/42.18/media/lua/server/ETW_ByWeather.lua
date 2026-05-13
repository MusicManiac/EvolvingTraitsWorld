local ETW_ModDataServer = require("ETW_ModDataServer")
local ETW_CommonFunctions = require("ETW_CommonFunctions")
local ETW_CommonLogicChecks = require("ETW_CommonLogicChecks")

---@type EvolvingTraitsWorldSandboxVars
local SBvars = SandboxVars.EvolvingTraitsWorld

---@type EvolvingTraitsWorldRegistries
local ETW_Registry = require("ETW_Registry")
---@type EvolvingTraitsWorldTraitsRegistries
local ETWTraitsRegistry = ETW_Registry.traits

---@type fun(...: any)
local logETW = ETW_CommonFunctions.log
local FILENAME = "ETWByWeather.lua"

if
	not ETW_CommonFunctions.gameModeSafeguard(
		FILENAME,
		{ ETW_CommonFunctions.GameMode.SP, ETW_CommonFunctions.GameMode.MP_SERVER }
	)
then
	return
end

local gameMode = ETW_CommonFunctions.gameMode()

---@param player IsoPlayer
---@return boolean
local desensitized = function(player)
	return player:hasTrait(CharacterTrait.DESENSITIZED) and SBvars.BraverySystemRemovesOtherFearPerks
end

---Function responsible for managing Rain System traits
---@param player IsoPlayer
---@param isKill boolean
local function rainTraits(player, isKill)
	isKill = isKill or false
	rainIntensity = getClimateManager():getRainIntensity()
	if rainIntensity == 0 then
		return
	end
	local playersList = player and { player } or ETW_CommonFunctions.playersList()
	for i = 0, playersList:size() - 1 do
		player = playersList:get(i)
		if player:isOutside() and player:getVehicle() == nil then
			local modData = ETW_CommonFunctions.getETWModData(player)
			if not modData then
				logETW("ETW Logger | rainTraits(): modData is nil, returning early")
				return
			end
			local startedWithPluviophobia = modData.StartingTraits[ETWTraitsRegistry.PLUVIOPHOBIA:toString()]
			local startedWithPluviophile = modData.StartingTraits[ETWTraitsRegistry.PLUVIOPHILE:toString()]
			local panic = player:getStats():get(CharacterStat.PANIC) -- 0-100
			local primaryItem = player:getPrimaryHandItem()
			local secondaryItem = player:getSecondaryHandItem()
			local rainProtection = (primaryItem and primaryItem:isProtectFromRainWhileEquipped())
				or (secondaryItem and secondaryItem:isProtectFromRainWhileEquipped())
			local SBCounter = SBvars.RainSystemCounter
			local lowerBoundary = -SBCounter * 2
			local upperBoundary = SBCounter * 2
			local rainGain = rainIntensity * (rainProtection and 0.5 or 1) * SBvars.RainSystemCounterIncreaseMultiplier
			rainGain = rainGain
				/ ((SBvars.AffinitySystem and startedWithPluviophobia) and SBvars.AffinitySystemLoseDivider or 1)
			rainGain = rainGain
				* ((SBvars.AffinitySystem and startedWithPluviophile) and SBvars.AffinitySystemGainMultiplier or 1)
			local rainDecrease = rainGain
				* (panic / 100)
				* 0.9
				* SBvars.RainSystemCounterDecreaseMultiplier
				* (isKill and 0.25 or 1)
			rainDecrease = rainDecrease
				/ ((SBvars.AffinitySystem and startedWithPluviophile) and SBvars.AffinitySystemLoseDivider or 1)
			rainDecrease = rainDecrease
				* ((SBvars.AffinitySystem and startedWithPluviophobia) and SBvars.AffinitySystemGainMultiplier or 1)
			local finalRainCounter = modData.RainCounter + rainGain - rainDecrease
			finalRainCounter = math.min(upperBoundary, finalRainCounter)
			finalRainCounter = math.max(lowerBoundary, finalRainCounter)
			modData.RainCounter = finalRainCounter
			if isKill then
				logETW("ETW Logger | rainTraits(): was triggered by a kill")
			end
			logETW("ETW Logger | rainTraits(): modData.RainCounter=" .. modData.RainCounter)
			if
				not player:hasTrait(ETWTraitsRegistry.PLUVIOPHOBIA)
				and modData.RainCounter <= -SBCounter
				and not desensitized(player)
				and SBvars.TraitsLockSystemCanGainNegative
			then
				ETW_CommonFunctions.addTraitToPlayer({
					player = player,
					trait = ETWTraitsRegistry.PLUVIOPHOBIA,
					positiveTrait = false,
				})
			elseif
				player:hasTrait(ETWTraitsRegistry.PLUVIOPHOBIA)
				and modData.RainCounter > -SBCounter
				and SBvars.TraitsLockSystemCanLoseNegative
			then
				ETW_CommonFunctions.removeTraitFromPlayer({
					player = player,
					trait = ETWTraitsRegistry.PLUVIOPHOBIA,
					positiveTrait = false,
				})
			elseif
				player:hasTrait(ETWTraitsRegistry.PLUVIOPHILE)
				and modData.RainCounter <= SBCounter
				and SBvars.TraitsLockSystemCanLosePositive
			then
				ETW_CommonFunctions.removeTraitFromPlayer({
					player = player,
					trait = ETWTraitsRegistry.PLUVIOPHILE,
					positiveTrait = true,
				})
			elseif
				not player:hasTrait(ETWTraitsRegistry.PLUVIOPHILE)
				and modData.RainCounter > SBCounter
				and SBvars.TraitsLockSystemCanGainPositive
			then
				ETW_CommonFunctions.addTraitToPlayer({
					player = player,
					trait = ETWTraitsRegistry.PLUVIOPHILE,
					positiveTrait = true,
				})
			end
		end
	end
end

---Function responsible for managing Fog system traits
---@param player IsoPlayer
---@param isKill boolean
local function fogTraits(player, isKill)
	isKill = isKill or false
	fogIntensity = getClimateManager():getFogIntensity()
	if fogIntensity == 0 then
		return
	end
	local playersList = player and { player } or ETW_CommonFunctions.playersList()
	for i = 0, playersList:size() - 1 do
		player = playersList:get(i)
		if player:isOutside() and player:getVehicle() == nil then
			local modData = ETW_CommonFunctions.getETWModData(player)
			if not modData then
				logETW("ETW Logger | fogTraits(): modData is nil, returning early")
				return
			end
			local startedWithHomichlophobia = modData.StartingTraits[ETWTraitsRegistry.HOMICHLOPHOBIA:toString()]
			local startedWithHomichlophile = modData.StartingTraits[ETWTraitsRegistry.HOMICHLOPHILE:toString()]
			local panic = player:getStats():get(CharacterStat.PANIC) -- 0-100
			local fogGain = fogIntensity * SBvars.FogSystemCounterIncreaseMultiplier
			fogGain = fogGain
				/ ((SBvars.AffinitySystem and startedWithHomichlophobia) and SBvars.AffinitySystemLoseDivider or 1)
			fogGain = fogGain
				* ((SBvars.AffinitySystem and startedWithHomichlophile) and SBvars.AffinitySystemGainMultiplier or 1)
			local fogDecrease = fogIntensity
				* (2 * panic / 100)
				* SBvars.FogSystemCounterDecreaseMultiplier
				* (isKill and 0.25 or 1)
			fogDecrease = fogDecrease
				/ ((SBvars.AffinitySystem and startedWithHomichlophile) and SBvars.AffinitySystemLoseDivider or 1)
			fogDecrease = fogDecrease
				* ((SBvars.AffinitySystem and startedWithHomichlophobia) and SBvars.AffinitySystemGainMultiplier or 1)
			local SBCounter = SBvars.FogSystemCounter
			local lowerBoundary = -SBCounter * 2
			local upperBoundary = SBCounter * 2
			local finalFogCounter = modData.FogCounter + fogGain - fogDecrease
			finalFogCounter = math.max(finalFogCounter, lowerBoundary)
			finalFogCounter = math.min(finalFogCounter, upperBoundary)
			modData.FogCounter = finalFogCounter
			if isKill then
				logETW("ETW Logger | fogTraits(): was triggered by a kill")
			end
			logETW("ETW Logger | fogTraits(): modData.FogCounter=" .. modData.FogCounter)
			if
				not player:hasTrait(ETWTraitsRegistry.HOMICHLOPHOBIA)
				and modData.FogCounter <= -SBCounter
				and not desensitized(player)
				and SBvars.TraitsLockSystemCanGainNegative
			then
				ETW_CommonFunctions.addTraitToPlayer({
					player = player,
					trait = ETWTraitsRegistry.HOMICHLOPHOBIA,
					positiveTrait = false,
				})
			elseif
				player:hasTrait(ETWTraitsRegistry.HOMICHLOPHOBIA)
				and modData.FogCounter > -SBCounter
				and SBvars.TraitsLockSystemCanLoseNegative
			then
				ETW_CommonFunctions.removeTraitFromPlayer({
					player = player,
					trait = ETWTraitsRegistry.HOMICHLOPHOBIA,
					positiveTrait = false,
				})
			elseif
				player:hasTrait(ETWTraitsRegistry.HOMICHLOPHILE)
				and modData.FogCounter <= SBCounter
				and SBvars.TraitsLockSystemCanLosePositive
			then
				ETW_CommonFunctions.removeTraitFromPlayer({
					player = player,
					trait = ETWTraitsRegistry.HOMICHLOPHILE,
					positiveTrait = true,
				})
			elseif
				not player:hasTrait(ETWTraitsRegistry.HOMICHLOPHILE)
				and modData.FogCounter > SBCounter
				and SBvars.TraitsLockSystemCanGainPositive
			then
				ETW_CommonFunctions.addTraitToPlayer({
					player = player,
					trait = ETWTraitsRegistry.HOMICHLOPHILE,
					positiveTrait = true,
				})
			end
		end
	end
end

---Helper function to fire rainTraits() on zombie kill
---@param zombie IsoZombie
local function rainTraitsKill(zombie)
	local player = zombie:getAttackedBy()
	---@cast player IsoPlayer
	if not player or not instanceof(player, "IsoPlayer") or not player:isLocalPlayer() then
		return
	else
		rainTraits(player, true)
	end
end

---Helper function to fire fogTraits() on zombie kill
---@param zombie IsoZombie
local function fogTraitsKill(zombie)
	local player = zombie:getAttackedBy()
	---@cast player IsoPlayer
	if not player or not instanceof(player, "IsoPlayer") or not player:isLocalPlayer() then
		return
	else
		fogTraits(player, true)
	end
end

---Function responsible for setting up events
---@param playerIndex number
---@param player IsoPlayer
local function initializeEventsETW(playerIndex, player)
	Events.EveryOneMinute.Remove(rainTraits)
	Events.OnZombieDead.Remove(rainTraitsKill)
	if ETW_CommonLogicChecks.RainSystemShouldExecute(player) then
		Events.EveryOneMinute.Add(rainTraits)
		Events.OnZombieDead.Add(rainTraitsKill)
	end
	Events.EveryOneMinute.Remove(fogTraits)
	Events.OnZombieDead.Remove(fogTraitsKill)
	if ETW_CommonLogicChecks.FogSystemShouldExecute(player) then
		Events.EveryOneMinute.Add(fogTraits)
		Events.OnZombieDead.Add(fogTraitsKill)
	end
	if gameMode == ETW_CommonFunctions.GameMode.MP_SERVER then
		Events.OnTick.Remove(initializeEventsETW)
	end
end

---Function responsible for clearing events
---@param character IsoPlayer
local function clearEventsETW(character)
	Events.EveryOneMinute.Remove(rainTraits)
	Events.EveryOneMinute.Remove(fogTraits)
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
