local ETW_CommonFunctions = require("ETW_CommonFunctions")
local ETW_Registry = require("ETW_Registry")
local ETW_CommonLogicChecks = require("ETW_CommonLogicChecks")

local FILENAME = "ETW_MentalTraits.lua"
if
	not ETW_CommonFunctions.gameModeSafeguard(
		FILENAME,
		{ ETW_CommonFunctions.GameMode.SP, ETW_CommonFunctions.GameMode.MP_SERVER }
	)
then
	return
end

local ETW_MentalTraits = {}

---@type EvolvingTraitsWorldTraitsRegistries
local ETWTraitsRegistry = ETW_Registry.traits
---@type EvolvingTraitsWorldSandboxVars
local SBvars = SandboxVars.EvolvingTraitsWorld
local random_instance = newrandom()
local logETW = ETW_CommonFunctions.log
local gameMode = ETW_CommonFunctions.gameMode()
local PARANOIA_YELL_RADIUS = 50
local PARANOIA_YELL_VOLUME = 50
local FIRE_RADIUS = 12
local FIRE_PANIC_PER_MINUTE = 10
local FIRE_CLOSE_PANIC_RADIUS = 3
local FIRE_CLOSE_PANIC_BONUS = 40
local FIRE_UNHAPPINESS_PER_PANIC = 0.1
local COLD_CORE_TEMPERATURE_THRESHOLD = 36.5
local HOT_CORE_TEMPERATURE_THRESHOLD = 37.5
local TEMPERATURE_STRESS_PER_DEGREE = 0.005
local TEMPERATURE_DISCOMFORT_PER_DEGREE = 0.5

---Returns the distance squared to an active fire on a loaded square, if any.
---@param cell IsoCell
---@param x number
---@param y number
---@param z number
---@param playerX number
---@param playerY number
---@param maximumSquared number
---@return number|nil distanceSquared
local function fireDistanceSquaredAtSquare(cell, x, y, z, playerX, playerY, maximumSquared)
	local deltaX, deltaY = x + 0.5 - playerX, y + 0.5 - playerY
	local distanceSquared = deltaX * deltaX + deltaY * deltaY
	if distanceSquared > FIRE_RADIUS * FIRE_RADIUS or distanceSquared > maximumSquared then
		return nil
	end
	local square = cell:getGridSquare(x, y, z)
	if not square then
		return nil
	end
	if square:haveFire() then
		return distanceSquared
	end
	local objects = square:getObjects()
	for i = 0, objects:size() - 1 do
		local object = objects:get(i)
		if instanceof(object, "IsoFireplace") and object:isLit() then
			return distanceSquared
		end
	end
	local movingObjects = square:getMovingObjects()
	for i = 0, movingObjects:size() - 1 do
		local object = movingObjects:get(i)
		if instanceof(object, "IsoGameCharacter") and object:isOnFire() then
			return distanceSquared
		end
	end
	return nil
end

---Finds the closest active fire by scanning outward from the player's square.
---After each ring, stops only when later rings cannot contain a closer square center.
---@param player IsoPlayer
---@return number|nil distance
local function nearestFireDistance(player)
	if player:isOnFire() then
		return 0
	end
	local cell = player:getCell()
	if not cell then
		return nil
	end
	local playerX, playerY = player:getX(), player:getY()
	local tileX, tileY = math.floor(playerX), math.floor(playerY)
	local playerZ = math.floor(player:getZ())
	local radiusSquared = FIRE_RADIUS * FIRE_RADIUS
	local nearestSquared = radiusSquared + 1.0
	for ring = 0, FIRE_RADIUS do
		if ring == 0 then
			local found = fireDistanceSquaredAtSquare(cell, tileX, tileY, playerZ, playerX, playerY, nearestSquared)
			if found then
				nearestSquared = found
			end
		else
			for offsetX = -ring, ring do
				local x = tileX + offsetX
				local north = fireDistanceSquaredAtSquare(cell, x, tileY - ring, playerZ, playerX, playerY, nearestSquared)
				local south = fireDistanceSquaredAtSquare(cell, x, tileY + ring, playerZ, playerX, playerY, nearestSquared)
				if north and north < nearestSquared then
					nearestSquared = north
				end
				if south and south < nearestSquared then
					nearestSquared = south
				end
			end
			for offsetY = -ring + 1, ring - 1 do
				local y = tileY + offsetY
				local west = fireDistanceSquaredAtSquare(cell, tileX - ring, y, playerZ, playerX, playerY, nearestSquared)
				local east = fireDistanceSquaredAtSquare(cell, tileX + ring, y, playerZ, playerX, playerY, nearestSquared)
				if west and west < nearestSquared then
					nearestSquared = west
				end
				if east and east < nearestSquared then
					nearestSquared = east
				end
			end
		end
		local nextRingMinimum = ring + 0.5
		if nearestSquared <= radiusSquared and nearestSquared <= nextRingMinimum * nextRingMinimum then
			return math.sqrt(nearestSquared)
		end
	end
	if nearestSquared <= radiusSquared then
		return math.sqrt(nearestSquared)
	end
	return nil
