---@diagnostic disable: undefined-global
---@diagnostic disable-next-line: unresolved-require
require("MF_ISMoodle")
local ETW_CommonFunctions = require("ETW_CommonFunctions")
local ETW_Registry = require("ETW_Registry")

local FILENAME = "ETW_Moodles.lua"
if
	not ETW_CommonFunctions.gameModeSafeguard(
		FILENAME,
		{ ETW_CommonFunctions.GameMode.SP, ETW_CommonFunctions.GameMode.MP_CLIENT }
	)
then
	return
end

---@type PZAPI.ModOptions.Options|nil
local modOptions

---Function responsible for setting up mod options on character load
---@param playerIndex number
---@param player IsoPlayer
local function initializeModOptions(playerIndex, player)
	modOptions = PZAPI.ModOptions:getOptions("ETWModOptions")
end

---Returns a boolean ETW mod option, defaulting to enabled while options are unavailable.
---@param optionID string
---@return boolean
local function isMoodleEnabled(optionID)
	modOptions = modOptions or PZAPI.ModOptions:getOptions("ETWModOptions")
	if not modOptions then
		return true
	end
	local option = modOptions:getOption(optionID)
	if not option then
		return true
	end
	---@cast option umbrella.ModOptions.TickBox
	return option:getValue()
end

Events.OnCreatePlayer.Remove(initializeModOptions)
Events.OnCreatePlayer.Add(initializeModOptions)

local ETW_Moodles = {}

---@type EvolvingTraitsWorldSandboxVars
local SBvars = SandboxVars.EvolvingTraitsWorld

---@type fun(...: string)
local logETW = ETW_CommonFunctions.log

local ALCOHOLIC_WITHDRAWAL_MOODLE = "AlcoholicWithdrawalMoodle"
local ALCOHOLIC_WITHDRAWAL_MOODLE_TEXTURE = "media/ui/Moodles/AlcoholismWithdrawalMoodle.png"
local MODERATE_WITHDRAWAL_SEVERITY = 67
local SEVERE_WITHDRAWAL_SEVERITY = 100
local MOODLE_NEUTRAL_VALUE = 0.5
local MOODLE_BAD_1_THRESHOLD = 0.499999
local MOODLE_BAD_2_THRESHOLD = MOODLE_NEUTRAL_VALUE - MODERATE_WITHDRAWAL_SEVERITY / 200
local MOODLE_BAD_3_THRESHOLD = MOODLE_NEUTRAL_VALUE - SEVERE_WITHDRAWAL_SEVERITY / 200
local MOODLE_GOOD_1_VALUE = 0.75
local MOODLE_GOOD_2_VALUE = 1

local ALCOHOLIC_TRAIT_STAGES = {
	[ETW_Registry.traits.ALCOHOLIC_MILD] = 1,
	[ETW_Registry.traits.ALCOHOLIC_MODERATE] = 2,
	[ETW_Registry.traits.ALCOHOLIC_SEVERE] = 3,
}

MF.createMoodle("SleepHealthMoodle")
MF.createMoodle(ALCOHOLIC_WITHDRAWAL_MOODLE)

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
	if MF.getMoodle("SleepHealthMoodle") then
		ensureMoodleModData(player, "SleepHealthMoodle")
	end
end

Events.OnPlayerUpdate.Remove(repairInitializedMoodleModData)
Events.OnPlayerUpdate.Add(repairInitializedMoodleModData)

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
		moodle:setThresholds(1.5, 3, 4.5, 5.999, 6.001, 7.5, 9, 10.5)
		if player == getPlayer() and isMoodleEnabled("EnableSleepHealthMoodle") and not args.hide then
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

---Returns withdrawal severity from the server-synchronized player ModData without initializing or replacing it.
---@param player IsoPlayer
---@return number severity Percentage from 0 to 100.
local function getSyncedWithdrawalSeverity(player)
	local playerModData = player:getModData()
	local modData = playerModData and playerModData.EvolvingTraitsWorld
	local alcoholicSystem = modData and modData.AlcoholicSystem
	local severity = alcoholicSystem and tonumber(alcoholicSystem.WithdrawalSeverity) or 0
	return math.max(0, math.min(SEVERE_WITHDRAWAL_SEVERITY, severity))
end

