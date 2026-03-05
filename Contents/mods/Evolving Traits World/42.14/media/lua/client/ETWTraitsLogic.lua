require("ETWModData")
require("ETWModOptions")
local ETWCommonFunctions = require("ETWCommonFunctions")
local ETWRegistries = require("ETWRegistry")

---@type EvolvingTraitsWorldTraitsRegistries
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
	return modOptions:getOption("EnableNotifications"):getValue()
end
---@return boolean
local delayedNotification = function()
	return modOptions:getOption("EnableDelayedNotifications"):getValue()
end
---@return boolean
local detailedDebug = function()
	return modOptions:getOption("GatherDetailedDebug"):getValue()
end

---Prints out debugs inside console if detailedDebug is enabled
---@param ... string Strings to log
local logETW = function(...)
	ETWCommonFunctions.log(...)
end

---Function responsible for processing Bloodlust trait execution logic
---@param zombie IsoZombie
local function OnZombieDeadETW(zombie)
	local player = getPlayer()
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

-- MOVE TO NEW SUBMODULE LATER

-- ---Function responsible for processing carry weight traits execution logic
-- ---@param player IsoPlayer
-- local function checkWeightLimit(player)
-- 	local maxWeightBase = 8
-- 	local strength = player:getPerkLevel(Perks.Strength)

-- 	if getActivatedMods():contains("ToadTraits") then
-- 		if player:hasTrait("packmule") then maxWeightBase = math.floor(SandboxVars.MoreTraits.WeightPackMule + strength / 5) end
-- 		if player:hasTrait("packmouse") then maxWeightBase = SandboxVars.MoreTraits.WeightPackMouse end
-- 		if not player:hasTrait("packmule") and not player:hasTrait("packmouse") then maxWeightBase = SandboxVars.MoreTraits.WeightDefault end
-- 		maxWeightBase = maxWeightBase + SandboxVars.MoreTraits.WeightGlobalMod
-- 		logETW("ETW Logger | checkWeightLimit(): [ToadTraits present] Set maxWeightBase to " .. maxWeightBase)
-- 	end

-- 	if getActivatedMods():contains("SimpleOverhaulTraitsAndOccupations") or getActivatedMods():contains("AliceSPack") then
-- 		if player:hasTrait("StrongBack") or player:hasTrait("Strongback2") or player:hasTrait("Strongback") then
-- 			maxWeightBase = maxWeightBase + 1
-- 		elseif player:hasTrait("WeakBack") then
-- 			maxWeightBase = maxWeightBase - 1
-- 		end
-- 		if player:hasTrait("Metalstrongback") or player:hasTrait("Metalstrongback2") then
-- 			maxWeightBase = maxWeightBase + 4
-- 		end
-- 		logETW("ETW Logger | checkWeightLimit(): [SOTO/AlicePack compatibility] Set maxWeightBase to " .. tostring(maxWeightBase))
-- 	end

-- 	if player:hasTrait("Hoarder") then
-- 		maxWeightBase = maxWeightBase + strength * SBvars.HoarderWeight
-- 		logETW("ETW Logger | checkWeightLimit(): Set Hoarder maxWeightBase to " .. maxWeightBase)
-- 	end

-- 	if getActivatedMods():contains("zReArmorPackBYKK") and player:getWornItem("zReExoskeleton") then
-- 		maxWeightBase = math.floor(maxWeightBase * 1.5)
-- 		logETW("ETW Logger | checkWeightLimit(): [zReArmorPackBYKK compatibility] Set maxWeightBase to " .. maxWeightBase)
-- 	end
-- 	---@cast maxWeightBase integer
-- 	player:setMaxWeightBase(maxWeightBase)
-- end

