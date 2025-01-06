require "ETWModData";
require "ETWModOptions";
local ETWCommonFunctions = require "ETWCommonFunctions";
local ETWCommonLogicChecks = require "ETWCommonLogicChecks";

---@type EvolvingTraitsWorldSandboxVars
local SBvars = SandboxVars.EvolvingTraitsWorld;

local modOptions;

---Function responsible for setting up mod options on character load
---@param playerIndex number
---@param player IsoPlayer
local function initializeModOptions(playerIndex, player)
	modOptions = PZAPI.ModOptions:getOptions("ETWModOptions");
end

Events.OnCreatePlayer.Remove(initializeModOptions);
Events.OnCreatePlayer.Add(initializeModOptions);

---@return boolean
local notification = function() return modOptions:getOption("EnableNotifications"):getValue() end
---@return boolean
local delayedNotification = function() return modOptions:getOption("EnableDelayedNotifications"):getValue() end
---@return boolean
local detailedDebug = function() return modOptions:getOption("GatherDetailedDebug"):getValue() end

local desensitized = function(player) return player:HasTrait("Desensitized") and SBvars.BraverySystemRemovesOtherFearPerks end

---Function responsible for managing Outdoorsman trait
---@param isKill boolean
local function outdoorsman(isKill)
	local isKill = isKill or false;
	local player = getPlayer();
	local modData = ETWCommonFunctions.getETWModData(player);
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
		totalGain = totalGain * ((SBvars.AffinitySystem and modData.StartingTraits.Outdoorsman) and SBvars.AffinitySystemGainMultiplier or 1) * SBvars.OutdoorsmanCounterIncreaseMultiplier;
		outdoorsmanModData.MinutesSinceOutside = math.max(0, outdoorsmanModData.MinutesSinceOutside - 3);
		outdoorsmanModData.OutdoorsmanCounter = math.min(outdoorsmanModData.OutdoorsmanCounter + totalGain, SBvars.OutdoorsmanCounter * 2);
		if detailedDebug() then
			if isKill then print("ETW Logger | outdoorsman(): was triggered by a kill") end
			print("ETW Logger | outdoorsman(): totalGain=" .. totalGain .. ". OutdoorsmanCounter=" .. outdoorsmanModData.OutdoorsmanCounter);
		end
		if not player:HasTrait("Outdoorsman") and outdoorsmanModData.OutdoorsmanCounter >= SBvars.OutdoorsmanCounter and SBvars.TraitsLockSystemCanGainPositive then
			player:getTraits():add("Outdoorsman");
			ETWCommonFunctions.traitSound(player);
			if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_outdoorsman"), true, HaloTextHelper.getColorGreen()) end
		end
	elseif outdoorsmanModData.OutdoorsmanCounter > 0 and not isKill then
		local totalLose = totalGain * 0.1 * (1 + outdoorsmanModData.MinutesSinceOutside / 100) * SBvars.OutdoorsmanCounterDecreaseMultiplier;
		totalLose = totalLose / ((SBvars.AffinitySystem and modData.StartingTraits.Outdoorsman) and SBvars.AffinitySystemLoseDivider or 1);
		outdoorsmanModData.MinutesSinceOutside = math.min(900, outdoorsmanModData.MinutesSinceOutside + 1);
		outdoorsmanModData.OutdoorsmanCounter = math.max(SBvars.OutdoorsmanCounter * -2, outdoorsmanModData.OutdoorsmanCounter - totalLose);
		if detailedDebug() then print("ETW Logger | outdoorsman(): totalLose=" .. totalLose .. ". OutdoorsmanCounter=" .. outdoorsmanModData.OutdoorsmanCounter) end
		if player:HasTrait("Outdoorsman") and outdoorsmanModData.OutdoorsmanCounter <= -SBvars.OutdoorsmanCounter and SBvars.TraitsLockSystemCanLosePositive then
			player:getTraits():remove("Outdoorsman");
			ETWCommonFunctions.traitSound(player);
			if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_outdoorsman"), false, HaloTextHelper.getColorRed()) end
		end
	end
