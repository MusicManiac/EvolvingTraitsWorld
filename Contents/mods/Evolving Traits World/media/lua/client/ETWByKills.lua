require "ETWModData";
local ETWMoodles = require "ETWMoodles";
local ETWCommonFunctions = require "ETWCommonFunctions";
local ETWCommonLogicChecks = require "ETWCommonLogicChecks";

---@type EvolvingTraitsWorldSandboxVars
local SBvars = SandboxVars.EvolvingTraitsWorld;

---@return boolean
local notification = function() return EvolvingTraitsWorld.settings.EnableNotifications end;
---@return boolean
local delayedNotification = function() return EvolvingTraitsWorld.settings.EnableDelayedNotifications end;
---@return boolean
local debug = function() return EvolvingTraitsWorld.settings.GatherDebug end;
---@return boolean
local detailedDebug = function() return EvolvingTraitsWorld.settings.GatherDetailedDebug end;

local bloodlustMeterCapacity = 72;

---Function responsible for checking % of bloodied clothes
---@param player IsoPlayer
---@return number -- percentage of bloodied clothes (0-1)
local function bloodiedClothesLevel(player)
	local wornItems = player:getWornItems();
	local totalBloodLevelPercentage = 0;
	local amountOfWornItems = 0;
	local detailedDebug = detailedDebug();
	if wornItems ~= nil and wornItems:size() > 1 then
		for i = 0, wornItems:size() - 1, 1 do
			local item = wornItems:getItemByIndex(i);
			if instanceof(item, "Clothing") then
				---@cast item Clothing
				if item:getBloodClothingType() ~= nil then
					local bloodLevel = item:getBloodLevel() or 0;
					amountOfWornItems = amountOfWornItems + 1;
					totalBloodLevelPercentage = totalBloodLevelPercentage + bloodLevel;
					if detailedDebug then print("ETW Logger | bloodiedClothesLevel(): Clothing = " .. item:getClothingItemName() .. " | blood clothing type = " .. tostring(item:getBloodClothingType()) .. " | blood level = " .. bloodLevel) end;
				end
			end
		end
		if amountOfWornItems == 0 then
		    return 0;
		end
		local avg = totalBloodLevelPercentage / 100 / amountOfWornItems;
		if detailedDebug then print("ETW Logger | bloodiedClothesLevel(): avg = " .. avg) end;
		return avg;
	end
	return 0;
end

---Function responsible for managing Bloodlust meter
---@param zombie IsoZombie
local function bloodlustKillETW(zombie)
	local player = getPlayer();
	local detailedDebug = detailedDebug();
	if player:isLocalPlayer() == false then -- checks if it's NPC doing stuff
		if detailedDebug then print("ETW Logger | bloodlustKillETW(): kill by NPC") end;
	else
		if detailedDebug then print("ETW Logger | bloodlustKillETW(): kill by player") end;
		local distance = player:DistTo(zombie);
		if detailedDebug then print("ETW Logger | bloodlustKillETW(): distance=" .. distance) end;
		if distance <= 10 then
			local modData = ETWCommonFunctions.getETWModData(player);
			local bloodlust = modData.BloodlustSystem;
			bloodlust.LastKillTimestamp = player:getHoursSurvived();
			if bloodlust.BloodlustMeter <= bloodlustMeterCapacity then
				bloodlust.BloodlustMeter = bloodlust.BloodlustMeter + math.min(1.4 / distance, 1) * SBvars.BloodlustMeterFillMultiplier * (1 + bloodiedClothesLevel(player));
				if detailedDebug then print("ETW Logger | bloodlustKillETW(): BloodlustMeter=" .. bloodlust.BloodlustMeter) end;
			elseif bloodlust.BloodlustMeter < bloodlustMeterCapacity * SBvars.BloodlustMeterMaxCapMultiplier then
				bloodlust.BloodlustMeter = bloodlust.BloodlustMeter + math.min(1.4 / distance, 1) * SBvars.BloodlustMeterFillMultiplier * (1 + bloodiedClothesLevel(player)) * 0.5;
				if detailedDebug then print("ETW Logger | bloodlustKillETW(): BloodlustMeter (soft-capped)=" .. bloodlust.BloodlustMeter) end;
			end
			ETWMoodles.bloodlustMoodleUpdate(player, false);
		end
	end
