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
local notification = function () return modOptions:getOption("EnableNotifications"):getValue() end
---@return boolean
local delayedNotification = function () return modOptions:getOption("EnableDelayedNotifications"):getValue() end
---@return boolean
local detailedDebug = function () return modOptions:getOption("GatherDetailedDebug"):getValue() end

---Prints out debugs inside console if detailedDebug is enabled
---@param ... string Strings to log
local logETW = function (...) ETWCommonFunctions.log(...) end

---Function responsible for managing Immunity traits
local function immunitySystemTraits()
	local player = getPlayer();
	local bodyDamage = player:getBodyDamage();
	local coldStrength = bodyDamage:getColdStrength() / 100;
	local infectionLevel = bodyDamage:getInfectionLevel() / 100;
	local modData = ETWCommonFunctions.getETWModData(player);
	if coldStrength > 0 or infectionLevel > 0 then
		modData.ImmunitySystemCounter = modData.ImmunitySystemCounter + coldStrength +
			infectionLevel * SBvars.ImmunitySystemInfectionMultiplier;
		logETW("ETW Logger | immunitySystemTraits(): modData.ImmunitySystemCounter = " .. modData.ImmunitySystemCounter);
		if player:HasTrait("ProneToIllness") and modData.ImmunitySystemCounter >= SBvars.ImmunitySystemCounter / 2 and SBvars.TraitsLockSystemCanLoseNegative then
			if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("ProneToIllness") then
				ETWCommonFunctions.addTraitToDelayTable(modData, "ProneToIllness", player, false);
				if delayedNotification() then
					HaloTextHelper.addTextWithArrow(player,
						getText("UI_ETW_DelayedNotificationsStringRemove") .. getText("UI_trait_pronetoillness"),
						true,
						HaloTextHelper.getColorGreen()
					);
				end
			elseif not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("ProneToIllness")) then
				ETWCommonFunctions.removeTraitFromPlayer("ProneToIllness");
				if notification() then
					HaloTextHelper.addTextWithArrow(
						player,
						getText("UI_trait_pronetoillness"),
						false,
						HaloTextHelper.getColorGreen()
					);
				end
			end
		elseif not player:HasTrait("ProneToIllness") and not player:HasTrait("Resilient") and modData.ImmunitySystemCounter >= SBvars.ImmunitySystemCounter and SBvars.TraitsLockSystemCanGainPositive then
			if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("Resilient") then
				ETWCommonFunctions.addTraitToDelayTable(modData, "Resilient", player, true);
				if delayedNotification() then
					HaloTextHelper.addTextWithArrow(
						player,
						getText("UI_ETW_DelayedNotificationsStringAdd") .. getText("UI_trait_resilient"),
						true,
						HaloTextHelper.getColorGreen()
					);
				end
			elseif not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("Resilient")) then
				ETWCommonFunctions.addTraitToPlayer("Resilient");
				Events.EveryOneMinute.Remove(immunitySystemTraits);
				if notification() then
					HaloTextHelper.addTextWithArrow(
						player,
						getText("UI_trait_resilient"),
						true,
						HaloTextHelper.getColorGreen()
					);
				end
			end
		end
	end
end