end

---Adjusts panic and unhappiness once per minute according to the nearest active fire.
---@param player IsoPlayer
---@param stats Stats
function ETW_MentalTraits.fireTrait(player, stats)
	local effectMultiplier = math.max(0, SBvars.FireTraitsEffectMultiplier or 1)
	if effectMultiplier == 0 then
		return
	end
	local distance = nearestFireDistance(player)
	if not distance then
		return
	end
	local panicChange = FIRE_PANIC_PER_MINUTE * (FIRE_RADIUS + 1 - distance) / (FIRE_RADIUS + 1)
	local panic = stats:get(CharacterStat.PANIC)
	if player:hasTrait(ETWTraitsRegistry.PYROPHOBIA) then
		if distance < FIRE_CLOSE_PANIC_RADIUS then
			panicChange = panicChange + FIRE_CLOSE_PANIC_BONUS * (1 - distance / FIRE_CLOSE_PANIC_RADIUS)
		end
		panicChange = panicChange * effectMultiplier
		stats:set(CharacterStat.PANIC, math.min(100, panic + panicChange))
		stats:set(
			CharacterStat.UNHAPPINESS,
			math.min(100, stats:get(CharacterStat.UNHAPPINESS) + panicChange * FIRE_UNHAPPINESS_PER_PANIC)
		)
	elseif player:hasTrait(ETWTraitsRegistry.PYROMANIA) then
		panicChange = panicChange * effectMultiplier
		stats:set(CharacterStat.PANIC, math.max(0, panic - panicChange))
		stats:set(
			CharacterStat.UNHAPPINESS,
			math.max(0, stats:get(CharacterStat.UNHAPPINESS) - panicChange * FIRE_UNHAPPINESS_PER_PANIC)
		)
	end
end

---Adjusts stress and discomfort once per minute according to core body temperature and temperature preference.
---@param player IsoPlayer
---@param stats Stats
---@param bodyDamage BodyDamage
function ETW_MentalTraits.temperatureTrait(player, stats, bodyDamage)
	local effectMultiplier = math.max(0, SBvars.TemperatureTraitsEffectMultiplier or 1)
	if effectMultiplier == 0 then
		return
	end
	local coldThreshold = SBvars.ColdTraitsTemperatureThreshold or COLD_CORE_TEMPERATURE_THRESHOLD
	local heatThreshold = SBvars.HeatTraitsTemperatureThreshold or HOT_CORE_TEMPERATURE_THRESHOLD
	local coreTemperature = bodyDamage:getThermoregulator():getCoreTemperature()
	local effectDirection
	local temperatureDeviation
	local heatAverse = player:hasTrait(ETWTraitsRegistry.HEAT_AVERSE)
	local heatLoving = player:hasTrait(ETWTraitsRegistry.HEAT_LOVING)
	local coldAverse = player:hasTrait(ETWTraitsRegistry.COLD_AVERSE)
	local coldLoving = player:hasTrait(ETWTraitsRegistry.COLD_LOVING)
	if (heatAverse or heatLoving) and coreTemperature > heatThreshold then
		if heatAverse then
			effectDirection = 1
		else
			effectDirection = -1
		end
		temperatureDeviation = coreTemperature - heatThreshold
	elseif (coldAverse or coldLoving) and coreTemperature < coldThreshold then
		if coldAverse then
			effectDirection = 1
		else
			effectDirection = -1
		end
		temperatureDeviation = coldThreshold - coreTemperature
	else
		return
	end

	local stress = stats:get(CharacterStat.STRESS)
	local discomfort = stats:get(CharacterStat.DISCOMFORT)
	local stressChange = temperatureDeviation * TEMPERATURE_STRESS_PER_DEGREE * effectMultiplier * effectDirection
	local discomfortChange = temperatureDeviation * TEMPERATURE_DISCOMFORT_PER_DEGREE * effectMultiplier * effectDirection
	local newStress = math.max(0, math.min(1, stress + stressChange))
	local newDiscomfort = math.max(0, math.min(100, discomfort + discomfortChange))
	stats:set(CharacterStat.STRESS, newStress)
	stats:set(CharacterStat.DISCOMFORT, newDiscomfort)
	logETW(
		"ETW Logger | temperatureTrait(): coreTemperature="
			.. coreTemperature
			.. ", effectDirection="
			.. effectDirection
			.. ", temperatureDeviation="
			.. temperatureDeviation
			.. ", stressChange="
			.. stressChange
			.. ", discomfortChange="
			.. discomfortChange
			.. ", stress="
			.. stats:get(CharacterStat.STRESS)
			.. "->"
			.. newStress
			.. ", discomfort="
			.. stats:get(CharacterStat.DISCOMFORT)
			.. "->"
			.. newDiscomfort
	)
