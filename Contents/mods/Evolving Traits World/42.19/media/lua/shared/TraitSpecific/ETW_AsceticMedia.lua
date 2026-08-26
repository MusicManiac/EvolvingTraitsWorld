require("RadioCom/ISRadioInteractions")

local ETW_CommonFunctions = require("ETW_CommonFunctions")
local ETW_Registry = require("ETW_Registry")

local FILENAME = "TraitSpecific/ETW_AsceticMedia.lua"
if
	not ETW_CommonFunctions.gameModeSafeguard(
		FILENAME,
		{
			ETW_CommonFunctions.GameMode.SP,
			ETW_CommonFunctions.GameMode.MP_CLIENT,
			ETW_CommonFunctions.GameMode.MP_SERVER,
		}
	)
then
	return
end

---@type EvolvingTraitsWorldTraitsRegistries
local ETWTraitsRegistry = ETW_Registry.traits
---@type EvolvingTraitsWorldSandboxVars
local SBvars = SandboxVars.EvolvingTraitsWorld
local logETW = ETW_CommonFunctions.log
local gameMode = ETW_CommonFunctions.gameMode()

---@param x number
---@param y number
---@param z number
---@return boolean
local function isTelevisionSource(x, y, z)
	if x == -1 and y == -1 and z == -1 then
		return false
	end
	local square = getCell():getGridSquare(x, y, z)
	if not square then
		return false
	end
	local objects = square:getObjects()
	for i = 0, objects:size() - 1 do
		if instanceof(objects:get(i), "IsoTelevision") then
			return true
		end
	end
	return false
end

---@param player IsoPlayer
---@param interactionCode string
---@return boolean
local function isBeneficialMoodCode(player, interactionCode)
	if interactionCode:len() <= 4 then
		return false
	end
	local code = string.sub(interactionCode, 1, 3)
	local stat
	if code == "BOR" then
		stat = CharacterStat.BOREDOM
	elseif code == "UHP" then
		stat = CharacterStat.UNHAPPINESS
	else
		return false
	end

	local operator = string.sub(interactionCode, 4, 4)
	local amount = tonumber(string.sub(interactionCode, 5))
	if not amount then
		return false
	end
	if operator == "=" then
		return amount < player:getStats():get(stat)
	end
	if operator == "-" then
		amount = -amount
	end
	return amount < 0
end

---@param player IsoPlayer
---@param interactionCodes string
---@return string filteredCodes
---@return string suppressedCodes
local function suppressTelevisionMoodBenefits(player, interactionCodes)
	local filtered = {}
	local suppressed = {}
	for interactionCode in string.gmatch(interactionCodes, "[^,]+") do
		if isBeneficialMoodCode(player, interactionCode) then
			table.insert(suppressed, interactionCode)
		else
			table.insert(filtered, interactionCode)
		end
	end
	return table.concat(filtered, ","), table.concat(suppressed, ",")
end

local radioInteractions = ISRadioInteractions:getInstance()
local original_ISRadioInteractions_checkPlayer = radioInteractions.checkPlayer

---Prevents television broadcasts from relieving an Ascetic's boredom or unhappiness.
---@param player IsoPlayer
---@param guid string
---@param interactionCodes string
---@param x number
---@param y number
---@param z number
---@param line string
---@param source unknown
function radioInteractions.checkPlayer(player, guid, interactionCodes, x, y, z, line, source)
	if
		SBvars.AsceticTelevisionEffect ~= false
		and player:hasTrait(ETWTraitsRegistry.ASCETIC)
		and interactionCodes
		and interactionCodes:len() > 0
		and isTelevisionSource(x, y, z)
	then
		local filteredCodes, suppressedCodes = suppressTelevisionMoodBenefits(player, interactionCodes)
		if suppressedCodes ~= "" then
			logETW(
				"ETW Logger | Ascetic television "
					.. gameMode
					.. ": suppressed mood benefits for "
					.. tostring(player:getUsername())
					.. " (OnlineID="
					.. player:getOnlineID()
					.. "); suppressed: "
					.. suppressedCodes
					.. "; remaining: "
					.. (filteredCodes ~= "" and filteredCodes or "none")
			)
			interactionCodes = filteredCodes
		end
	end
	return original_ISRadioInteractions_checkPlayer(
		player,
		guid,
		interactionCodes,
		x,
		y,
		z,
		line,
		source
	)
end
