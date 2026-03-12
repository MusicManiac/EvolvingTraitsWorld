local ETWCombinedTraitChecks = {}

local ETWCommonFunctions = require("ETWCommonFunctions")

---@type EvolvingTraitsWorldSandboxVars
local SBvars = SandboxVars.EvolvingTraitsWorld

---@type EvolvingTraitsWorldRegistries
local ETWRegistries = require("ETWRegistry")
---@type EvolvingTraitsWorldTraitsRegistries
local ETWTraitsRegistry = ETWRegistries.traits

-- local modOptions

-- ---@return boolean
-- local notification = function() return modOptions:getOption("EnableNotifications"):getValue() end
-- ---@return boolean
-- local delayedNotification = function() return modOptions:getOption("EnableDelayedNotifications"):getValue() end
-- ---@return boolean
-- local detailedDebug = function() return modOptions:getOption("GatherDetailedDebug"):getValue() end

---Function responsible for checking if player qualifies for Bodywork Enthusiast trait
---@param DebugAndNotificationArgs DebugAndNotificationArgs
function ETWCombinedTraitChecks.bodyworkEnthusiastCheck(DebugAndNotificationArgs)
	local player = getPlayer()
	local modData = ETWCommonFunctions.getETWModData(player)
	local level = player:getPerkLevel(Perks.MetalWelding) + player:getPerkLevel(Perks.Mechanics)
	if level >= SBvars.BodyworkEnthusiastSkill and modData.VehiclePartRepairs >= SBvars.BodyworkEnthusiastRepairs then
		if
			SBvars.DelayedTraitsSystem
			and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable(ETWTraitsRegistry.BODY_WORK_ENTHUSIAST)
		then
			ETWCommonFunctions.addTraitToDelayTable({
				modData = modData,
				trait = ETWTraitsRegistry.BODY_WORK_ENTHUSIAST,
				player = player,
				positiveTrait = true,
				gainingTrait = true,
				delayedNotification = DebugAndNotificationArgs.delayedNotification,
			})
		elseif
			not SBvars.DelayedTraitsSystem
			or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits(ETWTraitsRegistry.BODY_WORK_ENTHUSIAST))
		then
			ETWCommonFunctions.addTraitToPlayer(ETWTraitsRegistry.BODY_WORK_ENTHUSIAST)
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
	local modData = ETWCommonFunctions.getETWModData(player)
	if player:getPerkLevel(Perks.Mechanics) >= SBvars.MechanicsSkill and modData.VehiclePartRepairs >= SBvars.MechanicsRepairs then
		if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable(CharacterTrait.MECHANICS) then
			ETWCommonFunctions.addTraitToDelayTable({
				modData = modData,
				trait = CharacterTrait.MECHANICS,
				player = player,
				positiveTrait = true,
				gainingTrait = true,
				delayedNotification = DebugAndNotificationArgs.delayedNotification,
			})
		elseif
			not SBvars.DelayedTraitsSystem
			or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits(CharacterTrait.MECHANICS))
		then
			ETWCommonFunctions.addTraitToPlayer(CharacterTrait.MECHANICS)
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
	local modData = ETWCommonFunctions.getETWModData(player)
	if player:getPerkLevel(Perks.Tailoring) >= SBvars.SewerSkill and #modData.UniqueClothingRipped >= SBvars.SewerUniqueClothesRipped then
		if SBvars.DelayedTraitsSystem and not ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable(CharacterTrait.TAILOR) then
			ETWCommonFunctions.addTraitToDelayTable({
				modData = modData,
				trait = CharacterTrait.TAILOR,
				player = player,
				positiveTrait = true,
				gainingTrait = true,
				delayedNotification = DebugAndNotificationArgs.delayedNotification,
			})
		elseif
			not SBvars.DelayedTraitsSystem or (SBvars.DelayedTraitsSystem and ETWCommonFunctions.checkDelayedTraits(CharacterTrait.TAILOR))
		then
			ETWCommonFunctions.addTraitToPlayer(CharacterTrait.TAILOR)
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
	local modData = ETWCommonFunctions.getETWModData(player)
	if DebugAndNotificationArgs.detailedDebug then
		print("ETW Logger | ETWCommonFunctions.addClothingToUniqueRippedClothingList() item: " .. itemName)
	end
	if ETWCommonFunctions.indexOf(modData.UniqueClothingRipped, itemName) == -1 then
		table.insert(modData.UniqueClothingRipped, itemName)
		ETWCombinedTraitChecks.sewerCheck(DebugAndNotificationArgs)
	end
end

return ETWCombinedTraitChecks
