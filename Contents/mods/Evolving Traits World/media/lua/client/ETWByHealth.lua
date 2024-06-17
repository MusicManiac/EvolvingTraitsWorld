require "ETWModData";

local ETWCommonFunctions = require "ETWCommonFunctions";

local SBvars = SandboxVars.EvolvingTraitsWorld;

local notification = function() return EvolvingTraitsWorld.settings.EnableNotifications end
local delayedNotification = function() return EvolvingTraitsWorld.settings.EnableDelayedNotifications end
local debug = function() return EvolvingTraitsWorld.settings.GatherDebug end
local detailedDebug = function() return EvolvingTraitsWorld.settings.GatherDetailedDebug end
local noTraitsLock = function() return (SBvars.TraitsLockSystemCanGainNegative or SBvars.TraitsLockSystemCanLoseNegative or SBvars.TraitsLockSystemCanGainPositive or SBvars.TraitsLockSystemCanLosePositive) end

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
			if player:HasTrait("ProneToIllness") and modData.ColdsWeathered >= SBvars.ColdIllnessSystemColdsWeathered / 2 and SBvars.TraitsLockSystemCanLoseNegative then
				if not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("ProneToIllness")) then
					player:getTraits():remove("ProneToIllness");
					if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_pronetoillness"), false, HaloTextHelper.getColorGreen()) end
				end
				if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("ProneToIllness") then
					if delayedNotification() then HaloTextHelper.addTextWithArrow(player, getText("UI_EvolvingTraitsWorld_DelayedNotificationsStringRemove")..getText("UI_trait_pronetoillness"), true, HaloTextHelper.getColorGreen()) end
					ETWCommonFunctions.addTraitToDelayTable(modData, "ProneToIllness", player, false)
				end
			elseif not player:HasTrait("ProneToIllness") and not player:HasTrait("Resilient") and modData.ColdsWeathered >= SBvars.ColdIllnessSystemColdsWeathered and SBvars.TraitsLockSystemCanGainPositive then
				if not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("Resilient")) then
					player:getTraits():add("Resilient");
					if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_resilient"), true, HaloTextHelper.getColorGreen()) end
					Events.EveryOneMinute.Remove(coldTraits);
				end
				if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("Resilient") then
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
	if player:HasTrait("WeakStomach") and modData.FoodSicknessWeathered >= SBvars.FoodSicknessSystemCounter / 2 and SBvars.TraitsLockSystemCanLoseNegative then
		if not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("WeakStomach")) then
			player:getTraits():remove("WeakStomach");
			if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_WeakStomach"), false, HaloTextHelper.getColorGreen()) end
		end
		if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("WeakStomach") then
			if delayedNotification() then HaloTextHelper.addTextWithArrow(player, getText("UI_EvolvingTraitsWorld_DelayedNotificationsStringRemove")..getText("UI_trait_WeakStomach"), true, HaloTextHelper.getColorGreen()) end
			ETWCommonFunctions.addTraitToDelayTable(modData, "WeakStomach", player, false)
		end
	elseif not player:HasTrait("WeakStomach") and not player:HasTrait("IronGut") and modData.FoodSicknessWeathered >= SBvars.FoodSicknessSystemCounter and SBvars.TraitsLockSystemCanGainPositive then
		if not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("IronGut")) then
			player:getTraits():add("IronGut");
			if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_IronGut"), true, HaloTextHelper.getColorGreen()) end
			Events.EveryOneMinute.Remove(foodSicknessTraits);
		end
		if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("IronGut") then
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
	local modData = player:getModData().EvolvingTraitsWorld;
	local weight = player:getNutrition():getWeight();
	if weight >= 100 or weight <= 65 then
		if not player:HasTrait("SlowHealer") and startingTraits.FastHealer ~= true and SBvars.TraitsLockSystemCanGainNegative then
			player:getTraits():add("SlowHealer");
			if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_SlowHealer"), true, HaloTextHelper.getColorRed()) end
		end
		if not player:HasTrait("Thinskinned") and startingTraits.ThickSkinned ~= true and SBvars.TraitsLockSystemCanGainNegative then
			player:getTraits():add("Thinskinned");
			if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_ThinSkinned"), true, HaloTextHelper.getColorRed()) end
		end
	else
		if player:HasTrait("Thinskinned") and startingTraits.ThinSkinned ~= true and SBvars.TraitsLockSystemCanLoseNegative then
			player:getTraits():remove("Thinskinned");
			if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_ThinSkinned"), false, HaloTextHelper.getColorGreen()) end
		end
		if player:HasTrait("SlowHealer") and startingTraits.SlowHealer ~= true and SBvars.TraitsLockSystemCanLoseNegative then
			player:getTraits():remove("SlowHealer");
			if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_SlowHealer"), false, HaloTextHelper.getColorGreen()) end
		end
	end
	if (weight > 85 and weight < 100) or (weight > 65 and weight < 75) then
		if not player:HasTrait("HeartyAppitite") and startingTraits.LightEater ~= true and SBvars.TraitsLockSystemCanGainNegative then
			player:getTraits():add("HeartyAppitite");
			if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_heartyappetite"), true, HaloTextHelper.getColorRed()) end
		end
		if not player:HasTrait("HighThirst") and startingTraits.LowThirst ~= true and SBvars.TraitsLockSystemCanGainNegative then
			player:getTraits():add("HighThirst");
			if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_HighThirst"), true, HaloTextHelper.getColorRed()) end
		end
		if player:HasTrait("ThickSkinned") and startingTraits.ThickSkinned ~= true and SBvars.TraitsLockSystemCanLosePositive then
			player:getTraits():remove("ThickSkinned");
			if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_thickskinned"), false, HaloTextHelper.getColorRed()) end
		end
		if player:HasTrait("FastHealer") and startingTraits.FastHealer ~= true and SBvars.TraitsLockSystemCanLosePositive then
			player:getTraits():remove("FastHealer");
			if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_FastHealer"), false, HaloTextHelper.getColorRed()) end
		end
		if player:HasTrait("LightEater") and startingTraits.LightEater ~= true and SBvars.TraitsLockSystemCanLosePositive then
			player:getTraits():remove("LightEater");
			if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_lighteater"), false, HaloTextHelper.getColorRed()) end
		end
		if player:HasTrait("LowThirst") and startingTraits.LowThirst ~= true and SBvars.TraitsLockSystemCanLosePositive then
			player:getTraits():remove("LowThirst");
			if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_LowThirst"), false, HaloTextHelper.getColorRed()) end
		end
	end
	if weight >= 75 and weight <= 85 then
		-- losing Hearty Appetite and High Thirst if weight 75-85
		if player:HasTrait("HeartyAppitite") and startingTraits.HeartyAppetite ~= true and SBvars.TraitsLockSystemCanLoseNegative then
			player:getTraits():remove("HeartyAppitite");
			if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_heartyappetite"), false, HaloTextHelper.getColorGreen()) end
		end
		if player:HasTrait("HighThirst") and startingTraits.HighThirst ~= true and SBvars.TraitsLockSystemCanLoseNegative then
			player:getTraits():remove("HighThirst");
			if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_HighThirst"), false, HaloTextHelper.getColorGreen()) end
		end
		-- losing Thick Skinned and Fast Healer if mental state not good
		if modData.RecentAverageMental <= (SBvars.WeightSystemLowerMentalThreshold / 100) then
			if player:HasTrait("ThickSkinned") and startingTraits.ThickSkinned ~= true and SBvars.TraitsLockSystemCanLosePositive then
				player:getTraits():remove("ThickSkinned");
				if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_thickskinned"), false, HaloTextHelper.getColorRed()) end
			end
			if player:HasTrait("FastHealer") and startingTraits.FastHealer ~= true and SBvars.TraitsLockSystemCanLosePositive then
				player:getTraits():remove("FastHealer");
				if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_FastHealer"), false, HaloTextHelper.getColorRed()) end
			end
		else -- gaining Thick Skinned and Fast Healer if weight 75-85, mental is good, passive levels are good and sleep health enabled
			local passiveLevels = player:getPerkLevel(Perks.Strength) + player:getPerkLevel(Perks.Fitness);
			if sleepCheck(modData.SleepSystem.SleepHealthinessBar) and passiveLevels >= SBvars.WeightSystemSkill then
				if not player:HasTrait("ThickSkinned") and startingTraits.ThinSkinned ~= true and SBvars.TraitsLockSystemCanGainPositive then
					player:getTraits():add("ThickSkinned");
					if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_thickskinned"), true, HaloTextHelper.getColorGreen()) end
				end
				if not player:HasTrait("FastHealer") and startingTraits.SlowHealer ~= true and SBvars.TraitsLockSystemCanGainPositive then
					player:getTraits():add("FastHealer");
					if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_FastHealer"), true, HaloTextHelper.getColorGreen()) end
				end
			end
		end
		-- losing Light Eater and Low Thirst if mental is not good or if sleep is bad
		if modData.RecentAverageMental <= (SBvars.WeightSystemUpperMentalThreshold / 100) or sleepCheck(modData.SleepSystem.SleepHealthinessBar) == false then
			if player:HasTrait("LightEater") and startingTraits.LightEater ~= true and SBvars.TraitsLockSystemCanLosePositive then
				player:getTraits():remove("LightEater");
				if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_lighteater"), false, HaloTextHelper.getColorRed()) end
			end
			if player:HasTrait("LowThirst") and startingTraits.LowThirst ~= true and SBvars.TraitsLockSystemCanLosePositive then
				player:getTraits():remove("LowThirst");
				if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_LowThirst"), false, HaloTextHelper.getColorRed()) end
			end
		else
			-- gaining Light Eater and Low Thirst if mental is good, sleep is good, and weight 75-85
			if not player:HasTrait("LightEater") and startingTraits.HeartyAppetite ~= true and SBvars.TraitsLockSystemCanGainPositive then
				player:getTraits():add("LightEater");
				if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_lighteater"), true, HaloTextHelper.getColorGreen()) end
			end
			if not player:HasTrait("LowThirst") and startingTraits.HighThirst ~= true and SBvars.TraitsLockSystemCanGainPositive then
				player:getTraits():add("LowThirst");
				if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_LowThirst"), true, HaloTextHelper.getColorGreen()) end
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

