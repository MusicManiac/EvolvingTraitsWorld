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
								ETWTraitsRegistry.PET_THERAPY
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
								and ETW_CommonFunctions.checkDelayedTraits(player, ETWTraitsRegistry.PET_THERAPY)
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
	original_ISPetAnimal_animEvent(self, event, parameter)
end

---Applies Blissful's passive mood recovery.
---@param player IsoPlayer
---@param stats Stats
function ETW_MentalTraits.blissfulTrait(player, stats)
	local unhappiness = stats:get(CharacterStat.UNHAPPINESS)
	local boredom = stats:get(CharacterStat.BOREDOM)
	local unhappinessReduction = PZMath.clamp(SBvars.BlissfulUnhappinessReductionPerMinute or 1, 0, 100)
	local boredomReduction = PZMath.clamp(SBvars.BlissfulBoredomReductionPerMinute or 0.5, 0, 100)
	local resultingUnhappiness = math.max(0, unhappiness - unhappinessReduction)
	local resultingBoredom = math.max(0, boredom - boredomReduction)
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
	local episodeIncrease = PZMath.clamp(SBvars.DepressiveUnhappinessIncrease or 25, 0, 100)
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
		local recovery = PZMath.clamp(SBvars.DepressiveRecoveryPerMinute or 0.01, 0, 100)
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
	maximumHealthLoss = PZMath.clamp(maximumHealthLoss, 0, 100)
	local healthFloor = PZMath.clamp(100 - unhappiness / 100 * maximumHealthLoss, 0, 100)
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
	local baseChance = PZMath.clamp(SBvars.ParanoiaBaseChancePercent or 1, 0, 100)
	local stressBonus = PZMath.clamp(SBvars.ParanoiaStressChanceBonusPercent or 2, 0, 100)
	local chance = PZMath.clamp(baseChance + stress * stressBonus, 0, 100)
	local roll = random_instance:random(1, 100)
	if roll > chance then
		return
	end

	local panic = stats:get(CharacterStat.PANIC)
	local panicIncrease = PZMath.clamp(SBvars.ParanoiaPanicIncrease or 25, 0, 100)
	local stressIncrease = PZMath.clamp(SBvars.ParanoiaStressIncreasePercent or 10, 0, 100) / 100
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
			player:getX(),
			player:getY(),
			player:getZ(),
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
	local unhappinessReduction = PZMath.clamp(SBvars.AsceticUnhappinessReductionPerMinute or 0.25, 0, 100)
	local boredomReduction = PZMath.clamp(SBvars.AsceticBoredomReductionPerMinute or 0.25, 0, 100)
	local resultingUnhappiness = math.max(0, unhappiness - unhappinessReduction)
	local resultingBoredom = math.max(0, boredom - boredomReduction)
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

return ETW_MentalTraits
