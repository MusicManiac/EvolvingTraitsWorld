require "ETWModData";
local ETWMoodles = require "ETWMoodles";

local SBvars = SandboxVars.EvolvingTraitsWorld;

local notification = function() return EvolvingTraitsWorld.settings.EnableNotifications end
local delayedNotification = function() return EvolvingTraitsWorld.settings.EnableDelayedNotifications end
local debug = function() return EvolvingTraitsWorld.settings.GatherDebug end
local detailedDebug = function() return EvolvingTraitsWorld.settings.GatherDetailedDebug end

local function catEyes()
	local player = getPlayer();
	local nightStrength = getClimateManager():getNightStrength()
	if nightStrength > 0 then
		local playerNum = player:getPlayerNum();
		local checkedSquares = 0;
		local squaresVisible = 0;
		local darknessLevel = 0;
		local square;
		local plX, plY, plZ = player:getX(), player:getY(), player:getZ();
		local radius = 30;
		local modData = player:getModData().EvolvingTraitsWorld;
		for x = -radius, radius do
			for y = -radius, radius do
				square = getCell():getGridSquare(plX + x, plY + y, plZ);
				checkedSquares = checkedSquares + 1;
				if square and square:isCanSee(playerNum) then
					local squareDarknessLevel = nightStrength * (1 - square:getLightLevel(playerNum)) * 0.01 * (square:isInARoom() and player:isInARoom() and 2 or 1);
					squaresVisible = squaresVisible + 1;
					darknessLevel = darknessLevel + squareDarknessLevel;
					modData.CatEyesCounter = modData.CatEyesCounter + squareDarknessLevel;
				end
			end
		end
		if detailedDebug() then print("ETW Logger | catEyes(): Checked squares: "..checkedSquares..", visible squares: "..squaresVisible.." with total darkness level of "..darknessLevel) end
		if debug() then print("ETW Logger | catEyes(): CatEyesCounter: "..modData.CatEyesCounter) end
		if not player:HasTrait("NightVision") and modData.CatEyesCounter >= SBvars.CatEyesCounter then
			if not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("NightVision")) then
				player:getTraits():add("NightVision");
				if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_NightVision"), true, HaloTextHelper.getColorGreen()) end
				Events.EveryOneMinute.Remove(catEyes);
			end
			if SBvars.DelayedTraitsSystem then
				if delayedNotification() then HaloTextHelper.addTextWithArrow(player, getText("UI_EvolvingTraitsWorld_DelayedNotificationsStringAdd")..getText("UI_trait_NightVision"), true, HaloTextHelper.getColorGreen()) end
				ETWCommonFunctions.addTraitToDelayTable(modData, "NightVision", player, true)
			end
		end
	end
end

local function findMidpoint(time1, time2)
	local midPoint = 0;
	if time1 > time2 then midPoint = (time1 + time2 + 24) / 2 else midPoint = (time1 + time2) / 2 end
	if midPoint >= 24 then midPoint = midPoint - 24 end
	return midPoint
end