end

---Function responsible for managing Bloodlust meter with flow of time
local function bloodlustTimeETW()
	local player = getPlayer();
	local modData = ETWCommonFunctions.getETWModData(player);
	local bloodlustModData = modData.BloodlustSystem;
	bloodlustModData.BloodlustMeter = math.min(bloodlustModData.BloodlustMeter, bloodlustMeterCapacity * SBvars.BloodlustMeterMaxCapMultiplier)
    bloodlustModData.BloodlustMeter = math.max(bloodlustModData.BloodlustMeter - 1, 0); -- hourly decay
	ETWMoodles.bloodlustMoodleUpdate(player, false);
	if detailedDebug() then print("ETW Logger | bloodlustTimeETW(): Bloodlust Meter: ".. bloodlustModData.BloodlustMeter) end;
    if bloodlustModData.BloodlustMeter >= bloodlustMeterCapacity / 2 then -- gain if above 50%
        local bloodLustProgressIncrease = bloodlustModData.BloodlustMeter * 0.1 * (1 + bloodiedClothesLevel(player)) * ((SBvars.AffinitySystem and modData.StartingTraits.Bloodlust) and SBvars.AffinitySystemGainMultiplier or 1);
        bloodlustModData.BloodlustProgress = math.min(SBvars.BloodlustProgress * 2, bloodlustModData.BloodlustProgress + bloodLustProgressIncrease);
        if debug() then print("ETW Logger | bloodlustTimeETW(): BloodlustMeter is above 50%, BloodlustProgress =" .. bloodlustModData.BloodlustProgress) end;
    else -- lose if below 50%
        local bloodLustProgressDecrease = bloodlustModData.BloodlustMeter * 0.1 * (1 - bloodiedClothesLevel(player)) / ((SBvars.AffinitySystem and modData.StartingTraits.Bloodlust) and SBvars.AffinitySystemLoseDivider or 1);
        bloodlustModData.BloodlustProgress = math.max(0, bloodlustModData.BloodlustProgress - (bloodlustMeterCapacity / 10 - bloodLustProgressDecrease));
        if debug() then print("ETW Logger | bloodlustTimeETW(): BloodlustMeter is below 50%, BloodlustProgress =" .. bloodlustModData.BloodlustProgress) end;
    end
	if player:HasTrait("Bloodlust") and bloodlustModData.BloodlustProgress <= SBvars.BloodlustProgress / 2 and SBvars.TraitsLockSystemCanLosePositive then
		player:getTraits():remove("Bloodlust");
		ETWCommonFunctions.traitSound(player);
		if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Bloodlust"), false, HaloTextHelper.getColorRed()) end;
	elseif not player:HasTrait("Bloodlust") and bloodlustModData.BloodlustProgress >= SBvars.BloodlustProgress and SBvars.TraitsLockSystemCanGainPositive then
		player:getTraits():add("Bloodlust");
		ETWCommonFunctions.traitSound(player);
		if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Bloodlust"), true, HaloTextHelper.getColorGreen()) end;
	end
end

