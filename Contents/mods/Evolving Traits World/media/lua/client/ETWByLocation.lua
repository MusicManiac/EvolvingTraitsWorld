require "ETWModData";

local SBvars = SandboxVars.EvolvingTraitsWorld;

local notification = function() return EvolvingTraitsWorld.settings.EnableNotifications end
local debug = function() return EvolvingTraitsWorld.settings.GatherDebug end
local detailedDebug = function() return EvolvingTraitsWorld.settings.GatherDetailedDebug end
local desensitized = function(player) return player:HasTrait("Desensitized") and SBvars.BraverySystemRemovesOtherFearPerks end

local function outdoorsman()
	local player = getPlayer();
	local modData = player:getModData().EvolvingTraitsWorld;
	local outdoorsmanModData = modData.OutdoorsmanSystem;
	local climateManager = getClimateManager();
	local rainIntensity = climateManager:getRainIntensity();
	local snowIntensity = climateManager:getSnowIntensity();
	local windIntensity = climateManager:getWindIntensity();
	local fogIntensity = climateManager:getFogIntensity();
	local isThunderstorm = climateManager:getIsThunderStorming();
	local baseGain = 1;
	local rainGain = 5 * rainIntensity * (player:HasTrait("Pluviophile") and 1.2 or 1) * (player:HasTrait("Pluviophobia") and 0.8 or 1) * (isThunderstorm and 3 or 1);
	local snowGain = 2 * snowIntensity;
	local windGain = 2 * windIntensity;
	local fogGain = fogIntensity * (player:HasTrait("Homichlophile") and 1.2 or 1) * (player:HasTrait("Homichlophobia") and 0.8 or 1);
	local totalGain = baseGain + (rainGain + snowGain + windGain + fogGain) * (player:HasTrait("Hiker") and 1.1 or 1);
	if player:isOutside() and player:getVehicle() == nil then
		totalGain = totalGain * ((SBvars.AffinitySystem and modData.StartingTraits.Outdoorsman) and SBvars.AffinitySystemGainMultiplier or 1);
		outdoorsmanModData.MinutesSinceOutside = math.max(0, outdoorsmanModData.MinutesSinceOutside - 3);
		outdoorsmanModData.OutdoorsmanCounter = math.min(outdoorsmanModData.OutdoorsmanCounter + totalGain, SBvars.OutdoorsmanCounter * 10);
		if debug() then print("ETW Logger | outdoorsman(): totalGain=" .. totalGain .. ". OutdoorsmanCounter=" .. outdoorsmanModData.OutdoorsmanCounter) end
		if not player:HasTrait("Outdoorsman") and outdoorsmanModData.OutdoorsmanCounter >= SBvars.OutdoorsmanCounter then
			player:getTraits():add("Outdoorsman");
			if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_outdoorsman"), true, HaloTextHelper.getColorGreen()) end
		end
	elseif outdoorsmanModData.OutdoorsmanCounter > 0 then
		local totalLose = totalGain * 0.1 * (1 + outdoorsmanModData.MinutesSinceOutside / 100) * SBvars.OutdoorsmanCounterLoseMultiplier;
		totalLose = totalLose / ((SBvars.AffinitySystem and modData.StartingTraits.Outdoorsman) and SBvars.AffinitySystemLoseDivider or 1);
		outdoorsmanModData.MinutesSinceOutside = math.min(900, outdoorsmanModData.MinutesSinceOutside + 1);
		outdoorsmanModData.OutdoorsmanCounter = math.max(0, outdoorsmanModData.OutdoorsmanCounter - totalLose);
		if debug() then print("ETW Logger | outdoorsman(): totalLose=" .. totalLose .. ". OutdoorsmanCounter=" .. outdoorsmanModData.OutdoorsmanCounter) end
		if player:HasTrait("Outdoorsman") and outdoorsmanModData.OutdoorsmanCounter <= SBvars.OutdoorsmanCounter / 2 then
			player:getTraits():remove("Outdoorsman");
			if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_outdoorsman"), false, HaloTextHelper.getColorRed()) end
		end
	end
end

