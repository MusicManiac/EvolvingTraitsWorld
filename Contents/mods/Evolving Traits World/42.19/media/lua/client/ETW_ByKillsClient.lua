local ETW_CommonFunctions = require("ETW_CommonFunctions")
local ETW_CommonLogicChecks = require("ETW_CommonLogicChecks")
local ETW_EagleEyedTracking = require("ETW_EagleEyedTracking")

---@type fun(...: string)
local logETW = ETW_CommonFunctions.log

local FILENAME = "ETW_ByKillsClient.lua"
if not ETW_CommonFunctions.gameModeSafeguard(FILENAME, { ETW_CommonFunctions.GameMode.MP_CLIENT }) then
	return
end

---Tracks the most recent hit distance client-side and forwards it to the server.
---@param zombie IsoZombie
---@param attacker IsoGameCharacter
---@param bodyPart BodyPartType
---@param weapon HandWeapon
local function eagleEyedTrackHitETW(zombie, attacker, bodyPart, weapon)
	local localPlayer = getPlayer()
	if not localPlayer or attacker ~= localPlayer or not zombie:isZombie() then
		return
	end
	if not ETW_CommonLogicChecks.EagleEyedShouldExecute(localPlayer) then
		return
	end

	local distance = localPlayer:DistTo(zombie)
	local zombieId = ETW_EagleEyedTracking.getZombieTrackingId(zombie)
	if not zombieId then
		logETW("ETW Logger | eagleEyedTrackHitETW(): missing zombie tracking id, skipping")
		return
	end

	logETW(
		"ETW Logger | eagleEyedTrackHitETW(): client sending player="
			.. tostring(localPlayer:getUsername())
			.. " zombieId="
			.. tostring(zombieId)
			.. " distance="
			.. tostring(distance)
	)
	ETW_EagleEyedTracking.recordHitById(localPlayer, zombieId, distance)
	sendClientCommand(localPlayer, "ETW", "eagleEyedRecordHit", {
		zombieId = zombieId,
		distance = distance,
	})
end

---Sets up Eagle Eyed hit tracking for the local MP client.
---@param playerIndex number
---@param player IsoPlayer
local function initializeEventsETW(playerIndex, player)
	Events.OnHitZombie.Remove(eagleEyedTrackHitETW)
	if ETW_CommonLogicChecks.EagleEyedShouldExecute(player) then
		Events.OnHitZombie.Add(eagleEyedTrackHitETW)
	end
end

---@param character IsoPlayer
local function clearEventsETW(character)
	Events.OnHitZombie.Remove(eagleEyedTrackHitETW)
	logETW("ETW Logger | System: clearEventsETW in " .. FILENAME)
end

Events.OnCreatePlayer.Remove(initializeEventsETW)
Events.OnCreatePlayer.Add(initializeEventsETW)
Events.OnPlayerDeath.Remove(clearEventsETW)
Events.OnPlayerDeath.Add(clearEventsETW)