---Applies the Alcoholic artwork to every enabled moodle level.
---@param moodle any
local function setAlcoholicWithdrawalMoodlePictures(moodle)
	local texture = getTexture(ALCOHOLIC_WITHDRAWAL_MOODLE_TEXTURE)
	moodle:setPicture(1, 1, texture)
	moodle:setPicture(1, 2, texture)
	moodle:setPicture(2, 1, texture)
	moodle:setPicture(2, 2, texture)
	moodle:setPicture(2, 3, texture)
end

---Returns the severity stage of the Alcoholic trait held by the player.
---@param player IsoPlayer
---@return integer stage Zero when the player has no Alcoholic trait.
local function getAlcoholicTraitStage(player)
	if player:hasTrait(ETW_Registry.traits.ALCOHOLIC_SEVERE) then
		return ALCOHOLIC_TRAIT_STAGES[ETW_Registry.traits.ALCOHOLIC_SEVERE]
	elseif player:hasTrait(ETW_Registry.traits.ALCOHOLIC_MODERATE) then
		return ALCOHOLIC_TRAIT_STAGES[ETW_Registry.traits.ALCOHOLIC_MODERATE]
	elseif player:hasTrait(ETW_Registry.traits.ALCOHOLIC_MILD) then
		return ALCOHOLIC_TRAIT_STAGES[ETW_Registry.traits.ALCOHOLIC_MILD]
	end
	return 0
end

---Formats a sandbox percentage without unnecessary trailing zeroes.
---@param value number
---@return string
local function formatWithdrawalChance(value)
	local formatted = string.format("%.2f", value)
	formatted = string.gsub(formatted, "0+$", "")
	formatted = string.gsub(formatted, "%.$", "")
	return formatted
end

---Sets one withdrawal stage description using the active sandbox effect chances.
---@param moodle any
---@param level integer
---@param descriptionKey string
---@param dropChance number
---@param screamChance number
---@param headPainChance number
---@param sicknessChance number
---@param temperatureSwingChance number
---@param wakeUpChance number
local function setAlcoholicWithdrawalMoodleDescription(
	moodle,
	level,
	descriptionKey,
	dropChance,
	screamChance,
	headPainChance,
	sicknessChance,
	temperatureSwingChance,
	wakeUpChance
)
	local description = getText(
		descriptionKey,
		formatWithdrawalChance(dropChance),
		formatWithdrawalChance(screamChance),
		formatWithdrawalChance(headPainChance),
		formatWithdrawalChance(sicknessChance)
	)
	description = description
		.. getText(
			"Moodles_AlcoholicWithdrawalMoodle_Bad_desc_effects_continued",
			formatWithdrawalChance(temperatureSwingChance),
			tostring(SBvars.AlcoholicWithdrawalTemperatureSwingDurationMinutes),
			formatWithdrawalChance(wakeUpChance)
		)
	moodle:setDescription(2, level, description)
end

---Applies detailed descriptions for every withdrawal stage using current sandbox values.
---@param moodle any
local function setAlcoholicWithdrawalMoodleDescriptions(moodle)
	setAlcoholicWithdrawalMoodleDescription(
		moodle,
		1,
		"Moodles_AlcoholicWithdrawalMoodle_Bad_desc_lvl1",
		SBvars.AlcoholicMildWithdrawalHandItemDropChancePercent,
		SBvars.AlcoholicMildWithdrawalScreamChancePercent,
		SBvars.AlcoholicMildWithdrawalHeadPainChancePercent,
		SBvars.AlcoholicMildWithdrawalSicknessChancePercent,
		SBvars.AlcoholicMildWithdrawalTemperatureSwingChancePercent,
		SBvars.AlcoholicMildWithdrawalWakeUpChancePercent
	)
	setAlcoholicWithdrawalMoodleDescription(
		moodle,
		2,
		"Moodles_AlcoholicWithdrawalMoodle_Bad_desc_lvl2",
		SBvars.AlcoholicModerateWithdrawalHandItemDropChancePercent,
		SBvars.AlcoholicModerateWithdrawalScreamChancePercent,
		SBvars.AlcoholicModerateWithdrawalHeadPainChancePercent,
		SBvars.AlcoholicModerateWithdrawalSicknessChancePercent,
		SBvars.AlcoholicModerateWithdrawalTemperatureSwingChancePercent,
		SBvars.AlcoholicModerateWithdrawalWakeUpChancePercent
	)
	setAlcoholicWithdrawalMoodleDescription(
		moodle,
		3,
		"Moodles_AlcoholicWithdrawalMoodle_Bad_desc_lvl3",
		SBvars.AlcoholicSevereWithdrawalHandItemDropChancePercent,
		SBvars.AlcoholicSevereWithdrawalScreamChancePercent,
		SBvars.AlcoholicSevereWithdrawalHeadPainChancePercent,
		SBvars.AlcoholicSevereWithdrawalSicknessChancePercent,
		SBvars.AlcoholicSevereWithdrawalTemperatureSwingChancePercent,
		SBvars.AlcoholicSevereWithdrawalWakeUpChancePercent
	)