---Function responsible for managing Food Sickness System traits
local function foodSicknessTraitsETW()
	local player = getPlayer();
	local foodSicknessStrength = player:getBodyDamage():getFoodSicknessLevel() / 100; -- 0-100 -> 0-1
	local normalSickness = player:getStats():getSickness();                        -- 0-1
	logETW("ETW Logger | foodSicknessTraitsETW(): foodSicknessStrength = " .. foodSicknessStrength .. ", normal sickness: " .. normalSickness);
	local modData = ETWCommonFunctions.getETWModData(player);
	modData.FoodSicknessWeathered = modData.FoodSicknessWeathered + foodSicknessStrength +
		math.max((normalSickness - foodSicknessStrength), 0) * SBvars.FoodSicknessSystemNormalSicknessMultiplier;
	if player:HasTrait("WeakStomach") and modData.FoodSicknessWeathered >= SBvars.FoodSicknessSystemCounter / 2 and SBvars.TraitsLockSystemCanLoseNegative then
		if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("WeakStomach") then
			ETWCommonFunctions.addTraitToDelayTable(modData, "WeakStomach", player, false);
			if delayedNotification() then
				HaloTextHelper.addTextWithArrow(
					player,
					getText("UI_ETW_DelayedNotificationsStringRemove") .. getText("UI_trait_WeakStomach"),
					true,
					HaloTextHelper.getColorGreen()
				);
			end
		elseif not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("WeakStomach")) then
			ETWCommonFunctions.removeTraitFromPlayer("WeakStomach");
			if notification() then
				HaloTextHelper.addTextWithArrow(
					player,
					getText("UI_trait_WeakStomach"),
					false,
					HaloTextHelper.getColorGreen()
				);
			end
		end
	elseif not player:HasTrait("WeakStomach") and not player:HasTrait("IronGut") and modData.FoodSicknessWeathered >= SBvars.FoodSicknessSystemCounter and SBvars.TraitsLockSystemCanGainPositive then
		if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("IronGut") then
			ETWCommonFunctions.addTraitToDelayTable(modData, "IronGut", player, true);
			if delayedNotification() then
				HaloTextHelper.addTextWithArrow(
					player,
					getText("UI_ETW_DelayedNotificationsStringAdd") .. getText("UI_trait_IronGut"),
					true,
					HaloTextHelper.getColorGreen()
				);
			end
		elseif not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("IronGut")) then
			ETWCommonFunctions.addTraitToPlayer("IronGut");
			Events.EveryOneMinute.Remove(foodSicknessTraitsETW);
			if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_IronGut"), true, HaloTextHelper.getColorGreen()) end
		end
	end
end

---Function responsible for checking if players sleep health is good (if applicable)
--- @param SleepHealthinessBar number
local function sleepCheck(SleepHealthinessBar)
	if not getServerOptions():getBoolean("SleepNeeded") then return true end
	if SBvars.SleepSystem == true and SleepHealthinessBar > 0 then return true end
	if SBvars.SleepSystem == false then return true end
	return false;
end

