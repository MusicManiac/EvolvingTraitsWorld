require("TimedActions/ISEatFoodAction")

local ETW_CommonFunctions = require("ETW_CommonFunctions")
local ETW_CommonLogicChecks = require("ETW_CommonLogicChecks")
local ETW_Registry = require("ETW_Registry")

---@type EvolvingTraitsWorldSandboxVars
local SBvars = SandboxVars.EvolvingTraitsWorld

---@type EvolvingTraitsWorldTraitsRegistries
local ETWTraitsRegistry = ETW_Registry.traits
local random_instance = newrandom()

local FILENAME = "ETW_ISEatFoodActionOverrideServer.lua"
if
	not ETW_CommonFunctions.gameModeSafeguard(
		FILENAME,
		{ ETW_CommonFunctions.GameMode.SP, ETW_CommonFunctions.GameMode.MP_SERVER }
	)
then
	return
end

---@type fun(...: string)
local logETW = ETW_CommonFunctions.log

local naturalFoodTypes = {
	BEAN = true,
	BERRY = true,
	CITRUS = true,
	FRUITS = true,
	GREENS = true,
	MUSHROOM = true,
	NUT = true,
	VEGETABLE = true,
	VEGETABLES = true,
}

---Restores mental stats after a Natural Eater consumes a qualifying uncooked food portion.
---@param player IsoPlayer
---@param item Food
---@param portion number
---@param hungerValue number
local function naturalEaterTrait(player, item, portion, hungerValue)
	if not item:isUncooked() then
		return
	end
	local foodType = string.upper(item:getFoodType() or "")
	if not naturalFoodTypes[foodType] then
		return
	end
	local multiplier = math.max(0, SBvars.NaturalEaterMentalRecoveryPercentOfHunger or 50) / 100
	local maximum = math.max(0, SBvars.NaturalEaterMaximumMentalRecoveryPercent or 5) / 100
	local recovery = math.min(maximum, hungerValue * multiplier)
	if recovery <= 0 then
		return
	end

	local stats = player:getStats()
	local scaledRecovery = recovery * 100
	stats:set(CharacterStat.ANGER, math.max(0, stats:get(CharacterStat.ANGER) - recovery))
	stats:set(CharacterStat.STRESS, math.max(0, stats:get(CharacterStat.STRESS) - recovery))
	stats:set(CharacterStat.BOREDOM, math.max(0, stats:get(CharacterStat.BOREDOM) - scaledRecovery))
	stats:set(CharacterStat.PANIC, math.max(0, stats:get(CharacterStat.PANIC) - scaledRecovery))
	stats:set(CharacterStat.UNHAPPINESS, math.max(0, stats:get(CharacterStat.UNHAPPINESS) - scaledRecovery))
	logETW(
		"ETW Logger | naturalEaterTrait(): consumed "
			.. item:getFullType()
			.. " ("
			.. foodType
			.. "); portion: "
			.. portion
			.. ", hunger value: "
			.. hungerValue
			.. ", mental recovery: "
			.. recovery * 100
			.. "%"
	)
end

local original_ISEatFoodAction_getDuration = ISEatFoodAction.getDuration

---Applies the eating-speed traits after vanilla has calculated the duration so
---portion sizes, utensils, and item-specific EatTime values keep working.
---@return number
function ISEatFoodAction:getDuration()
	local duration = original_ISEatFoodAction_getDuration(self)
	if duration <= 1 then
		return duration
	end

	local item = self.item
	local isFood = item ~= nil
		and item:getCustomMenuOption() ~= getText("ContextMenu_Drink")
		and not item:hasTag(ItemTag.SMOKABLE)
	if isFood and self.character:hasTrait(ETW_Registry.traits.FAST_EATER) then
		local reduction = PZMath.clamp(SBvars.FastEaterSpeed or 25, 0, 90) / 100
		return math.max(1, duration * (1 - reduction))
	end
	if isFood and self.character:hasTrait(ETW_Registry.traits.SLOW_EATER) then
		local increase = PZMath.clamp(SBvars.SlowEaterSpeed or 25, 0, 90) / 100
		return duration * (1 + increase)
	end

	return duration
end

