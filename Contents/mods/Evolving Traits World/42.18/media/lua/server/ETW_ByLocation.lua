local ETW_ModDataServer = require("ETW_ModDataServer")
local ETW_CommonFunctions = require("ETW_CommonFunctions")
local ETW_CommonLogicChecks = require("ETW_CommonLogicChecks")

local gameMode = ETW_CommonFunctions.gameMode()

local ETW_Registry = require("ETW_Registry")
local ETWTraitsRegistry = ETW_Registry.traits

---@type EvolvingTraitsWorldSandboxVars
local SBvars = SandboxVars.EvolvingTraitsWorld

---@type fun(...: string)
local logETW = ETW_CommonFunctions.log
local FILENAME = "ETW_ByLocation.lua"

if
	not ETW_CommonFunctions.gameModeSafeguard(
		FILENAME,
		{ ETW_CommonFunctions.GameMode.SP, ETW_CommonFunctions.GameMode.MP_SERVER }
	)
then
	return
end

local desensitized = function(player)
	return player:hasTrait(CharacterTrait.DESENSITIZED) and SBvars.BraverySystemRemovesOtherFearPerks
end

---Function responsible for managing Outdoorsman trait
---@param isKill boolean
local function outdoorsman(player, isKill)
	isKill = isKill or false
	if isKill then
		logETW("ETW Logger | outdoorsman(): was triggered by a kill")
	end
	local climateManager = getClimateManager()
	local rainIntensity = climateManager:getRainIntensity()
	local snowIntensity = climateManager:getSnowIntensity()
	local windIntensity = climateManager:getWindIntensity()
	local fogIntensity = climateManager:getFogIntensity()
	local isThunderstorm = climateManager:getIsThunderStorming()
	local playersList = ArrayList.new()
	if player then
		playerList:add(player)
	else
		playerList = ETW_CommonFunctions.playersList()
	end
	for i = 0, playersList:size() - 1 do
		player = playersList:get(i)
		local modData = ETW_CommonFunctions.getETWModData(player)
		if not modData then
			logETW("ETW Logger | outdoorsman(): modData is nil, returning early")
			return
		end
		local startedWithOutdoorsman = modData.StartingTraits[CharacterTrait.OUTDOORSMAN:toString()]
		local outdoorsmanModData = modData.OutdoorsmanSystem
		local baseGain = 1
		local rainGain = 5
			* rainIntensity
			* (player:hasTrait(ETWTraitsRegistry.PLUVIOPHILE) and 1.2 or 1)
			* (player:hasTrait(ETWTraitsRegistry.PLUVIOPHOBIA) and 0.8 or 1)
			* (isThunderstorm and 3 or 1)
		local snowGain = 2 * snowIntensity
		local windGain = 2 * windIntensity
		local fogGain = fogIntensity
			* (player:hasTrait(ETWTraitsRegistry.HOMICHLOPHILE) and 1.2 or 1)
			* (player:hasTrait(ETWTraitsRegistry.HOMICHLOPHOBIA) and 0.8 or 1)
		local totalGain = baseGain
			+ (rainGain + snowGain + windGain + fogGain) * (player:hasTrait(CharacterTrait.HIKER) and 1.1 or 1)
		if player:isOutside() and player:getVehicle() == nil then
			totalGain = totalGain
				* ((SBvars.AffinitySystem and startedWithOutdoorsman) and SBvars.AffinitySystemGainMultiplier or 1)
				* SBvars.OutdoorsmanCounterIncreaseMultiplier
			outdoorsmanModData.MinutesSinceOutside = math.max(0, outdoorsmanModData.MinutesSinceOutside - 3)
			outdoorsmanModData.OutdoorsmanCounter =
				math.min(outdoorsmanModData.OutdoorsmanCounter + totalGain, SBvars.OutdoorsmanCounter * 2)
			logETW(
				"ETW Logger | outdoorsman(): totalGain="
					.. totalGain
					.. ". OutdoorsmanCounter="
					.. outdoorsmanModData.OutdoorsmanCounter
			)
			if
				not player:hasTrait(CharacterTrait.OUTDOORSMAN)
				and outdoorsmanModData.OutdoorsmanCounter >= SBvars.OutdoorsmanCounter
				and SBvars.TraitsLockSystemCanGainPositive
			then
				ETW_CommonFunctions.addTraitToPlayer({
					player = player,
					trait = CharacterTrait.OUTDOORSMAN,
					positiveTrait = true,
				})
			end
		elseif outdoorsmanModData.OutdoorsmanCounter > 0 and not isKill then
			local totalLose = totalGain
				* 0.1
				* (1 + outdoorsmanModData.MinutesSinceOutside / 100)
				* SBvars.OutdoorsmanCounterDecreaseMultiplier
			totalLose = totalLose
				/ ((SBvars.AffinitySystem and startedWithOutdoorsman) and SBvars.AffinitySystemLoseDivider or 1)
			outdoorsmanModData.MinutesSinceOutside = math.min(900, outdoorsmanModData.MinutesSinceOutside + 1)
			outdoorsmanModData.OutdoorsmanCounter =
				math.max(SBvars.OutdoorsmanCounter * -2, outdoorsmanModData.OutdoorsmanCounter - totalLose)
			logETW(
				"ETW Logger | outdoorsman(): totalLose="
					.. totalLose
					.. ". OutdoorsmanCounter="
					.. outdoorsmanModData.OutdoorsmanCounter
			)
			if
				player:hasTrait(CharacterTrait.OUTDOORSMAN)
				and outdoorsmanModData.OutdoorsmanCounter <= -SBvars.OutdoorsmanCounter
				and SBvars.TraitsLockSystemCanLosePositive
			then
				ETW_CommonFunctions.removeTraitFromPlayer({
					player = player,
					trait = CharacterTrait.OUTDOORSMAN,
					positiveTrait = true,
				})
			end
		end
	end
