local ETWCombinedTraitChecks = {}

local ETW_CommonFunctions = require("ETW_CommonFunctions")

---@type EvolvingTraitsWorldSandboxVars
local SBvars = SandboxVars.EvolvingTraitsWorld

local ETW_Registry = require("ETW_Registry")
local ETWTraitsRegistry = ETW_Registry.traits

---@type fun(...: string)
local logETW = ETW_CommonFunctions.log

local FILENAME = "ETWCombinedTraitChecks.lua"
ETW_CommonFunctions.gameModeSafeguard(
	FILENAME,
	{ ETW_CommonFunctions.GameMode.SP, ETW_CommonFunctions.GameMode.MP_CLIENT, ETW_CommonFunctions.GameMode.MP_SERVER }
)

---Function responsible for checking if player qualifies for Bodywork Enthusiast trait
---@param player IsoPlayer
function ETWCombinedTraitChecks.bodyworkEnthusiastCheck(player)
	local player = player or getPlayer()
	local modData = ETW_CommonFunctions.getETWModData(player)
	local level = player:getPerkLevel(Perks.MetalWelding) + player:getPerkLevel(Perks.Mechanics)
	if level >= SBvars.BodyworkEnthusiastSkill and modData.VehiclePartRepairs >= SBvars.BodyworkEnthusiastRepairs then
		if
			SBvars.DelayedTraitsSystem
			and not ETW_CommonFunctions.checkIfTraitIsInDelayedTraitsTable(
				player,
				ETWTraitsRegistry.BODYWORK_ENTHUSIAST
			)
		then
			ETW_CommonFunctions.addTraitToDelayTable({
				modData = modData,
				trait = ETWTraitsRegistry.BODYWORK_ENTHUSIAST,
				player = player,
				positiveTrait = true,
				gainingTrait = true,
			})
		elseif
			not SBvars.DelayedTraitsSystem
			or (
				SBvars.DelayedTraitsSystem
				and ETW_CommonFunctions.checkDelayedTraits(player, ETWTraitsRegistry.BODYWORK_ENTHUSIAST)
			)
		then
			ETW_CommonFunctions.addTraitToPlayer({
				player = player,
				trait = ETWTraitsRegistry.BODYWORK_ENTHUSIAST,
				positiveTrait = true,
			})
		end
	end
end

---Function responsible for checking if player qualifies for Mechanics trait
---@param player IsoPlayer
function ETWCombinedTraitChecks.mechanicsCheck(player)
	local player = player or getPlayer()
	local modData = ETW_CommonFunctions.getETWModData(player)
	if
		player:getPerkLevel(Perks.Mechanics) >= SBvars.MechanicsSkill
		and modData.VehiclePartRepairs >= SBvars.MechanicsRepairs
	then
		if
			SBvars.DelayedTraitsSystem
			and not ETW_CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, CharacterTrait.MECHANICS)
		then
			ETW_CommonFunctions.addTraitToDelayTable({
				modData = modData,
				trait = CharacterTrait.MECHANICS,
				player = player,
				positiveTrait = true,
				gainingTrait = true,
			})
		elseif
			not SBvars.DelayedTraitsSystem
			or (SBvars.DelayedTraitsSystem and ETW_CommonFunctions.checkDelayedTraits(player, CharacterTrait.MECHANICS))
		then
			ETW_CommonFunctions.addTraitToPlayer({
				player = player,
				trait = CharacterTrait.MECHANICS,
				positiveTrait = true,
			})
		end
	end
end

---Function responsible for checking if player qualifies for Sewer trait
---@param player IsoPlayer
function ETWCombinedTraitChecks.sewerCheck(player)
	local player = player or getPlayer()
	local modData = ETW_CommonFunctions.getETWModData(player)
	if
		player:getPerkLevel(Perks.Tailoring) >= SBvars.SewerSkill
		and #modData.UniqueClothingRipped >= SBvars.SewerUniqueClothesRipped
	then
		if
			SBvars.DelayedTraitsSystem
			and not ETW_CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, CharacterTrait.TAILOR)
		then
			ETW_CommonFunctions.addTraitToDelayTable({
				modData = modData,
				trait = CharacterTrait.TAILOR,
				player = player,
				positiveTrait = true,
				gainingTrait = true,
			})
		elseif
			not SBvars.DelayedTraitsSystem
			or (SBvars.DelayedTraitsSystem and ETW_CommonFunctions.checkDelayedTraits(player, CharacterTrait.TAILOR))
		then
			ETW_CommonFunctions.addTraitToPlayer({
				player = player,
				trait = CharacterTrait.TAILOR,
				positiveTrait = true,
			})
		end
	end
end

---Adds item name to the table of unique ripped clothes
---@param player IsoPlayer
---@param itemName String
function ETWCombinedTraitChecks.addClothingToUniqueRippedClothingList(player, itemName)
	local modData = ETW_CommonFunctions.getETWModData(player)
	if ETW_CommonFunctions.indexOf(modData.UniqueClothingRipped, itemName) == -1 then
		table.insert(modData.UniqueClothingRipped, itemName)
		ETWCombinedTraitChecks.sewerCheck(player)
	end
end

return ETWCombinedTraitChecks
