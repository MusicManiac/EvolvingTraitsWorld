local ETWCombinedTraitChecks = {}

local ETW_CommonFunctions = require("ETW_CommonFunctions")

---@type EvolvingTraitsWorldSandboxVars
local SBvars = SandboxVars.EvolvingTraitsWorld

local ETWRegistries = require("ETW_Registry")
local ETWTraitsRegistry = ETWRegistries.traits

---Function responsible for checking if player qualifies for Bodywork Enthusiast trait
---@param DebugAndNotificationArgs DebugAndNotificationArgs
function ETWCombinedTraitChecks.bodyworkEnthusiastCheck(DebugAndNotificationArgs)
	local player = getPlayer()
	local modData = ETW_CommonFunctions.getETWModData(player)
	local level = player:getPerkLevel(Perks.MetalWelding) + player:getPerkLevel(Perks.Mechanics)
	if level >= SBvars.BodyworkEnthusiastSkill and modData.VehiclePartRepairs >= SBvars.BodyworkEnthusiastRepairs then
		if
			SBvars.DelayedTraitsSystem
			and not ETW_CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, ETWTraitsRegistry.BODYWORK_ENTHUSIAST)
		then
			ETW_CommonFunctions.addTraitToDelayTable({
				modData = modData,
				trait = ETWTraitsRegistry.BODYWORK_ENTHUSIAST,
				player = player,
				positiveTrait = true,
				gainingTrait = true,
				delayedNotification = DebugAndNotificationArgs.delayedNotification,
			})
		elseif
			not SBvars.DelayedTraitsSystem
			or (SBvars.DelayedTraitsSystem and ETW_CommonFunctions.checkDelayedTraits(player, ETWTraitsRegistry.BODYWORK_ENTHUSIAST))
		then
			ETW_CommonFunctions.addTraitToPlayer(player, ETWTraitsRegistry.BODYWORK_ENTHUSIAST)
			if DebugAndNotificationArgs.notification then
				HaloTextHelper.addTextWithArrow(player, getText("UI_trait_BodyWorkEnthusiast"), true, HaloTextHelper.getColorGreen())
			end
		end
	end
end

---Function responsible for checking if player qualifies for Mechanics trait
---@param DebugAndNotificationArgs DebugAndNotificationArgs
function ETWCombinedTraitChecks.mechanicsCheck(DebugAndNotificationArgs)
	local player = getPlayer()
	local modData = ETW_CommonFunctions.getETWModData(player)
	if player:getPerkLevel(Perks.Mechanics) >= SBvars.MechanicsSkill and modData.VehiclePartRepairs >= SBvars.MechanicsRepairs then
		if SBvars.DelayedTraitsSystem and not ETW_CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, CharacterTrait.MECHANICS) then
			ETW_CommonFunctions.addTraitToDelayTable({
				modData = modData,
				trait = CharacterTrait.MECHANICS,
				player = player,
				positiveTrait = true,
				gainingTrait = true,
				delayedNotification = DebugAndNotificationArgs.delayedNotification,
			})
		elseif
			not SBvars.DelayedTraitsSystem
			or (SBvars.DelayedTraitsSystem and ETW_CommonFunctions.checkDelayedTraits(player, CharacterTrait.MECHANICS))
		then
			ETW_CommonFunctions.addTraitToPlayer(player, CharacterTrait.MECHANICS)
			if DebugAndNotificationArgs.notification then
				HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Mechanics"), true, HaloTextHelper.getColorGreen())
			end
		end
	end
end

---Function responsible for checking if player qualifies for Sewer trait
---@param DebugAndNotificationArgs DebugAndNotificationArgs
function ETWCombinedTraitChecks.sewerCheck(DebugAndNotificationArgs)
	local player = getPlayer()
	local modData = ETW_CommonFunctions.getETWModData(player)
	if player:getPerkLevel(Perks.Tailoring) >= SBvars.SewerSkill and #modData.UniqueClothingRipped >= SBvars.SewerUniqueClothesRipped then
		if SBvars.DelayedTraitsSystem and not ETW_CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, CharacterTrait.TAILOR) then
			ETW_CommonFunctions.addTraitToDelayTable({
				modData = modData,
				trait = CharacterTrait.TAILOR,
				player = player,
				positiveTrait = true,
				gainingTrait = true,
				delayedNotification = DebugAndNotificationArgs.delayedNotification,
			})
		elseif
			not SBvars.DelayedTraitsSystem
			or (SBvars.DelayedTraitsSystem and ETW_CommonFunctions.checkDelayedTraits(player, CharacterTrait.TAILOR))
		then
			ETW_CommonFunctions.addTraitToPlayer(player, CharacterTrait.TAILOR)
			if DebugAndNotificationArgs.notification then
				HaloTextHelper.addTextWithArrow(player, getText("UI_trait_Tailor"), true, HaloTextHelper.getColorGreen())
			end
		end
	end
end

---Adds item name to the table of unique ripped clothes
---@param player IsoPlayer
---@param item Clothing
---@param DebugAndNotificationArgs DebugAndNotificationArgs
function ETWCombinedTraitChecks.addClothingToUniqueRippedClothingList(player, item, DebugAndNotificationArgs)
	local itemName = item:getName()
	local modData = ETW_CommonFunctions.getETWModData(player)
	if DebugAndNotificationArgs.detailedDebug then
		print("ETW Logger | ETW_CommonFunctions.addClothingToUniqueRippedClothingList() item: " .. itemName)
	end
	if ETW_CommonFunctions.indexOf(modData.UniqueClothingRipped, itemName) == -1 then
		table.insert(modData.UniqueClothingRipped, itemName)
		ETWCombinedTraitChecks.sewerCheck(DebugAndNotificationArgs)
	end
end

return ETWCombinedTraitChecks