end

local original_ISPetAnimal_animEvent = ISPetAnimal.animEvent

---Decorates animal petting to provide Pet Therapy mood effects and progression.
function ISPetAnimal:animEvent(event, parameter)
	if event == "pettingFinished" then
		local player = self.character
		if
			player:hasTrait(ETWTraitsRegistry.PET_THERAPY)
			or ETW_CommonLogicChecks.PetTherapyShouldExecute(player)
		then
			local modData = ETW_CommonFunctions.getETWModData(player)
			if modData then
				local animalsSystemModData = modData.AnimalsSystem
				local currentMinute = GameTime.getInstance():getMinutesStamp()
				if
					currentMinute - animalsSystemModData.LastMinuteTimestampWhenPettedWithBoost
					>= SBvars.PetTherapyMinutesBetweenPets
				then
					local animalID = self.animal:getAnimalID()
					logETW(
						"ETW Logger | ISPetAnimal:animEvent(pettingFinished): caught, petting animal with ID " .. animalID
					)
					if player:hasTrait(ETWTraitsRegistry.PET_THERAPY) then
						animalsSystemModData.LastMinuteTimestampWhenPettedWithBoost = currentMinute
						local stats = player:getStats()
						local nicotineWithdrawal = stats:get(CharacterStat.NICOTINE_WITHDRAWAL)
						local unhappiness = stats:get(CharacterStat.UNHAPPINESS)
						local stress = math.max(0, stats:get(CharacterStat.STRESS) - nicotineWithdrawal)
						local panic = stats:get(CharacterStat.PANIC)
						local boredom = stats:get(CharacterStat.BOREDOM)
						local moodMultiplier = SBvars.PetTherapyMoodBoostMultiplier
						stats:set(CharacterStat.UNHAPPINESS, math.max(0, unhappiness - moodMultiplier))
						stats:set(CharacterStat.STRESS, math.max(0, stress - 0.01 * moodMultiplier))
						stats:set(CharacterStat.PANIC, math.max(0, panic - moodMultiplier))
						stats:set(CharacterStat.BOREDOM, math.max(0, boredom - moodMultiplier))
						logETW(
							"ETW Logger | ISPetAnimal:animEvent(): Petting Animal. Unhappiness:"
								.. unhappiness
								.. "->"
								.. stats:get(CharacterStat.UNHAPPINESS)
								.. ", stress: "
								.. math.min(1, stress + nicotineWithdrawal)
								.. "->"
								.. stats:get(CharacterStat.STRESS)
								.. ", panic: "
								.. panic
								.. "->"
								.. stats:get(CharacterStat.PANIC)
								.. ", boredom: "
								.. boredom
								.. "->"
								.. stats:get(CharacterStat.BOREDOM)
						)
					else
						if ETW_CommonFunctions.indexOf(animalsSystemModData.UniqueAnimalsPetted, animalID) == -1 then
							table.insert(animalsSystemModData.UniqueAnimalsPetted, animalID)
							logETW(
								"ETW Logger | ISPetAnimal:animEvent(pettingFinished): petting animal that's not in UniqueAnimalsPetted, added it"
							)
						end
						local husbandry = player:getPerkLevel(Perks.Husbandry)
						if
							#animalsSystemModData.UniqueAnimalsPetted >= SBvars.PetTherapyUniqueAnimalsPetted
							and husbandry >= SBvars.PetTherapySkill
						then
							if
								SBvars.DelayedTraitsSystem
								and not ETW_CommonFunctions.checkIfTraitIsInDelayedTraitsTable(
									player,
									ETWTraitsRegistry.PET_THERAPY,
									modData
								)
							then
								ETW_CommonFunctions.addTraitToDelayTable({
									modData = modData,
									trait = ETWTraitsRegistry.PET_THERAPY,
									player = player,
									positiveTrait = true,
									gainingTrait = true,
								})
							elseif
								not SBvars.DelayedTraitsSystem
								or (
									SBvars.DelayedTraitsSystem
									and ETW_CommonFunctions.checkDelayedTraits(
										player,
										ETWTraitsRegistry.PET_THERAPY,
										modData
									)
								)
							then
								ETW_CommonFunctions.addTraitToPlayer({
									player = player,
									trait = ETWTraitsRegistry.PET_THERAPY,
									positiveTrait = true,
								})
							end
						end
					end
				end
			end
		end
	end
	original_ISPetAnimal_animEvent(self, event, parameter)
