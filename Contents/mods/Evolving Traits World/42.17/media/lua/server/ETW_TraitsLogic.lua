local ETW_ModDataServer = require("ETW_ModDataServer")
local ETW_CommonFunctions = require("ETW_CommonFunctions")
local ETWRegistries = require("ETW_Registry")

---@type EvolvingTraitsWorldTraitsRegistries
local ETWTraitsRegistry = ETWRegistries.traits

---@type EvolvingTraitsWorldSandboxVars
local SBvars = SandboxVars.EvolvingTraitsWorld

local gameMode = ETW_CommonFunctions.gameMode()

---Prints out debugs inside console if detailedDebug is enabled
---@param ... string Strings to log
local logETW = function(...)
	ETW_CommonFunctions.log(...)
end

---Function responsible for processing Bloodlust trait execution logic
---@param zombie IsoZombie
local function OnZombieDeadETW(zombie)
	local playersList = ETW_CommonFunctions.playersList()
	for i = 0, playersList:size() - 1 do
		local player = playersList:get(i)
		-- TODO: figure if there's better way to do this than checking DistTo for all players
		if player:hasTrait(ETWTraitsRegistry.BLOODLUST) and player:DistTo(zombie) <= 4 then
			local stats = player:getStats()
			local nicotineWithdrawal = stats:get(CharacterStat.NICOTINE_WITHDRAWAL) -- 0-1
			local unhappiness = stats:get(CharacterStat.UNHAPPINESS) -- 0-100
			local stress = math.max(0, stats:get(CharacterStat.STRESS) - nicotineWithdrawal) -- 0-1, may be higher with stress from cigarettes
			local panic = stats:get(CharacterStat.PANIC) -- 0-100
			stats:set(CharacterStat.UNHAPPINESS, math.max(0, unhappiness - 4 * SBvars.BloodlustMultiplier))
			stats:set(CharacterStat.STRESS, math.max(0, stress - 0.04 * SBvars.BloodlustMultiplier))
			stats:set(CharacterStat.PANIC, math.max(0, panic - 4 * SBvars.BloodlustMultiplier))
			logETW(
				"ETW Logger | OnZombieDeadETW(): Bloodlust kill. Unhappiness:"
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
			)
		end
	end
end

---Function responsible for processing Rain traits execution logic
---@param player IsoPlayer
---@param rainIntensity number
local function rainTraits(player, rainIntensity)
	local pluviophobia = player:hasTrait(ETWTraitsRegistry.PLUVIOPHOBIA)
	local pluviophile = player:hasTrait(ETWTraitsRegistry.PLUVIOPHILE)
	-- TODO: vehicle front window check, if its broken
	if (pluviophobia or pluviophile) and player:isOutside() and player:getVehicle() == nil then
		local primaryItem = player:getPrimaryHandItem()
		local secondaryItem = player:getSecondaryHandItem()
		local rainProtection = (primaryItem and primaryItem:isProtectFromRainWhileEquipped())
			or (secondaryItem and secondaryItem:isProtectFromRainWhileEquipped())
		local stats = player:getStats()
		local nicotineWithdrawal = stats:get(CharacterStat.NICOTINE_WITHDRAWAL) -- 0-1
		if pluviophobia then
			local unhappinessIncrease = 0.1 * rainIntensity * (rainProtection and 0.5 or 1) * SBvars.PluviophobiaMultiplier
			stats:set(CharacterStat.UNHAPPINESS, math.min(100, stats:get(CharacterStat.UNHAPPINESS) + unhappinessIncrease))
			local boredomIncrease = 0.02 * rainIntensity * (rainProtection and 0.5 or 1) * SBvars.PluviophobiaMultiplier
			stats:set(CharacterStat.BOREDOM, math.min(100, stats:get(CharacterStat.BOREDOM) + boredomIncrease))
			local stressIncrease = 0.04 * rainIntensity * (rainProtection and 0.5 or 1) * SBvars.PluviophobiaMultiplier
			stats:set(CharacterStat.STRESS, math.min(1, stats:get(CharacterStat.STRESS) - nicotineWithdrawal + stressIncrease))
			logETW(
				"ETW Logger | rainTraits(): unhappinessIncrease:" .. unhappinessIncrease,
				"ETW Logger | rainTraits(): boredomIncrease:" .. boredomIncrease,
				"ETW Logger | rainTraits(): stressIncrease:" .. stressIncrease
			)
		elseif pluviophile then
			local unhappinessDecrease = 0.1 * rainIntensity * (rainProtection and 0.5 or 1) * SBvars.PluviophileMultiplier
			stats:set(CharacterStat.UNHAPPINESS, math.max(0, stats:get(CharacterStat.UNHAPPINESS) - unhappinessDecrease))
			local boredomDecrease = 0.02 * rainIntensity * (rainProtection and 0.5 or 1) * SBvars.PluviophileMultiplier
			stats:set(CharacterStat.BOREDOM, math.max(0, stats:get(CharacterStat.BOREDOM) - boredomDecrease))
			local stressDecrease = 0.04 * rainIntensity * (rainProtection and 0.5 or 1) * SBvars.PluviophileMultiplier
			stats:set(CharacterStat.STRESS, math.max(0, stats:get(CharacterStat.STRESS) - nicotineWithdrawal - stressDecrease))
			logETW(
				"ETW Logger | rainTraits(): unhappinessDecrease:" .. unhappinessDecrease,
				"ETW Logger | rainTraits(): boredomDecrease:" .. boredomDecrease,
				"ETW Logger | rainTraits(): stressDecrease:" .. stressDecrease
			)
		end
	end