---Function responsible for managing Eagle Eyed trait
---@param wielder IsoGameCharacter
---@param character IsoGameCharacter
---@param handWeapon HandWeapon
---@param damage number
local function eagleEyedETW(wielder, character, handWeapon, damage)
	if ETWCommonLogicChecks.EagleEyedShouldExecute() and wielder == getPlayer() and character:isZombie() then
        local player = wielder;
		---@cast player IsoPlayer;
		local zombie = character;
		local zHealth = zombie:getHealth();
		local distance = player:DistTo(zombie);
		local modData = ETWCommonFunctions.getETWModData(player);
		if distance >= SBvars.EagleEyedDistance and zHealth <= damage then
			modData.EagleEyedKills = modData.EagleEyedKills + 1;
			if debug() then print("ETW Logger | eagleEyedETW(): Caught a kill on following distance: " .. distance .. ", current eagle eyed kills:" .. player:getModData().EvolvingTraitsWorld.EagleEyedKills) end;
			if player:getModData().EvolvingTraitsWorld.EagleEyedKills >= SBvars.EagleEyedKills then
				if not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("EagleEyed")) then
					player:getTraits():add("EagleEyed");
					ETWCommonFunctions.traitSound(player);
					if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_eagleeyed"), true, HaloTextHelper.getColorGreen()) end;
				end
				if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable("EagleEyed") then
					if delayedNotification() then HaloTextHelper.addTextWithArrow(player, getText("UI_ETW_DelayedNotificationsStringAdd") .. getText("UI_trait_eagleeyed"), true, HaloTextHelper.getColorGreen()) end;
					ETWCommonFunctions.addTraitToDelayTable(modData, "EagleEyed", player, true);
					ETWCommonFunctions.traitSound(player);
				end
			end
		end
	end
end

---Function responsible for managing Bravery System traits
---@param zombie IsoZombie
local function braverySystemETW(zombie)
	local player = getPlayer();
	local totalKills = player:getZombieKills();
	local braveryKills = SBvars.BraverySystemKills;
	local modDataGlobal = player:getModData();
	local killCountModData = modDataGlobal.KillCount.WeaponCategory;
	local ETWModData = modDataGlobal.EvolvingTraitsWorld;
	local fireKills = killCountModData["Fire"].count;
	local firearmsKills = killCountModData["Firearm"].count;
	local vehiclesKills = killCountModData["Vehicles"].count;
	local explosivesKills = killCountModData["Explosives"].count;
	local meleeKills = totalKills - firearmsKills - fireKills - vehiclesKills - explosivesKills;
	local traitInfo = {
		{ trait = "Cowardly", threshold = braveryKills * 0.1, remove = true },
		{ trait = "Hemophobic", threshold = braveryKills * 0.2, remove = true, cantHaveTrait = "Cowardly" },
		{ trait = "Pacifist", threshold = braveryKills * 0.3, remove = true, cantHaveTrait = "Hemophobic"},
		{ trait = "AdrenalineJunkie", threshold = braveryKills * 0.4, add = true, cantHaveTrait = "Pacifist"},
		{ trait = "Brave", threshold = braveryKills * 0.6, add = true, requiredTrait = "AdrenalineJunkie" },
		{ trait = "Desensitized", threshold = braveryKills, add = true, requiredTrait = "Brave" }
	};
	for i = 1, #traitInfo do
		local info = traitInfo[i]
		local trait = info.trait;
		local threshold = info.threshold;
		local negativeTrait = info.remove;
		local positiveTrait = info.add;
		local cantHaveTrait = info.cantHaveTrait;
        local requiredTrait = info.requiredTrait;
		if (totalKills + meleeKills) >= threshold then -- melee kills counted double
            if player:HasTrait(trait) and negativeTrait and (not cantHaveTrait or not player:HasTrait(cantHaveTrait)) and SBvars.TraitsLockSystemCanLoseNegative then
				if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable(trait) then
					if delayedNotification() then HaloTextHelper.addTextWithArrow(player, getText("UI_ETW_DelayedNotificationsStringRemove") .. getText("UI_trait_" .. (trait == "Cowardly" and "cowardly" or trait)), true, HaloTextHelper.getColorGreen()) end;
					ETWCommonFunctions.addTraitToDelayTable(ETWModData, trait, player, false);
					ETWCommonFunctions.traitSound(player);
				elseif not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits(trait)) then
					player:getTraits():remove(trait);
					ETWCommonFunctions.traitSound(player);
					if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_" .. (trait == "Cowardly" and "cowardly" or trait)), false, HaloTextHelper.getColorGreen()) end;
				end
				return
            elseif not player:HasTrait(trait) and positiveTrait and (not cantHaveTrait or not player:HasTrait(cantHaveTrait)) and (not requiredTrait or player:HasTrait(requiredTrait)) and SBvars.TraitsLockSystemCanGainPositive then
				if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable(trait) then
					if delayedNotification() then HaloTextHelper.addTextWithArrow(player, getText("UI_ETW_DelayedNotificationsStringAdd") .. getText("UI_trait_" .. (trait == "Brave" and "brave" or trait)), true, HaloTextHelper.getColorGreen()) end;
					ETWCommonFunctions.addTraitToDelayTable(ETWModData, trait, player, true);
					ETWCommonFunctions.traitSound(player);
				elseif not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits(trait)) then
					player:getTraits():add(trait);
					ETWCommonFunctions.traitSound(player);
					if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_" .. (trait == "Brave" and "brave" or trait)), true, HaloTextHelper.getColorGreen()) end;
					if trait == "Desensitized" then
						Events.OnZombieDead.Remove(braverySystemETW);
						if SBvars.BraverySystemRemovesOtherFearPerks == true and SBvars.TraitsLockSystemCanLoseNegative then
							if player:HasTrait("Agoraphobic") then
								player:getTraits():remove("Agoraphobic");
								if notification() then HaloTextHelper.addTextWithArrow(player, "UI_trait_agoraphobic", false, HaloTextHelper.getColorGreen()) end;
							end
							if player:HasTrait("Claustophobic") then
								player:getTraits():remove("Claustophobic");
								if notification() then HaloTextHelper.addTextWithArrow(player, "UI_trait_claustro", false, HaloTextHelper.getColorGreen()) end;
							end
							if player:HasTrait("Pluviophobia") then
								player:getTraits():remove("Pluviophobia");
								if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Pluviophobia"), false, HaloTextHelper.getColorGreen()) end;
							end
							if player:HasTrait("Homichlophobia") then
								player:getTraits():remove("Homichlophobia");
								if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Homichlophobia"), false, HaloTextHelper.getColorGreen()) end;
							end
						end
					end
				end
				return
			end
		end
	end
