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

---@param player IsoPlayer
---@return boolean
local desensitized = function(player) return player:HasTrait("Desensitized") and SBvars.BraverySystemRemovesOtherFearPerks end

---Function responsible for managing Rain System traits
---@param isKill boolean
local function rainTraits(isKill)
	local isKill = isKill or false;
	local player = getPlayer();
	local rainIntensity = getClimateManager():getRainIntensity();
	if rainIntensity > 0 and player:isOutside() and player:getVehicle() == nil then
		local panic = player:getStats():getPanic(); -- 0-100
		local primaryItem = player:getPrimaryHandItem();
		local secondaryItem = player:getSecondaryHandItem();
		local rainProtection = (primaryItem and primaryItem:isProtectFromRainWhileEquipped()) or (secondaryItem and secondaryItem:isProtectFromRainWhileEquipped());
		local modData = ETWCommonFunctions.getETWModData(player);
		local SBCounter = SBvars.RainSystemCounter
		local lowerBoundary = -SBCounter * 2;
		local upperBoundary = SBCounter * 2;
		local rainGain = rainIntensity * (rainProtection and 0.5 or 1) * SBvars.RainSystemCounterIncreaseMultiplier;
		rainGain = rainGain / ((SBvars.AffinitySystem and modData.StartingTraits.Pluviophobia) and SBvars.AffinitySystemLoseDivider or 1);
		rainGain = rainGain * ((SBvars.AffinitySystem and modData.StartingTraits.Pluviophile) and SBvars.AffinitySystemGainMultiplier or 1);
		local rainDecrease = rainGain * (panic / 100) * 0.9 * SBvars.RainSystemCounterDecreaseMultiplier * (isKill and 0.25 or 1);
		rainDecrease = rainDecrease / ((SBvars.AffinitySystem and modData.StartingTraits.Pluviophile) and SBvars.AffinitySystemLoseDivider or 1);
		rainDecrease = rainDecrease * ((SBvars.AffinitySystem and modData.StartingTraits.Pluviophobia) and SBvars.AffinitySystemGainMultiplier or 1);
		local finalRainCounter = modData.RainCounter + rainGain - rainDecrease;
		finalRainCounter = math.min(upperBoundary, finalRainCounter);
		finalRainCounter = math.max(lowerBoundary, finalRainCounter);
		modData.RainCounter = finalRainCounter;
		if detailedDebug() then
			if isKill then print("ETW Logger | rainTraits(): was triggered by a kill") end
			print("ETW Logger | rainTraits(): modData.RainCounter=" .. modData.RainCounter);
		end
		if not player:HasTrait("Pluviophobia") and modData.RainCounter <= -SBCounter and not desensitized(player) and SBvars.TraitsLockSystemCanGainNegative then
			player:getTraits():add("Pluviophobia");
			ETWCommonFunctions.traitSound(player);
			if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Pluviophobia"), true, HaloTextHelper.getColorRed()) end
		elseif player:HasTrait("Pluviophobia") and modData.RainCounter > -SBCounter and SBvars.TraitsLockSystemCanLoseNegative then
			player:getTraits():remove("Pluviophobia");
			ETWCommonFunctions.traitSound(player);
			if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Pluviophobia"), false, HaloTextHelper.getColorGreen()) end
		elseif player:HasTrait("Pluviophile") and modData.RainCounter <= SBCounter and SBvars.TraitsLockSystemCanLosePositive then
			player:getTraits():remove("Pluviophile");
			ETWCommonFunctions.traitSound(player);
			if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Pluviophile"), false, HaloTextHelper.getColorRed()) end
		elseif not player:HasTrait("Pluviophile") and modData.RainCounter > SBCounter and SBvars.TraitsLockSystemCanGainPositive then
			player:getTraits():add("Pluviophile");
			ETWCommonFunctions.traitSound(player);
			if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Pluviophile"), true, HaloTextHelper.getColorGreen()) end
		end
	end
end

