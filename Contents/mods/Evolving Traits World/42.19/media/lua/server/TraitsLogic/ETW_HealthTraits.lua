local ETW_CommonFunctions = require("ETW_CommonFunctions")
local ETW_Registry = require("ETW_Registry")

local FILENAME = "ETW_HealthTraits.lua"
if
	not ETW_CommonFunctions.gameModeSafeguard(
		FILENAME,
		{ ETW_CommonFunctions.GameMode.SP, ETW_CommonFunctions.GameMode.MP_SERVER }
	)
then
	return
end

local ETW_HealthTraits = {}

---@type EvolvingTraitsWorldTraitsRegistries
local ETWTraitsRegistry = ETW_Registry.traits
---@type EvolvingTraitsWorldSandboxVars
local SBvars = SandboxVars.EvolvingTraitsWorld
local logETW = ETW_CommonFunctions.log

---Caps pain for a player with Pain Tolerance.
---@param player IsoPlayer
function ETW_HealthTraits.painToleranceTrait(player)
	local stats = player:getStats()
	local pain = stats:get(CharacterStat.PAIN)
	if pain > SBvars.PainToleranceThreshold then
		stats:set(CharacterStat.PAIN, SBvars.PainToleranceThreshold)
	end
end

---Applies Anemic's additional damage to actively bleeding, unstemmed wounds.
---@param bodyDamage BodyDamage
function ETW_HealthTraits.anemicTrait(bodyDamage)
	if bodyDamage:getNumPartsBleeding() <= 0 then
		return
	end
	local damage = math.max(0, SBvars.AnemicBleedingDamage or 0.4)
	local parts = bodyDamage:getBodyParts()
	local damagedParts = 0
	local totalDamage = 0
	for i = 0, parts:size() - 1 do
		local part = parts:get(i)
		if part:bleeding() and not part:IsBleedingStemmed() then
			local partDamage = damage
			if part:getType() == BodyPartType.Head or part:getType() == BodyPartType.Neck then
				partDamage = partDamage * 2
			end
			part:ReduceHealth(partDamage)
			damagedParts = damagedParts + 1
			totalDamage = totalDamage + partDamage
		end
	end
	if damagedParts > 0 then
		logETW(
			"ETW Logger | anemicTrait(): damaged "
				.. damagedParts
				.. " bleeding parts for "
				.. totalDamage
				.. " total health"
		)
	end
end

---Restores health to actively bleeding, unstemmed wounds for Thick Blooded.
---@param bodyDamage BodyDamage
function ETW_HealthTraits.thickBloodedTrait(bodyDamage)
	if bodyDamage:getNumPartsBleeding() <= 0 then
		return
	end
	local health = math.max(0, SBvars.ThickBloodedBleedingHealthPerMinute or 0.15)
	if health == 0 then
		return
	end
	local parts = bodyDamage:getBodyParts()
	local restoredParts = 0
	local totalHealth = 0
	for i = 0, parts:size() - 1 do
		local part = parts:get(i)
		if part:bleeding() and not part:IsBleedingStemmed() then
			local partHealth = health
			if part:getType() == BodyPartType.Head or part:getType() == BodyPartType.Neck then
				partHealth = partHealth * 2
			end
			part:AddHealth(partHealth)
			restoredParts = restoredParts + 1
			totalHealth = totalHealth + partHealth
		end
	end
	if restoredParts > 0 then
		logETW(
			"ETW Logger | thickBloodedTrait(): restored "
				.. totalHealth
				.. " health across "
				.. restoredParts
				.. " bleeding parts"
		)
	end
end