end

---Function responsible for setting up events
---@param playerIndex number
---@param player IsoPlayer
local function initializeEventsETW(playerIndex, player)
	if ETWCommonLogicChecks.BloodlustShouldExecute() then
		ETWMoodles.bloodlustMoodleUpdate(player, true);
		Events.OnZombieDead.Remove(bloodlustKillETW);
		Events.OnZombieDead.Add(bloodlustKillETW);
		Events.EveryHours.Remove(bloodlustTimeETW);
		Events.EveryHours.Add(bloodlustTimeETW);
	end
	Events.OnWeaponHitCharacter.Remove(eagleEyedETW);
	if ETWCommonLogicChecks.EagleEyedShouldExecute() then Events.OnWeaponHitCharacter.Add(eagleEyedETW) end;
	Events.OnZombieDead.Remove(braverySystemETW);
	if ETWCommonLogicChecks.BraverySystemShouldExecute() then Events.OnZombieDead.Add(braverySystemETW) end;
end

---Function responsible for clearing events
---@param character IsoPlayer
local function clearEventsETW(character)
	Events.OnZombieDead.Remove(bloodlustKillETW);
	Events.EveryHours.Remove(bloodlustTimeETW)
	Events.OnWeaponHitCharacter.Remove(eagleEyedETW);
	Events.OnZombieDead.Remove(braverySystemETW);
	if detailedDebug() then print("ETW Logger | System: clearEventsETW in ETWByKills.lua") end;
end

Events.OnCreatePlayer.Remove(initializeEventsETW);
Events.OnCreatePlayer.Add(initializeEventsETW);
Events.OnPlayerDeath.Remove(clearEventsETW);
Events.OnPlayerDeath.Add(clearEventsETW);
