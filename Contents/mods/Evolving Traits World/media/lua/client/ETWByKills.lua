require "ETWModData";
local ETWMoodles = require "ETWMoodles";
local ETWCommonFunctions = require "ETWCommonFunctions";

local SBvars = SandboxVars.EvolvingTraitsWorld;

local notification = function() return EvolvingTraitsWorld.settings.EnableNotifications end
local delayedNotification = function() return EvolvingTraitsWorld.settings.EnableDelayedNotifications end
local debug = function() return EvolvingTraitsWorld.settings.GatherDebug end
local detailedDebug = function() return EvolvingTraitsWorld.settings.GatherDetailedDebug end

local function bloodlustKill(zombie)
	if SBvars.Bloodlust == true then
		local player = getPlayer();
		local bloodlust = player:getModData().EvolvingTraitsWorld.BloodlustSystem;
		local distance = player:DistTo(zombie);
		if distance <= 10 then
			bloodlust.LastKillTimestamp = player:getHoursSurvived();
			if bloodlust.BloodlustMeter <= 36 then
				bloodlust.BloodlustMeter = bloodlust.BloodlustMeter + math.min(1 / distance, 1) * SBvars.BloodlustMeterFillMultiplier;
				if detailedDebug() then print("ETW Logger | bloodlustKill(): BloodlustMeter="..bloodlust.BloodlustMeter) end
			else
				bloodlust.BloodlustMeter = bloodlust.BloodlustMeter + math.min(1 / distance, 1) * SBvars.BloodlustMeterFillMultiplier * 0.1;
				if detailedDebug() then print("ETW Logger | bloodlustKill(): BloodlustMeter (soft-capped)="..bloodlust.BloodlustMeter) end
			end
			ETWMoodles.bloodlustMoodleUpdate(player, false);
		end
	end
end

local function bloodlustTime()
	if SBvars.Bloodlust == true then
		local player = getPlayer();
		local modData = player:getModData().EvolvingTraitsWorld;
		local bloodlustModData = modData.BloodlustSystem;
		bloodlustModData.BloodlustMeter = math.max(bloodlustModData.BloodlustMeter - 1, 0);
		ETWMoodles.bloodlustMoodleUpdate(player, false);
		-- Bloodlust Progress when no perk
		if detailedDebug() then print("ETW Logger | bloodlustTime(): Bloodlust Meter: ".. bloodlustModData.BloodlustMeter) end
		if bloodlustModData.BloodlustMeter >= 18 then -- gain if above 50%
			local bloodLustProgressIncrease = bloodlustModData.BloodlustMeter * 0.1 * ((SBvars.AffinitySystem and modData.StartingTraits.Bloodlust) and SBvars.AffinitySystemGainMultiplier or 1);
			bloodlustModData.BloodlustProgress = math.min(SBvars.BloodlustProgress * 2, bloodlustModData.BloodlustProgress + bloodLustProgressIncrease);
			if debug() then print("ETW Logger | bloodlustTime(): BloodlustMeter is above 50%, BloodlustProgress =".. bloodlustModData.BloodlustProgress) end
		else -- lose if below 50%
			local bloodLustProgressDecrease = bloodlustModData.BloodlustMeter * 0.1 / ((SBvars.AffinitySystem and modData.StartingTraits.Bloodlust) and SBvars.AffinitySystemLoseDivider or 1);
			bloodlustModData.BloodlustProgress = math.max(0, bloodlustModData.BloodlustProgress - (3.6 - bloodLustProgressDecrease));
			if debug() then print("ETW Logger | bloodlustTime(): BloodlustMeter is below 50%, BloodlustProgress =".. bloodlustModData.BloodlustProgress) end
		end
		if player:HasTrait("Bloodlust") and bloodlustModData.BloodlustProgress <= SBvars.BloodlustProgress / 2 then
			player:getTraits():remove("Bloodlust");
			if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Bloodlust"), false, HaloTextHelper.getColorRed()) end
		elseif not player:HasTrait("Bloodlust") and bloodlustModData.BloodlustProgress >= SBvars.BloodlustProgress then
			player:getTraits():add("Bloodlust");
			if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Bloodlust"), true, HaloTextHelper.getColorGreen()) end
		end
	end
end

local function eagleEyed(wielder, character, handWeapon, damage)
	if wielder == getPlayer() and character:isZombie() and SBvars.EagleEyed == true and not wielder:HasTrait("EagleEyed") then
		local player = wielder;
		local zombie = character;
		local zHealth = zombie:getHealth();
		local distance = player:DistTo(zombie);
		local modData = player:getModData().EvolvingTraitsWorld;
		if distance >= SBvars.EagleEyedDistance and zHealth <= damage then
			modData.EagleEyedKills = modData.EagleEyedKills + 1;
			if debug() then print("ETW Logger | eagleEyed(): Caught a kill on following distance: "..distance..", current eagle eyed kills:"..player:getModData().EvolvingTraitsWorld.EagleEyedKills) end
			if player:getModData().EvolvingTraitsWorld.EagleEyedKills >= SBvars.EagleEyedKills then
				if not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits("EagleEyed")) then
					player:getTraits():add("EagleEyed");
					if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_eagleeyed"), true, HaloTextHelper.getColorGreen()) end
				end
				if SBvars.DelayedTraitsSystem then
					if delayedNotification() then HaloTextHelper.addTextWithArrow(player, getText("UI_EvolvingTraitsWorld_DelayedNotificationsStringAdd")..getText("UI_trait_eagleeyed"), true, HaloTextHelper.getColorGreen()) end
					ETWCommonFunctions.addTraitToDelayTable(modData, "EagleEyed", player)
				end
			end
		end
	end
