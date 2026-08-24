local ETWCombinedTraitChecks = {}

local ETW_CommonFunctions = require("ETW_CommonFunctions")

---@type EvolvingTraitsWorldSandboxVars
local SBvars = SandboxVars.EvolvingTraitsWorld

local ETW_Registry = require("ETW_Registry")
local ETWTraitsRegistry = ETW_Registry.traits
local gameMode = ETW_CommonFunctions.gameMode()

---@type fun(...: string)
local logETW = ETW_CommonFunctions.log

local FILENAME = "ETW_CombinedTraitFunctions.lua"
ETW_CommonFunctions.gameModeSafeguard(
	FILENAME,
	{ ETW_CommonFunctions.GameMode.SP, ETW_CommonFunctions.GameMode.MP_CLIENT, ETW_CommonFunctions.GameMode.MP_SERVER }
)

---Visits every living zombie within a bounded two-dimensional radius of the player.
---Only loaded moving objects on the player's current Z-level are considered.
---@param player IsoPlayer
---@param radius number
---@param visitor fun(zombie: IsoZombie, distanceSquared: number)|nil
---@return integer nearbyCount
function ETWCombinedTraitChecks.forEachNearbyLivingZombie(player, radius, visitor)
	radius = math.max(0, radius)
	local cell = player:getCell()
	if not cell then
		return 0
	end

	local playerX = player:getX()
	local playerY = player:getY()
	local playerZ = math.floor(player:getZ())
	local tileX = math.floor(playerX)
	local tileY = math.floor(playerY)
	local tileRadius = math.ceil(radius)
	local radiusSquared = radius * radius
	local nearbyCount = 0

	for x = tileX - tileRadius, tileX + tileRadius do
		for y = tileY - tileRadius, tileY + tileRadius do
			local square = cell:getGridSquare(x, y, playerZ)
			if square then
				local movingObjects = square:getMovingObjects()
				for i = 0, movingObjects:size() - 1 do
					local object = movingObjects:get(i)
					if instanceof(object, "IsoZombie") and not object:isDead() then
						local deltaX = object:getX() - playerX
						local deltaY = object:getY() - playerY
						local distanceSquared = deltaX * deltaX + deltaY * deltaY
						if distanceSquared <= radiusSquared then
							nearbyCount = nearbyCount + 1
							if visitor then
								visitor(object, distanceSquared)
							end
						end
					end
				end
			end
		end
	end
	return nearbyCount
end

local gymRatMuscleGroups = {
	arms = {
		BodyPartType.UpperArm_L,
		BodyPartType.UpperArm_R,
		BodyPartType.ForeArm_L,
		BodyPartType.ForeArm_R,
		BodyPartType.Hand_L,
		BodyPartType.Hand_R,
	},
	legs = {
		BodyPartType.UpperLeg_L,
		BodyPartType.UpperLeg_R,
		BodyPartType.LowerLeg_L,
		BodyPartType.LowerLeg_R,
	},
	chest = { BodyPartType.Torso_Upper },
	abs = { BodyPartType.Torso_Lower },
}

---Reduces each body part in a Gym Rat muscle group by the requested amount.
---@param player IsoPlayer
---@param groupName string
---@param amountPerPart number
---@return number|nil removedStiffness
function ETWCombinedTraitChecks.reduceGymRatStiffness(player, groupName, amountPerPart)
	local parts = gymRatMuscleGroups[groupName]
	if not parts then
		return nil
	end
	amountPerPart = math.max(0, amountPerPart)
	local removedStiffness = 0
	local bodyDamage = player:getBodyDamage()
	for _, partType in ipairs(parts) do
		local bodyPart = bodyDamage:getBodyPart(partType)
		local stiffness = bodyPart:getStiffness()
		local amount = math.min(stiffness, amountPerPart)
		if amount > 0 then
			bodyPart:setStiffness(stiffness - amount)
			removedStiffness = removedStiffness + amount
		end
	end
	return removedStiffness
end

---Removes only stiffness added by suppressed Gym Rat queue increments.
---@param player IsoPlayer
---@param groupName string
---@param increments integer
---@return number|nil removedStiffness
function ETWCombinedTraitChecks.undoGymRatStiffnessIncrements(player, groupName, increments)
	return ETWCombinedTraitChecks.reduceGymRatStiffness(player, groupName, math.max(0, increments) * 2.5)
end

---Applies vanilla-rate stiffness decay while the vanilla Fitness queue blocks natural decay.
---@param player IsoPlayer
---@param stiffnessState table
---@param decayPerPart number
---@param pendingServerDecay table|nil
function ETWCombinedTraitChecks.decayGymRatSuppressedStiffness(
	player,
	stiffnessState,
	decayPerPart,
	pendingServerDecay
)
	for groupName, state in pairs(stiffnessState) do
		if state.suppressing then
			ETWCombinedTraitChecks.reduceGymRatStiffness(player, groupName, decayPerPart)
			if pendingServerDecay then
				pendingServerDecay[groupName] = (pendingServerDecay[groupName] or 0) + decayPerPart
			end
		end
	end