local function fearOfLocations()
	local player = getPlayer();
	local modData = player:getModData().EvolvingTraitsWorld;
	local fearOfLocationsModData = modData.LocationFearSystem;
	local stress = player:getStats():getStress(); -- 0-1
	local unhappiness = player:getBodyDamage():getUnhappynessLevel(); -- 0-100
	local SBCounter = SBvars.FearOfLocationsSystemCounter;
	local upperCounterBoundary = SBCounter * 2;
	local lowerCounterBoundary = -2 * SBCounter;
	local counterDecrease = 1;
	if stress > 0 then counterDecrease = counterDecrease * (2 * stress) end
	if unhappiness > 0 then counterDecrease = counterDecrease * (2 * unhappiness / 100) end
	if counterDecrease == 1 then counterDecrease = 0 end
	counterDecrease = counterDecrease * SBvars.FearOfLocationsSystemCounterLoseMultiplier;
	if player:isOutside() then
		counterDecrease = counterDecrease * ((SBvars.AffinitySystem and modData.StartingTraits.Agoraphobic) and SBvars.AffinitySystemGainMultiplier or 1);
		local resultingCounter = fearOfLocationsModData.FearOfOutside - counterDecrease + ((SBvars.AffinitySystem and modData.StartingTraits.Agoraphobic) and 1 / SBvars.AffinitySystemLoseDivider or 1); -- +1/divider passive ticking of just being outside
		resultingCounter = math.min(upperCounterBoundary, resultingCounter);
		resultingCounter = math.max(lowerCounterBoundary, resultingCounter);
		fearOfLocationsModData.FearOfOutside = resultingCounter;
		if debug() then print("ETW Logger | fearOfLocations(): modData.FearOfOutside: " .. fearOfLocationsModData.FearOfOutside) end
		if player:HasTrait("Agoraphobic") and fearOfLocationsModData.FearOfOutside >= SBCounter then
			player:getTraits():remove("Agoraphobic");
			if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_agoraphobic"), false, HaloTextHelper.getColorGreen()) end
		end
		if not player:HasTrait("Agoraphobic") and fearOfLocationsModData.FearOfOutside <= -SBCounter and not desensitized(player) then
			player:getTraits():add("Agoraphobic");
			if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_agoraphobic"), true, HaloTextHelper.getColorRed()) end
		end
	elseif not player:isOutside() or player:getVehicle() ~= nil then
		counterDecrease = counterDecrease * ((SBvars.AffinitySystem and modData.StartingTraits.Claustrophobic) and SBvars.AffinitySystemGainMultiplier or 1);
		local resultingCounter = fearOfLocationsModData.FearOfInside - counterDecrease + ((SBvars.AffinitySystem and modData.StartingTraits.Claustrophobic) and 1 / SBvars.AffinitySystemLoseDivider or 1); -- +1/divider passive ticking of just being inside
		resultingCounter = math.min(upperCounterBoundary, resultingCounter);
		resultingCounter = math.max(lowerCounterBoundary, resultingCounter);
		fearOfLocationsModData.FearOfInside = resultingCounter;
		if debug() then print("ETW Logger | fearOfLocations(): modData.FearOfInside: " .. fearOfLocationsModData.FearOfInside) end
		if player:HasTrait("Claustophobic") and fearOfLocationsModData.FearOfInside >= SBCounter then
			player:getTraits():remove("Claustophobic");
			if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_claustro"), false, HaloTextHelper.getColorGreen()) end
		end
		if not player:HasTrait("Claustophobic") and fearOfLocationsModData.FearOfInside <= -SBCounter and not desensitized(player) then
			player:getTraits():add("Claustophobic");
			if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_claustro"), true, HaloTextHelper.getColorRed()) end
		end
	end
end

local function initializeEvents(playerIndex, player)
	Events.EveryOneMinute.Remove(outdoorsman);
	if SBvars.Outdoorsman == true then Events.EveryOneMinute.Add(outdoorsman) end
	Events.EveryOneMinute.Remove(fearOfLocations);
	if SBvars.FearOfLocationsSystem == true then Events.EveryOneMinute.Add(fearOfLocations) end
end

local function clearEvents(character)
	Events.EveryOneMinute.Remove(outdoorsman);
	Events.EveryOneMinute.Remove(fearOfLocations);
	if detailedDebug() then print("ETW Logger | System: clearEvents in ETWByLocation.lua") end
end

Events.OnCreatePlayer.Remove(initializeEvents);
Events.OnCreatePlayer.Add(initializeEvents);
Events.OnPlayerDeath.Add(clearEvents);