---Function responsible for managing Weight System traits
local function weightSystemETW()
	local player = getPlayer();
	local modData = ETWCommonFunctions.getETWModData(player);
	local startingTraits = modData.StartingTraits;
	local weight = player:getNutrition():getWeight();
	local notification = notification();
	if weight >= 100 or weight <= 65 then
		if not player:HasTrait("SlowHealer") and startingTraits.FastHealer ~= true and SBvars.TraitsLockSystemCanGainNegative then
			ETWCommonFunctions.addTraitToPlayer("SlowHealer");
			if notification then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_SlowHealer"), true, HaloTextHelper.getColorRed()) end
		end
		if not player:HasTrait("Thinskinned") and startingTraits.ThickSkinned ~= true and SBvars.TraitsLockSystemCanGainNegative then
			ETWCommonFunctions.addTraitToPlayer("Thinskinned");
			if notification then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_ThinSkinned"), true, HaloTextHelper.getColorRed()) end
		end
	else
		if player:HasTrait("Thinskinned") and startingTraits.ThinSkinned ~= true and SBvars.TraitsLockSystemCanLoseNegative then
			ETWCommonFunctions.removeTraitFromPlayer("Thinskinned");
			if notification then
				HaloTextHelper.addTextWithArrow(
					player,
					getText("UI_trait_ThinSkinned"),
					false,
					HaloTextHelper.getColorGreen()
				);
			end
		end
		if player:HasTrait("SlowHealer") and startingTraits.SlowHealer ~= true and SBvars.TraitsLockSystemCanLoseNegative then
			ETWCommonFunctions.removeTraitFromPlayer("SlowHealer");
			if notification then
				HaloTextHelper.addTextWithArrow(
					player, getText("UI_trait_SlowHealer"),
					false,
					HaloTextHelper.getColorGreen()
				);
			end
		end
	end
	if (weight > 85 and weight < 100) or (weight > 65 and weight < 75) then
		if not player:HasTrait("HeartyAppitite") and startingTraits.LightEater ~= true and SBvars.TraitsLockSystemCanGainNegative then
			ETWCommonFunctions.addTraitToPlayer("HeartyAppitite");
			if notification then
				HaloTextHelper.addTextWithArrow(
					player,
					getText("UI_trait_heartyappetite"),
					true,
					HaloTextHelper.getColorRed()
				);
			end
		end
		if not player:HasTrait("HighThirst") and startingTraits.LowThirst ~= true and SBvars.TraitsLockSystemCanGainNegative then
			ETWCommonFunctions.addTraitToPlayer("HighThirst");
			if notification then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_HighThirst"), true, HaloTextHelper.getColorRed()) end
		end
		if player:HasTrait("ThickSkinned") and startingTraits.ThickSkinned ~= true and SBvars.TraitsLockSystemCanLosePositive then
			ETWCommonFunctions.removeTraitFromPlayer("ThickSkinned");
			if notification then
				HaloTextHelper.addTextWithArrow(
					player,
					getText("UI_trait_thickskinned"),
					false,
					HaloTextHelper.getColorRed()
				);
			end
		end
		if player:HasTrait("FastHealer") and startingTraits.FastHealer ~= true and SBvars.TraitsLockSystemCanLosePositive then
			ETWCommonFunctions.removeTraitFromPlayer("FastHealer");
			if notification then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_FastHealer"), false, HaloTextHelper.getColorRed()) end
		end
		if player:HasTrait("LightEater") and startingTraits.LightEater ~= true and SBvars.TraitsLockSystemCanLosePositive then
			ETWCommonFunctions.removeTraitFromPlayer("LightEater");
			if notification then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_lighteater"), false, HaloTextHelper.getColorRed()) end
		end
		if player:HasTrait("LowThirst") and startingTraits.LowThirst ~= true and SBvars.TraitsLockSystemCanLosePositive then
			ETWCommonFunctions.removeTraitFromPlayer("LowThirst");
			if notification then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_LowThirst"), false, HaloTextHelper.getColorRed()) end
		end
	end
	if weight >= 75 and weight <= 85 then
		-- losing Hearty Appetite and High Thirst if weight 75-85
		if player:HasTrait("HeartyAppitite") and startingTraits.HeartyAppetite ~= true and SBvars.TraitsLockSystemCanLoseNegative then
			ETWCommonFunctions.removeTraitFromPlayer("HeartyAppitite");
			if notification then
				HaloTextHelper.addTextWithArrow(
					player,
					getText("UI_trait_heartyappetite"),
					false,
					HaloTextHelper.getColorGreen()
				);
			end
		end
		if player:HasTrait("HighThirst") and startingTraits.HighThirst ~= true and SBvars.TraitsLockSystemCanLoseNegative then
			ETWCommonFunctions.removeTraitFromPlayer("HighThirst");
			if notification then
				HaloTextHelper.addTextWithArrow(
					player,
					getText("UI_trait_HighThirst"),
					false,
					HaloTextHelper.getColorGreen()
				);
			end
		end
		-- losing Thick Skinned and Fast Healer if mental state not good
		if modData.RecentAverageMental <= (SBvars.WeightSystemLowerMentalThreshold / 100) then
			if player:HasTrait("ThickSkinned") and startingTraits.ThickSkinned ~= true and SBvars.TraitsLockSystemCanLosePositive then
				ETWCommonFunctions.removeTraitFromPlayer("ThickSkinned");
				if notification then
					HaloTextHelper.addTextWithArrow(
						player,
						getText("UI_trait_thickskinned"),
						false,
						HaloTextHelper.getColorRed()
					);
				end
			end
			if player:HasTrait("FastHealer") and startingTraits.FastHealer ~= true and SBvars.TraitsLockSystemCanLosePositive then
				ETWCommonFunctions.removeTraitFromPlayer("FastHealer");
				if notification then
					HaloTextHelper.addTextWithArrow(
						player,
						getText("UI_trait_FastHealer"),
						false,
						HaloTextHelper.getColorRed()
					);
				end
			end
		else -- gaining Thick Skinned and Fast Healer if weight 75-85, mental is good, passive levels are good and sleep health enabled
			local passiveLevels = player:getPerkLevel(Perks.Strength) + player:getPerkLevel(Perks.Fitness);
			if sleepCheck(modData.SleepSystem.SleepHealthinessBar) and passiveLevels >= SBvars.WeightSystemSkill then
				if not player:HasTrait("ThickSkinned") and startingTraits.ThinSkinned ~= true and SBvars.TraitsLockSystemCanGainPositive then
					ETWCommonFunctions.addTraitToPlayer("ThickSkinned");
					if notification then
						HaloTextHelper.addTextWithArrow(
							player,
							getText("UI_trait_thickskinned"),
							true,
							HaloTextHelper.getColorGreen()
						);
					end
				end
				if not player:HasTrait("FastHealer") and startingTraits.SlowHealer ~= true and SBvars.TraitsLockSystemCanGainPositive then
					ETWCommonFunctions.addTraitToPlayer("FastHealer");
					if notification then
						HaloTextHelper.addTextWithArrow(
							player,
							getText("UI_trait_FastHealer"),
							true,
							HaloTextHelper.getColorGreen()
						);
					end
				end
			end
		end
		-- losing Light Eater and Low Thirst if mental is not good or if sleep is bad
		if modData.RecentAverageMental <= (SBvars.WeightSystemUpperMentalThreshold / 100) or sleepCheck(modData.SleepSystem.SleepHealthinessBar) == false then
			if player:HasTrait("LightEater") and startingTraits.LightEater ~= true and SBvars.TraitsLockSystemCanLosePositive then
				ETWCommonFunctions.removeTraitFromPlayer("LightEater");
				if notification then
					HaloTextHelper.addTextWithArrow(
						player,
						getText("UI_trait_lighteater"),
						false,
						HaloTextHelper.getColorRed()
					);
				end
			end
			if player:HasTrait("LowThirst") and startingTraits.LowThirst ~= true and SBvars.TraitsLockSystemCanLosePositive then
				ETWCommonFunctions.removeTraitFromPlayer("LowThirst");
				if notification then
					HaloTextHelper.addTextWithArrow(
						player,
						getText("UI_trait_LowThirst"),
						false,
						HaloTextHelper.getColorRed()
					);
				end
			end
		else
			-- gaining Light Eater and Low Thirst if mental is good, sleep is good, and weight 75-85
			if not player:HasTrait("LightEater") and startingTraits.HeartyAppetite ~= true and SBvars.TraitsLockSystemCanGainPositive then
				ETWCommonFunctions.addTraitToPlayer("LightEater");
				if notification then
					HaloTextHelper.addTextWithArrow(player, getText("UI_trait_lighteater"), true,
						HaloTextHelper.getColorGreen())
				end
			end
			if not player:HasTrait("LowThirst") and startingTraits.HighThirst ~= true and SBvars.TraitsLockSystemCanGainPositive then
				ETWCommonFunctions.addTraitToPlayer("LowThirst");
				if notification then
					HaloTextHelper.addTextWithArrow(
						player,
						getText("UI_trait_LowThirst"),
						true,
						HaloTextHelper.getColorGreen()
					)
				end
			end
		end
	end
