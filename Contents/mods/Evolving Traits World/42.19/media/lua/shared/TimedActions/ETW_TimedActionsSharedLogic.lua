local ETW_TimedActionsSharedLogic = {}

---@type EvolvingTraitsWorldSandboxVars
local SBvars = SandboxVars.EvolvingTraitsWorld

local ETW_CommonFunctions = require("ETW_CommonFunctions")
local ETW_Registry = require("ETW_Registry")
local ETWTraitsRegistry = ETW_Registry.traits

---Returns true when an eat action is consuming food rather than a drink or smokable.
---@param action ISEatFoodAction
---@return boolean
function ETW_TimedActionsSharedLogic.isFoodEatingAction(action)
	local item = action.item
	return item ~= nil
		and item:getCustomMenuOption() ~= getText("ContextMenu_Drink")
		and not item:hasTag(ItemTag.SMOKABLE)
end

---Removes Slow Eater and adds Fast Eater when the Eating Speed System thresholds are reached.
---@param player IsoPlayer
---@param modData EvolvingTraitsWorldModData
function ETW_TimedActionsSharedLogic.checkEatingSpeedTraits(player, modData)
	local counter = modData.MinutesSpentEating or 0
	local target = SBvars.EatingSpeedSystemMinutes or 60
	if
		player:hasTrait(ETWTraitsRegistry.SLOW_EATER)
		and counter >= target / 2
		and SBvars.TraitsLockSystemCanLoseNegative
	then
		if
			SBvars.DelayedTraitsSystem
			and not ETW_CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, ETWTraitsRegistry.SLOW_EATER)
		then
			ETW_CommonFunctions.addTraitToDelayTable({
				modData = modData,
				trait = ETWTraitsRegistry.SLOW_EATER,
				player = player,
				positiveTrait = false,
				gainingTrait = false,
			})
		elseif
			not SBvars.DelayedTraitsSystem
			or (
				SBvars.DelayedTraitsSystem
					and ETW_CommonFunctions.checkDelayedTraits(player, ETWTraitsRegistry.SLOW_EATER)
			)
		then
			ETW_CommonFunctions.removeTraitFromPlayer({
				player = player,
				trait = ETWTraitsRegistry.SLOW_EATER,
				positiveTrait = false,
			})
		end
	elseif
		not player:hasTrait(ETWTraitsRegistry.SLOW_EATER)
		and not player:hasTrait(ETWTraitsRegistry.FAST_EATER)
		and counter >= target
		and SBvars.TraitsLockSystemCanGainPositive
	then
		if
			SBvars.DelayedTraitsSystem
			and not ETW_CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, ETWTraitsRegistry.FAST_EATER)
		then
			ETW_CommonFunctions.addTraitToDelayTable({
				modData = modData,
				trait = ETWTraitsRegistry.FAST_EATER,
				player = player,
				positiveTrait = true,
				gainingTrait = true,
			})
		elseif
			not SBvars.DelayedTraitsSystem
			or (
				SBvars.DelayedTraitsSystem
					and ETW_CommonFunctions.checkDelayedTraits(player, ETWTraitsRegistry.FAST_EATER)
			)
		then
			ETW_CommonFunctions.addTraitToPlayer({
				player = player,
				trait = ETWTraitsRegistry.FAST_EATER,
				positiveTrait = true,
			})
		end
	end
end

