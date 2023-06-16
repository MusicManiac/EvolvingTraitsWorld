ETWMoodles = {};
require "MF_ISMoodle";

local SBvars = SandboxVars.EvolvingTraitsWorld;

local detailedDebug = function() return EvolvingTraitsWorld.settings.GatherDetailedDebug end

MF.createMoodle("BloodlustMoodle");
MF.createMoodle("SleepHealthMoodle");
MF.createMoodle("SmokerGSMoodle");
MF.createMoodle("SmokerLSMoodle");

function ETWMoodles.bloodlustMoodleUpdate(player, hide)
	if SBvars.BloodlustMoodle == true then
		local MOvars = EvolvingTraitsWorld.settings;
		local moodle = MF.getMoodle("BloodlustMoodle");
		local modData = player:getModData().EvolvingTraitsWorld.BloodlustSystem;
		local timeSinceLastKill = player:getHoursSurvived() - modData.LastKillTimestamp;
		moodle:setThresholds(0.1, 0.2, 0.35, 0.4999, 0.5001, 0.65, 0.8, 0.9);
		if player == getPlayer() and MOvars.EnableBloodLustMoodle == true and hide == false and timeSinceLastKill <= SBvars.BloodlustMoodleVisibilityHours then
			local percentage = modData.BloodlustMeter / 36;
			local displayedPercentage = string.format("%.2f", percentage * 100);
			moodle:setValue(percentage);
			moodle:setDescription(moodle:getGoodBadNeutral(), moodle:getLevel(), getText("Moodles_BloodlustMoodle_Custom", displayedPercentage));
			moodle:setPicture(moodle:getGoodBadNeutral(), moodle:getLevel(),getTexture("media/ui/Moodles/BloodlustMoodle.png"));
		else
			moodle:setValue(0.5);
		end
	end
end

function ETWMoodles.sleepHealthMoodleUpdate(player, hoursAwayFromPreferredHour, hide)
	if SBvars.SleepMoodle == true then
		local MOvars = EvolvingTraitsWorld.settings;
		local moodle = MF.getMoodle("SleepHealthMoodle");
		moodle:setThresholds(1.5, 3, 4.5, 5.999, 6.001, 7.5, 9, 10.5);
		if player == getPlayer() and MOvars.EnableSleepHealthMoodle == true and hide == false then
			if detailedDebug() then print("ETW Logger | ETWMoodles.sleepHealthMoodleUpdate(): hoursAwayFromPreferredHour: "..hoursAwayFromPreferredHour) end
			local displayedDifference = string.format("%.2f", hoursAwayFromPreferredHour);
			moodle:setValue(12 - hoursAwayFromPreferredHour);
			moodle:setDescription(moodle:getGoodBadNeutral(), moodle:getLevel(), getText("Moodles_SleepHealthMoodle_Custom", displayedDifference));
			moodle:setPicture(moodle:getGoodBadNeutral(), moodle:getLevel(),getTexture("media/ui/Moodles/SleepHealthMoodle.png"));
		else
			moodle:setValue(6);
		end
	end
end

function ETWMoodles.smokerMoodleUpdate(player, smokingAddiction)
	if SBvars.SmokerMoodle == true and player == getPlayer() then
		local MOvars = EvolvingTraitsWorld.settings;
		local moodleGainSmoker = MF.getMoodle("SmokerGSMoodle");
		local moodleLoseSmoker = MF.getMoodle("SmokerLSMoodle");
		moodleGainSmoker:setThresholds(10, 25, 30, 49.99, 50.01, 60, 75, 90);
		moodleLoseSmoker:setThresholds(10, 25, 30, 49.99, 50.01, 60, 75, 90);
		local SBCounter = SBvars.SmokerCounter;
		local smokerLoseThreshold = SBCounter / 2;
		local smokerGainThreshold = SBCounter;
		local upperBoundary = SBCounter * 2;
		if not player:HasTrait("Smoker") then
			local percentage = 100 - smokingAddiction * 100 / smokerGainThreshold;
			if percentage <= math.min(SBvars.SmokerMoodlePercentage, MOvars.SmokerMoodleVisibilityValue) and percentage ~= 100 and MOvars.EnableSmokerMoodle == true then
				local displayedDifference = string.format("%.2f", percentage);
				moodleGainSmoker:setValue(percentage);
				moodleGainSmoker:setDescription(moodleGainSmoker:getGoodBadNeutral(), moodleGainSmoker:getLevel(), getText("Moodles_SmokerGSMoodle_GainingSmoker", displayedDifference));
				moodleGainSmoker:setPicture(moodleGainSmoker:getGoodBadNeutral(), moodleGainSmoker:getLevel(),getTexture("media/ui/Moodles/SmokerGSMoodle.png"));
			else
				moodleGainSmoker:setValue(50);
			end
			moodleLoseSmoker:setValue(50);
		else
			local percentage = 100 - (smokingAddiction - smokerLoseThreshold) * 100 / (upperBoundary - smokerLoseThreshold);
			if 100 - percentage <= math.min(SBvars.SmokerMoodlePercentage, MOvars.SmokerMoodleVisibilityValue) and MOvars.EnableSmokerMoodle == true then
				local displayedDifference = string.format("%.2f", math.abs(100 - percentage));
				moodleLoseSmoker:setValue(percentage);
				moodleLoseSmoker:setDescription(moodleLoseSmoker:getGoodBadNeutral(), moodleLoseSmoker:getLevel(), getText("Moodles_SmokerLSMoodle_LosingSmoker", displayedDifference));
				moodleLoseSmoker:setPicture(moodleLoseSmoker:getGoodBadNeutral(), moodleLoseSmoker:getLevel(),getTexture("media/ui/Moodles/SmokerLSMoodle.png"));
			else
				moodleLoseSmoker:setValue(50);
			end
			moodleGainSmoker:setValue(50);
		end
	end
end

return ETWMoodles;