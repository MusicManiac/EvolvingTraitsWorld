local ETW_CommonFunctions = require("ETW_CommonFunctions")
local ETWCombinedTraitChecks = require("ETW_CombinedTraitFunctions")

local FILENAME = "ETW_NearbyZombieScanner.lua"
if
	not ETW_CommonFunctions.gameModeSafeguard(
		FILENAME,
		{ ETW_CommonFunctions.GameMode.SP, ETW_CommonFunctions.GameMode.MP_CLIENT }
	)
then
	return
end

local ETW_NearbyZombieScanner = {}

---@class ETWNearbyZombieConsumerDefinition
---@field radius number
---@field isEnabled (fun(player: IsoPlayer): boolean)|nil
---@field beforeScan fun(player: IsoPlayer)|nil
---@field onZombie fun(player: IsoPlayer, zombie: IsoZombie, distanceSquared: number)|nil
---@field afterScan fun(player: IsoPlayer)|nil

---@class ETWNearbyZombieConsumer : ETWNearbyZombieConsumerDefinition
---@field radiusSquared number

---@type table<string, ETWNearbyZombieConsumer>
local consumers = {}
---@type table<integer, ETWNearbyZombieConsumer|nil>
local activeConsumers = {}
local activeConsumerCount = 0
---@type IsoPlayer|nil
local scanPlayer

---Dispatches one nearby zombie to every active consumer whose radius contains it.
---@param zombie IsoZombie
---@param distanceSquared number
local function dispatchNearbyZombie(zombie, distanceSquared)
	for i = 1, activeConsumerCount do
		local consumer = activeConsumers[i]
		---@cast consumer ETWNearbyZombieConsumer
		if distanceSquared <= consumer.radiusSquared and consumer.onZombie then
			local player = scanPlayer
			---@cast player IsoPlayer
			consumer.onZombie(player, zombie, distanceSquared)
		end
	end
end

---Runs one bounded traversal using the largest radius requested by an active consumer.
local function scanNearbyZombies()
	local player = getPlayer()
	if not player or player:isDead() then
		return
	end

	local maximumRadius = 0.0
	local count = 0
	for _, consumer in pairs(consumers) do
		if not consumer.isEnabled or consumer.isEnabled(player) then
			count = count + 1
			activeConsumers[count] = consumer
			if consumer.radius > maximumRadius then
				maximumRadius = consumer.radius
			end
		end
	end
	for i = count + 1, activeConsumerCount do
		activeConsumers[i] = nil
	end
	activeConsumerCount = count
	if count == 0 then
		return
	end

	for i = 1, count do
		local consumer = activeConsumers[i]
		---@cast consumer ETWNearbyZombieConsumer
		local beforeScan = consumer.beforeScan
		if beforeScan then
			beforeScan(player)
		end
	end

	scanPlayer = player
	ETWCombinedTraitChecks.forEachNearbyLivingZombieCachedThisFrame(
		player,
		maximumRadius,
		dispatchNearbyZombie
	)
	scanPlayer = nil

	for i = 1, count do
		local consumer = activeConsumers[i]
		---@cast consumer ETWNearbyZombieConsumer
		local afterScan = consumer.afterScan
		if afterScan then
			afterScan(player)
		end
	end
end

---Registers or replaces one consumer of the shared nearby-zombie traversal.
---@param id string
---@param definition ETWNearbyZombieConsumerDefinition
function ETW_NearbyZombieScanner.register(id, definition)
	local radius = math.max(0, definition.radius or 0)
	definition.radius = radius
	---@cast definition ETWNearbyZombieConsumer
	definition.radiusSquared = radius * radius
	consumers[id] = definition
	Events.OnTick.Remove(scanNearbyZombies)
	Events.OnTick.Add(scanNearbyZombies)
end

---Unregisters one consumer and removes the tick hook when no consumers remain.
---@param id string
function ETW_NearbyZombieScanner.unregister(id)
	consumers[id] = nil
	for _ in pairs(consumers) do
		return
	end
	Events.OnTick.Remove(scanNearbyZombies)
end

return ETW_NearbyZombieScanner