end

---Function responsible for managing Fear of Locations System traits
---@param isKill boolean
local function fearOfLocations(isKill)
	local isKill = isKill or false;
	local player = getPlayer();
	local modData = ETWCommonFunctions.getETWModData(player);
	local fearOfLocationsModData = modData.LocationFearSystem;
	local stress = player:getStats():getStress(); -- 0-1, may be higher with stress from cigarettes
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
		counterDecrease = counterDecrease * ((SBvars.AffinitySystem and modData.StartingTraits.Agoraphobic) and SBvars.AffinitySystemGainMultiplier or 1) * (isKill and 0.25 or 1);
		local resultingCounter = fearOfLocationsModData.FearOfOutside - counterDecrease + ((SBvars.AffinitySystem and modData.StartingTraits.Agoraphobic) and 1 / SBvars.AffinitySystemLoseDivider or 1); -- +1/divider passive ticking of just being outside
		resultingCounter = math.min(upperCounterBoundary, resultingCounter);
		resultingCounter = math.max(lowerCounterBoundary, resultingCounter);
		fearOfLocationsModData.FearOfOutside = resultingCounter;
		fearOfLocationsModData.FearOfInside = math.min(upperCounterBoundary, fearOfLocationsModData.FearOfInside + SBvars.FearOfLocationsSystemPassiveCounterDecay);
	elseif not player:isOutside() or player:getVehicle() ~= nil then
		counterDecrease = counterDecrease * ((SBvars.AffinitySystem and modData.StartingTraits.Claustrophobic) and SBvars.AffinitySystemGainMultiplier or 1) * (isKill and 0.25 or 1);
		local resultingCounter = fearOfLocationsModData.FearOfInside - counterDecrease + ((SBvars.AffinitySystem and modData.StartingTraits.Claustrophobic) and 1 / SBvars.AffinitySystemLoseDivider or 1); -- +1/divider passive ticking of just being inside
		resultingCounter = math.min(upperCounterBoundary, resultingCounter);
		resultingCounter = math.max(lowerCounterBoundary, resultingCounter);
		fearOfLocationsModData.FearOfInside = resultingCounter;
		fearOfLocationsModData.FearOfOutside = math.min(upperCounterBoundary, fearOfLocationsModData.FearOfOutside + SBvars.FearOfLocationsSystemPassiveCounterDecay);
	end
	if detailedDebug() then
		if isKill then print("ETW Logger | fearOfLocations(): was triggered by a kill") end
		print("ETW Logger | fearOfLocations(): modData.FearOfOutside: " .. fearOfLocationsModData.FearOfOutside);
		print("ETW Logger | fearOfLocations(): modData.FearOfInside: " .. fearOfLocationsModData.FearOfInside);
	end
	if not SBvars.FearOfLocationsExclusiveFears then
		if not player:HasTrait("Agoraphobic") and fearOfLocationsModData.FearOfOutside <= -SBCounter and not desensitized(player) and SBvars.TraitsLockSystemCanGainNegative then
			player:getTraits():add("Agoraphobic");
			ETWCommonFunctions.traitSound(player);
			if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_agoraphobic"), true, HaloTextHelper.getColorRed()) end
		end
		if not player:HasTrait("Claustophobic") and fearOfLocationsModData.FearOfInside <= -SBCounter and not desensitized(player) and SBvars.TraitsLockSystemCanGainNegative then
			player:getTraits():add("Claustophobic");
			ETWCommonFunctions.traitSound(player);
			if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_claustro"), true, HaloTextHelper.getColorRed()) end
		end
	elseif SBvars.TraitsLockSystemCanLoseNegative and SBvars.TraitsLockSystemCanGainNegative then
		if fearOfLocationsModData.FearOfOutside <= -SBCounter and not desensitized(player) and fearOfLocationsModData.FearOfOutside < fearOfLocationsModData.FearOfInside and not player:HasTrait("Agoraphobic") then
			player:getTraits():remove("Claustophobic");
			if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_claustro"), false, HaloTextHelper.getColorGreen()) end
			player:getTraits():add("Agoraphobic");
			ETWCommonFunctions.traitSound(player);
			if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_agoraphobic"), true, HaloTextHelper.getColorRed()) end
		end
		if fearOfLocationsModData.FearOfInside <= -SBCounter and not desensitized(player) and fearOfLocationsModData.FearOfInside < fearOfLocationsModData.FearOfOutside and not player:HasTrait("Claustophobic") then
			player:getTraits():remove("Agoraphobic");
			if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_agoraphobic"), false, HaloTextHelper.getColorGreen()) end
			player:getTraits():add("Claustophobic");
			ETWCommonFunctions.traitSound(player);
			if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_claustro"), true, HaloTextHelper.getColorRed()) end
		end
	end
	if player:HasTrait("Agoraphobic") and fearOfLocationsModData.FearOfOutside >= SBCounter and SBvars.TraitsLockSystemCanLoseNegative then
		player:getTraits():remove("Agoraphobic");
		ETWCommonFunctions.traitSound(player);
		if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_agoraphobic"), false, HaloTextHelper.getColorGreen()) end
	end
	if player:HasTrait("Claustophobic") and fearOfLocationsModData.FearOfInside >= SBCounter and SBvars.TraitsLockSystemCanLoseNegative then
		player:getTraits():remove("Claustophobic");
		ETWCommonFunctions.traitSound(player);
		if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_claustro"), false, HaloTextHelper.getColorGreen()) end
	end