---Function responsible for processing Rain traits execution logic
---@param player IsoPlayer
---@param rainIntensity number
local function rainTraits(player, rainIntensity)
	local Pluviophobia = player:hasTrait(ETWTraitsRegistry.PLUVIOPHOBIA)
	local Pluviophile = player:hasTrait(ETWTraitsRegistry.PLUVIOPHILE)
	-- TODO: vehicle front window check, if its broken
	if rainIntensity > 0 and (Pluviophobia or Pluviophile) and player:isOutside() and player:getVehicle() == nil then
		local primaryItem = player:getPrimaryHandItem()
		local secondaryItem = player:getSecondaryHandItem()
		local rainProtection = (primaryItem and primaryItem:isProtectFromRainWhileEquipped())
			or (secondaryItem and secondaryItem:isProtectFromRainWhileEquipped())
		local stats = player:getStats()
		local nicotineWithdrawal = stats:get(CharacterStat.NICOTINE_WITHDRAWAL) -- 0-1
		if Pluviophobia then
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
		elseif Pluviophile then
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
	local Homichlophobia = player:hasTrait(ETWTraitsRegistry.HOMICHLOPHOBIA)
	local Homichlophile = player:hasTrait(ETWTraitsRegistry.HOMICHLOPHILE)
	if fogIntensity > 0 and (Homichlophobia or Homichlophile) and player:isOutside() and player:getVehicle() == nil then
		local stats = player:getStats()
		local nicotineWithdrawal = stats:get(CharacterStat.NICOTINE_WITHDRAWAL) -- 0-1
		if Homichlophobia then
			local panicIncrease = 4 * fogIntensity * SBvars.HomichlophobiaMultiplier
			local resultingPanic = stats:get(CharacterStat.PANIC) + panicIncrease
			if resultingPanic <= 50 then
				stats:setPanic(math.max(0, resultingPanic))
				logETW("ETW Logger | fogTraits(): panicIncrease:" .. panicIncrease)
			end
			local stressIncrease = 0.04 * fogIntensity * SBvars.HomichlophobiaMultiplier
			local resultingStress = math.min(1, stats:get(CharacterStat.STRESS) + stressIncrease)
			if resultingStress <= 0.5 then
				stats:set(CharacterStat.STRESS, math.min(1, resultingStress - nicotineWithdrawal))
				logETW("ETW Logger | fogTraits(): stressIncrease:" .. stressIncrease)
			end
		elseif Homichlophile then
			local panicDecrease = 4 * fogIntensity * SBvars.HomichlophileMultiplier
			stats:set(CharacterStat.PANIC, math.max(0, stats:get(CharacterStat.PANIC) - panicDecrease))
			local stressDecrease = 0.04 * fogIntensity * SBvars.HomichlophileMultiplier
			stats:set(CharacterStat.STRESS, math.max(0, stats:get(CharacterStat.STRESS) - nicotineWithdrawal - stressDecrease))
			logETW("ETW Logger | fogTraits(): panicDecrease:" .. panicDecrease .. ", stressDecrease: " .. stressDecrease)
		end
	end
end

---Function responsible for processing Pain Tolerance execution logic
local function painTolerance()
	local player = getPlayer()
	local PainTolerance = player:hasTrait("PainTolerance")
	local stats = player:getStats()
	local pain = stats:get(CharacterStat.PAIN)
	if PainTolerance and pain > SBvars.PainToleranceThreshold then
		stats:set(CharacterStat.PAIN, SBvars.PainToleranceThreshold)
	end
end