end

---Function responsible for managing Fear of Locations System traits
---@param isKill boolean
local function fearOfLocations(player, isKill)
	isKill = isKill or false
	if isKill then
		logETW("ETW Logger | fearOfLocations(): was triggered by a kill")
	end
	local playersList = ArrayList.new()
	if player then
		playersList:add(player)
	else
		playersList = ETW_CommonFunctions.playersList()
	end
	for i = 0, playersList:size() - 1 do
		player = playersList:get(i)
		local modData = ETW_CommonFunctions.getETWModData(player)
		if not modData then
			logETW("ETW Logger | fearOfLocations(): modData is nil, returning early")
			return
		end
		local startedWithAgoraphobic = modData.StartingTraits[CharacterTrait.AGORAPHOBIC:toString()]
		local startedWithClaustrophobic = modData.StartingTraits[CharacterTrait.CLAUSTROPHOBIC:toString()]
		local fearOfLocationsModData = modData.LocationFearSystem
		local stats = player:getStats()
		local stress = stats:get(CharacterStat.STRESS) -- 0-1, may be higher with stress from cigarettes
		local unhappiness = stats:get(CharacterStat.UNHAPPINESS) -- 0-100
		local playerHasAgoraphobia = player:hasTrait(CharacterTrait.AGORAPHOBIC)
		local playerHasClaustrophobia = player:hasTrait(CharacterTrait.CLAUSTROPHOBIC)
		local SBCounter = SBvars.FearOfLocationsSystemCounter
		local upperCounterBoundary = SBCounter * 2
		local lowerCounterBoundary = -2 * SBCounter
		local counterDecrease = 0
		if stress > 0 or unhappiness > 0 then
			counterDecrease = (2 * stress) + (2 * unhappiness / 100)
		end
		counterDecrease = counterDecrease * SBvars.FearOfLocationsSystemCounterLoseMultiplier
		if player:isOutside() then
			counterDecrease = counterDecrease
				* ((SBvars.AffinitySystem and startedWithAgoraphobic) and SBvars.AffinitySystemGainMultiplier or 1)
				* (isKill and 0.25 or 1)
			local resultingCounter = fearOfLocationsModData.FearOfOutside
				- counterDecrease
				+ ((SBvars.AffinitySystem and startedWithAgoraphobic) and 1 / SBvars.AffinitySystemLoseDivider or 1) -- +1/divider passive ticking of just being outside
			resultingCounter = math.min(upperCounterBoundary, resultingCounter)
			resultingCounter = math.max(lowerCounterBoundary, resultingCounter)
			fearOfLocationsModData.FearOfOutside = resultingCounter
			fearOfLocationsModData.FearOfInside = math.min(
				upperCounterBoundary,
				fearOfLocationsModData.FearOfInside + SBvars.FearOfLocationsSystemPassiveCounterDecay
			)
		elseif not player:isOutside() or player:getVehicle() ~= nil then
			counterDecrease = counterDecrease
				* ((SBvars.AffinitySystem and startedWithClaustrophobic) and SBvars.AffinitySystemGainMultiplier or 1)
				* (isKill and 0.25 or 1)
			local resultingCounter = fearOfLocationsModData.FearOfInside
				- counterDecrease
				+ ((SBvars.AffinitySystem and startedWithClaustrophobic) and 1 / SBvars.AffinitySystemLoseDivider or 1) -- +1/divider passive ticking of just being inside
			resultingCounter = math.min(upperCounterBoundary, resultingCounter)
			resultingCounter = math.max(lowerCounterBoundary, resultingCounter)
			fearOfLocationsModData.FearOfInside = resultingCounter
			fearOfLocationsModData.FearOfOutside = math.min(
				upperCounterBoundary,
				fearOfLocationsModData.FearOfOutside + SBvars.FearOfLocationsSystemPassiveCounterDecay
			)
		end
		logETW(
			"ETW Logger | fearOfLocations(): modData.FearOfOutside: " .. fearOfLocationsModData.FearOfOutside,
			"ETW Logger | fearOfLocations(): modData.FearOfInside: " .. fearOfLocationsModData.FearOfInside
		)
		if not SBvars.FearOfLocationsExclusiveFears then
			if
				not playerHasAgoraphobia
				and fearOfLocationsModData.FearOfOutside <= -SBCounter
				and not desensitized(player)
				and SBvars.TraitsLockSystemCanGainNegative
			then
				ETW_CommonFunctions.addTraitToPlayer({
					player = player,
					trait = CharacterTrait.AGORAPHOBIC,
					positiveTrait = false,
				})
			end
			if
				not playerHasClaustrophobia
				and fearOfLocationsModData.FearOfInside <= -SBCounter
				and not desensitized(player)
				and SBvars.TraitsLockSystemCanGainNegative
			then
				ETW_CommonFunctions.addTraitToPlayer({
					player = player,
					trait = CharacterTrait.CLAUSTROPHOBIC,
					positiveTrait = false,
				})
			end
		elseif SBvars.TraitsLockSystemCanLoseNegative and SBvars.TraitsLockSystemCanGainNegative then
			if
				fearOfLocationsModData.FearOfOutside <= -SBCounter
				and not desensitized(player)
				and fearOfLocationsModData.FearOfOutside < fearOfLocationsModData.FearOfInside
				and not playerHasAgoraphobia
			then
				ETW_CommonFunctions.removeTraitFromPlayer({
					player = player,
					trait = CharacterTrait.CLAUSTROPHOBIC,
					positiveTrait = false,
				})
				ETW_CommonFunctions.addTraitToPlayer({
					player = player,
					trait = CharacterTrait.AGORAPHOBIC,
					positiveTrait = false,
				})
			end
			if
				fearOfLocationsModData.FearOfInside <= -SBCounter
				and not desensitized(player)
				and fearOfLocationsModData.FearOfInside < fearOfLocationsModData.FearOfOutside
				and not playerHasClaustrophobia
			then
				ETW_CommonFunctions.removeTraitFromPlayer({
					player = player,
					trait = CharacterTrait.AGORAPHOBIC,
					positiveTrait = false,
				})
				ETW_CommonFunctions.addTraitToPlayer({
					player = player,
					trait = CharacterTrait.CLAUSTROPHOBIC,
					positiveTrait = false,
				})
			end
		end
		if
			playerHasAgoraphobia
			and fearOfLocationsModData.FearOfOutside >= SBCounter
			and SBvars.TraitsLockSystemCanLoseNegative
		then
			ETW_CommonFunctions.removeTraitFromPlayer({
				player = player,
				trait = CharacterTrait.AGORAPHOBIC,
				positiveTrait = false,
			})
		end
		if
			playerHasClaustrophobia
			and fearOfLocationsModData.FearOfInside >= SBCounter
			and SBvars.TraitsLockSystemCanLoseNegative
		then
			ETW_CommonFunctions.removeTraitFromPlayer({
				player = player,
				trait = CharacterTrait.CLAUSTROPHOBIC,
				positiveTrait = false,
			})
		end
	end
