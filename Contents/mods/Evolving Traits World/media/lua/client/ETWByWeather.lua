require "ETWModData";

local SBvars = SandboxVars.EvolvingTraitsWorld;

local notification = function() return EvolvingTraitsWorld.settings.EnableNotifications end
local debug = function() return EvolvingTraitsWorld.settings.GatherDebug end
local detailedDebug = function() return EvolvingTraitsWorld.settings.GatherDetailedDebug end
local desensitized = function(player) return player:HasTrait("Desensitized") and SBvars.BraverySystemRemovesOtherFearPerks end

local function rainTraits()
	local player = getPlayer();
	local rainIntensity = getClimateManager():getRainIntensity();
	if rainIntensity > 0 and player:isOutside() and player:getVehicle() == nil then
		local panic = player:getStats():getPanic(); -- 0-100
		local primaryItem = player:getPrimaryHandItem();
		local secondaryItem = player:getSecondaryHandItem();
		local rainProtection = (primaryItem and primaryItem:isProtectFromRainWhileEquipped()) or (secondaryItem and secondaryItem:isProtectFromRainWhileEquipped());
		local rainGain = rainIntensity * (rainProtection and 0.5 or 1);
		local modData = player:getModData().EvolvingTraitsWorld;
		local SBCounter = SBvars.RainSystemCounter
		local lowerBoundary = -SBCounter * 2;
		local upperBoundary = SBCounter * 2;
		if panic <= 25 then
			rainGain = rainGain / ((SBvars.AffinitySystem and modData.StartingTraits.Pluviophobia) and SBvars.AffinitySystemLoseDivider or 1);
			rainGain = rainGain * ((SBvars.AffinitySystem and modData.StartingTraits.Pluviophile) and SBvars.AffinitySystemGainMultiplier or 1);
			if debug() then print("ETW Logger | rainTraits(): rainTraits rainGain="..rainGain..". RainCounter=" .. modData.RainCounter) end
			modData.RainCounter = math.min(upperBoundary, modData.RainCounter + rainGain);
		else
			local rainDecrease = rainGain * panic / 100 * SBvars.RainSystemCounterMultiplier;
			rainDecrease = rainDecrease / ((SBvars.AffinitySystem and modData.StartingTraits.Pluviophile) and SBvars.AffinitySystemLoseDivider or 1);
			rainDecrease = rainDecrease * ((SBvars.AffinitySystem and modData.StartingTraits.Pluviophobia) and SBvars.AffinitySystemGainMultiplier or 1);
			if debug() then print("ETW Logger | rainTraits(): rainTraits rainDecrease="..rainDecrease..". RainCounter=" .. modData.RainCounter) end
			modData.RainCounter = math.max(lowerBoundary, modData.RainCounter - rainDecrease);
		end
		if not player:HasTrait("Pluviophobia") and modData.RainCounter <= -SBCounter and not desensitized(player) then
			player:getTraits():add("Pluviophobia");
			if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Pluviophobia"), true, HaloTextHelper.getColorRed()) end
		elseif player:HasTrait("Pluviophobia") and modData.RainCounter > -SBCounter then
			player:getTraits():remove("Pluviophobia");
			if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Pluviophobia"), false, HaloTextHelper.getColorGreen()) end
		elseif player:HasTrait("Pluviophile") and modData.RainCounter <= SBCounter then
			player:getTraits():remove("Pluviophile");
			if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Pluviophile"), false, HaloTextHelper.getColorRed()) end
		elseif not player:HasTrait("Pluviophile") and modData.RainCounter > SBCounter then
			player:getTraits():add("Pluviophile");
			if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Pluviophile"), true, HaloTextHelper.getColorGreen()) end
		end
	end
end

local function fogTraits()
	local player = getPlayer();
	local fogIntensity = getClimateManager():getFogIntensity();
	if fogIntensity > 0 and player:isOutside() and player:getVehicle() == nil then
		local modData = player:getModData().EvolvingTraitsWorld;
		local panic = player:getStats():getPanic(); -- 0-100
		local fogGain = fogIntensity * SBvars.FogSystemCounterIncreaseMultiplier;
		fogGain = fogGain / ((SBvars.AffinitySystem and modData.StartingTraits.Homichlophobia) and SBvars.AffinitySystemLoseDivider or 1);
		fogGain = fogGain * ((SBvars.AffinitySystem and modData.StartingTraits.Homichlophile) and SBvars.AffinitySystemGainMultiplier or 1);
		local fogDecrease = fogIntensity * (panic / 100) * 0.9 * SBvars.FogSystemCounterDecreaseMultiplier;
		fogDecrease = fogDecrease / ((SBvars.AffinitySystem and modData.StartingTraits.Homichlophile) and SBvars.AffinitySystemLoseDivider or 1);
		fogDecrease = fogDecrease * ((SBvars.AffinitySystem and modData.StartingTraits.Homichlophobia) and SBvars.AffinitySystemGainMultiplier or 1);
		local SBCounter = SBvars.FogSystemCounter
		local lowerBoundary = -SBCounter * 2;
		local upperBoundary = SBCounter * 2;
		local finalFogCounter = modData.FogCounter + fogGain - fogDecrease;
		finalFogCounter = math.max(finalFogCounter, lowerBoundary);
		finalFogCounter = math.min(finalFogCounter, upperBoundary);
		modData.FogCounter = finalFogCounter;
		if debug() then print("ETW Logger | fogTraits(): modData.FogCounter="..modData.FogCounter) end
		if not player:HasTrait("Homichlophobia") and modData.FogCounter <= -SBCounter and not desensitized(player) then
			player:getTraits():add("Homichlophobia");
			if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Homichlophobia"), true, HaloTextHelper.getColorRed()) end
		elseif player:HasTrait("Homichlophobia") and modData.FogCounter > -SBCounter then
			player:getTraits():remove("Homichlophobia");
			if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Homichlophobia"), false, HaloTextHelper.getColorGreen()) end
		elseif player:HasTrait("Homichlophile") and modData.FogCounter <= SBCounter then
			player:getTraits():remove("Homichlophile");
			if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Homichlophobia"), false, HaloTextHelper.getColorRed()) end
		elseif not player:HasTrait("Homichlophile") and modData.FogCounter > SBCounter then
			player:getTraits():add("Homichlophile");
			if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Homichlophobia"), true, HaloTextHelper.getColorGreen()) end
		end
	end
end

local function initializeEvents(playerIndex, player)
	local activatedMods = getActivatedMods();
	Events.EveryOneMinute.Remove(rainTraits);
	if not activatedMods:contains("EvolvingTraitsWorldDisableRainTraits") and SBvars.RainSystem == true then Events.EveryOneMinute.Add(rainTraits) end
	Events.EveryOneMinute.Remove(fogTraits);
	if not activatedMods:contains("EvolvingTraitsWorldDisableFogTraits") and SBvars.FogSystem == true then Events.EveryOneMinute.Add(fogTraits) end
end

local function clearEvents(character)
	Events.EveryOneMinute.Remove(rainTraits);
	Events.EveryOneMinute.Remove(fogTraits);
	if detailedDebug() then print("ETW Logger | System: clearEvents in ETWByWeather.lua") end
end

Events.OnCreatePlayer.Remove(initializeEvents);
Events.OnCreatePlayer.Add(initializeEvents);
Events.OnPlayerDeath.Add(clearEvents);