---Applies Quick Rest to endurance recovered since the previous tick.
---@param player IsoPlayer
---@param modData EvolvingTraitsWorldModData
function ETW_HealthTraits.quickRestTrait(player, modData)
	local stats = player:getStats()
	local endurance = stats:get(CharacterStat.ENDURANCE)
	if (player:isSitOnGround() or player:isSittingOnFurniture())
		and endurance > modData.QuickRestLastEndurance
	then
		local multiplier = math.max(1, SBvars.QuickRestRecoveryMultiplier or 2)
		local bonus = (endurance - modData.QuickRestLastEndurance) * (multiplier - 1)
		stats:set(CharacterStat.ENDURANCE, math.min(1, endurance + bonus))
	end
	modData.QuickRestLastEndurance = stats:get(CharacterStat.ENDURANCE)
end

---Transfers endurance between Hardy's reserve and the normal endurance bar.
---@param player IsoPlayer
---@param modData EvolvingTraitsWorldModData
function ETW_HealthTraits.hardyTrait(player, modData)
	-- TODO: moodle support as a display of available endurance reserve
	if not player:hasTrait(ETWTraitsRegistry.HARDY) then
		modData.HardyReserve = nil
		return
	end
	local stats = player:getStats()
	local endurance = stats:get(CharacterStat.ENDURANCE)
	local maximumReserve = PZMath.clamp((SBvars.HardyExtraEndurancePercent or 25) / 100, 0, 1)
	local transfer = PZMath.clamp(SBvars.HardyTransferPerMinute or 0.05, 0, 1)
	modData.HardyReserve = PZMath.clamp(modData.HardyReserve or maximumReserve, 0, maximumReserve)
	if endurance < 0.85 and modData.HardyReserve > 0 then
		local amount = math.min(transfer, modData.HardyReserve, 1 - endurance)
		stats:set(CharacterStat.ENDURANCE, endurance + amount)
		modData.HardyReserve = modData.HardyReserve - amount
		logETW(
			"ETW Logger | hardyTrait(): transferred "
				.. amount
				.. " from reserve; endurance: "
				.. endurance
				.. "->"
				.. (endurance + amount)
				.. ", reserve: "
				.. modData.HardyReserve
		)
	elseif endurance >= 0.99 and modData.HardyReserve < maximumReserve then
		local amount = math.min(transfer, maximumReserve - modData.HardyReserve, endurance)
		stats:set(CharacterStat.ENDURANCE, endurance - amount)
		modData.HardyReserve = modData.HardyReserve + amount
		logETW(
			"ETW Logger | hardyTrait(): replenished reserve by "
				.. amount
				.. "; endurance: "
				.. endurance
				.. "->"
				.. (endurance - amount)
				.. ", reserve: "
				.. modData.HardyReserve
		)
	end
end

---Adjusts positive calorie gains when Ideal Weight is below or above its target range.
---@param player IsoPlayer
---@param modData EvolvingTraitsWorldModData
function ETW_HealthTraits.idealWeightTrait(player, modData)
	local nutrition = player:getNutrition()
	local calories = nutrition:getCalories()
	if player:hasTrait(ETWTraitsRegistry.IDEAL_WEIGHT) and calories > modData.IdealWeightLastCalories then
		local originalCalories = calories
		local gain = calories - modData.IdealWeightLastCalories
		local weight = nutrition:getWeight()
		local lowerWeight = SBvars.IdealWeightLowerThreshold or 78
		local upperWeight = SBvars.IdealWeightUpperThreshold or 82
		if weight <= lowerWeight then
			calories = modData.IdealWeightLastCalories + gain * math.max(0, SBvars.IdealWeightUnderMultiplier or 1.5)
		elseif weight >= upperWeight then
			calories = modData.IdealWeightLastCalories + gain * math.max(0, SBvars.IdealWeightOverMultiplier or 0.75)
		end
		nutrition:setCalories(calories)
		if calories ~= originalCalories then
			logETW(
				"ETW Logger | idealWeightTrait(): weight: "
					.. weight
					.. ", calories: "
					.. originalCalories
					.. "->"
					.. calories
			)
		end
	end
	modData.IdealWeightLastCalories = calories
end

return ETW_HealthTraits