end

---Helper function to fire fearOfLocations() on zombie kill
---@param zombie IsoZombie
local function outdoorsmanKill(zombie)
    local player = zombie:getAttackedBy()
	---@cast player IsoPlayer
    if not player or not instanceof(player, "IsoPlayer") or not player:isLocalPlayer() then
		return;
	else
		outdoorsman(true);
	end
end

---Helper function to fire fearOfLocations() on zombie kill
---@param zombie IsoZombie
local function fearOfLocationsKill(zombie)
    local player = zombie:getAttackedBy()
	---@cast player IsoPlayer
    if not player or not instanceof(player, "IsoPlayer") or not player:isLocalPlayer() then
		return;
	else
		fearOfLocations(true);
	end
end

---Function responsible for setting up events
---@param playerIndex number
---@param player IsoPlayer
local function initializeEventsETW(playerIndex, player)
	modOptions = PZAPI.ModOptions:getOptions("ETWModOptions");
	Events.EveryOneMinute.Remove(outdoorsman);
	Events.OnZombieDead.Remove(outdoorsmanKill);
	if ETWCommonLogicChecks.OutdoorsmanShouldExecute() then
		Events.EveryOneMinute.Add(outdoorsman)
		Events.OnZombieDead.Add(outdoorsmanKill);
	end
	Events.EveryOneMinute.Remove(fearOfLocations);
	Events.OnZombieDead.Remove(fearOfLocationsKill);
	if ETWCommonLogicChecks.FearOfLocationsSystemShouldExecute() then
		Events.EveryOneMinute.Add(fearOfLocations);
		Events.OnZombieDead.Add(fearOfLocationsKill);
	end
end

---Function responsible for clearing events
---@param character IsoPlayer
local function clearEventsETW(character)
	Events.EveryOneMinute.Remove(outdoorsman);
	Events.OnZombieDead.Remove(outdoorsmanKill);
	Events.EveryOneMinute.Remove(fearOfLocations);
	Events.OnZombieDead.Remove(fearOfLocationsKill);
	if detailedDebug() then print("ETW Logger | System: clearEventsETW in ETWByLocation.lua") end
end

Events.OnCreatePlayer.Remove(initializeEventsETW);
Events.OnCreatePlayer.Add(initializeEventsETW);
Events.OnPlayerDeath.Remove(clearEventsETW);
Events.OnPlayerDeath.Add(clearEventsETW);