end

---Applies Blissful's passive mood recovery.
---@param player IsoPlayer
---@param stats Stats
function ETW_MentalTraits.blissfulTrait(player, stats)
	local unhappiness = stats:get(CharacterStat.UNHAPPINESS)
	local boredom = stats:get(CharacterStat.BOREDOM)
	local unhappinessReduction = math.max(0, math.min(100, SBvars.BlissfulUnhappinessReductionPerMinute or 1))
	local boredomReduction = math.max(0, math.min(100, SBvars.BlissfulBoredomReductionPerMinute or 0.5))
	local resultingUnhappiness = math.max(0.0, unhappiness - unhappinessReduction)
	local resultingBoredom = math.max(0.0, boredom - boredomReduction)
	stats:set(CharacterStat.UNHAPPINESS, resultingUnhappiness)
	stats:set(CharacterStat.BOREDOM, resultingBoredom)
	if resultingUnhappiness ~= unhappiness or resultingBoredom ~= boredom then
		logETW(
			"ETW Logger | blissfulTrait(): unhappiness: "
				.. unhappiness
				.. "->"
				.. resultingUnhappiness
				.. ", boredom: "
				.. boredom
				.. "->"
				.. resultingBoredom
		)
	end
end

---Starts hourly Depressive episodes and recovers their unhappiness every minute.
---@param player IsoPlayer
---@param modData EvolvingTraitsWorldModData
---@param stats Stats|nil
---@param attemptEpisode boolean
function ETW_MentalTraits.depressiveTrait(player, modData, stats, attemptEpisode)
	stats = stats or player:getStats()
	local unhappiness = stats:get(CharacterStat.UNHAPPINESS)
	local episodeIncrease = math.max(0, math.min(100, SBvars.DepressiveUnhappinessIncrease or 25))
	if episodeIncrease == 0 then
		modData.DepressiveEpisodeActive = false
		return
	end
	if modData.DepressiveEpisodeActive then
		if unhappiness < episodeIncrease then
			modData.DepressiveEpisodeActive = false
			logETW(
				"ETW Logger | depressiveTrait(): episode ended for "
					.. tostring(player:getUsername())
					.. " (OnlineID="
					.. player:getOnlineID()
					.. ") at unhappiness "
					.. unhappiness
			)
			return
		end
		local recovery = math.max(0, math.min(100, SBvars.DepressiveRecoveryPerMinute or 0.01))
		stats:set(CharacterStat.UNHAPPINESS, math.max(0, unhappiness - recovery))
		return
	end
	if not attemptEpisode then
		return
	end
	local chance = PZMath.clamp(SBvars.DepressiveEpisodeChance or 2, 0, 100)
	local hasSelfDestructive = player:hasTrait(ETWTraitsRegistry.SELF_DESTRUCTIVE)
	if hasSelfDestructive then
		chance = PZMath.clamp(
			chance + (SBvars.SelfDestructiveDepressiveEpisodeChanceBonus or 1),
			0,
			100
		)
	end
	local roll = random_instance:random(1, 100)
	logETW(
		"ETW Logger | depressiveTrait(): episode roll for "
			.. tostring(player:getUsername())
			.. " (OnlineID="
			.. player:getOnlineID()
			.. "); roll: "
			.. roll
			.. "/100; chance: "
			.. chance
			.. "%; Self-Destructive interaction: "
			.. tostring(hasSelfDestructive)
	)
	if roll <= chance then
		local resultingUnhappiness = math.min(100, unhappiness + episodeIncrease)
		stats:set(CharacterStat.UNHAPPINESS, resultingUnhappiness)
		modData.DepressiveEpisodeActive = true
		logETW(
			"ETW Logger | depressiveTrait(): episode started for "
				.. tostring(player:getUsername())
				.. " (OnlineID="
				.. player:getOnlineID()
				.. "); unhappiness: "
				.. unhappiness
				.. "->"
				.. resultingUnhappiness
		)
	end
