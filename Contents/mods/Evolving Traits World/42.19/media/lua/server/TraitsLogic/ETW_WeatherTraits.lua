local ETW_CommonFunctions = require("ETW_CommonFunctions")
local ETW_Registry = require("ETW_Registry")

local FILENAME = "ETW_WeatherTraits.lua"
if
	not ETW_CommonFunctions.gameModeSafeguard(
		FILENAME,
		{ ETW_CommonFunctions.GameMode.SP, ETW_CommonFunctions.GameMode.MP_SERVER }
	)
then
	return
end

local ETW_WeatherTraits = {}

---@type EvolvingTraitsWorldTraitsRegistries
local ETWTraitsRegistry = ETW_Registry.traits
---@type EvolvingTraitsWorldSandboxVars
local SBvars = SandboxVars.EvolvingTraitsWorld
local logETW = ETW_CommonFunctions.log

---Applies and recovers Sun Sensitivity exposure and its contribution to head pain.
---@param player IsoPlayer
---@param bodyDamage BodyDamage
---@param modData EvolvingTraitsWorldModData
---@param hasTrait boolean
function ETW_WeatherTraits.sunSensitivityTrait(player, bodyDamage, modData, hasTrait)
	local previousAppliedPain = modData.SunSensitivityAppliedPain or 0
	if not hasTrait then
		if previousAppliedPain > 0 then
			local head = bodyDamage:getBodyPart(BodyPartType.Head)
			head:setAdditionalPain(math.max(0, head:getAdditionalPain() - previousAppliedPain))
			logETW("ETW Logger | sunSensitivityTrait(): removed lingering ETW head pain")
		end
		modData.SunSensitivityExposure = nil
		modData.SunSensitivityAppliedPain = nil
		return
	end

	local exposure = modData.SunSensitivityExposure or 0
	local maximumPain = math.max(0, SBvars.SunSensitivityMaximumPain or 40)
	local exposurePerMinute = math.max(0, SBvars.SunSensitivityExposurePerMinute or 1)
	local recoveryPerMinute = math.max(0, SBvars.SunSensitivityRecoveryPerMinute or 2)
	local umbrellaMultiplier = PZMath.clamp(SBvars.SunSensitivityUmbrellaMultiplier or 0.5, 0, 1)
	local daylightStrength = PZMath.clamp(getClimateManager():getDayLightStrength(), 0, 1)
	local outside = player:isOutside()
	local exposedToDaylight = outside and daylightStrength > 0
	local primaryItem = player:getPrimaryHandItem()
	local secondaryItem = player:getSecondaryHandItem()
	local hasUmbrella = (primaryItem and primaryItem:isProtectFromRainWhileEquipped())
		or (secondaryItem and secondaryItem:isProtectFromRainWhileEquipped())

	if exposedToDaylight then
		exposure = math.min(
			maximumPain,
			exposure + exposurePerMinute * daylightStrength * (hasUmbrella and umbrellaMultiplier or 1)
		)
	elseif outside then
		exposure = math.max(0, exposure - recoveryPerMinute / 2)
	else
		exposure = math.max(0, exposure - recoveryPerMinute)
	end
	modData.SunSensitivityExposure = exposure

	local desiredPain = exposure
	if exposedToDaylight and hasUmbrella then
		desiredPain = desiredPain * umbrellaMultiplier
	elseif outside and not exposedToDaylight then
		desiredPain = desiredPain / 2
	elseif not outside then
		desiredPain = desiredPain / 4
	end
	local head = bodyDamage:getBodyPart(BodyPartType.Head)
	local currentPain = head:getAdditionalPain()
	local baselinePain = math.max(0, currentPain - previousAppliedPain)
	local resultingPain = PZMath.clamp(baselinePain + desiredPain, 0, 100)
	local appliedPain = resultingPain - baselinePain
	head:setAdditionalPain(resultingPain)
	modData.SunSensitivityAppliedPain = appliedPain
	if appliedPain ~= previousAppliedPain then
		logETW(
			"ETW Logger | sunSensitivityTrait(): exposure: "
				.. exposure
				.. ", applied head pain: "
				.. previousAppliedPain
				.. "->"
				.. appliedPain
				.. ", daylight strength: "
				.. daylightStrength
				.. ", umbrella: "
				.. tostring(hasUmbrella == true)
		)
	end
end

