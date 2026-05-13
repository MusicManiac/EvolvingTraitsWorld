-- Separate file for functions that are exported for use in other mods, so that they can hook into ETW systems.

local ETW_ExportedFunctions = {}
local ETW_CommonFunctions = require("ETW_CommonFunctions")

---@type EvolvingTraitsWorldSandboxVars
local SBvars = SandboxVars.EvolvingTraitsWorld

local logETW = function(...)
	ETW_CommonFunctions.log(...)
end

---Function that adds to ETW smoking addiction as if character smoked cigarette/cigare/etc
---For example, if you use custom function for smoking in your mod and you want it to count for smoking addiction, you can use this.
---@param character IsoGameCharacter
function ETW_ExportedFunctions.smokingAddictionMath(character)
	if not isServer() then
		if detailedDebug() then
			print("ETW Logger | RecipeCodeOnEat.consumeNicotine: detected smoking")
		end
		local modData = ETW_CommonFunctions.getETWModData(character)
		local smokerModData = modData.SmokeSystem -- SmokingAddiction MinutesSinceLastSmoke
		local timeSinceLastSmoke = character:getTimeSinceLastSmoke() * 60
		logETW(
			"ETW Logger | RecipeCodeOnEat.consumeNicotine: timeSinceLastSmoke:"
				.. timeSinceLastSmoke
				.. ", modData.MinutesSinceLastSmoke: "
				.. smokerModData.MinutesSinceLastSmoke
		)
		local stress = character:getStats():get(CharacterStat.STRESS) -- stress is 0-1, may be higher with stress from cigarettes
		local panic = character:getStats():get(CharacterStat.PANIC) -- 0-100
		local addictionGain = SBvars.SmokingAddictionMultiplier
			* (1 + stress)
			* (1 + panic / 100)
			* 1000
			/ (math.max(timeSinceLastSmoke, smokerModData.MinutesSinceLastSmoke) + 100)
		if SBvars.AffinitySystem and modData.StartingTraits.Smoker then
			addictionGain = addictionGain * SBvars.AffinitySystemGainMultiplier
		end
		smokerModData.SmokingAddiction = math.min(SBvars.SmokerCounter * 2, smokerModData.SmokingAddiction + addictionGain)
		logETW(
			"ETW Logger | RecipeCodeOnEat.consumeNicotine: addictionGain: "
				.. addictionGain
				.. ", modData.SmokingAddiction: "
				.. smokerModData.SmokingAddiction
		)
		smokerModData.MinutesSinceLastSmoke = 0
	end
end

return ETW_ExportedFunctions

--[=====[
Example on how you can refresh timeSinceLastSmoke for smoking addiction math if you have your own custom smoking implementation, so that it counts for addiction gain when player smokes with your custom implementation.

local ETW_ExportedFunctions
local ETW_isLoaded = getActivatedMods():contains('EvolvingTraitsWorld')
if ETW_isLoaded then
	ETW_ExportedFunctions = require "ETW_ExportedFunctions"
end

local function yourFunction()
	-- some code
	if ETW_isLoaded then
		ETW_ExportedFunctions.smokingAddictionMath(getPlayer())
	end
end

--]=====]
