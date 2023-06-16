require "ETWModData";

local ETWCommonFunctions = require "ETWCommonFunctions";

local SBvars = SandboxVars.EvolvingTraitsWorld;

local notification = function() return EvolvingTraitsWorld.settings.EnableNotifications end
local delayedNotification = function() return EvolvingTraitsWorld.settings.EnableDelayedNotifications end
local debug = function() return EvolvingTraitsWorld.settings.GatherDebug end
local detailedDebug = function() return EvolvingTraitsWorld.settings.GatherDetailedDebug end

local function coldTraits()
	local player = getPlayer();
	local coldStrength = player:getBodyDamage():getColdStrength() / 100;
	local modData = player:getModData().EvolvingTraitsWorld.ColdSystem;
	if coldStrength > 0 and modData.CurrentlySick == false then modData.CurrentlySick = true end
	if modData.CurrentlySick == true then
		modData.CurrentColdCounterContribution = modData.CurrentColdCounterContribution + coldStrength / 60;
		if detailedDebug() then print("ETW Logger | coldTraits(): CurrentColdCounterContribution = "..modData.CurrentColdCounterContribution) end
		if coldStrength == 0 then
			modData.CurrentColdCounterContribution = math.min(10, modData.CurrentColdCounterContribution);
			if detailedDebug() then print("ETW Logger | coldTraits(): Healthy now, CurrentColdCounterContribution = "..modData.CurrentColdCounterContribution) end
			modData.CurrentlySick = false;
			if modData.CurrentColdCounterContribution == 10 then
				modData.ColdsWeathered = modData.ColdsWeathered + 1
				if debug() then print("ETW Logger | coldTraits(): Weathered a cold, modData.ColdsWeathered = "..modData.ColdsWeathered) end
			end
			modData.CurrentColdCounterContribution = 0;
			if player:HasTrait("ProneToIllness") and modData.ColdsWeathered >= SBvars.ColdIllnessSystemColdsWeathered / 2 then
				if not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("ProneToIllness")) then
					player:getTraits():remove("ProneToIllness");
					if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_pronetoillness"), false, HaloTextHelper.getColorGreen()) end
				end
				if SBvars.DelayedTraitsSystem then
					if delayedNotification() then HaloTextHelper.addTextWithArrow(player, getText("UI_EvolvingTraitsWorld_DelayedNotificationsStringRemove")..getText("UI_trait_pronetoillness"), true, HaloTextHelper.getColorGreen()) end
					ETWCommonFunctions.addTraitToDelayTable(modData, "ProneToIllness", player, false)
				end
			elseif not player:HasTrait("ProneToIllness") and not player:HasTrait("Resilient") and modData.ColdsWeathered >= SBvars.ColdIllnessSystemColdsWeathered then
				if not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("Resilient")) then
					player:getTraits():add("Resilient");
					if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_resilient"), true, HaloTextHelper.getColorGreen()) end
					Events.EveryOneMinute.Remove(coldTraits);
				end
				if SBvars.DelayedTraitsSystem then
					if delayedNotification() then HaloTextHelper.addTextWithArrow(player, getText("UI_EvolvingTraitsWorld_DelayedNotificationsStringAdd")..getText("UI_trait_resilient"), true, HaloTextHelper.getColorGreen()) end
					ETWCommonFunctions.addTraitToDelayTable(modData, "Resilient", player, true)
				end
			end
		end
	end
end

local function foodSicknessTraits()
	local player = getPlayer();
	local foodSicknessStrength = player:getBodyDamage():getFoodSicknessLevel() / 100;
	if detailedDebug() then print("ETW Logger | foodSicknessTraits(): foodSicknessStrength="..foodSicknessStrength) end
	local modData = player:getModData().EvolvingTraitsWorld;
	modData.FoodSicknessWeathered = modData.FoodSicknessWeathered + foodSicknessStrength;
	if player:HasTrait("WeakStomach") and modData.FoodSicknessWeathered >= SBvars.FoodSicknessSystemCounter / 2 then
		if not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("WeakStomach")) then
			player:getTraits():remove("WeakStomach");
			if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_WeakStomach"), false, HaloTextHelper.getColorGreen()) end
		end
		if SBvars.DelayedTraitsSystem then
			if delayedNotification() then HaloTextHelper.addTextWithArrow(player, getText("UI_EvolvingTraitsWorld_DelayedNotificationsStringRemove")..getText("UI_trait_WeakStomach"), true, HaloTextHelper.getColorGreen()) end
			ETWCommonFunctions.addTraitToDelayTable(modData, "WeakStomach", player, false)
		end
	elseif not player:HasTrait("WeakStomach") and not player:HasTrait("IronGut") and modData.FoodSicknessWeathered >= SBvars.FoodSicknessSystemCounter then
		if not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("IronGut")) then
			player:getTraits():add("IronGut");
			if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_IronGut"), true, HaloTextHelper.getColorGreen()) end
			Events.EveryOneMinute.Remove(foodSicknessTraits);
		end
		if SBvars.DelayedTraitsSystem then
			if delayedNotification() then HaloTextHelper.addTextWithArrow(player, getText("UI_EvolvingTraitsWorld_DelayedNotificationsStringAdd")..getText("UI_trait_IronGut"), true, HaloTextHelper.getColorGreen()) end
			ETWCommonFunctions.addTraitToDelayTable(modData, "IronGut", player, true)
		end
	end