---Checks if player qualifies for gaining or losing innventory transfer system perks
---@param player IsoPlayer player
---@param modData EvolvingTraitsWorldModData ETW modData table
function ETW_TimedActionsSharedLogic.checkInventoryTransferPerks(player, modData)
	local transferModData = modData.TransferSystem
	if
		player:hasTrait(CharacterTrait.DISORGANIZED)
		and transferModData.WeightTransferred >= SBvars.InventoryTransferSystemWeight * 0.66
		and transferModData.ItemsTransferred >= SBvars.InventoryTransferSystemItems * 0.33
		and SBvars.TraitsLockSystemCanLoseNegative
	then
		if
			SBvars.DelayedTraitsSystem
			and not ETW_CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, CharacterTrait.DISORGANIZED)
		then
			ETW_CommonFunctions.addTraitToDelayTable({
				modData = modData,
				trait = CharacterTrait.DISORGANIZED,
				player = player,
				positiveTrait = false,
				gainingTrait = false,
			})
		elseif
			not SBvars.DelayedTraitsSystem
			or (
				SBvars.DelayedTraitsSystem
				and ETW_CommonFunctions.checkDelayedTraits(player, CharacterTrait.DISORGANIZED)
			)
		then
			ETW_CommonFunctions.removeTraitFromPlayer({
				player = player,
				trait = CharacterTrait.DISORGANIZED,
				positiveTrait = false,
			})
		end
	end
	if
		not player:hasTrait(CharacterTrait.DISORGANIZED)
		and not player:hasTrait(CharacterTrait.ORGANIZED)
		and transferModData.WeightTransferred >= SBvars.InventoryTransferSystemWeight
		and transferModData.ItemsTransferred >= SBvars.InventoryTransferSystemItems * 0.66
		and SBvars.TraitsLockSystemCanGainPositive
	then
		if
			SBvars.DelayedTraitsSystem
			and not ETW_CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, CharacterTrait.ORGANIZED)
		then
			ETW_CommonFunctions.addTraitToDelayTable({
				modData = modData,
				trait = CharacterTrait.ORGANIZED,
				player = player,
				positiveTrait = true,
				gainingTrait = true,
			})
		elseif
			not SBvars.DelayedTraitsSystem
			or (SBvars.DelayedTraitsSystem and ETW_CommonFunctions.checkDelayedTraits(player, CharacterTrait.ORGANIZED))
		then
			ETW_CommonFunctions.addTraitToPlayer({
				player = player,
				trait = CharacterTrait.ORGANIZED,
				positiveTrait = true,
			})
		end
	end
	if
		player:hasTrait(CharacterTrait.ALL_THUMBS)
		and transferModData.WeightTransferred >= SBvars.InventoryTransferSystemWeight * 0.33
		and transferModData.ItemsTransferred >= SBvars.InventoryTransferSystemItems * 0.66
		and SBvars.TraitsLockSystemCanLoseNegative
	then
		if
			SBvars.DelayedTraitsSystem
			and not ETW_CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, CharacterTrait.ALL_THUMBS)
		then
			ETW_CommonFunctions.addTraitToDelayTable({
				modData = modData,
				trait = CharacterTrait.ALL_THUMBS,
				player = player,
				positiveTrait = false,
				gainingTrait = false,
			})
		elseif
			not SBvars.DelayedTraitsSystem
			or (
				SBvars.DelayedTraitsSystem
				and ETW_CommonFunctions.checkDelayedTraits(player, CharacterTrait.ALL_THUMBS)
			)
		then
			ETW_CommonFunctions.removeTraitFromPlayer({
				player = player,
				trait = CharacterTrait.ALL_THUMBS,
				positiveTrait = false,
			})
		end
	end
	if
		not player:hasTrait(CharacterTrait.DEXTROUS)
		and transferModData.WeightTransferred >= SBvars.InventoryTransferSystemWeight * 0.66
		and transferModData.ItemsTransferred >= SBvars.InventoryTransferSystemItems
		and SBvars.TraitsLockSystemCanGainPositive
	then
		if
			SBvars.DelayedTraitsSystem
			and not ETW_CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, CharacterTrait.DEXTROUS)
		then
			ETW_CommonFunctions.addTraitToDelayTable({
				modData = modData,
				trait = CharacterTrait.DEXTROUS,
				player = player,
				positiveTrait = true,
				gainingTrait = true,
			})
		elseif
			not SBvars.DelayedTraitsSystem
			or (SBvars.DelayedTraitsSystem and ETW_CommonFunctions.checkDelayedTraits(player, CharacterTrait.DEXTROUS))
		then
			ETW_CommonFunctions.addTraitToPlayer({
				player = player,
				trait = CharacterTrait.DEXTROUS,
				positiveTrait = true,
			})
		end
	end
end

return ETW_TimedActionsSharedLogic