local function recordMentalState()
	local player = getPlayer();
	local modData = player:getModData().EvolvingTraitsWorld;
	local stress = player:getStats():getStress(); -- 0-1
	local unhappiness = player:getBodyDamage():getUnhappynessLevel() / 100; -- 0-100 -> 0-1
	local panic = player:getStats():getPanic() / 100; -- 0-100 -> 0-1
	local fear = player:getStats():getFear(); -- 0-1
	local mentalHealth = 1 - ((stress + unhappiness + panic + fear) / 4);
	table.insert(modData.MentalStateInLast60Min, mentalHealth)
	if #modData.MentalStateInLast60Min >= 60 then
		local sum = 0;
		for i = 1, 60 do
			sum = sum + modData.MentalStateInLast60Min[i];
		end
		local average = sum / 60;
		if debug() then print("ETW Logger | recordMentalState(): average mental in last 60 min: "..average) end
		table.insert(modData.MentalStateInLast24Hours, average);
		modData.MentalStateInLast60Min = {average};
		-- last 24h mental
		if #modData.MentalStateInLast24Hours >= 24 then
			sum = 0;
			for i = 1, 24 do
				sum = sum + modData.MentalStateInLast24Hours[i];
			end
			average = sum / 24;
			if debug() then print("ETW Logger | recordMentalState(): average mental in last 24 hours: "..average) end
			table.insert(modData.MentalStateInLast31Days, average);
			modData.MentalStateInLast24Hours = {average};
			-- last days mental
			sum = 0;
			for i = 1, #modData.MentalStateInLast31Days do
				sum = sum + modData.MentalStateInLast31Days[i];
			end
			modData.RecentAverageMental = sum / #modData.MentalStateInLast31Days;
			if debug() then print("ETW Logger | recordMentalState(): average mental in last 31 days: "..average) end
			if #modData.MentalStateInLast31Days > 31 then
				table.remove(modData.MentalStateInLast31Days, 1);
			end
		end
	end