end

---Tracks Gym Rat's vanilla queue and suppresses new stiffness after the configured threshold.
---@param player IsoPlayer
---@param stiffnessState table
---@param reduction number Fraction of peak queued stiffness after which further application is suppressed.
---@return boolean suppressionActive
function ETWCombinedTraitChecks.processGymRatExerciseFatigue(player, stiffnessState, reduction)
	local fitness = player:getFitness()
	local suppressionActive = false
	for groupName, _ in pairs(gymRatMuscleGroups) do
		local currentStiffness = fitness:getCurrentExeStiffnessInc(groupName)
		local state = stiffnessState[groupName]
		if not state and currentStiffness > 0 then
			state = {
				peak = currentStiffness,
				previous = currentStiffness,
				suppressing = reduction >= 1,
			}
			stiffnessState[groupName] = state
		elseif state then
			if currentStiffness > state.previous then
				state.peak = currentStiffness
				state.suppressing = reduction >= 1
			elseif state.suppressing and currentStiffness < state.previous then
				local increments = currentStiffness <= 0 and math.ceil(state.previous)
					or math.max(1, math.floor(state.previous - currentStiffness + 0.5))
				local removedStiffness =
					ETWCombinedTraitChecks.undoGymRatStiffnessIncrements(player, groupName, increments)
				local serverUndoRequested = gameMode == ETW_CommonFunctions.GameMode.MP_CLIENT
				if serverUndoRequested then
					sendClientCommand(
						player,
						"ETW",
						"undoGymRatStiffnessIncrements",
						{ group = groupName, increments = increments }
					)
				end
				logETW(
					"ETW Logger | Gym Rat fatigue: suppressed "
						.. increments
						.. " "
						.. groupName
						.. " queue increment(s) for "
						.. tostring(player:getUsername())
						.. " (OnlineID="
						.. player:getOnlineID()
						.. "); queued stiffness: "
						.. state.previous
						.. "->"
						.. currentStiffness
						.. ", applied stiffness removed: "
						.. removedStiffness
						.. ", server undo requested: "
						.. tostring(serverUndoRequested)
				)
			elseif not state.suppressing and currentStiffness <= state.peak * reduction then
				state.suppressing = true
				logETW(
					"ETW Logger | Gym Rat fatigue: began suppressing "
						.. groupName
						.. " at queued stiffness "
						.. currentStiffness
						.. "/"
						.. state.peak
				)
			end
			state.previous = currentStiffness
			if currentStiffness <= 0 then
				stiffnessState[groupName] = nil
			end
		end
		state = stiffnessState[groupName]
		if state and state.suppressing then
			suppressionActive = true
		end
	end
	return suppressionActive
end

---Calculates Anti-Gun Activist's protected XP penalty for a firearm skill.
---@param player IsoPlayer
---@param perk PerkFactory.Perk
---@param earnedAmount number
---@param penaltyPercent number
---@return number xpToRemove
---@return number|nil progress
---@return string|nil reason
function ETWCombinedTraitChecks.calculateAntiGunXPPenalty(player, perk, earnedAmount, penaltyPercent)
	earnedAmount = tonumber(earnedAmount)
	if not earnedAmount or earnedAmount <= 0 then
		return 0, nil, "invalid earned amount"
	end
	if not player:hasTrait(ETWTraitsRegistry.ANTI_GUN_ACTIVIST) then
		return 0, nil, "trait missing"
	end

	local level = player:getPerkLevel(perk)
	if level >= 10 then
		return 0, nil, "maximum level"
	end
	local perkDefinition = PerkFactory.getPerk(perk)
	local lowerXP = perkDefinition:getTotalXpForLevel(level)
	local upperXP = perkDefinition:getTotalXpForLevel(level + 1)
	local levelSpan = upperXP - lowerXP
	if levelSpan <= 0 then
		return 0, nil, "invalid level span"
	end

	local currentXP = player:getXp():getXP(perk)
	local progress = PZMath.clamp((currentXP - lowerXP) / levelSpan, 0, 1)
	local lowerBoundary = 0.05
	local upperBoundary = 0.95
	if progress < lowerBoundary or progress > upperBoundary then
		return 0, progress, "outside 5%-95% range"
	end

	local penaltyMultiplier = PZMath.clamp(penaltyPercent or 25, 0, 100) / 100
	local protectedXP = lowerXP + levelSpan * lowerBoundary
	local xpToRemove = math.min(earnedAmount * penaltyMultiplier, math.max(0, currentXP - protectedXP))
	if xpToRemove <= 0 then
		return 0, progress, "protected lower boundary"
	end
	return xpToRemove, progress, nil
end

---Calculates Anti-Gun Activist's protected Aiming XP penalty.
---@param player IsoPlayer
---@param earnedAmount number
---@return number xpToRemove
---@return number|nil progress
---@return string|nil reason
function ETWCombinedTraitChecks.calculateAntiGunAimingXPPenalty(player, earnedAmount)
	return ETWCombinedTraitChecks.calculateAntiGunXPPenalty(
		player,
		Perks.Aiming,
		earnedAmount,
		SBvars.AntiGunAimingXPPenaltyPercent or 25
	)
