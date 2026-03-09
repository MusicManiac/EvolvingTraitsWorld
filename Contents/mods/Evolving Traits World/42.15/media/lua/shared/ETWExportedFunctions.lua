local ETWExportedFunctions = {}
local ETWCommonFunctions = require("ETWCommonFunctions")

---@type EvolvingTraitsWorldSandboxVars
local SBvars = SandboxVars.EvolvingTraitsWorld

local logETW = function(...)
	ETWCommonFunctions.log(...)
end

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

---Function that adds to ETW smoking addiction as if character smoked cigarette/cigare/etc
---For example, if you use custom function for smoking in your mod and you want it to count for smoking addiction, you can use this.
---@param character IsoGameCharacter
function ETWExportedFunctions.smokingAddictionMath(character)
	if not isServer() then
		modOptions = PZAPI.ModOptions:getOptions("ETWModOptions")
		if detailedDebug() then
			print("ETW Logger | OnEat_Cigarettes(): detected smoking")
		end
		local modData = ETWCommonFunctions.getETWModData(character)
		local smokerModData = modData.SmokeSystem -- SmokingAddiction MinutesSinceLastSmoke
		local timeSinceLastSmoke = character:getTimeSinceLastSmoke() * 60
		logETW(
			"ETW Logger | OnEat_Cigarettes(): timeSinceLastSmoke:"
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
			"ETW Logger | OnEat_Cigarettes(): addictionGain: "
				.. addictionGain
				.. ", modData.SmokingAddiction: "
				.. smokerModData.SmokingAddiction
		)
		smokerModData.MinutesSinceLastSmoke = 0
	end
end

return ETWExportedFunctions

--[=====[
Example on how you can refresh timeSinceLastSmoke for smoking addiction math if you have your own custom smoking implementation, so that it counts for addiction gain when player smokes with your custom implementation.

local ETWExportedFunctions
if getActivatedMods():contains('\\2914075159/EvolvingTraitsWorld') then
	local ETWExportedFunctions = require "ETWExportedFunctions"
end

local function yourFunction()
	-- some code
	if getActivatedMods():contains('\\2914075159/EvolvingTraitsWorld') then
		ETWExportedFunctions.smokingAddictionMath(getPlayer())
	end
end

--]=====]