---@param player IsoPlayer
---@param rainIntensity number
function ETW_WeatherTraits.rainTraits(player, rainIntensity)
	local pluviophobia = player:hasTrait(ETWTraitsRegistry.PLUVIOPHOBIA)
	local pluviophile = player:hasTrait(ETWTraitsRegistry.PLUVIOPHILE)
	-- TODO: vehicle front window check, if its broken
	if (pluviophobia or pluviophile) and player:isOutside() and player:getVehicle() == nil then
		local primaryItem = player:getPrimaryHandItem()
		local secondaryItem = player:getSecondaryHandItem()
		local rainProtection = (primaryItem and primaryItem:isProtectFromRainWhileEquipped())
			or (secondaryItem and secondaryItem:isProtectFromRainWhileEquipped())
		local stats = player:getStats()
		local nicotineWithdrawal = stats:get(CharacterStat.NICOTINE_WITHDRAWAL)
		if pluviophobia then
			local unhappinessIncrease = 0.1
				* rainIntensity
				* (rainProtection and 0.5 or 1)
				* SBvars.PluviophobiaMultiplier
			stats:set(
				CharacterStat.UNHAPPINESS,
				math.min(100, stats:get(CharacterStat.UNHAPPINESS) + unhappinessIncrease)
			)
			local boredomIncrease = 0.02 * rainIntensity * (rainProtection and 0.5 or 1) * SBvars.PluviophobiaMultiplier
			stats:set(CharacterStat.BOREDOM, math.min(100, stats:get(CharacterStat.BOREDOM) + boredomIncrease))
			local stressIncrease = 0.04 * rainIntensity * (rainProtection and 0.5 or 1) * SBvars.PluviophobiaMultiplier
			stats:set(
				CharacterStat.STRESS,
				math.min(1, stats:get(CharacterStat.STRESS) - nicotineWithdrawal + stressIncrease)
			)
			logETW(
				"ETW Logger | rainTraits(): unhappinessIncrease:" .. unhappinessIncrease,
				"ETW Logger | rainTraits(): boredomIncrease:" .. boredomIncrease,
				"ETW Logger | rainTraits(): stressIncrease:" .. stressIncrease
			)
		elseif pluviophile then
			local unhappinessDecrease = 0.1
				* rainIntensity
				* (rainProtection and 0.5 or 1)
				* SBvars.PluviophileMultiplier
			stats:set(
				CharacterStat.UNHAPPINESS,
				math.max(0, stats:get(CharacterStat.UNHAPPINESS) - unhappinessDecrease)
			)
			local boredomDecrease = 0.02 * rainIntensity * (rainProtection and 0.5 or 1) * SBvars.PluviophileMultiplier
			stats:set(CharacterStat.BOREDOM, math.max(0, stats:get(CharacterStat.BOREDOM) - boredomDecrease))
			local stressDecrease = 0.04 * rainIntensity * (rainProtection and 0.5 or 1) * SBvars.PluviophileMultiplier
			stats:set(
				CharacterStat.STRESS,
				math.max(0, stats:get(CharacterStat.STRESS) - nicotineWithdrawal - stressDecrease)
			)
			logETW(
				"ETW Logger | rainTraits(): unhappinessDecrease:" .. unhappinessDecrease,
				"ETW Logger | rainTraits(): boredomDecrease:" .. boredomDecrease,
				"ETW Logger | rainTraits(): stressDecrease:" .. stressDecrease
			)
		end
	end
end

---@param player IsoPlayer
---@param fogIntensity number
function ETW_WeatherTraits.fogTraits(player, fogIntensity)
	local homichlophobia = player:hasTrait(ETWTraitsRegistry.HOMICHLOPHOBIA)
	local homichlophile = player:hasTrait(ETWTraitsRegistry.HOMICHLOPHILE)
	if (homichlophobia or homichlophile) and player:isOutside() and player:getVehicle() == nil then
		local stats = player:getStats()
		local nicotineWithdrawal = stats:get(CharacterStat.NICOTINE_WITHDRAWAL)
		if homichlophobia then
			local panicIncrease = 4 * fogIntensity * SBvars.HomichlophobiaMultiplier
			local resultingPanic = stats:get(CharacterStat.PANIC) + panicIncrease
			if resultingPanic <= 50 then
				stats:set(CharacterStat.PANIC, math.max(0, resultingPanic))
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
			stats:set(
				CharacterStat.STRESS,
				math.max(0, stats:get(CharacterStat.STRESS) - nicotineWithdrawal - stressDecrease)
			)
			logETW(
				"ETW Logger | fogTraits(): panicDecrease:" .. panicDecrease .. ", stressDecrease: " .. stressDecrease
			)
		end
	end
end

return ETW_WeatherTraits
