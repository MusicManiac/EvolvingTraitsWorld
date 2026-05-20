local ETW_CommonFunctions = require("ETW_CommonFunctions")

local ETW_EagleEyedTracking = {}

---@type fun(...: string)
local logETW = ETW_CommonFunctions.log

local TRACKED_HITS_MAX = 64
local TRACKED_HIT_MAX_AGE_HOURS = 1
local RECENT_COMPLETED_ZOMBIE_IDS_MAX = 64
local RECENT_COMPLETED_ZOMBIE_ID_LIFETIME_MS = 5000

---@type table<string, table<string, {distance:number, timestamp:number}>>
local trackedHitsByPlayer = {}
---@type table<string, number>
local recentCompletedZombieIds = {}

---Returns whether a table contains at least one key.
---@param tbl table|nil
---@return boolean
local function hasEntries(tbl)
	if type(tbl) ~= "table" then
		return false
	end

	for _, _ in pairs(tbl) do
		return true
	end

	return false
end

---Removes expired completed zombie ids and keeps the buffer small.
local function pruneRecentCompletedZombieIds()
	local now = getTimestampMs() or 0
	local keptEntries = {}

	for zombieId, completedAtMs in pairs(recentCompletedZombieIds) do
		if type(completedAtMs) == "number" and now - completedAtMs <= RECENT_COMPLETED_ZOMBIE_ID_LIFETIME_MS then
			keptEntries[#keptEntries + 1] = {
				zombieId = zombieId,
				completedAtMs = completedAtMs,
			}
		else
			recentCompletedZombieIds[zombieId] = nil
		end
	end

	if #keptEntries <= RECENT_COMPLETED_ZOMBIE_IDS_MAX then
		return
	end

	table.sort(keptEntries, function(a, b)
		return a.completedAtMs > b.completedAtMs
	end)

	for i = RECENT_COMPLETED_ZOMBIE_IDS_MAX + 1, #keptEntries do
		recentCompletedZombieIds[keptEntries[i].zombieId] = nil
	end
end

---Returns current world age in hours, or 0 when game time is unavailable.
---@return number
local function getWorldAgeHoursSafe()
	local gameTime = getGameTime and getGameTime() or nil
	if gameTime and gameTime.getWorldAgeHours then
		return gameTime:getWorldAgeHours()
	end
	return 0
end

---Builds a serializable runtime id for a zombie that exists on both client and server.
---@param zombie IsoZombie|nil
---@return string|nil
function ETW_EagleEyedTracking.getZombieTrackingId(zombie)
	if not zombie then
		return nil
	end

	local zombieId = zombie.zombieId
	if type(zombieId) == "number" and zombieId >= 0 then
		return "zombieId:" .. tostring(zombieId)
	end

	local onlineID = zombie.getOnlineID and zombie:getOnlineID() or nil
	if type(onlineID) == "number" and onlineID >= 0 then
		return "online:" .. tostring(onlineID)
	end

	local uid = zombie.getUID and zombie:getUID() or nil
	if type(uid) == "string" and uid ~= "" then
		return "uid:" .. uid
	end

	return nil
end

---Returns a stable player key for runtime tracking.
---@param player IsoPlayer|IsoGameCharacter|nil
---@return string|nil
local function getPlayerTrackingKey(player)
	if not player then
		return nil
	end

	local username = player.getUsername and player:getUsername() or nil
	if type(username) == "string" and username ~= "" then
		return username
	end

	local uid = player.getUID and player:getUID() or nil
	if type(uid) == "string" and uid ~= "" then
		return uid
	end

	return nil
end

---Prunes old or excess entries from a player's tracked hits cache.
---@param playerKey string
local function pruneTrackedHits(playerKey)
	local hits = trackedHitsByPlayer[playerKey]
	if not hits then
		return
	end

	local now = getWorldAgeHoursSafe()
	local count = 0
	local oldestZombieId
	local oldestTimestamp

	for zombieId, entry in pairs(hits) do
		if type(entry) ~= "table" or type(entry.timestamp) ~= "number" then
			hits[zombieId] = nil
		elseif now - entry.timestamp > TRACKED_HIT_MAX_AGE_HOURS then
			hits[zombieId] = nil
		else
			count = count + 1
			if not oldestTimestamp or entry.timestamp < oldestTimestamp then
				oldestTimestamp = entry.timestamp
				oldestZombieId = zombieId
			end
		end
	end

	while count > TRACKED_HITS_MAX and oldestZombieId do
		hits[oldestZombieId] = nil
		count = count - 1

		oldestZombieId = nil
		oldestTimestamp = nil
		for zombieId, entry in pairs(hits) do
			if type(entry) == "table" and type(entry.timestamp) == "number" then
				if not oldestTimestamp or entry.timestamp < oldestTimestamp then
					oldestTimestamp = entry.timestamp
					oldestZombieId = zombieId
				end
			end
		end
	end

	if not hasEntries(hits) then
		trackedHitsByPlayer[playerKey] = nil
	end