end

local function sleepCheck(SleepHealthinessBar)
	if not getServerOptions():getBoolean("SleepNeeded") then return true end;
	if SBvars.SleepSystem == true and SleepHealthinessBar > 0 then return true end;
	if SBvars.SleepSystem == false then return true end;
	return false;
end

local function weightSystem()
	local player = getPlayer();
	local startingTraits = player:getModData().EvolvingTraitsWorld.StartingTraits;
	local modData = player:getModData().EvolvingTraitsWorld.SleepSystem;
	local weight = player:getNutrition():getWeight();
	local stress = player:getStats():getStress();
	local unhappiness = player:getBodyDamage():getUnhappynessLevel();
	if detailedDebug() then print("ETW Logger | weightSystem(): stress: "..stress.." unhappiness:"..unhappiness) end -- stress is 0-1, unhappiness is 0-100
	if weight >= 100 or weight <= 65 then
		if not player:HasTrait("SlowHealer") and startingTraits.FastHealer ~= true then
			player:getTraits():add("SlowHealer");
			if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_SlowHealer"), true, HaloTextHelper.getColorRed()) end
		end
		if not player:HasTrait("Thinskinned") and startingTraits.ThickSkinned ~= true then
			player:getTraits():add("Thinskinned");
			if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_ThinSkinned"), true, HaloTextHelper.getColorRed()) end
		end
	end
	if (weight > 85 and weight < 100) or (weight > 65 and weight < 75) then
		if not player:HasTrait("HeartyAppitite") and startingTraits.LightEater ~= true then
			player:getTraits():add("HeartyAppitite");
			if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_heartyappetite"), true, HaloTextHelper.getColorRed()) end
		end
		if not player:HasTrait("HighThirst") and startingTraits.LowThirst ~= true then
			player:getTraits():add("HighThirst");
			if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_HighThirst"), true, HaloTextHelper.getColorRed()) end
		end
		if player:HasTrait("Thinskinned") and startingTraits.ThinSkinned ~= true then
			player:getTraits():remove("Thinskinned");
			if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_ThinSkinned"), false, HaloTextHelper.getColorGreen()) end
		end
		if player:HasTrait("SlowHealer") and startingTraits.SlowHealer ~= true then
			player:getTraits():remove("SlowHealer");
			if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_SlowHealer"), false, HaloTextHelper.getColorGreen()) end
		end
		if player:HasTrait("ThickSkinned") and startingTraits.ThickSkinned ~= true then
			player:getTraits():remove("ThickSkinned");
			if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_thickskinned"), false, HaloTextHelper.getColorRed()) end
		end
		if player:HasTrait("FastHealer") and startingTraits.FastHealer ~= true then
			player:getTraits():remove("FastHealer");
			if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_FastHealer"), false, HaloTextHelper.getColorRed()) end
		end
		if player:HasTrait("LightEater") and startingTraits.LightEater ~= true then
			player:getTraits():remove("LightEater");
			if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_lighteater"), false, HaloTextHelper.getColorRed()) end
		end
		if player:HasTrait("LowThirst") and startingTraits.LowThirst ~= true then
			player:getTraits():remove("LowThirst");
			if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_LowThirst"), false, HaloTextHelper.getColorRed()) end
		end
	end
	if weight >= 75 and weight <= 85 then
		if player:HasTrait("HeartyAppitite") and startingTraits.HeartyAppetite ~= true then
			player:getTraits():remove("HeartyAppitite");
			if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_heartyappetite"), false, HaloTextHelper.getColorGreen()) end
		end
		if player:HasTrait("HighThirst") and startingTraits.HighThirst ~= true then
			player:getTraits():remove("HighThirst");
			if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_HighThirst"), false, HaloTextHelper.getColorGreen()) end
		end
		if (stress <= 0.75 and unhappiness <= 75) and sleepCheck(modData.SleepHealthinessBar) then
			if not player:HasTrait("LightEater") and startingTraits.HeartyAppetite ~= true then
				player:getTraits():add("LightEater");
				if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_lighteater"), true, HaloTextHelper.getColorGreen()) end
			end
			if not player:HasTrait("LowThirst") and startingTraits.HighThirst ~= true then
				player:getTraits():add("LowThirst");
				if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_LowThirst"), true, HaloTextHelper.getColorGreen()) end
			end
			local passiveLevels = player:getPerkLevel(Perks.Strength) + player:getPerkLevel(Perks.Fitness);
			if passiveLevels >= SBvars.WeightSystemSkill then
				if not player:HasTrait("ThickSkinned") and startingTraits.ThinSkinned ~= true then
					player:getTraits():add("ThickSkinned");
					if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_thickskinned"), true, HaloTextHelper.getColorGreen()) end
				end
				if not player:HasTrait("FastHealer") and startingTraits.SlowHealer ~= true then
					player:getTraits():add("FastHealer");
					if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_FastHealer"), true, HaloTextHelper.getColorGreen()) end
				end
			end
		else
			if player:HasTrait("LightEater") and startingTraits.LightEater ~= true then
				player:getTraits():remove("LightEater");
				if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_lighteater"), false, HaloTextHelper.getColorRed()) end
			end
			if player:HasTrait("LowThirst") and startingTraits.LowThirst ~= true then
				player:getTraits():remove("LowThirst");
				if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_LowThirst"), false, HaloTextHelper.getColorRed()) end
			end
		end
	end
