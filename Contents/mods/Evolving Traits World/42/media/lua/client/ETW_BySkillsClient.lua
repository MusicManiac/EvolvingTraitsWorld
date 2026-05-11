local ETW_CommonFunctions = require("ETW_CommonFunctions")

local gameMode = ETW_CommonFunctions.gameMode()

local FILENAME = "ETW_BySkillsClient.lua"
if not ETW_CommonFunctions.gameModeSafeguard(FILENAME, { ETW_CommonFunctions.GameMode.MP_CLIENT }) then
	return
end

---@type fun(...: string)
local logETW = ETW_CommonFunctions.log

local lastLeveledPerk = nil

local function sendTraitLevelUpEventToServer()
	if lastLeveledPerk then
		local perkName = tostring(lastLeveledPerk:getName())
		logETW("ETW Logger | sendTraitLevelUpEventToServer called for perk " .. perkName)
		sendClientCommand(getPlayer(), "ETW", "fireLevelPerkEventOnServer", { perkName = perkName })
		lastLeveledPerk = nil
		Events.OnTick.Remove(sendTraitLevelUpEventToServer)
	end
end

local function sendTraitLevelUpEventToServerWithDelay(player, perk, level, increased)
	lastLeveledPerk = perk
	logETW(
		"ETW Logger | sendTraitLevelUpEventToServerWithDelay received for perk "
			.. tostring(perk:getName())
			.. " at level "
			.. tostring(level)
	)
	Events.OnTick.Add(sendTraitLevelUpEventToServer)
end

Events.LevelPerk.Remove(sendTraitLevelUpEventToServerWithDelay)
Events.LevelPerk.Add(sendTraitLevelUpEventToServerWithDelay)