end

---Records the most recent hit distance for a zombie/player pair.
---@param player IsoPlayer|IsoGameCharacter|nil
---@param zombieId string|nil
---@param distance number|nil
function ETW_EagleEyedTracking.recordHitById(player, zombieId, distance)
	local playerKey = getPlayerTrackingKey(player)
	if not playerKey or not zombieId or type(distance) ~= "number" then
		return
	end

	trackedHitsByPlayer[playerKey] = trackedHitsByPlayer[playerKey] or {}
	trackedHitsByPlayer[playerKey][zombieId] = {
		distance = distance,
		timestamp = getWorldAgeHoursSafe(),
	}
	pruneTrackedHits(playerKey)
	logETW(
		"ETW Logger | ETW_EagleEyedTracking.recordHitById(): player="
			.. playerKey
			.. " zombieId="
			.. zombieId
			.. " distance="
			.. tostring(distance)
	)
end

---Records a zombie hit directly from the object.
---@param player IsoPlayer|IsoGameCharacter|nil
---@param zombie IsoZombie|nil
---@param distance number|nil
function ETW_EagleEyedTracking.recordHit(player, zombie, distance)
	ETW_EagleEyedTracking.recordHitById(player, ETW_EagleEyedTracking.getZombieTrackingId(zombie), distance)
end

---@param zombieId string|nil
---@return boolean
function ETW_EagleEyedTracking.isRecentCompletedZombieId(zombieId)
	if type(zombieId) ~= "string" then
		return false
	end
	pruneRecentCompletedZombieIds()
	return recentCompletedZombieIds[zombieId] ~= nil
end

---@param zombieId string|nil
function ETW_EagleEyedTracking.markRecentCompletedZombieId(zombieId)
	if type(zombieId) ~= "string" then
		return
	end
	recentCompletedZombieIds[zombieId] = getTimestampMs() or 0
	pruneRecentCompletedZombieIds()
end

function ETW_EagleEyedTracking.pruneRecentCompletedZombieIds()
	pruneRecentCompletedZombieIds()
end

---Consumes a tracked hit by zombie id if it meets the minimum distance.
---@param player IsoPlayer|IsoGameCharacter|nil
---@param zombieId string|nil
---@param minimumDistance number
---@return number|nil
function ETW_EagleEyedTracking.consumeKillById(player, zombieId, minimumDistance)
	local playerKey = getPlayerTrackingKey(player)
	if not playerKey or not zombieId then
		logETW(
			"ETW Logger | ETW_EagleEyedTracking.consumeKillById(): missing key playerKey="
				.. tostring(playerKey)
				.. " zombieId="
				.. tostring(zombieId)
		)
		return nil
	end

	pruneTrackedHits(playerKey)

	local hits = trackedHitsByPlayer[playerKey]
	if not hits then
		logETW(
			"ETW Logger | ETW_EagleEyedTracking.consumeKillById(): no hits table for player="
				.. tostring(playerKey)
				.. " zombieId="
				.. tostring(zombieId)
		)
		return nil
	end

	local entry = hits[zombieId]
	hits[zombieId] = nil
	if not hasEntries(hits) then
		trackedHitsByPlayer[playerKey] = nil
	end

	if type(entry) == "table" and type(entry.distance) == "number" and entry.distance >= minimumDistance then
		logETW(
			"ETW Logger | ETW_EagleEyedTracking.consumeKillById(): player="
				.. playerKey
				.. " zombieId="
				.. zombieId
				.. " distance="
				.. tostring(entry.distance)
		)
		return entry.distance
	end

	logETW(
		"ETW Logger | ETW_EagleEyedTracking.consumeKillById(): unmatched or below threshold player="
			.. tostring(playerKey)
			.. " zombieId="
			.. tostring(zombieId)
			.. " entryDistance="
			.. tostring(entry and entry.distance or nil)
			.. " minimumDistance="
			.. tostring(minimumDistance)
	)

	return nil
end

---Consumes a tracked hit if it matches the zombie and meets the minimum distance.
---@param player IsoPlayer|IsoGameCharacter|nil
---@param zombie IsoZombie|nil
---@param minimumDistance number
---@return number|nil
function ETW_EagleEyedTracking.consumeKill(player, zombie, minimumDistance)
	local zombieId = ETW_EagleEyedTracking.getZombieTrackingId(zombie)
	return ETW_EagleEyedTracking.consumeKillById(player, zombieId, minimumDistance)
end

return ETW_EagleEyedTracking