if not getActivatedMods():contains("\\2934686936/EvolvingTraitsWorldDisablePetTherapy") then
	local original_ISPetAnimal_animEvent = ISPetAnimal.animEvent
	---Decorating animEvent on petting animal to boost player mood through petting if they have the perk.
	---Can't use ISPetAnimal.perform() because fuck knows why we can't, it just doesn't execute.
	---@param event any
	---@param parameter any
	function ISPetAnimal:animEvent(event, parameter)
		if event == "pettingFinished" then
			local player = self.character
			local modData = ETWCommonFunctions.getETWModData(player)
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
					if ETWCommonFunctions.indexOf(animalsSystemModData.UniqueAnimalsPetted, animalID) == -1 then
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
							and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable(ETWTraitsRegistry.PET_THERAPY)
						then
							if delayedNotification then
								HaloTextHelper.addTextWithArrow(
									player,
									getText("UI_ETW_DelayedNotificationsStringAdd") .. getText("UI_trait_PetTherapy"),
									true,
									HaloTextHelper.getColorGreen()
								)
							end
							ETWCommonFunctions.addTraitToDelayTable(modData, ETWTraitsRegistry.PET_THERAPY, player, true)
						elseif
							not SBvars.DelayedTraitsSystem
							or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits(ETWTraitsRegistry.PET_THERAPY))
						then
							ETWCommonFunctions.addTraitToPlayer(ETWTraitsRegistry.PET_THERAPY)
							if notification then
								HaloTextHelper.addTextWithArrow(
									player,
									getText("UI_trait_PetTherapy"),
									true,
									HaloTextHelper.getColorGreen()
								)
							end
						end
					end
				end
			end
		end
		original_ISPetAnimal_animEvent(self)
	end
end
---Function responsible for setting up every minute updates
local function oneMinuteUpdate()
	local player = getPlayer()
	local climateManager = getClimateManager()
	-- if not getActivatedMods():contains("\\2934686936/EvolvingTraitsWorldDisableHoarder") then checkWeightLimit(player) end
	if not getActivatedMods():contains("\\2934686936/EvolvingTraitsWorldDisableRainTraits") then
		rainTraits(player, climateManager:getRainIntensity())
	end
	if not getActivatedMods():contains("\\2934686936/EvolvingTraitsWorldDisableFogTraits") then
		fogTraits(player, climateManager:getFogIntensity())
	end
end

---Function responsible for activating Pain Tolerance trait. It's global so it can be called from another file
---@param player IsoPlayer
function ETW_InitiatePainToleranceTrait(player)
	Events.OnTick.Remove(painTolerance)
	if
		not getActivatedMods():contains("\\2934686936/EvolvingTraitsWorldDisablePainTolerance")
		and player:hasTrait(ETWTraitsRegistry.PAIN_TOLERANCE)
	then
		Events.OnTick.Add(painTolerance)
	end
end

---Function responsible for initializing all traits logic
---@param playerIndex number
---@param player IsoPlayer
local function initializeTraitsLogic(playerIndex, player)
	modOptions = PZAPI.ModOptions:getOptions("ETWModOptions")
	Events.OnZombieDead.Remove(OnZombieDeadETW)
	Events.OnZombieDead.Add(OnZombieDeadETW)
	Events.EveryOneMinute.Remove(oneMinuteUpdate)
	Events.EveryOneMinute.Add(oneMinuteUpdate)
	Events.OnTick.Remove(painTolerance)
	if
		not getActivatedMods():contains("\\2934686936/EvolvingTraitsWorldDisablePainTolerance")
		and getPlayer():hasTrait(ETWTraitsRegistry.PAIN_TOLERANCE)
	then
		Events.OnTick.Add(painTolerance)
	end
end

---Function responsible for clearing events
---@param character IsoPlayer
local function clearEventsETW(character)
	Events.OnZombieDead.Remove(OnZombieDeadETW)
	Events.EveryOneMinute.Remove(oneMinuteUpdate)
	Events.OnTick.Remove(painTolerance)
	logETW("ETW Logger | System: clearEventsETW in ETWTraitsLogic.lua")
end

---@diagnostic disable-next-line: undefined-global
Events.EveryHours.Remove(SOcheckWeight)

Events.OnCreatePlayer.Remove(initializeTraitsLogic)
Events.OnCreatePlayer.Add(initializeTraitsLogic)
Events.OnPlayerDeath.Remove(clearEventsETW)
Events.OnPlayerDeath.Add(clearEventsETW)
