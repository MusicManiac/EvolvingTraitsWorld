local ETW_CommonFunctions = require("ETW_CommonFunctions")
local ETW_CommonLogicChecks = require("ETW_CommonLogicChecks")
local ETW_TimedActionsSharedLogic = require("TimedActions/ETW_TimedActionsSharedLogic")

local gameMode = ETW_CommonFunctions.gameMode()
local FILENAME = "ETW_ActionsOverrideClient.lua"
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

local original_ISInventoryTransferAction_perform = ISInventoryTransferAction.perform
---Overwriting ISInventoryTransferAction:perform() here to insert ETW logic catching player transferring items
function ISInventoryTransferAction:perform()
	if ETW_CommonLogicChecks.InventoryTransferSystemShouldExecute(self.character) and self.character == getPlayer() then
		local itemWeight = math.max(0, self.item:getWeight())
		if gameMode == ETW_CommonFunctions.GameMode.SP then
			local modData = ETW_CommonFunctions.getETWModData(self.character)
			local transferModData = modData.TransferSystem
			transferModData.ItemsTransferred = transferModData.ItemsTransferred + 1
			transferModData.WeightTransferred =
				ETW_CommonFunctions.round(transferModData.WeightTransferred + itemWeight, 2)
			logETW(
				"ETW Logger | ISInventoryTransferAction.perform(): Moving an item with weight of " .. itemWeight,
				"ETW Logger | ISInventoryTransferAction.perform(): Moved weight: "
					.. transferModData.WeightTransferred
					.. ", Moved Items: "
					.. transferModData.ItemsTransferred
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