end

local function braverySystem(zombie)
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
		{ trait = "Hemophobic", threshold = braveryKills * 0.2, remove = true },
		{ trait = "Pacifist", threshold = braveryKills * 0.3, remove = true },
		{ trait = "AdrenalineJunkie", threshold = braveryKills * 0.4, add = true },
		{ trait = "Brave", threshold = braveryKills * 0.6, add = true },
		{ trait = "Desensitized", threshold = braveryKills, add = true }
	}
	for i, info in ipairs(traitInfo) do
		local trait = info.trait
		local threshold = info.threshold
		local remove = info.remove
		local add = info.add
		if (totalKills + meleeKills) >= threshold then -- melee kills counted double
			if player:HasTrait(trait) and remove then
				if not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits(trait)) then
					player:getTraits():remove(trait)
					if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_" .. trait), false, HaloTextHelper.getColorGreen()) end
				end
				if SBvars.DelayedTraitsSystem then
					if delayedNotification() then HaloTextHelper.addTextWithArrow(player, getText("UI_EvolvingTraitsWorld_DelayedNotificationsStringRemove")..getText("UI_trait_" .. trait), true, HaloTextHelper.getColorGreen()) end
					ETWCommonFunctions.addTraitToDelayTable(ETWModData, trait, player, false)
				end
			elseif not player:HasTrait(trait) and add then
				if not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits(trait)) then
					player:getTraits():add(trait)
					if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_" .. (trait == "Brave" and "brave" or trait)), true, HaloTextHelper.getColorGreen()) end
					if trait == "Desensitized" then
						Events.OnZombieDead.Remove(braverySystem);
						if SBvars.BraverySystemRemovesOtherFearPerks == true then
							if player:HasTrait("Agoraphobic") then
								player:getTraits():remove("Agoraphobic");
								if notification() then HaloTextHelper.addTextWithArrow(player, "UI_trait_agoraphobic", false, HaloTextHelper.getColorGreen()) end
							end
							if player:HasTrait("Claustophobic") then
								player:getTraits():remove("Claustophobic");
								if notification() then HaloTextHelper.addTextWithArrow(player, "UI_trait_claustro", false, HaloTextHelper.getColorGreen()) end
							end
							if player:HasTrait("Pluviophobia") then
								player:getTraits():remove("Pluviophobia");
								if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Pluviophobia"), false, HaloTextHelper.getColorGreen()) end
							end
							if player:HasTrait("Homichlophobia") then
								player:getTraits():remove("Homichlophobia");
								if notification() then HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Homichlophobia"), false, HaloTextHelper.getColorGreen()) end
							end
						end
					end
				end
				if SBvars.DelayedTraitsSystem then
					if delayedNotification() then HaloTextHelper.addTextWithArrow(player, getText("UI_EvolvingTraitsWorld_DelayedNotificationsStringAdd")..getText("UI_trait_" .. (trait == "Brave" and "brave" or trait)), true, HaloTextHelper.getColorGreen()) end
					ETWCommonFunctions.addTraitToDelayTable(ETWModData, trait, player, true)
				end
			end
		end
	end
end

local function initializeKills(playerIndex, player)
	if not getActivatedMods():contains("EvolvingTraitsWorldDisableBloodlust") then
		ETWMoodles.bloodlustMoodleUpdate(player);
		Events.OnZombieDead.Remove(bloodlustKill);
		Events.OnZombieDead.Add(bloodlustKill);
		Events.EveryHours.Remove(bloodlustTime);
		Events.EveryHours.Add(bloodlustTime);
	end
	Events.OnWeaponHitCharacter.Remove(eagleEyed);
	if SBvars.EagleEyed == true and not player:HasTrait("EagleEyed") then Events.OnWeaponHitCharacter.Add(eagleEyed) end
	Events.OnZombieDead.Remove(braverySystem);
	if SBvars.BraverySystem == true and not player:HasTrait("Desensitized") then Events.OnZombieDead.Add(braverySystem) end
end

local function clearEvents(character)
	Events.OnZombieDead.Remove(bloodlustKill);
	Events.EveryHours.Remove(bloodlustTime)
	Events.OnWeaponHitCharacter.Remove(eagleEyed);
	Events.OnZombieDead.Remove(braverySystem);
	if detailedDebug() then print("ETW Logger | System: clearEvents in ETWByKills.lua") end
end

Events.OnCreatePlayer.Remove(initializeKills);
Events.OnCreatePlayer.Add(initializeKills);
Events.OnPlayerDeath.Add(clearEvents);