end

local function painToleranceTrait()
	local player = getPlayer();
	local modData = player:getModData().EvolvingTraitsWorld;
	modData.PainToleranceCounter = modData.PainToleranceCounter + player:getStats():getPain(); -- pain is 0-100
	if debug() then print("ETW Logger | painToleranceTrait(): pain counter: "..modData.PainToleranceCounter) end
	if modData.PainToleranceCounter >= SBvars.PainToleranceCounter then
		if not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("PainTolerance")) then
			player:getTraits():add("PainTolerance");
			if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_PainTolerance"), true, HaloTextHelper.getColorGreen()) end
			ETW_InitiatePainToleranceTrait(player);
			Events.EveryTenMinutes.Remove(painToleranceTrait);
		end
		if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("PainTolerance") then
			if delayedNotification() then HaloTextHelper.addTextWithArrow(player, getText("UI_EvolvingTraitsWorld_DelayedNotificationsStringAdd")..getText("UI_trait_PainTolerance"), true, HaloTextHelper.getColorGreen()) end
			ETWCommonFunctions.addTraitToDelayTable(modData, "PainTolerance", player, true);
		end
	end
end

local function initializeEvents(playerIndex, player)
	Events.EveryOneMinute.Remove(coldTraits);
	if SBvars.ColdIllnessSystem == true and not player:HasTrait("Resilient") and (SBvars.TraitsLockSystemCanGainPositive or SBvars.TraitsLockSystemCanLoseNegative) then
		Events.EveryOneMinute.Add(coldTraits);
	end
	Events.EveryOneMinute.Remove(foodSicknessTraits);
	if SBvars.FoodSicknessSystem == true and not player:HasTrait("IronGut") and (SBvars.TraitsLockSystemCanGainPositive or SBvars.TraitsLockSystemCanLoseNegative) then
		Events.EveryOneMinute.Add(foodSicknessTraits) ;
	end
	Events.EveryTenMinutes.Remove(weightSystem);
	if SBvars.WeightSystem == true and noTraitsLock() then
		Events.EveryTenMinutes.Add(weightSystem) ;
	end
	Events.EveryTenMinutes.Remove(painToleranceTrait);
	if SBvars.PainTolerance == true and not player:HasTrait("PainTolerance") and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("PainTolerance") and SBvars.TraitsLockSystemCanGainPositive then
		Events.EveryTenMinutes.Add(painToleranceTrait);
	end
	Events.EveryOneMinute.Remove(asthmaticTrait);
	if SBvars.Asthmatic == true and SBvars.TraitsLockSystemCanLoseNegative then Events.EveryOneMinute.Add(asthmaticTrait) end
	Events.EveryOneMinute.Remove(recordMentalState);
	Events.EveryOneMinute.Add(recordMentalState);
end

local function clearEvents(character)
	Events.EveryOneMinute.Remove(coldTraits);
	Events.EveryOneMinute.Remove(foodSicknessTraits);
	Events.EveryTenMinutes.Remove(weightSystem);
	Events.EveryOneMinute.Remove(asthmaticTrait);
	Events.EveryOneMinute.Remove(recordMentalState);
	if detailedDebug() then print("ETW Logger | System: clearEvents in ETWByHealth.lua") end
end

Events.OnCreatePlayer.Remove(initializeEvents);
Events.OnCreatePlayer.Add(initializeEvents);
Events.OnPlayerDeath.Remove(clearEvents);
Events.OnPlayerDeath.Add(clearEvents);