end

---Function responsible for managing Asthmatic trait
local function asthmaticTraitETW()
	local player = getPlayer();
	local modData = ETWCommonFunctions.getETWModData(player);
	local running = player:isRunning();
	local sprinting = player:isSprinting();
	local smoker = player:HasTrait("Smoker");
	local asthmatic = player:HasTrait("Asthmatic");
	local outside = player:isOutside();
	local endurance = player:getStats():getEndurance(); -- 0-1
	local temperature = getClimateManager():getAirTemperatureForCharacter(player);
	local temperatureMultiplier = math.max(0, 1.01 ^ (-7.6 * temperature) + 0.53);
	local lowerBoundary = -2 * SBvars.AsthmaticCounter;
	local upperBoundary = 2 * SBvars.AsthmaticCounter;
	if (running or sprinting) and (temperature <= 10 or smoker) then
		local counterDecrease = temperatureMultiplier * (outside and 1.2 or 1) * (smoker and 1.5 or 0.8) * (asthmatic and 1.5 or 0.8) *
			(sprinting and 1.5 or 1);
		counterDecrease = counterDecrease *
			((SBvars.AffinitySystem and modData.StartingTraits.Asthmatic) and SBvars.AffinitySystemGainMultiplier or 1);
		modData.AsthmaticCounter = math.max(lowerBoundary, modData.AsthmaticCounter - counterDecrease);
		logETW("ETW Logger | asthmaticTraitETW(): counterDecrease: " ..
			counterDecrease .. ", modData.AsthmaticCounter: " .. modData.AsthmaticCounter);
	end
	if not running and not sprinting and temperature >= 0 then
		local counterIncrease = (1 + player:getPerkLevel(Perks.Fitness) * 0.1) * (smoker and 0.5 or 1) * (asthmatic and 0.5 or 1) * endurance;
		counterIncrease = counterIncrease /
			((SBvars.AffinitySystem and modData.StartingTraits.Asthmatic) and SBvars.AffinitySystemLoseDivider or 1);
		modData.AsthmaticCounter = math.min(upperBoundary, modData.AsthmaticCounter + counterIncrease);
		logETW("ETW Logger | asthmaticTraitETW(): counterDecrease: " ..
			counterIncrease .. ", modData.AsthmaticCounter: " .. modData.AsthmaticCounter);
	end
	if modData.AsthmaticCounter <= -SBvars.AsthmaticCounter and not player:HasTrait("Asthmatic") and SBvars.TraitsLockSystemCanGainNegative then
		ETWCommonFunctions.addTraitToPlayer("Asthmatic");
		if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Asthmatic"), true, HaloTextHelper.getColorRed()) end
	elseif modData.AsthmaticCounter >= SBvars.AsthmaticCounter and player:HasTrait("Asthmatic") and SBvars.TraitsLockSystemCanLoseNegative then
		ETWCommonFunctions.removeTraitFromPlayer("Asthmatic");
		if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Asthmatic"), false, HaloTextHelper.getColorGreen()) end
	end
