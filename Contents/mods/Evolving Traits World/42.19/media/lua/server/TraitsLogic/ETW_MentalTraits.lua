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

local original_ISPetAnimal_animEvent = ISPetAnimal.animEvent

---Decorates animal petting to provide Pet Therapy mood effects and progression.
function ISPetAnimal:animEvent(event, parameter)
	if event == "pettingFinished" then
		local player = self.character
		if ETW_CommonLogicChecks.PetTherapyShouldExecute(player) then
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
function ETW_MentalTraits.blissfulTrait(player)
	local stats = player:getStats()
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
---@param attemptEpisode boolean
function ETW_MentalTraits.depressiveTrait(player, modData, attemptEpisode)
	if not player:hasTrait(ETWTraitsRegistry.DEPRESSIVE) then
		modData.DepressiveEpisodeActive = false
		return
	end
	local stats = player:getStats()
	local unhappiness = stats:get(CharacterStat.UNHAPPINESS)
	local episodeIncrease = PZMath.clamp(SBvars.DepressiveUnhappinessIncrease or 25, 0, 100)
	if episodeIncrease == 0 then
		modData.DepressiveEpisodeActive = false
		return
	end
	if modData.DepressiveEpisodeActive then
		if unhappiness < episodeIncrease then
			modData.DepressiveEpisodeActive = false
			logETW("ETW Logger | depressiveTrait(): episode ended at unhappiness " .. unhappiness)
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
	if random_instance:random(1, 100) <= chance then
		local resultingUnhappiness = math.min(100, unhappiness + episodeIncrease)
		stats:set(CharacterStat.UNHAPPINESS, resultingUnhappiness)
		modData.DepressiveEpisodeActive = true
		logETW(
			"ETW Logger | depressiveTrait(): episode started; unhappiness: "
				.. unhappiness
				.. "->"
				.. resultingUnhappiness
		)
	end
end

return ETW_MentalTraits