local function sleepSystem()
	local player = getPlayer();
	local modData = player:getModData().EvolvingTraitsWorld;
	local startingTraitsModData = modData.StartingTraits;
	local sleepModData = modData.SleepSystem;
	local timeOfDay = getGameTime():getTimeOfDay();
	local currentPreferredTargetHour = sleepModData.LastMidpoint;
	if player:isAsleep() then
		local hoursAwayFromPreferredHour = math.min(math.abs(currentPreferredTargetHour - timeOfDay), 24 - math.abs(timeOfDay - currentPreferredTargetHour));
		if sleepModData.CurrentlySleeping == false then
			sleepModData.CurrentlySleeping = true;
			sleepModData.WentToSleepAt = timeOfDay;
			if detailedDebug() then print("ETW Logger | sleepSystem(): player went to sleep at: "..sleepModData.WentToSleepAt) end
		end
		if hoursAwayFromPreferredHour <= 6 then
			local sleepHealthinessBarIncreaseMultiplier = SBvars.SleepSystemMultiplier;
			if SBvars.AffinitySystem then
				if startingTraitsModData.NeedsLessSleep then
					sleepHealthinessBarIncreaseMultiplier = sleepHealthinessBarIncreaseMultiplier * SBvars.AffinitySystemGainMultiplier;
				elseif startingTraitsModData.NeedsMoreSleep then
					sleepHealthinessBarIncreaseMultiplier = sleepHealthinessBarIncreaseMultiplier / SBvars.AffinitySystemLoseDivider;
				end
			end
			local sleepHealthinessBarIncrease = (1 / 6) * sleepHealthinessBarIncreaseMultiplier;
			sleepModData.SleepHealthinessBar = math.min(200, sleepModData.SleepHealthinessBar + sleepHealthinessBarIncrease);
		else
			local sleepHealthinessBarDecreaseMultiplier = SBvars.SleepSystemMultiplier;
			if SBvars.AffinitySystem then
				if startingTraitsModData.NeedsLessSleep then
					sleepHealthinessBarDecreaseMultiplier = sleepHealthinessBarDecreaseMultiplier / SBvars.AffinitySystemGainMultiplier;
				elseif startingTraitsModData.NeedsMoreSleep then
					sleepHealthinessBarDecreaseMultiplier = sleepHealthinessBarDecreaseMultiplier * SBvars.AffinitySystemLoseDivider;
				end
			end
			local sleepHealthinessBarDecrease = (1 / 6) * sleepHealthinessBarDecreaseMultiplier;
			sleepModData.SleepHealthinessBar = math.max(-200, sleepModData.SleepHealthinessBar - sleepHealthinessBarDecrease);
		end
		ETWMoodles.sleepHealthMoodleUpdate(player, hoursAwayFromPreferredHour, false);
	end
	if not player:isAsleep() and sleepModData.CurrentlySleeping == true then
		ETWMoodles.sleepHealthMoodleUpdate(nil, nil, true);
		sleepModData.LastMidpoint = findMidpoint(sleepModData.WentToSleepAt, timeOfDay);
		sleepModData.CurrentlySleeping = false;
		sleepModData.HoursSinceLastSleep = 0;
		if detailedDebug() then
			print("ETW Logger | sleepSystem(): SleepHealthinessBar: ".. sleepModData.SleepHealthinessBar);
			print("ETW Logger | sleepSystem(): new sleepModData.LastMidpoint: "..sleepModData.LastMidpoint..", calculated from "..sleepModData.WentToSleepAt.." and "..timeOfDay);
		end
	end
	if not player:isAsleep() then
		sleepModData.HoursSinceLastSleep = sleepModData.HoursSinceLastSleep + 1 / 6;
		if sleepModData.HoursSinceLastSleep >= 24 then
			local sleepHealthinessBarIncreaseMultiplier = SBvars.SleepSystemMultiplier;
			if SBvars.AffinitySystem then
				if startingTraitsModData.NeedsLessSleep then
					sleepHealthinessBarIncreaseMultiplier = sleepHealthinessBarIncreaseMultiplier / SBvars.AffinitySystemGainMultiplier;
				elseif startingTraitsModData.NeedsMoreSleep then
					sleepHealthinessBarIncreaseMultiplier = sleepHealthinessBarIncreaseMultiplier * SBvars.AffinitySystemLoseDivider;
				end
			end
			sleepModData.SleepHealthinessBar = math.max(-200, sleepModData.SleepHealthinessBar - (1 / 6) * SBvars.SleepSystemMultiplier);
		end
	end
	if sleepModData.SleepHealthinessBar > 100 then
		if not player:HasTrait("NeedsLessSleep") then
			player:getTraits():add("NeedsLessSleep")
			if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_LessSleep"), true, HaloTextHelper.getColorGreen()) end
		end
	elseif sleepModData.SleepHealthinessBar < -100 then
		if not player:HasTrait("NeedsMoreSleep") then
			player:getTraits():add("NeedsMoreSleep")
			if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_MoreSleep"), true, HaloTextHelper.getColorRed()) end
		end
	else
		if player:HasTrait("NeedsLessSleep") then
			player:getTraits():remove("NeedsLessSleep")
			if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_LessSleep"), false, HaloTextHelper.getColorRed()) end
		end
		if player:HasTrait("NeedsMoreSleep") then
			player:getTraits():remove("NeedsMoreSleep")
			if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_MoreSleep"), true, HaloTextHelper.getColorGreen()) end
		end
	end
	if detailedDebug() then print("ETW Logger | sleepSystem(): modData.SleepHealthinessBar: ".. sleepModData.SleepHealthinessBar) end