end

---Function responsible for processing Rain traits execution logic
---@param player IsoPlayer
---@param fogIntensity number
local function fogTraits(player, fogIntensity)
	local homichlophobia = player:hasTrait(ETWTraitsRegistry.HOMICHLOPHOBIA)
	local homichlophile = player:hasTrait(ETWTraitsRegistry.HOMICHLOPHILE)
	if (homichlophobia or homichlophile) and player:isOutside() and player:getVehicle() == nil then
		local stats = player:getStats()
		local nicotineWithdrawal = stats:get(CharacterStat.NICOTINE_WITHDRAWAL) -- 0-1
		if homichlophobia then
			local panicIncrease = 4 * fogIntensity * SBvars.HomichlophobiaMultiplier
			local resultingPanic = stats:get(CharacterStat.PANIC) + panicIncrease
			if resultingPanic <= 50 then
				stats:set(CharacterStat.PANIC,math.max(0, resultingPanic))
				logETW("ETW Logger | fogTraits(): panicIncrease:" .. panicIncrease)
			end
			local stressIncrease = 0.04 * fogIntensity * SBvars.HomichlophobiaMultiplier
			local resultingStress = math.min(1, stats:get(CharacterStat.STRESS) + stressIncrease)
			if resultingStress <= 0.5 then
				stats:set(CharacterStat.STRESS, math.min(1, resultingStress - nicotineWithdrawal))
				logETW("ETW Logger | fogTraits(): stressIncrease:" .. stressIncrease)
			end
		elseif homichlophile then
			local panicDecrease = 4 * fogIntensity * SBvars.HomichlophileMultiplier
			stats:set(CharacterStat.PANIC, math.max(0, stats:get(CharacterStat.PANIC) - panicDecrease))
			local stressDecrease = 0.04 * fogIntensity * SBvars.HomichlophileMultiplier
			stats:set(CharacterStat.STRESS, math.max(0, stats:get(CharacterStat.STRESS) - nicotineWithdrawal - stressDecrease))
			logETW("ETW Logger | fogTraits(): panicDecrease:" .. panicDecrease .. ", stressDecrease: " .. stressDecrease)
		end
	end
end

---Function responsible for processing Pain Tolerance execution logic
local function painToleranceTrait()
	local playersList = ETW_CommonFunctions.playersList()
	-- TODO: see if this can be done better? Don't like that it's calling playersList() every tick, maybe cache it?
	for i = 0, playersList:size() - 1 do
		local player = playersList:get(i)
		local painTolerance = player:hasTrait(ETWTraitsRegistry.PAIN_TOLERANCE)
		local stats = player:getStats()
		local pain = stats:get(CharacterStat.PAIN)
		if painTolerance and pain > SBvars.PainToleranceThreshold then
			stats:set(CharacterStat.PAIN, SBvars.PainToleranceThreshold)
		end
	end
end