end

---Applies positive moodle descriptions using the player's current intoxication thresholds.
---@param moodle any
---@param withdrawalResetThreshold number
---@param positiveEffectThreshold number
local function setAlcoholicPositiveMoodleDescriptions(moodle, withdrawalResetThreshold, positiveEffectThreshold)
	moodle:setDescription(
		1,
		1,
		getText(
			"Moodles_AlcoholicWithdrawalMoodle_Good_desc_lvl1",
			formatWithdrawalChance(withdrawalResetThreshold),
			formatWithdrawalChance(positiveEffectThreshold)
		)
	)
	moodle:setDescription(
		1,
		2,
		getText(
			"Moodles_AlcoholicWithdrawalMoodle_Good_desc_lvl2",
			formatWithdrawalChance(positiveEffectThreshold)
		)
	)
end

---Updates the local player's Alcoholic withdrawal moodle from synchronized ModData.
local function updateAlcoholicWithdrawalMoodle()
	local player = getPlayer()
	if not player then
		return
	end
	local moodle = MF.getMoodle(ALCOHOLIC_WITHDRAWAL_MOODLE, player:getPlayerNum())
	if not moodle then
		return
	end
	if SBvars.AlcoholicMoodle ~= true or not isMoodleEnabled("EnableAlcoholicMoodle") then
		moodle:setValue(MOODLE_NEUTRAL_VALUE)
		return
	end

	-- Negative: mild = 1, moderate = 2, severe = 3. Positive: withdrawal reset = 1, benefits active = 2.
	moodle:setThresholds(
		nil,
		MOODLE_BAD_3_THRESHOLD,
		MOODLE_BAD_2_THRESHOLD,
		MOODLE_BAD_1_THRESHOLD,
		MOODLE_GOOD_1_VALUE,
		MOODLE_GOOD_2_VALUE,
		nil,
		nil
	)
	setAlcoholicWithdrawalMoodlePictures(moodle)
	setAlcoholicWithdrawalMoodleDescriptions(moodle)
	local previousLevel = moodle:getLevel()
	local previousGoodBadNeutral = moodle:getGoodBadNeutral()
	local withdrawalSeverity = getSyncedWithdrawalSeverity(player)
	local alcoholicTraitStage = getAlcoholicTraitStage(player)
	local intoxication = player:getStats():get(CharacterStat.INTOXICATION)
	local positiveEffectThreshold = SBvars.AlcoholicPositiveEffectBaseIntoxicationPercent
		+ SBvars.AlcoholicPositiveEffectIntoxicationPercentPerStage * alcoholicTraitStage
	local withdrawalResetThreshold = positiveEffectThreshold * SBvars.AlcoholicWithdrawalResetThresholdPercent / 100
	local moodleValue = MOODLE_NEUTRAL_VALUE
	if alcoholicTraitStage > 0 and intoxication >= positiveEffectThreshold then
		moodleValue = MOODLE_GOOD_2_VALUE
	elseif alcoholicTraitStage > 0 and intoxication >= withdrawalResetThreshold then
		moodleValue = MOODLE_GOOD_1_VALUE
	elseif alcoholicTraitStage > 0 and withdrawalSeverity > 0 then
		moodleValue = MOODLE_NEUTRAL_VALUE - withdrawalSeverity / 200
	end
	setAlcoholicPositiveMoodleDescriptions(moodle, withdrawalResetThreshold, positiveEffectThreshold)
	moodle:setValue(moodleValue)
	if previousLevel ~= moodle:getLevel() or previousGoodBadNeutral ~= moodle:getGoodBadNeutral() then
		logETW(
			"ETW Logger | updateAlcoholicWithdrawalMoodle(): severity: "
				.. withdrawalSeverity
				.. "; moodle value: "
				.. moodleValue
				.. "; intoxication: "
				.. intoxication
				.. "; level: "
				.. moodle:getLevel()
		)
	end
end

Events.EveryOneMinute.Remove(updateAlcoholicWithdrawalMoodle)
Events.EveryOneMinute.Add(updateAlcoholicWithdrawalMoodle)

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