end

---Reduces health toward an unhappiness-scaled floor for Self-Destructive characters.
---@param player IsoPlayer
---@param stats Stats
---@param bodyDamage BodyDamage
function ETW_MentalTraits.selfDestructiveTrait(player, stats, bodyDamage)
	local unhappiness = stats:get(CharacterStat.UNHAPPINESS)
	local threshold = PZMath.clamp(SBvars.SelfDestructiveUnhappinessThreshold or 25, 0, 100)
	if unhappiness < threshold then
		return
	end

	local hasDepressive = player:hasTrait(ETWTraitsRegistry.DEPRESSIVE)
	local maximumHealthLoss = SBvars.SelfDestructiveMaximumHealthLossPercent or 33.33
	if hasDepressive then
		maximumHealthLoss = SBvars.SelfDestructiveMaxHealthLossWithDepressive or 50
	end
	maximumHealthLoss = math.max(0, math.min(100, maximumHealthLoss))
	local healthFloor = math.max(0, math.min(100, 100 - unhappiness / 100 * maximumHealthLoss))
	local currentHealth = bodyDamage:getOverallBodyHealth()
	if currentHealth <= healthFloor then
		return
	end

	local configuredDamage = math.max(0, SBvars.SelfDestructiveDamagePerMinute or 0.15)
	local damage = math.min(configuredDamage, currentHealth - healthFloor)
	if damage <= 0 then
		return
	end
	local bodyParts = bodyDamage:getBodyParts()
	for i = 0, bodyParts:size() - 1 do
		bodyParts:get(i):AddDamage(damage)
	end
	logETW(
		"ETW Logger | selfDestructiveTrait(): damaged "
			.. tostring(player:getUsername())
			.. " (OnlineID="
			.. player:getOnlineID()
			.. "); unhappiness: "
			.. unhappiness
			.. "; overall health: "
			.. currentHealth
			.. "->"
			.. bodyDamage:getOverallBodyHealth()
			.. "; health floor: "
			.. healthFloor
			.. "; damage per body part: "
			.. damage
			.. "; Depressive interaction: "
			.. tostring(hasDepressive)
	)
end

---Periodically triggers a false scare while a Paranoia character is moving.
---@param player IsoPlayer
---@param stats Stats
---@param modData EvolvingTraitsWorldModData
function ETW_MentalTraits.paranoiaTrait(player, stats, modData)
	if modData.ParanoiaCooldownMinutes > 0 then
		modData.ParanoiaCooldownMinutes = modData.ParanoiaCooldownMinutes - 1
		return
	end
	if not player:isPlayerMoving() then
		return
	end

	local stress = stats:get(CharacterStat.STRESS)
	local baseChance = math.max(0, math.min(100, SBvars.ParanoiaBaseChancePercent or 1))
	local stressBonus = math.max(0, math.min(100, SBvars.ParanoiaStressChanceBonusPercent or 2))
	local chance = math.max(0, math.min(100, baseChance + stress * stressBonus))
	local roll = random_instance:random(1, 100)
	if roll > chance then
		return
	end

	local panic = stats:get(CharacterStat.PANIC)
	local panicIncrease = math.max(0, math.min(100, SBvars.ParanoiaPanicIncrease or 25))
	local stressIncrease = math.max(0, math.min(100, SBvars.ParanoiaStressIncreasePercent or 10)) / 100
	local resultingPanic = math.min(100, panic + panicIncrease)
	local resultingStress = math.min(1, stress + stressIncrease)
	stats:set(CharacterStat.PANIC, resultingPanic)
	stats:set(CharacterStat.STRESS, resultingStress)
	modData.ParanoiaCooldownMinutes = math.max(0, math.floor(SBvars.ParanoiaCooldownMinutes or 30))
	local yellChance = PZMath.clamp(SBvars.ParanoiaYellChancePercent or 25, 0, 100)
	local yellRoll = random_instance:random(1, 100)
	local yell = yellRoll <= yellChance
	if yell then
		addSound(
			player,
			math.floor(player:getX()),
			math.floor(player:getY()),
			math.floor(player:getZ()),
			PARANOIA_YELL_RADIUS,
			PARANOIA_YELL_VOLUME
		)
	end

	if gameMode == ETW_CommonFunctions.GameMode.MP_SERVER then
		sendServerCommand(player, "ETW", "triggerParanoiaScare", { yell = yell })
	else
		ETW_CommonFunctions.playParanoiaScare(player, yell)
	end
	logETW(
		"ETW Logger | paranoiaTrait(): triggered for "
			.. tostring(player:getUsername())
			.. " (OnlineID="
			.. player:getOnlineID()
			.. "); roll: "
			.. roll
			.. "/100; chance: "
			.. chance
			.. "%; panic: "
			.. panic
			.. "->"
			.. resultingPanic
			.. "; stress: "
			.. stress
			.. "->"
			.. resultingStress
			.. "; yell roll: "
			.. yellRoll
			.. "/100; yell chance: "
			.. yellChance
			.. "%; yelled: "
			.. tostring(yell)
			.. (yell and "; world sound: radius=50, volume=50" or "")
			.. "; cooldown: "
			.. modData.ParanoiaCooldownMinutes
			.. " minutes"
	)