---Function responsible for managing Fog system traits
---@param isKill boolean
local function fogTraits(isKill)
	local isKill = isKill or false;
	local player = getPlayer();
	local fogIntensity = getClimateManager():getFogIntensity();
	if fogIntensity > 0 and player:isOutside() and player:getVehicle() == nil then
		local modData = ETWCommonFunctions.getETWModData(player);
		local panic = player:getStats():getPanic(); -- 0-100
		local fogGain = fogIntensity * SBvars.FogSystemCounterIncreaseMultiplier;
		fogGain = fogGain / ((SBvars.AffinitySystem and modData.StartingTraits.Homichlophobia) and SBvars.AffinitySystemLoseDivider or 1);
		fogGain = fogGain * ((SBvars.AffinitySystem and modData.StartingTraits.Homichlophile) and SBvars.AffinitySystemGainMultiplier or 1);
		local fogDecrease = fogIntensity * (panic / 100) * 0.9 * SBvars.FogSystemCounterDecreaseMultiplier * (isKill and 0.25 or 1);
		fogDecrease = fogDecrease / ((SBvars.AffinitySystem and modData.StartingTraits.Homichlophile) and SBvars.AffinitySystemLoseDivider or 1);
		fogDecrease = fogDecrease * ((SBvars.AffinitySystem and modData.StartingTraits.Homichlophobia) and SBvars.AffinitySystemGainMultiplier or 1);
		local SBCounter = SBvars.FogSystemCounter
		local lowerBoundary = -SBCounter * 2;
		local upperBoundary = SBCounter * 2;
		local finalFogCounter = modData.FogCounter + fogGain - fogDecrease;
		finalFogCounter = math.max(finalFogCounter, lowerBoundary);
		finalFogCounter = math.min(finalFogCounter, upperBoundary);
		modData.FogCounter = finalFogCounter;
		if detailedDebug() then
			if isKill then print("ETW Logger | fogTraits(): was triggered by a kill") end
			print("ETW Logger | fogTraits(): modData.FogCounter=" .. modData.FogCounter);
		end
		if not player:HasTrait("Homichlophobia") and modData.FogCounter <= -SBCounter and not desensitized(player) and SBvars.TraitsLockSystemCanGainNegative then
			player:getTraits():add("Homichlophobia");
			ETWCommonFunctions.traitSound(player);
			if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Homichlophobia"), true, HaloTextHelper.getColorRed()) end
		elseif player:HasTrait("Homichlophobia") and modData.FogCounter > -SBCounter and SBvars.TraitsLockSystemCanLoseNegative then
			player:getTraits():remove("Homichlophobia");
			ETWCommonFunctions.traitSound(player);
			if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Homichlophobia"), false, HaloTextHelper.getColorGreen()) end
		elseif player:HasTrait("Homichlophile") and modData.FogCounter <= SBCounter and SBvars.TraitsLockSystemCanLosePositive then
			player:getTraits():remove("Homichlophile");
			ETWCommonFunctions.traitSound(player);
			if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Homichlophile"), false, HaloTextHelper.getColorRed()) end
		elseif not player:HasTrait("Homichlophile") and modData.FogCounter > SBCounter and SBvars.TraitsLockSystemCanGainPositive then
			player:getTraits():add("Homichlophile");
			ETWCommonFunctions.traitSound(player);
			if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Homichlophile"), true, HaloTextHelper.getColorGreen()) end
		end
	end
end

---Helper function to fire rainTraits() on zombie kill
---@param zombie IsoZombie
local function rainTraitsKill(zombie)
    local player = zombie:getAttackedBy()
	---@cast player IsoPlayer
    if not player or not instanceof(player, "IsoPlayer") or not player:isLocalPlayer() then
		return;
	else
		rainTraits(true);
	end
end

---Helper function to fire fogTraits() on zombie kill
---@param zombie IsoZombie
local function fogTraitsKill(zombie)
    local player = zombie:getAttackedBy()
	---@cast player IsoPlayer
    if not player or not instanceof(player, "IsoPlayer") or not player:isLocalPlayer() then
		return;
	else
		fogTraits(true);
	end
end

---Function responsible for setting up events
---@param playerIndex number
---@param player IsoPlayer
local function initializeEventsETW(playerIndex, player)
	modOptions = PZAPI.ModOptions:getOptions("ETWModOptions");
	Events.EveryOneMinute.Remove(rainTraits);
	Events.OnZombieDead.Remove(rainTraitsKill);
	if ETWCommonLogicChecks.RainSystemShouldExecute() then
		Events.EveryOneMinute.Add(rainTraits)
		Events.OnZombieDead.Add(rainTraitsKill);
	end
	Events.EveryOneMinute.Remove(fogTraits);
	Events.OnZombieDead.Remove(fogTraitsKill);
	if ETWCommonLogicChecks.RainSystemShouldExecute() then
		Events.EveryOneMinute.Add(fogTraits)
		Events.OnZombieDead.Add(fogTraitsKill);
	end
end

---Function responsible for clearing events
---@param character IsoPlayer
local function clearEventsETW(character)
	Events.EveryOneMinute.Remove(rainTraits);
	Events.EveryOneMinute.Remove(fogTraits);
	if detailedDebug() then print("ETW Logger | System: clearEventsETW in ETWByWeather.lua") end
end

Events.OnCreatePlayer.Remove(initializeEventsETW);
Events.OnCreatePlayer.Add(initializeEventsETW);
Events.OnPlayerDeath.Remove(clearEventsETW);
Events.OnPlayerDeath.Add(clearEventsETW);