local ETW_CommonFunctions = require("ETW_CommonFunctions")
local ETW_CommonLogicChecks = require("ETW_CommonLogicChecks")
local ETW_Registry = require("ETW_Registry")
local ETW_TimedActionsSharedLogic = require("TimedActions/ETW_TimedActionsSharedLogic")

local gameMode = ETW_CommonFunctions.gameMode()
local FILENAME = "ETW_ISInventoryTransferActionOverrideClient.lua"
if
	not ETW_CommonFunctions.gameModeSafeguard(
		FILENAME,
		{ ETW_CommonFunctions.GameMode.SP, ETW_CommonFunctions.GameMode.MP_CLIENT }
	)
then
	return
end

---@type fun(...: string)
local logETW = ETW_CommonFunctions.log
---@type EvolvingTraitsWorldTraitsRegistries
local ETWTraitsRegistry = ETW_Registry.traits
---@type EvolvingTraitsWorldSandboxVars
local SBvars = SandboxVars.EvolvingTraitsWorld
local random_instance = newrandom()

---@class PendingButterfingersDrop
---@field character IsoPlayer
---@field itemId integer
---@field itemType string
---@field sourceContainer ItemContainer
---@field queuedAt number

---@type PendingButterfingersDrop[]
local pendingButterfingersDrops = {}

---Waits for MP inventory synchronization before queuing a triggered Butterfingers ground transfer.
local function processPendingButterfingersDrops()
	local now = getTimestampMs()
	for i = #pendingButterfingersDrops, 1, -1 do
		local pendingDrop = pendingButterfingersDrops[i]
		---@cast pendingDrop PendingButterfingersDrop
		local item = pendingDrop.sourceContainer:getItemById(pendingDrop.itemId)
		if item then
			local floorContainer = ISInventoryPage.GetFloorContainer(pendingDrop.character:getPlayerNum())
			ISTimedActionQueue.add(
				ISInventoryTransferAction:new(
					pendingDrop.character,
					item,
					pendingDrop.sourceContainer,
					floorContainer,
					0
				)
			)
			ETW_CommonFunctions.displayButterfingersPopup(pendingDrop.character)
			logETW(
				"ETW Logger | processPendingButterfingersDrops(): destination synchronized; queued "
					.. pendingDrop.itemType
					.. " to drop on the ground"
			)
			table.remove(pendingButterfingersDrops, i)
		elseif now - pendingDrop.queuedAt >= 10000 then
			logETW(
				"ETW Logger | processPendingButterfingersDrops(): timed out waiting for "
					.. pendingDrop.itemType
					.. " to synchronize into the destination container"
			)
			table.remove(pendingButterfingersDrops, i)
		end
	end
	if #pendingButterfingersDrops == 0 then
		Events.OnTick.Remove(processPendingButterfingersDrops)
	end
end

local original_ISInventoryTransferAction_playTransferCompleteSound =
	ISInventoryTransferAction.playTransferCompleteSound
---Adds Butterfingers' independent per-item chance to drop a successfully transferred item on the ground.
---@param item InventoryItem
function ISInventoryTransferAction:playTransferCompleteSound(item)
	original_ISInventoryTransferAction_playTransferCompleteSound(self, item)
	if
		self.character ~= getPlayer()
		or not self.character:hasTrait(ETWTraitsRegistry.BUTTERFINGERS)
		or self.destContainer:getType() == "floor"
	then
		return
	end

	local chance = PZMath.clamp(SBvars.ButterfingersTransferDropChance or 5, 0, 100)
	if chance <= 0 then
		return
	end
	local roll = random_instance:random(1, 100)
	logETW(
		"ETW Logger | ISInventoryTransferAction.playTransferCompleteSound(): Butterfingers present",
		"ETW Logger | ISInventoryTransferAction.playTransferCompleteSound(): transfer drop roll "
			.. roll
			.. "/100 against "
			.. chance
			.. "% for "
			.. item:getFullType()
	)
	if roll > chance then
		return
	end

	if #pendingButterfingersDrops == 0 then
		Events.OnTick.Remove(processPendingButterfingersDrops)
		Events.OnTick.Add(processPendingButterfingersDrops)
	end
	table.insert(pendingButterfingersDrops, {
		character = self.character,
		itemId = item:getID(),
		itemType = item:getFullType(),
		sourceContainer = self.destContainer,
		queuedAt = getTimestampMs(),
	})
	logETW(
		"ETW Logger | ISInventoryTransferAction.playTransferCompleteSound(): Butterfingers triggered; waiting for "
			.. item:getFullType()
			.. " to synchronize into the destination container"
	)
end

local original_ISInventoryTransferAction_perform = ISInventoryTransferAction.perform
---Overwriting ISInventoryTransferAction:perform() here to insert ETW logic catching player transferring items
function ISInventoryTransferAction:perform()
	if ETW_CommonLogicChecks.InventoryTransferSystemShouldExecute(self.character) and self.character == getPlayer() then
		local item = self.item
		---@cast item InventoryItem
		local itemWeight = math.max(0, item:getWeight())
		if gameMode == ETW_CommonFunctions.GameMode.SP then
			local modData = ETW_CommonFunctions.getETWModData(self.character)
			---@cast modData EvolvingTraitsWorldModData
			local transferModData = modData.TransferSystem
			local initialItemsTransferred = transferModData.ItemsTransferred
			local initialWeightTransferred = transferModData.WeightTransferred
			transferModData.ItemsTransferred = transferModData.ItemsTransferred + 1
			transferModData.WeightTransferred = transferModData.WeightTransferred + itemWeight
			logETW(
				"ETW Logger | ISInventoryTransferAction:perform(): "
					.. ": itemsMoved="
					.. tostring(1)
					.. ", weightMoved="
					.. tostring(itemWeight)
					.. "ItemsTransferred="
					.. tostring(initialItemsTransferred)
					.. "->"
					.. tostring(transferModData.ItemsTransferred)
					.. ", WeightTransferred="
					.. tostring(initialWeightTransferred)
					.. "->"
					.. tostring(transferModData.WeightTransferred)
			)
			ETW_TimedActionsSharedLogic.checkInventoryTransferPerks(self.character, modData)
		elseif gameMode == ETW_CommonFunctions.GameMode.MP_CLIENT then
			---@type ISInventoryTransferActionPerformedArgs
			local args = {
				itemsMoved = 1,
				weightMoved = itemWeight,
			}
			logETW(
				"ETW Logger | ISInventoryTransferAction.perform(): Moving an item with weight of " .. itemWeight,
				"ETW Logger | ISInventoryTransferAction.perform(): Sending command to server"
			)
			sendClientCommand(self.character, "ETW", "ISInventoryTransferActionPerformed", args)
		end
	else
		logETW("ETW Logger | ISInventoryTransferAction.perform(): not a player or not running ITS")
	end
	original_ISInventoryTransferAction_perform(self)
end
