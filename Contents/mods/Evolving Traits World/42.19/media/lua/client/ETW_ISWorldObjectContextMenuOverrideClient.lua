require("ISUI/ISWorldObjectContextMenu")

local ETW_CommonFunctions = require("ETW_CommonFunctions")
local ETW_Registry = require("ETW_Registry")

local FILENAME = "ETW_ISWorldObjectContextMenuOverrideClient.lua"
if
	not ETW_CommonFunctions.gameModeSafeguard(
		FILENAME,
		{ ETW_CommonFunctions.GameMode.SP, ETW_CommonFunctions.GameMode.MP_CLIENT }
	)
then
	return
end

---@type EvolvingTraitsWorldTraitsRegistries
local ETWTraitsRegistry = ETW_Registry.traits
---@type EvolvingTraitsWorldSandboxVars
local SBvars = SandboxVars.EvolvingTraitsWorld
local logETW = ETW_CommonFunctions.log

---@diagnostic disable-next-line: assign-type-mismatch
---@type fun(player: IsoPlayer, bed: IsoObject|nil): string
local original_ISWorldObjectContextMenu_getBedQuality = ISWorldObjectContextMenu.getBedQuality

---Reverses good and poor bed quality for Ascetic, improves bare floors, and makes every pillow-equipped bed poor.
---@param player IsoPlayer
---@param bed IsoObject|nil
---@return string
function ISWorldObjectContextMenu.getBedQuality(player, bed)
	local bedType = original_ISWorldObjectContextMenu_getBedQuality(player, bed)
	if not player:hasTrait(ETWTraitsRegistry.ASCETIC) or SBvars.AsceticSleepEffect == false then
		return bedType
	end

	local asceticBedType = bedType
	if string.find(bedType, "Pillow", 1, true) then
		asceticBedType = "badBedPillow"
	elseif bedType == "badBed" or bedType == "floor" then
		asceticBedType = "goodBed"
	elseif bedType == "goodBed" then
		asceticBedType = "badBed"
	end

	logETW(
		"ETW Logger | ISWorldObjectContextMenu.getBedQuality(): Ascetic resolved bed quality for "
			.. tostring(player:getUsername())
			.. " (OnlineID="
			.. player:getOnlineID()
			.. "); "
			.. bedType
			.. "->"
			.. asceticBedType
	)
	return asceticBedType
end