end

---Calculates Anti-Gun Activist's protected Reloading XP penalty.
---@param player IsoPlayer
---@param earnedAmount number
---@return number xpToRemove
---@return number|nil progress
---@return string|nil reason
function ETWCombinedTraitChecks.calculateAntiGunReloadingXPPenalty(player, earnedAmount)
	return ETWCombinedTraitChecks.calculateAntiGunXPPenalty(
		player,
		Perks.Reloading,
		earnedAmount,
		SBvars.AntiGunReloadingXPPenaltyPercent or 25
	)
end

---Function responsible for checking if player qualifies for Bodywork Enthusiast trait
---@param player IsoPlayer
function ETWCombinedTraitChecks.bodyworkEnthusiastCheck(player)
	local player = player or getPlayer()
	local modData = ETW_CommonFunctions.getETWModData(player)
	local level = player:getPerkLevel(Perks.MetalWelding) + player:getPerkLevel(Perks.Mechanics)
	if level >= SBvars.BodyworkEnthusiastSkill and modData.VehiclePartRepairs >= SBvars.BodyworkEnthusiastRepairs then
		if
			SBvars.DelayedTraitsSystem
			and not ETW_CommonFunctions.checkIfTraitIsInDelayedTraitsTable(
				player,
				ETWTraitsRegistry.BODYWORK_ENTHUSIAST
			)
		then
			ETW_CommonFunctions.addTraitToDelayTable({
				modData = modData,
				trait = ETWTraitsRegistry.BODYWORK_ENTHUSIAST,
				player = player,
				positiveTrait = true,
				gainingTrait = true,
			})
		elseif
			not SBvars.DelayedTraitsSystem
			or (
				SBvars.DelayedTraitsSystem
				and ETW_CommonFunctions.checkDelayedTraits(player, ETWTraitsRegistry.BODYWORK_ENTHUSIAST)
			)
		then
			ETW_CommonFunctions.addTraitToPlayer({
				player = player,
				trait = ETWTraitsRegistry.BODYWORK_ENTHUSIAST,
				positiveTrait = true,
			})
		end
	end
end

---Function responsible for checking if player qualifies for Mechanics trait
---@param player IsoPlayer
function ETWCombinedTraitChecks.mechanicsCheck(player)
	local player = player or getPlayer()
	local modData = ETW_CommonFunctions.getETWModData(player)
	if
		player:getPerkLevel(Perks.Mechanics) >= SBvars.MechanicsSkill
		and modData.VehiclePartRepairs >= SBvars.MechanicsRepairs
	then
		if
			SBvars.DelayedTraitsSystem
			and not ETW_CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, CharacterTrait.MECHANICS)
		then
			ETW_CommonFunctions.addTraitToDelayTable({
				modData = modData,
				trait = CharacterTrait.MECHANICS,
				player = player,
				positiveTrait = true,
				gainingTrait = true,
			})
		elseif
			not SBvars.DelayedTraitsSystem
			or (SBvars.DelayedTraitsSystem and ETW_CommonFunctions.checkDelayedTraits(player, CharacterTrait.MECHANICS))
		then
			ETW_CommonFunctions.addTraitToPlayer({
				player = player,
				trait = CharacterTrait.MECHANICS,
				positiveTrait = true,
			})
		end
	end
end

---Function responsible for checking if player qualifies for Sewer trait
---@param player IsoPlayer
function ETWCombinedTraitChecks.sewerCheck(player)
	local player = player or getPlayer()
	local modData = ETW_CommonFunctions.getETWModData(player)
	if
		player:getPerkLevel(Perks.Tailoring) >= SBvars.SewerSkill
		and #modData.UniqueClothingRipped >= SBvars.SewerUniqueClothesRipped
	then
		if
			SBvars.DelayedTraitsSystem
			and not ETW_CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, CharacterTrait.TAILOR)
		then
			ETW_CommonFunctions.addTraitToDelayTable({
				modData = modData,
				trait = CharacterTrait.TAILOR,
				player = player,
				positiveTrait = true,
				gainingTrait = true,
			})
		elseif
			not SBvars.DelayedTraitsSystem
			or (SBvars.DelayedTraitsSystem and ETW_CommonFunctions.checkDelayedTraits(player, CharacterTrait.TAILOR))
		then
			ETW_CommonFunctions.addTraitToPlayer({
				player = player,
				trait = CharacterTrait.TAILOR,
				positiveTrait = true,
			})
		end
	end
end

---Adds item name to the table of unique ripped clothes
---@param player IsoPlayer
---@param itemName String
function ETWCombinedTraitChecks.addClothingToUniqueRippedClothingList(player, itemName)
	local modData = ETW_CommonFunctions.getETWModData(player)
	if ETW_CommonFunctions.indexOf(modData.UniqueClothingRipped, itemName) == -1 then
		table.insert(modData.UniqueClothingRipped, itemName)
		ETWCombinedTraitChecks.sewerCheck(player)
	end
end

return ETWCombinedTraitChecks