end

---Function responsible for recording players mental state into mod data
local function recordMentalStateETW()
	local player = getPlayer();
	local modData = ETWCommonFunctions.getETWModData(player);
	local stress = player:getStats():getStress();                        -- 0-1
	local unhappiness = player:getBodyDamage():getUnhappynessLevel() / 100; -- 0-100 -> 0-1
	local panic = player:getStats():getPanic() / 100;                    -- 0-100 -> 0-1
	local fear = player:getStats():getFear();                            -- 0-1
	local mentalHealth = 1 - ((stress + unhappiness + panic + fear) / 4);
	table.insert(modData.MentalStateInLast60Min, mentalHealth)
	if #modData.MentalStateInLast60Min >= 60 then
		local sum = 0;
		for i = 1, 60 do
			sum = sum + modData.MentalStateInLast60Min[i];
		end
		local average = sum / 60;
		logETW("ETW Logger | recordMentalStateETW(): average mental in last 60 min: " .. average);
		table.insert(modData.MentalStateInLast24Hours, average);
		modData.MentalStateInLast60Min = { average };
		-- last 24h mental
		if #modData.MentalStateInLast24Hours >= 24 then
			sum = 0;
			for i = 1, 24 do
				sum = sum + modData.MentalStateInLast24Hours[i];
			end
			average = sum / 24;
			logETW("ETW Logger | recordMentalStateETW(): average mental in last 24 hours: " .. average);
			table.insert(modData.MentalStateInLast31Days, average);
			modData.MentalStateInLast24Hours = { average };
			-- last days mental
			sum = 0;
			for i = 1, #modData.MentalStateInLast31Days do
				sum = sum + modData.MentalStateInLast31Days[i];
			end
			modData.RecentAverageMental = sum / #modData.MentalStateInLast31Days;
			logETW("ETW Logger | recordMentalStateETW(): average mental in last 31 days: " .. average);
			if #modData.MentalStateInLast31Days > 31 then
				table.remove(modData.MentalStateInLast31Days, 1);
			end
		end
	end
