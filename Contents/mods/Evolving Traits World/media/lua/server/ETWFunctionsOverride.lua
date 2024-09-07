local ETWActionsOverride;
local ETWCommonLogicChecks;
if not isClient() and not isServer() then
	ETWActionsOverride = require "TimedActions/ETWActionsOverride";
	ETWCommonLogicChecks = require "ETWCommonLogicChecks";
end

---@type EvolvingTraitsWorldSandboxVars
local SBvars = SandboxVars.EvolvingTraitsWorld;

---@return boolean
local debug = function() return EvolvingTraitsWorld.settings.GatherDebug end;
---@return boolean
local detailedDebug = function() return EvolvingTraitsWorld.settings.GatherDetailedDebug end;

local original_OnEat_Cigarettes = OnEat_Cigarettes;
---Overwriting OnEat_Cigarettes here to insert ETW logic catching player interaction with cigarettes
---@param food any
---@param character IsoGameCharacter
---@param percent number
function OnEat_Cigarettes(food, character, percent)
	if not isServer() then
		if detailedDebug() then print("ETW Logger | OnEat_Cigarettes(): detected smoking") end;
		local modData = character:getModData().EvolvingTraitsWorld;
		local smokerModData = modData.SmokeSystem; -- SmokingAddiction MinutesSinceLastSmoke
		local timeSinceLastSmoke = character:getTimeSinceLastSmoke() * 60;
		if detailedDebug() then print("ETW Logger | OnEat_Cigarettes(): timeSinceLastSmoke: " .. timeSinceLastSmoke .. ", modData.MinutesSinceLastSmoke: " .. smokerModData.MinutesSinceLastSmoke) end;
		local stress = character:getStats():getStress(); -- stress is 0-1, may be higher with stress from cigarettes
		local panic = character:getStats():getPanic(); -- 0-100
		local addictionGain = SBvars.SmokingAddictionMultiplier * (1 + stress) * (1 + panic / 100) * 1000 / (math.max(timeSinceLastSmoke, smokerModData.MinutesSinceLastSmoke) + 100);
		if SBvars.AffinitySystem and modData.StartingTraits.Smoker then
			addictionGain = addictionGain * SBvars.AffinitySystemGainMultiplier;
		end
		smokerModData.SmokingAddiction = math.min(SBvars.SmokerCounter * 2, smokerModData.SmokingAddiction + addictionGain);
		if debug() then print("ETW Logger | OnEat_Cigarettes(): addictionGain: " .. addictionGain .. ", modData.SmokingAddiction: " .. smokerModData.SmokingAddiction) end;
		smokerModData.MinutesSinceLastSmoke = 0;
	end
	original_OnEat_Cigarettes(food, character, percent);
end

--local original_Recipe_OnCreate_RipClothing = Recipe.OnCreate.RipClothing;
-----comment
-----@param items any
-----@param result any
-----@param player IsoPlayer
-----@param selectedItem any
--function Recipe.OnCreate.RipClothing(items, result, player, selectedItem)
--	local item = items:get(0)
--	---@cast item Clothing
--	print("ETW Logger | Recipe.OnCreate.RipClothing() item: " .. item:getName());
--	if not isClient() and not isServer() then
--		ETWCommonFunctions.addClothingToUniqueRippedClothingList(player, item);
--    else
--    	print("ETW Logger | Recipe.OnCreate.RipClothing() sending command");
--		local serverArgs = { item = item };
--		sendServerCommand(player, "ETW", "addClothingToUniqueRippedClothingList", serverArgs)
--    end
--    original_Recipe_OnCreate_RipClothing(items, result, player, selectedItem);
--end
