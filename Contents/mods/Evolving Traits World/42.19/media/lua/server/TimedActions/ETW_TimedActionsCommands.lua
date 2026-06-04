local ETW_CombinedTraitChecks = require("ETW_CombinedTraitChecks")
local ETW_CommonLogicChecks = require("ETW_CommonLogicChecks")
local ETW_TimedActionsSharedLogic = require("TimedActions/ETW_TimedActionsSharedLogic")

---@type ETW_CommonFunctions
local ETW_CommonFunctions = require("ETW_CommonFunctions")

local gameMode = ETW_CommonFunctions.gameMode()
local Commands = {}

local FILENAME = "ETW_TimedActionsCommands.lua"
if not ETW_CommonFunctions.gameModeSafeguard(FILENAME, { ETW_CommonFunctions.GameMode.MP_SERVER }) then
	return
end

---@type fun(...: string)
local logETW = ETW_CommonFunctions.log

---@class ISInventoryTransferActionPerformedArgs
---@field itemsMoved number
---@field weightMoved number

---Function to check by how much engine was repaired. If SP - updates relative moddata and checks traits. If MP - sends command back to client
---@param player IsoPlayer
---@param args ISInventoryTransferActionPerformedArgs
function Commands.ISInventoryTransferActionPerformed(player, args)
	logETW(
		"ETW Logger | ISInventoryTransferActionPerformed(): received from player "
			.. player:getUsername()
			.. ": itemsMoved="
			.. tostring(args.itemsMoved)
			.. ", weightMoved="
			.. tostring(args.weightMoved)
	)
	---@type EvolvingTraitsWorldModData
	local modData = ETW_CommonFunctions.getETWModData(player)
	local transferModData = modData.TransferSystem
	transferModData.ItemsTransferred = transferModData.ItemsTransferred + args.itemsMoved
	transferModData.WeightTransferred =
		ETW_CommonFunctions.round(transferModData.WeightTransferred + args.weightMoved, 2)
	ETW_TimedActionsSharedLogic.checkInventoryTransferPerks(player, modData)
end

---Function responsible for updating trees chopped counter and checking axeman perk
---@param player IsoPlayer
---@param args {}
function Commands.ISChopTreeActionPerformed(player, args)
	logETW("ETW Logger | ISChopTreeActionPerformed(): received from player " .. player:getUsername())
	---@type EvolvingTraitsWorldModData
	local modData = ETW_CommonFunctions.getETWModData(player)
	modData.TreesChopped = modData.TreesChopped + 1
	logETW("ETW Logger | ISChopTreeActionPerformed(): modData.TreesChopped = " .. modData.TreesChopped)
	ETW_TimedActionsSharedLogic.checkAxemanPerk(player, modData)
end

Commands.OnClientCommand = function(module, command, player, args)
	if module == "ETW" and Commands[command] then
		local argStr = ""
		args = args or {}
		for k, v in pairs(args) do
			argStr = argStr .. " " .. k .. "=" .. tostring(v)
		end
		Commands[command](player, args)
	end
end

Events.OnClientCommand.Add(Commands.OnClientCommand)