-- TODO: check the thing again see if this can be done in other place than animEvent, maybe complete() or some shit
local original_ISPetAnimal_animEvent = ISPetAnimal.animEvent
---Decorating animEvent on petting animal to boost player mood through petting if they have the perk.
---Can't use ISPetAnimal.perform() because fuck knows why we can't, it just doesn't execute.
---@param event any
---@param parameter any
function ISPetAnimal:animEvent(event, parameter)
	-- TODO: check if running this on server-side only is enough in case of MP_Client
	if event == "pettingFinished" and gameMode ~= ETW_CommonFunctions.GameMode.MP_CLIENT then
		local player = self.character
		local modData = ETW_CommonFunctions.getETWModData(player)
		local animalsSystemModData = modData.AnimalsSystem
		local currentMinute = GameTime.getInstance():getMinutesStamp()
		if currentMinute - animalsSystemModData.LastMinuteTimestampWhenPettedWithBoost >= SBvars.PetTherapyMinutesBetweenPets then
			local animalID = self.animal:getAnimalID()
			logETW("ETW Logger | ISPetAnimal:animEvent(pettingFinished): caught, petting animal with ID " .. animalID)
			if player:hasTrait(ETWTraitsRegistry.PET_THERAPY) then
				animalsSystemModData.LastMinuteTimestampWhenPettedWithBoost = currentMinute
				local stats = player:getStats()
				local nicotineWithdrawal = stats:get(CharacterStat.NICOTINE_WITHDRAWAL) -- 0-1
				local unhappiness = stats:get(CharacterStat.UNHAPPINESS) -- 0-100
				local stress = math.max(0, stats:get(CharacterStat.STRESS) - nicotineWithdrawal) -- 0-1, may be higher with stress from cigarettes
				local panic = stats:get(CharacterStat.PANIC) -- 0-100
				local boredom = stats:get(CharacterStat.BOREDOM) -- 0-100
				local moodMultiplier = SBvars.PetTherapyMoodBoostMultiplier
				stats:set(CharacterStat.UNHAPPINESS, math.max(0, unhappiness - 1 * moodMultiplier))
				stats:set(CharacterStat.STRESS, math.max(0, stress - 0.01 * moodMultiplier))
				stats:set(CharacterStat.PANIC, math.max(0, panic - 1 * moodMultiplier))
				stats:set(CharacterStat.BOREDOM, math.max(0, boredom - 1 * moodMultiplier))
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
			elseif not player:hasTrait(ETWTraitsRegistry.PET_THERAPY) then
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
						and not ETW_CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, ETWTraitsRegistry.PET_THERAPY)
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
						or (SBvars.DelayedTraitsSystem and ETW_CommonFunctions.checkDelayedTraits(player, ETWTraitsRegistry.PET_THERAPY))
					then
						ETW_CommonFunctions.addTraitToPlayer(player, ETWTraitsRegistry.PET_THERAPY)
						ETW_CommonFunctions.displayTraitNotification(player, getText("UI_trait_PetTherapy"), true, HaloTextHelper.getColorGreen())
					end
				end
			end
		end
	end
	original_ISPetAnimal_animEvent(self)
end

---Function responsible for setting up every minute updates
local function oneMinuteUpdate()
	local climateManager = getClimateManager()
	local rainIntensity = climateManager:getRainIntensity()
	local fogIntensity = climateManager:getFogIntensity()
	if fogIntensity == 0 and rainIntensity == 0 then
		return
	end
	local playersList = ETW_CommonFunctions.playersList()
	for i = 0, playersList:size() - 1 do
		local player = playersList:get(i)
		if fogIntensity > 0 then
			rainTraits(player, rainIntensity)
		end
		if rainIntensity > 0 then
			fogTraits(player, fogIntensity)
		end
	end
end

---Function responsible for activating Pain Tolerance trait. It's global so it can be called from another file
---@param player IsoPlayer
function ETW_InitiatePainToleranceTrait(player)
	Events.OnTick.Remove(painToleranceTrait)
	if
		not getActivatedMods():contains("\\2934686936/EvolvingTraitsWorldDisablePainTolerance")
		and player:hasTrait(ETWTraitsRegistry.PAIN_TOLERANCE)
	then
		Events.OnTick.Add(painToleranceTrait)
	end
end

---Function responsible for initializing all traits logic
---@param playerIndex number
---@param player IsoPlayer
local function initializeTraitsLogic(playerIndex, player)
	Events.OnZombieDead.Remove(OnZombieDeadETW)
	Events.OnZombieDead.Add(OnZombieDeadETW)
	Events.EveryOneMinute.Remove(oneMinuteUpdate)
	Events.EveryOneMinute.Add(oneMinuteUpdate)
	Events.OnTick.Remove(painToleranceTrait)
	if
		gameMode == ETW_CommonFunctions.GameMode.MP_SERVER
		or getPlayer():hasTrait(ETWTraitsRegistry.PAIN_TOLERANCE)
	then
		Events.OnTick.Add(painToleranceTrait)
	end
	if gameMode == ETW_CommonFunctions.GameMode.MP_SERVER then
		Events.OnTick.Remove(initializeTraitsLogic)
	end
end

---Function responsible for clearing events
---@param character IsoPlayer
local function clearEventsETW(character)
	Events.OnZombieDead.Remove(OnZombieDeadETW)
	Events.EveryOneMinute.Remove(oneMinuteUpdate)
	Events.OnTick.Remove(painToleranceTrait)
	logETW("ETW Logger | System: clearEventsETW in ETWTraitsLogic.lua")
end

if gameMode == ETW_CommonFunctions.GameMode.SP then
	Events.OnCreatePlayer.Remove(initializeTraitsLogic)
	Events.OnCreatePlayer.Add(initializeTraitsLogic)
	Events.OnPlayerDeath.Remove(clearEventsETW)
	Events.OnPlayerDeath.Add(clearEventsETW)
elseif gameMode == ETW_CommonFunctions.GameMode.MP_SERVER then
	Events.OnTick.Add(initializeTraitsLogic)
end