end

---Function responsible for managing Pain Tolerance trait
local function painToleranceTraitETW()
	local player = getPlayer();
	local modData = ETWCommonFunctions.getETWModData(player);
	modData.PainToleranceCounter = modData.PainToleranceCounter + player:getStats():getPain(); -- pain is 0-100
	logETW("ETW Logger | painToleranceTraitETW(): pain counter: " .. modData.PainToleranceCounter);
	if modData.PainToleranceCounter >= SBvars.PainToleranceCounter then
		if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("PainTolerance") then
			ETWCommonFunctions.addTraitToDelayTable(modData, "PainTolerance", player, true);
			if delayedNotification() then
				HaloTextHelper.addTextWithArrow(
					player,
					getText("UI_ETW_DelayedNotificationsStringAdd") .. getText("UI_trait_PainTolerance"),
					true,
					HaloTextHelper.getColorGreen()
				);
			end
		elseif not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("PainTolerance")) then
			ETWCommonFunctions.addTraitToPlayer("PainTolerance");
			ETW_InitiatePainToleranceTrait(player);
			Events.EveryTenMinutes.Remove(painToleranceTraitETW);
			if notification() then
				HaloTextHelper.addTextWithArrow(
					player,
					getText("UI_trait_PainTolerance"),
					true,
					HaloTextHelper.getColorGreen()
				);
			end
		end
	end
end

---@return boolean
local noTraitsLock = function ()
	return (
		SBvars.TraitsLockSystemCanGainNegative or
		SBvars.TraitsLockSystemCanLoseNegative or
		SBvars.TraitsLockSystemCanGainPositive or
		SBvars.TraitsLockSystemCanLosePositive
	) end

---Function responsible for setting up events
---@param playerIndex number
---@param player IsoPlayer
local function initializeEventsETW(playerIndex, player)
	modOptions = PZAPI.ModOptions:getOptions("ETWModOptions");
	Events.EveryOneMinute.Remove(immunitySystemTraits);
	if ETWCommonLogicChecks.ImmunitySystemShouldExecute() then
		Events.EveryOneMinute.Add(immunitySystemTraits);
	end
	Events.EveryOneMinute.Remove(foodSicknessTraitsETW);
	if ETWCommonLogicChecks.FoodSicknessSystemShouldExecute() then
		Events.EveryOneMinute.Add(foodSicknessTraitsETW);
	end
	Events.EveryTenMinutes.Remove(weightSystemETW);
	if SBvars.WeightSystem == true and noTraitsLock() then
		Events.EveryTenMinutes.Add(weightSystemETW);
	end
	Events.EveryTenMinutes.Remove(painToleranceTraitETW);
	if ETWCommonLogicChecks.PainToleranceShouldExecute() then
		Events.EveryTenMinutes.Add(painToleranceTraitETW);
	end
	Events.EveryOneMinute.Remove(asthmaticTraitETW);
	if ETWCommonLogicChecks.AsthmaticShouldExecute() then Events.EveryOneMinute.Add(asthmaticTraitETW) end
	Events.EveryOneMinute.Remove(recordMentalStateETW);
	Events.EveryOneMinute.Add(recordMentalStateETW);
end

---Function responsible for clearing events
---@param character IsoPlayer
local function clearEventsETW(character)
	Events.EveryOneMinute.Remove(immunitySystemTraits);
	Events.EveryOneMinute.Remove(foodSicknessTraitsETW);
	Events.EveryTenMinutes.Remove(weightSystemETW);
	Events.EveryTenMinutes.Remove(painToleranceTraitETW);
	Events.EveryOneMinute.Remove(asthmaticTraitETW);
	Events.EveryOneMinute.Remove(recordMentalStateETW);
	logETW("ETW Logger | System: clearEventsETW in ETWByHealth.lua");
end

Events.OnCreatePlayer.Remove(initializeEventsETW);
Events.OnCreatePlayer.Add(initializeEventsETW);
Events.OnPlayerDeath.Remove(clearEventsETW);
Events.OnPlayerDeath.Add(clearEventsETW);