end

local function smoker()
	local player = getPlayer();
	local modData = player:getModData().EvolvingTraitsWorld;
	local smokerModData = modData.SmokeSystem; -- SmokingAddiction MinutesSinceLastSmoke
	local timeSinceLastSmoke = player:getTimeSinceLastSmoke() * 60;
	smokerModData.MinutesSinceLastSmoke = smokerModData.MinutesSinceLastSmoke + 1;
	if detailedDebug() then print("ETW Logger | smoker(): timeSinceLastSmoke: "..timeSinceLastSmoke..", modData.MinutesSinceLastSmoke: ".. smokerModData.MinutesSinceLastSmoke) end
	local stats = player:getStats();
	local stress = stats:getStress(); -- stress is 0-1
	local panic = stats:getPanic(); -- 0-100
	local addictionDecay = SBvars.SmokingAddictionDecay * (0.0167 / 10) * (1 - stress) * (1 - panic / 100);
	if SBvars.AffinitySystem and modData.StartingTraits.Smoker then
		addictionDecay = addictionDecay / SBvars.AffinitySystemLoseDivider;
	end
	smokerModData.SmokingAddiction = math.max(0, smokerModData.SmokingAddiction - addictionDecay);
	ETWMoodles.smokerMoodleUpdate(player, smokerModData.SmokingAddiction);
	if debug() then print("ETW Logger | smoker(): smoking addictionDecay: "..addictionDecay..", modData.SmokingAddiction: ".. smokerModData.SmokingAddiction) end
	if smokerModData.SmokingAddiction >= SBvars.SmokerCounter and not player:HasTrait("Smoker") then
		player:getTraits():add("Smoker")
		if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Smoker"), true, HaloTextHelper.getColorRed()) end
	elseif smokerModData.SmokingAddiction <= SBvars.SmokerCounter / 2 and player:HasTrait("Smoker") then
		stats:setStressFromCigarettes(0);
		player:getTraits():remove("Smoker")
		if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Smoker"), false, HaloTextHelper.getColorGreen()) end
	end
end

local function herbalist()
	local player = getPlayer();
	local modData = player:getModData().EvolvingTraitsWorld;
	modData.HerbsPickedUp = math.max(0, modData.HerbsPickedUp - ((SBvars.AffinitySystem and modData.StartingTraits.Herbalist) and 1 / SBvars.AffinitySystemLoseDivider or 1));
	if debug() then print("ETW Logger | herbalist(): modData.HerbsPickedUp: "..modData.HerbsPickedUp) end
	if modData.HerbsPickedUp < SBvars.HerbalistHerbsPicked / 2 and player:HasTrait("Herbalist") then
		player:getTraits():remove("Herbalist");
		player:getKnownRecipes():remove("Herbalist");
		if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Herbalist"), false, HaloTextHelper.getColorRed()) end
	end
end

local function initializeEvents(playerIndex, player)
	Events.EveryOneMinute.Remove(catEyes);
	if SBvars.CatEyes == true and not player:HasTrait("NightVision") then Events.EveryOneMinute.Add(catEyes) end
	Events.EveryTenMinutes.Remove(sleepSystem);
	if
		((not isClient() and not isServer()) and SBvars.SleepSystem == true) or -- single player and SleepSystem is enabled
		(getServerOptions():getBoolean("SleepNeeded") and SBvars.SleepSystem == true) then -- server and SleepNeeded is enabled and SleepSystem is enabled
			Events.EveryTenMinutes.Add(sleepSystem) end
	Events.EveryOneMinute.Remove(smoker);
	if SBvars.Smoker == true then Events.EveryOneMinute.Add(smoker) end
	Events.EveryDays.Remove(herbalist);
	if SBvars.Herbalist == true then Events.EveryDays.Add(herbalist) end
end

local function clearEvents(character)
	Events.EveryOneMinute.Remove(catEyes);
	Events.EveryTenMinutes.Remove(sleepSystem);
	Events.EveryOneMinute.Remove(smoker);
	Events.EveryDays.Remove(herbalist);
	if detailedDebug() then print("ETW Logger | System: clearEvents in ETWByTime.lua") end
end

Events.OnCreatePlayer.Remove(initializeEvents);
Events.OnCreatePlayer.Add(initializeEvents);
Events.OnPlayerDeath.Add(clearEvents);