end

local function asthmaticTrait()
	local player = getPlayer();
	local modData = player:getModData().EvolvingTraitsWorld;
	local running = player:isRunning();
	local sprinting = player:isSprinting();
	local smoker = player:HasTrait("Smoker");
	local asthmatic = player:HasTrait("Asthmatic");
	local outside = player:isOutside();
	local endurance = player:getStats():getEndurance(); -- 0-1
	local temperature = getClimateManager():getAirTemperatureForCharacter(player);
	local temperatureMultiplier = math.max(0, 1.01 ^ (- 7.6 * temperature) + 0.53)
	local lowerBoundary = -2 * SBvars.AsthmaticCounter;
	local upperBoundary = 2 * SBvars.AsthmaticCounter;
	if (running or sprinting) and (temperature <= 10 or smoker) then
		local counterIncrease = temperatureMultiplier * (outside and 1.2 or 1) * (smoker and 1.5 or 0.8) * (asthmatic and 1.5 or 0.8) * (sprinting and 1.5 or 1);
		counterIncrease = counterIncrease * ((SBvars.AffinitySystem and modData.StartingTraits.Asthmatic) and SBvars.AffinitySystemGainMultiplier or 1);
		modData.AsthmaticCounter = math.min(upperBoundary, modData.AsthmaticCounter + counterIncrease);
		if debug() then print("ETW Logger | asthmaticTrait(): counterIncrease: "..counterIncrease..", modData.AsthmaticCounter: "..modData.AsthmaticCounter) end
		if modData.AsthmaticCounter >= SBvars.AsthmaticCounter and not player:HasTrait("Asthmatic") then
			player:getTraits():add("Asthmatic");
			if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Asthmatic"), true, HaloTextHelper.getColorRed()) end
		elseif modData.AsthmaticCounter <= SBvars.AsthmaticCounter and player:HasTrait("Asthmatic") then
			player:getTraits():remove("Asthmatic");
			if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Asthmatic"), false, HaloTextHelper.getColorGreen()) end
		end
	end
	if not running and not sprinting and temperature >= 0 then
		local counterDecrease = (1 + player:getPerkLevel(Perks.Fitness) * 0.1) * (smoker and 0.5 or 1) * (asthmatic and 0.5 or 1) * endurance;
		counterDecrease = counterDecrease * ((SBvars.AffinitySystem and modData.StartingTraits.Asthmatic) and SBvars.AffinitySystemLoseDivider or 1);
		modData.AsthmaticCounter = math.max(lowerBoundary, modData.AsthmaticCounter - counterDecrease);
		if debug() then print("ETW Logger | asthmaticTrait(): counterDecrease: "..counterDecrease..", modData.AsthmaticCounter: "..modData.AsthmaticCounter) end
	end
end

local function initializeEvents(playerIndex, player)
	Events.EveryOneMinute.Remove(coldTraits);
	if SBvars.ColdIllnessSystem == true and not player:HasTrait("Resilient") then Events.EveryOneMinute.Add(coldTraits) end
	Events.EveryOneMinute.Remove(foodSicknessTraits);
	if SBvars.FoodSicknessSystem == true and not player:HasTrait("IronGut") then Events.EveryOneMinute.Add(foodSicknessTraits) end
	Events.EveryTenMinutes.Remove(weightSystem);
	if SBvars.WeightSystem == true then Events.EveryTenMinutes.Add(weightSystem) end
	Events.EveryOneMinute.Remove(asthmaticTrait);
	if SBvars.Asthmatic == true then Events.EveryOneMinute.Add(asthmaticTrait) end
end

local function clearEvents(character)
	Events.EveryOneMinute.Remove(coldTraits);
	Events.EveryOneMinute.Remove(foodSicknessTraits);
	Events.EveryTenMinutes.Remove(weightSystem);
	Events.EveryOneMinute.Remove(asthmaticTrait);
	if detailedDebug() then print("ETW Logger | System: clearEvents in ETWByHealth.lua") end
end

Events.OnCreatePlayer.Remove(initializeEvents);
Events.OnCreatePlayer.Add(initializeEvents);
Events.OnPlayerDeath.Add(clearEvents);