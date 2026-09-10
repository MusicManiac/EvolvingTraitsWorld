local ETW_CommonFunctions = require("ETW_CommonFunctions")
local ETW_CommonLogicChecks = require("ETW_CommonLogicChecks")

---@type fun(...: string)
local logETW = ETW_CommonFunctions.log

local FILENAME = "ETW_ByKillsClient.lua"
if not ETW_CommonFunctions.gameModeSafeguard(FILENAME, { ETW_CommonFunctions.GameMode.MP_CLIENT }) then
	return
end

---Builds a serializable runtime id for a zombie.
---@param zombie IsoZombie
---@return string|nil
local function getZombieTrackingId(zombie)
	local onlineID = zombie:getOnlineID()
	if type(onlineID) == "number" and onlineID >= 0 then
		return "online:" .. tostring(onlineID)
	end

	local uid = zombie:getUID()
	if type(uid) == "string" and uid ~= "" then
		return "uid:" .. uid
	end

	return nil
end

---Reports a sufficiently distant Eagle Eyed kill to the server.
---@param zombie IsoZombie
local function eagleEyedKillETW(zombie)
	local localPlayer = getPlayer()
	if not localPlayer or not zombie:isZombie() or zombie:getAttackedBy() ~= localPlayer then
		return
	end
	if not ETW_CommonLogicChecks.EagleEyedShouldExecute(localPlayer) then
		return
	end

	local distance = localPlayer:DistTo(zombie)
	if distance < SandboxVars.EvolvingTraitsWorld.EagleEyedDistance then
		return
	end

	local zombieId = getZombieTrackingId(zombie)
	if not zombieId then
		logETW("ETW Logger | eagleEyedKillETW(): missing zombie tracking id, skipping")
		return
	end

	logETW(
		"ETW Logger | eagleEyedKillETW(): client sending qualifying kill player="
			.. tostring(localPlayer:getUsername())
			.. " zombieId="
			.. tostring(zombieId)
			.. " distance="
			.. tostring(distance)
	)
	sendClientCommand(localPlayer, "ETW", "eagleEyedRecordKill", {
		zombieId = zombieId,
		distance = distance,
	})
end

---Sets up Eagle Eyed kill tracking for the local MP client.
---@param playerIndex number
---@param player IsoPlayer
local function initializeEventsETW(playerIndex, player)
	Events.OnZombieDead.Remove(eagleEyedKillETW)
	if ETW_CommonLogicChecks.EagleEyedShouldExecute(player) then
		Events.OnZombieDead.Add(eagleEyedKillETW)
	end
end

---@param character IsoPlayer
local function clearEventsETW(character)
	Events.OnZombieDead.Remove(eagleEyedKillETW)
	logETW("ETW Logger | System: clearEventsETW in " .. FILENAME)
end

Events.OnCreatePlayer.Remove(initializeEventsETW)
Events.OnCreatePlayer.Add(initializeEventsETW)
Events.OnPlayerDeath.Remove(clearEventsETW)
Events.OnPlayerDeath.Add(clearEventsETW)
