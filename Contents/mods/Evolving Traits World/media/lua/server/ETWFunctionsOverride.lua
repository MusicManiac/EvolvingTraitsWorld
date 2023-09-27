local SBvars = SandboxVars.EvolvingTraitsWorld;

local notification = function() return EvolvingTraitsWorld.settings.EnableNotifications end
local debug = function() return EvolvingTraitsWorld.settings.GatherDebug end
local detailedDebug = function() return EvolvingTraitsWorld.settings.GatherDetailedDebug end

local original_oneat_cigarettes = OnEat_Cigarettes;

function OnEat_Cigarettes(food, character, percent)
	if isClient() or (not isClient() and not isServer()) then
		if detailedDebug() then print("ETW Logger | OnEat_Cigarettes(): detected smoking") end
		local modData = character:getModData().EvolvingTraitsWorld;
		local smokerModData = modData.SmokeSystem; -- SmokingAddiction MinutesSinceLastSmoke
		local timeSinceLastSmoke = character:getTimeSinceLastSmoke() * 60;
		if detailedDebug() then print("ETW Logger | OnEat_Cigarettes(): timeSinceLastSmoke: "..timeSinceLastSmoke..", modData.MinutesSinceLastSmoke: "..smokerModData.MinutesSinceLastSmoke) end
		local stress = character:getStats():getStress(); -- stress is 0-1
		local panic = character:getStats():getPanic(); -- 0-100
		local addictionGain = SBvars.SmokingAddictionMultiplier * (1 + stress) * (1 + panic / 100) * 1000 / (math.max(timeSinceLastSmoke, smokerModData.MinutesSinceLastSmoke) + 100);
		if SBvars.AffinitySystem and modData.StartingTraits.Smoker then
			addictionGain = addictionGain * SBvars.AffinitySystemGainMultiplier;
		end
		smokerModData.SmokingAddiction = math.min(SBvars.SmokerCounter * 2, smokerModData.SmokingAddiction + addictionGain);
		if debug() then print("ETW Logger | OnEat_Cigarettes(): addictionGain: "..addictionGain..", modData.SmokingAddiction: "..smokerModData.SmokingAddiction) end
		smokerModData.MinutesSinceLastSmoke = 0;
	end
	original_oneat_cigarettes(food, character, percent);
end