end

function ETW_MentalTraits.asceticTrait(player, stats)
	local unhappiness = stats:get(CharacterStat.UNHAPPINESS)
	local boredom = stats:get(CharacterStat.BOREDOM)
	local unhappinessReduction = math.max(0, math.min(100, SBvars.AsceticUnhappinessReductionPerMinute or 0.25))
	local boredomReduction = math.max(0, math.min(100, SBvars.AsceticBoredomReductionPerMinute or 0.25))
	local resultingUnhappiness = unhappiness - unhappinessReduction
	local resultingBoredom = boredom - boredomReduction
	if resultingUnhappiness < 0 then
		resultingUnhappiness = 0
	end
	if resultingBoredom < 0 then
		resultingBoredom = 0
	end
	if resultingUnhappiness ~= unhappiness or resultingBoredom ~= boredom then
		stats:set(CharacterStat.UNHAPPINESS, resultingUnhappiness)
		stats:set(CharacterStat.BOREDOM, resultingBoredom)
		logETW(
			"ETW Logger | asceticTrait(): unhappiness: "
				.. unhappiness
				.. "->"
				.. resultingUnhappiness
				.. ", boredom: "
				.. boredom
				.. "->"
				.. resultingBoredom
		)
	end
end

---Tracks an online minute and applies TV Junkie's mood penalties once the viewing grace period expires.
---@param player IsoPlayer
---@param stats Stats
---@param modData EvolvingTraitsWorldModData
function ETW_MentalTraits.tvJunkieTrait(player, stats, modData)
	local tvJunkieSystem = modData.TVJunkieSystem
	tvJunkieSystem.ActiveMinutes = tvJunkieSystem.ActiveMinutes + 1
	tvJunkieSystem.MinutesSinceLastWatch = tvJunkieSystem.MinutesSinceLastWatch + 1
	local graceMinutes = math.max(1, math.floor(SBvars.TVJunkieHoursWithoutTelevision or 24)) * 60
	if tvJunkieSystem.MinutesSinceLastWatch < graceMinutes then
		return
	end

	local unhappiness = stats:get(CharacterStat.UNHAPPINESS)
	local boredom = stats:get(CharacterStat.BOREDOM)
	local unhappinessIncrease = math.max(0, math.min(100, SBvars.TVJunkieUnhappinessPerMinute or 0.1))
	local boredomIncrease = math.max(0, math.min(100, SBvars.TVJunkieBoredomPerMinute or 0.1))
	local resultingUnhappiness = math.min(100, unhappiness + unhappinessIncrease)
	local resultingBoredom = math.min(100, boredom + boredomIncrease)
	stats:set(CharacterStat.UNHAPPINESS, resultingUnhappiness)
	stats:set(CharacterStat.BOREDOM, resultingBoredom)
	if resultingUnhappiness ~= unhappiness or resultingBoredom ~= boredom then
		logETW(
			"ETW Logger | tvJunkieTrait(): unhappiness: "
				.. unhappiness
				.. "->"
				.. resultingUnhappiness
				.. ", boredom: "
				.. boredom
				.. "->"
				.. resultingBoredom
		)
	end
end

return ETW_MentalTraits
