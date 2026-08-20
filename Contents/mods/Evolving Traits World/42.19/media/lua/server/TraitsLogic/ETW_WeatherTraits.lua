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
