---@diagnostic disable: undefined-global
require("MF_ISMoodle")
local ETW_CommonFunctions = require("ETW_CommonFunctions")

local FILENAME = "ETW_Moodles.lua"
if
	not ETW_CommonFunctions.gameModeSafeguard(
		FILENAME,
		{ ETW_CommonFunctions.GameMode.SP, ETW_CommonFunctions.GameMode.MP_CLIENT }
	)
then
	return
end

local modOptions

---Function responsible for setting up mod options on character load
---@param playerIndex number
---@param player IsoPlayer
local function initializeModOptions(playerIndex, player)
	modOptions = PZAPI.ModOptions:getOptions("ETWModOptions")
end

Events.OnCreatePlayer.Remove(initializeModOptions)
Events.OnCreatePlayer.Add(initializeModOptions)

local ETW_Moodles = {}

---@type EvolvingTraitsWorldSandboxVars
local SBvars = SandboxVars.EvolvingTraitsWorld

---@type fun(...: string)
local logETW = ETW_CommonFunctions.log

MF.createMoodle("BloodlustMoodle")
MF.createMoodle("SleepHealthMoodle")

local bloodlustMeterCapacity = 72

---Ensures MoodleFramework's backing modData entry exists for an initialized moodle.
---@param player IsoPlayer
---@param moodleName string
---@return boolean
local function ensureMoodleModData(player, moodleName)
	if not player then
		return false
	end
	local modData = player:getModData()
	if type(modData.Moodles) ~= "table" then
		modData.Moodles = {}
	end
	local moodleModData = modData.Moodles[moodleName]
	local restored = false
	if type(moodleModData) ~= "table" then
		modData.Moodles[moodleName] = {
			Level = 0,
			GoodBadNeutral = 0,
			Value = 0.5,
		}
		restored = true
	else
		if moodleModData.Level == nil then
			moodleModData.Level = 0
			restored = true
		end
		if moodleModData.GoodBadNeutral == nil then
			moodleModData.GoodBadNeutral = 0
			restored = true
		end
		if moodleModData.Value == nil then
			moodleModData.Value = 0.5
			restored = true
		end
	end
	if restored then
		logETW("ETW Logger | ensureMoodleModData(): restored missing backing data for " .. moodleName)
	end
	return true
end

---Repairs backing data that may be lost when player modData is synchronized in multiplayer.
---@param player IsoPlayer
local function repairInitializedMoodleModData(player)
	if player ~= getPlayer() then
		return
	end
	if MF.getMoodle("BloodlustMoodle") then
		ensureMoodleModData(player, "BloodlustMoodle")
	end
	if MF.getMoodle("SleepHealthMoodle") then
		ensureMoodleModData(player, "SleepHealthMoodle")
	end
end

Events.OnPlayerUpdate.Remove(repairInitializedMoodleModData)
Events.OnPlayerUpdate.Add(repairInitializedMoodleModData)

---@class bloodlustMoodleArgs
---@field hide boolean

---Function responsible for updating bloodlust moodle
---@param player IsoPlayer
---@param args bloodlustMoodleArgs
function ETW_Moodles.bloodlustMoodleUpdate(player, args)
	player = player or getPlayer()
	if SBvars.BloodlustMoodle == true then
		local moodle = MF.getMoodle("BloodlustMoodle")
		if not moodle or not ensureMoodleModData(player, "BloodlustMoodle") then
			return
		end
		local modData = ETW_CommonFunctions.getETWModData(player)
		if not modData then
			logETW("ETW Logger | bloodlustMoodleUpdate(): modData is nil, returning early")
			return
		end
		local BloodLustModData = modData.BloodlustSystem
		local timeSinceLastKill = player:getHoursSurvived() - BloodLustModData.LastKillTimestamp
		moodle:setThresholds(0.1, 0.2, 0.35, 0.4999, 0.5001, 0.65, 0.8, 0.9)
		if
			player == getPlayer()
			and modOptions:getOption("EnableBloodLustMoodle"):getValue()
			and not args.hide
			and timeSinceLastKill <= SBvars.BloodlustMoodleVisibilityHours
		then
			local percentage = BloodLustModData.BloodlustMeter / bloodlustMeterCapacity
			local displayedPercentage = string.format("%.2f", percentage * 100)
			moodle:setValue(percentage)
			moodle:setDescription(
				moodle:getGoodBadNeutral(),
				moodle:getLevel(),
				getText("Moodles_BloodlustMoodle_Custom", displayedPercentage)
			)
			moodle:setPicture(
				moodle:getGoodBadNeutral(),
				moodle:getLevel(),
				getTexture("media/ui/Moodles/BloodlustMoodle.png")
			)
		else
			moodle:setValue(0.5)
		end
	end
end

---@class sleepHealthMoodleArgs
---@field hoursAwayFromPreferredHour number
---@field hide boolean

---Function responsible for updating sleep health moodle
---@param player IsoPlayer
---@param args sleepHealthMoodleArgs
function ETW_Moodles.sleepHealthMoodleUpdate(player, args)
	player = player or getPlayer()
	if SBvars.SleepMoodle == true then
		local moodle = MF.getMoodle("SleepHealthMoodle")
		if not moodle or not ensureMoodleModData(player, "SleepHealthMoodle") then
			return
		end
		modOptions = PZAPI.ModOptions:getOptions("ETWModOptions")
		moodle:setThresholds(1.5, 3, 4.5, 5.999, 6.001, 7.5, 9, 10.5)
		if player == getPlayer() and modOptions:getOption("EnableSleepHealthMoodle"):getValue() and not args.hide then
			logETW(
				"ETW Logger | ETWMoodles.sleepHealthMoodleUpdate(): hoursAwayFromPreferredHour: "
					.. args.hoursAwayFromPreferredHour
			)
			local displayedDifference = string.format("%.2f", args.hoursAwayFromPreferredHour)
			moodle:setValue(12 - args.hoursAwayFromPreferredHour)
			moodle:setDescription(
				moodle:getGoodBadNeutral(),
				moodle:getLevel(),
				getText("Moodles_SleepHealthMoodle_Custom", displayedDifference)
			)
			moodle:setPicture(
				moodle:getGoodBadNeutral(),
				moodle:getLevel(),
				getTexture("media/ui/Moodles/SleepHealthMoodle.png")
			)
		else
			moodle:setValue(6)
		end
	end
end

function ETW_Moodles.OnServerCommand(module, command, args)
	if module == "ETW" and ETW_Moodles[command] then
		local argStr = ""
		args = args or {}
		for k, v in pairs(args) do
			argStr = argStr .. " " .. k .. "=" .. tostring(v)
		end
		ETW_Moodles[command](getPlayer(), args)
	end
end

Events.OnServerCommand.Add(ETW_Moodles.OnServerCommand)

return ETW_Moodles
