local ETW_CommonFunctions = require("ETW_CommonFunctions")
local ETW_CommonLogicChecks = require("ETW_CommonLogicChecks")

---@type EvolvingTraitsWorldSandboxVars
local SBvars = SandboxVars.EvolvingTraitsWorld
local gameMode = ETW_CommonFunctions.gameMode()

---@type fun(...: string)
local logETW = ETW_CommonFunctions.log

local FILENAME = "ETW_ByTimeClient.lua"
if
	not ETW_CommonFunctions.gameModeSafeguard(
		FILENAME,
		{ ETW_CommonFunctions.GameMode.SP, ETW_CommonFunctions.GameMode.MP_CLIENT }
	)
then
	return
end

local catEyes

---Applies Cat Eyes progress locally in SP or forwards it to the server in MP.
---@param player IsoPlayer
---@param progressIncrease number
---@param isKill boolean
local function applyCatEyesProgress(player, progressIncrease, isKill)
	if type(progressIncrease) ~= "number" or progressIncrease <= 0 then
		return
	end

	if gameMode == ETW_CommonFunctions.GameMode.MP_CLIENT then
		if isKill then
			logETW("ETW Logger | catEyes(): was triggered by a kill")
		end
		logETW(
			"ETW Logger | catEyes(): client sending player="
				.. tostring(player:getUsername())
				.. " progressIncrease="
				.. tostring(progressIncrease)
		)
		sendClientCommand(player, "ETW", "catEyesRecordProgress", {
			progressIncrease = progressIncrease,
			isKill = isKill,
		})
		return
	end

	local modData = ETW_CommonFunctions.getETWModData(player)
	if not modData then
		logETW("ETW Logger | applyCatEyesProgress(): modData is nil, returning early")
		return
	end

	modData.CatEyesCounter = modData.CatEyesCounter + progressIncrease
	if isKill then
		logETW("ETW Logger | applyCatEyesProgress(): was triggered by a kill")
	end
	logETW(
		"ETW Logger | applyCatEyesProgress(): progressIncrease="
			.. tostring(progressIncrease)
			.. ", CatEyesCounter="
			.. tostring(modData.CatEyesCounter)
	)

	if player:hasTrait(CharacterTrait.NIGHT_VISION) or modData.CatEyesCounter < SBvars.CatEyesCounter then
		return
	end

	if
		SBvars.DelayedTraitsSystem
		and not ETW_CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, CharacterTrait.NIGHT_VISION)
	then
		ETW_CommonFunctions.addTraitToDelayTable({
			modData = modData,
			trait = CharacterTrait.NIGHT_VISION,
			player = player,
			positiveTrait = true,
			gainingTrait = true,
		})
	elseif
		not SBvars.DelayedTraitsSystem
		or (SBvars.DelayedTraitsSystem and ETW_CommonFunctions.checkDelayedTraits(player, CharacterTrait.NIGHT_VISION))
	then
		ETW_CommonFunctions.addTraitToPlayer({
			player = player,
			trait = CharacterTrait.NIGHT_VISION,
			positiveTrait = true,
		})
		Events.EveryOneMinute.Remove(catEyes)
	end
end