---Removes Slow Eater and adds Fast Eater when the Eating Speed System thresholds are reached.
---@param player IsoPlayer
---@param modData EvolvingTraitsWorldModData
local function checkEatingSpeedTraits(player, modData)
	local counter = modData.EatingSpeedSystemCounter or 0
	local target = SBvars.EatingSpeedSystemCounter or 216000
	if
		player:hasTrait(ETWTraitsRegistry.SLOW_EATER)
		and counter >= target / 2
		and SBvars.TraitsLockSystemCanLoseNegative
	then
		if
			SBvars.DelayedTraitsSystem
			and not ETW_CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, ETWTraitsRegistry.SLOW_EATER)
		then
			ETW_CommonFunctions.addTraitToDelayTable({
				modData = modData,
				trait = ETWTraitsRegistry.SLOW_EATER,
				player = player,
				positiveTrait = false,
				gainingTrait = false,
			})
		elseif
			not SBvars.DelayedTraitsSystem
			or (
				SBvars.DelayedTraitsSystem
					and ETW_CommonFunctions.checkDelayedTraits(player, ETWTraitsRegistry.SLOW_EATER)
			)
		then
			ETW_CommonFunctions.removeTraitFromPlayer({
				player = player,
				trait = ETWTraitsRegistry.SLOW_EATER,
				positiveTrait = false,
			})
		end
	elseif
		not player:hasTrait(ETWTraitsRegistry.SLOW_EATER)
		and not player:hasTrait(ETWTraitsRegistry.FAST_EATER)
		and counter >= target
		and SBvars.TraitsLockSystemCanGainPositive
	then
		if
			SBvars.DelayedTraitsSystem
			and not ETW_CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, ETWTraitsRegistry.FAST_EATER)
		then
			ETW_CommonFunctions.addTraitToDelayTable({
				modData = modData,
				trait = ETWTraitsRegistry.FAST_EATER,
				player = player,
				positiveTrait = true,
				gainingTrait = true,
			})
		elseif
			not SBvars.DelayedTraitsSystem
			or (
				SBvars.DelayedTraitsSystem
					and ETW_CommonFunctions.checkDelayedTraits(player, ETWTraitsRegistry.FAST_EATER)
			)
		then
			ETW_CommonFunctions.addTraitToPlayer({
				player = player,
				trait = ETWTraitsRegistry.FAST_EATER,
				positiveTrait = true,
			})
		end
	end
end

---Records a completed food action's base duration and checks the Slow/Fast Eater thresholds.
---@param action ISEatFoodAction
local function recordEatingTime(action)
	if action.etwEatingTimeRecorded then
		return
	end
	local item = action.item
	local isFood = item ~= nil
		and item:getCustomMenuOption() ~= getText("ContextMenu_Drink")
		and not item:hasTag(ItemTag.SMOKABLE)
	local shouldExecute = ETW_CommonLogicChecks.EatingSpeedSystemShouldExecute(action.character)
	if not shouldExecute or not isFood then
		logETW(
			"ETW Logger | ISEatFoodAction: skipped; shouldExecute = "
				.. tostring(shouldExecute)
				.. ", isFood = "
				.. tostring(isFood)
		)
		return
	end
	local baseDuration = math.max(0, tonumber(original_ISEatFoodAction_getDuration(action)) or 0)
	if baseDuration <= 0 then
		logETW("ETW Logger | ISEatFoodAction: no duration recorded; baseDuration = " .. baseDuration)
		return
	end
	action.etwEatingTimeRecorded = true
	local modData = ETW_CommonFunctions.getETWModData(action.character)
	modData.EatingSpeedSystemCounter = (modData.EatingSpeedSystemCounter or 0) + baseDuration
	logETW(
		"ETW Logger | ISEatFoodAction: recordedDuration = " .. baseDuration,
		"ETW Logger | ISEatFoodAction: modData.EatingSpeedSystemCounter = "
			.. modData.EatingSpeedSystemCounter
	)
	checkEatingSpeedTraits(action.character, modData)
end

local original_ISEatFoodAction_complete = ISEatFoodAction.complete
---Records the full duration when an eating action completes in single-player or on the server.
function ISEatFoodAction:complete()
	local item = self.item
	local portion = PZMath.clamp(tonumber(self.percentage) or 1, 0, 1)
	local naturalEaterHungerValue = item
		and instanceof(item, "Food")
		and math.max(0, -item:getHungerChange()) * portion
		or 0
	logETW("ETW Logger | ISEatFoodAction:complete(): caught")
	local originalReturn = original_ISEatFoodAction_complete(self)
	recordEatingTime(self)
	local isFood = item ~= nil
		and item:getCustomMenuOption() ~= getText("ContextMenu_Drink")
		and not item:hasTag(ItemTag.SMOKABLE)
	if
		isFood
		and instanceof(item, "Food")
		and self.character:hasTrait(ETWTraitsRegistry.NATURAL_EATER)
	then
		naturalEaterTrait(self.character, item, portion, naturalEaterHungerValue)
	end
	if isFood and self.character:hasTrait(ETWTraitsRegistry.BAD_TEETH) then
		local chance = PZMath.clamp(SBvars.BadTeethPainChance or 10, 0, 100)
		if random_instance:random(1, 100) <= chance then
			local pain = portion * math.max(0, SBvars.BadTeethMaxPain or 20)
			local head = self.character:getBodyDamage():getBodyPart(BodyPartType.Head)
			local currentPain = head:getAdditionalPain()
			local resultingPain = math.min(100, currentPain + pain)
			head:setAdditionalPain(resultingPain)
			logETW(
				"ETW Logger | ISEatFoodAction:complete(): Bad Teeth triggered; head pain: "
					.. currentPain
					.. "->"
					.. resultingPain
					.. ", portion: "
					.. portion
			)
		end
	end
	return originalReturn
end