end

---Helper function to fire outdoorsman() on zombie kill
---@param zombie IsoZombie
local function outdoorsmanKill(zombie)
	local player = zombie:getAttackedBy()
	---@cast player IsoPlayer
	if
		not player
		or not instanceof(player, "IsoPlayer")
		or (gameMode == ETW_CommonFunctions.GameMode.SP and not player:isLocalPlayer())
	then
		return
	else
		outdoorsman(player, true)
	end
end

---Helper function to fire fearOfLocations() on zombie kill
---@param zombie IsoZombie
local function fearOfLocationsKill(zombie)
	local player = zombie:getAttackedBy()
	---@cast player IsoPlayer
	if
		not player
		or not instanceof(player, "IsoPlayer")
		or (gameMode == ETW_CommonFunctions.GameMode.SP and not player:isLocalPlayer())
	then
		return
	else
		fearOfLocations(player, true)
	end
end

---Function responsible for setting up events
---@param playerIndex number
---@param player IsoPlayer
local function initializeEventsETW(playerIndex, player)
	Events.EveryOneMinute.Remove(outdoorsman)
	Events.OnZombieDead.Remove(outdoorsmanKill)
	if ETW_CommonLogicChecks.OutdoorsmanShouldExecute(player) then
		Events.EveryOneMinute.Add(outdoorsman)
		Events.OnZombieDead.Add(outdoorsmanKill)
	end
	Events.EveryOneMinute.Remove(fearOfLocations)
	Events.OnZombieDead.Remove(fearOfLocationsKill)
	if ETW_CommonLogicChecks.FearOfLocationsSystemShouldExecute(player) then
		Events.EveryOneMinute.Add(fearOfLocations)
		Events.OnZombieDead.Add(fearOfLocationsKill)
	end
	if gameMode == ETW_CommonFunctions.GameMode.MP_SERVER then
		Events.OnTick.Remove(initializeEventsETW)
	end
end

---Function responsible for clearing events
---@param character IsoPlayer
local function clearEventsETW(character)
	Events.EveryOneMinute.Remove(outdoorsman)
	Events.OnZombieDead.Remove(outdoorsmanKill)
	Events.EveryOneMinute.Remove(fearOfLocations)
	Events.OnZombieDead.Remove(fearOfLocationsKill)
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