---Calculates Cat Eyes progress client-side and records it.
---@param player IsoPlayer
---@param isKill boolean
catEyes = function(player, isKill)
	player = player or getPlayer()
	if not player or not ETW_CommonLogicChecks.CatEyesShouldExecute(player) then
		return
	end

	isKill = isKill or false
	local nightStrength = getClimateManager():getNightStrength()
	if nightStrength <= 0 then
		return
	end

	local playerNum = player:getPlayerNum()
	local checkedSquares = 0
	local squaresVisible = 0
	local square
	local plX, plY, plZ = player:getX(), player:getY(), player:getZ()
	local radius = 30
	local playerIsInside = player:isInARoom()
	local hasEagleEyed = player:hasTrait(CharacterTrait.EAGLE_EYED)
	local progressIncrease = 0

	-- print(player:getDisplayName() .. " is checking for cat eyes with nightStrength: " .. tostring(nightStrength))
	-- print("Position: x=" .. tostring(plX) .. ", y=" .. tostring(plY) .. ", z=" .. tostring(plZ))

	for x = -radius, radius do
		for y = -radius, radius do
			square = getSquare(plX + x, plY + y, plZ)
			checkedSquares = checkedSquares + 1
			if square and square:isCanSee(playerNum) then
				-- print(
				-- 	"ETW catEyes debug | can see square at x="
				-- 		.. tostring(plX + x)
				-- 		.. ", y="
				-- 		.. tostring(plY + y)
				-- 		.. ", z="
				-- 		.. tostring(plZ)
				-- )
				local squareLightLevel = square:getLightLevel(playerNum)
				local squareLightPenalty = 1 - squareLightLevel
				local baseMultiplier = 0.01
				local squareInRoom = square:isInARoom()
				local roomMultiplier = (squareInRoom and playerIsInside and 2 or 1)
				local eagleEyedMultiplier = (hasEagleEyed and 2 or 1)
				local squareDarknessLevel = nightStrength
					* squareLightPenalty
					* baseMultiplier
					* roomMultiplier
					* eagleEyedMultiplier
				-- print(
				-- 	"ETW catEyes debug | nightStrength="
				-- 		.. tostring(nightStrength)
				-- 		.. ", playerNum="
				-- 		.. tostring(playerNum)
				-- 		.. ", squareLightLevel="
				-- 		.. tostring(squareLightLevel)
				-- 		.. ", squareLightPenalty="
				-- 		.. tostring(squareLightPenalty)
				-- 		.. ", baseMultiplier="
				-- 		.. tostring(baseMultiplier)
				-- 		.. ", squareInRoom="
				-- 		.. tostring(squareInRoom)
				-- 		.. ", playerIsInside="
				-- 		.. tostring(playerIsInside)
				-- 		.. ", roomMultiplier="
				-- 		.. tostring(roomMultiplier)
				-- 		.. ", hasEagleEyed="
				-- 		.. tostring(hasEagleEyed)
				-- 		.. ", eagleEyedMultiplier="
				-- 		.. tostring(eagleEyedMultiplier)
				-- 		.. ", squareDarknessLevel="
				-- 		.. tostring(squareDarknessLevel)
				-- )
				squaresVisible = squaresVisible + 1
				progressIncrease = progressIncrease + squareDarknessLevel
			end
		end
	end

	logETW(
		"ETW Logger | catEyes(): Checked squares: "
			.. checkedSquares
			.. ", visible squares: "
			.. squaresVisible
			.. " with total darkness level of "
			.. progressIncrease
	)
	applyCatEyesProgress(player, progressIncrease, isKill)
end

---Helper function to fire catEyes() on zombie kill.
---@param zombie IsoZombie
local function catEyesKill(zombie)
	local attacker = zombie:getAttackedBy()
	local player = getPlayer()
	if not player or attacker ~= player then
		return
	end
	catEyes(player, true)
end

---Sets up Cat Eyes tracking.
---@param playerIndex number
---@param player IsoPlayer
local function initializeEventsETW(playerIndex, player)
	Events.EveryOneMinute.Remove(catEyes)
	Events.OnZombieDead.Remove(catEyesKill)
	if ETW_CommonLogicChecks.CatEyesShouldExecute(player) then
		Events.EveryOneMinute.Add(catEyes)
		Events.OnZombieDead.Add(catEyesKill)
	end
end

---@param character IsoPlayer
local function clearEventsETW(character)
	Events.EveryOneMinute.Remove(catEyes)
	Events.OnZombieDead.Remove(catEyesKill)
	logETW("ETW Logger | System: clearEventsETW in " .. FILENAME)
end

Events.OnCreatePlayer.Remove(initializeEventsETW)
Events.OnCreatePlayer.Add(initializeEventsETW)
Events.OnPlayerDeath.Remove(clearEventsETW)
Events.OnPlayerDeath.Add(clearEventsETW)
