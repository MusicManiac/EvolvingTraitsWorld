local ETW_TimedActionsSharedLogic = {}

---@type EvolvingTraitsWorldSandboxVars
local SBvars = SandboxVars.EvolvingTraitsWorld

local ETW_CommonFunctions = require("ETW_CommonFunctions")
local ETW_Registry = require("ETW_Registry")
local ETWTraitsRegistry = ETW_Registry.traits

---Checks if player qualifies for gaining or losing inventory transfer system perks
---@param player IsoPlayer player
---@param modData EvolvingTraitsWorldModData ETW modData table
function ETW_TimedActionsSharedLogic.checkInventoryTransferPerks(player, modData)
	local transferModData = modData.TransferSystem
	if
		player:hasTrait(ETWTraitsRegistry.BUTTERFINGERS)
		and transferModData.WeightTransferred >= SBvars.InventoryTransferSystemWeight * 1.5
		and transferModData.ItemsTransferred >= SBvars.InventoryTransferSystemItems * 1.5
		and SBvars.TraitsLockSystemCanLoseNegative
	then
		ETW_CommonFunctions.processTraitChange({
			modData = modData,
			trait = ETWTraitsRegistry.BUTTERFINGERS,
			player = player,
			positiveTrait = false,
			gainingTrait = false,
		})
	end
	if
		player:hasTrait(CharacterTrait.DISORGANIZED)
		and transferModData.WeightTransferred >= SBvars.InventoryTransferSystemWeight * 0.66
		and transferModData.ItemsTransferred >= SBvars.InventoryTransferSystemItems * 0.33
		and SBvars.TraitsLockSystemCanLoseNegative
	then
		ETW_CommonFunctions.processTraitChange({
			modData = modData,
			trait = CharacterTrait.DISORGANIZED,
			player = player,
			positiveTrait = false,
			gainingTrait = false,
		})
	end
	if
		not player:hasTrait(CharacterTrait.DISORGANIZED)
		and not player:hasTrait(CharacterTrait.ORGANIZED)
		and transferModData.WeightTransferred >= SBvars.InventoryTransferSystemWeight
		and transferModData.ItemsTransferred >= SBvars.InventoryTransferSystemItems * 0.66
		and SBvars.TraitsLockSystemCanGainPositive
	then
		ETW_CommonFunctions.processTraitChange({
			modData = modData,
			trait = CharacterTrait.ORGANIZED,
			player = player,
			positiveTrait = true,
			gainingTrait = true,
		})
	end
	if
		player:hasTrait(CharacterTrait.ALL_THUMBS)
		and transferModData.WeightTransferred >= SBvars.InventoryTransferSystemWeight * 0.33
		and transferModData.ItemsTransferred >= SBvars.InventoryTransferSystemItems * 0.66
		and SBvars.TraitsLockSystemCanLoseNegative
	then
		ETW_CommonFunctions.processTraitChange({
			modData = modData,
			trait = CharacterTrait.ALL_THUMBS,
			player = player,
			positiveTrait = false,
			gainingTrait = false,
		})
	end
	if
		not player:hasTrait(CharacterTrait.DEXTROUS)
		and transferModData.WeightTransferred >= SBvars.InventoryTransferSystemWeight * 0.66
		and transferModData.ItemsTransferred >= SBvars.InventoryTransferSystemItems
		and SBvars.TraitsLockSystemCanGainPositive
	then
		ETW_CommonFunctions.processTraitChange({
			modData = modData,
			trait = CharacterTrait.DEXTROUS,
			player = player,
			positiveTrait = true,
			gainingTrait = true,
		})
	end
end

return ETW_TimedActionsSharedLogic
