require("RadioCom/ISRadioInteractions")

local ETW_CommonFunctions = require("ETW_CommonFunctions")
local ETW_Registry = require("ETW_Registry")

local FILENAME = "TraitSpecific/ETW_MediaTraits.lua"
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

---Returns whether vanilla will accept this media line for the player.
---@param player IsoPlayer
---@param guid string
---@param interactionCodes string
---@param x number
---@param y number
---@param z number
---@param line string
---@return boolean
local function canReceiveMediaLine(player, guid, interactionCodes, x, y, z, line)
	if player:isAsleep() or not interactionCodes or interactionCodes:len() == 0 or not line then
		return false
	end
	if guid and guid ~= "" and player:isKnownMediaLine(guid) then
		return false
	end
	if x ~= -1 or y ~= -1 or z ~= -1 then
		local sourceSquare = getCell():getGridSquare(x, y, z)
		local playerSquare = player:getSquare()
		if sourceSquare and playerSquare and sourceSquare:isOutside() ~= playerSquare:isOutside() then
			return false
		end
	end
	return true
end

---Counts syntactically valid numeric media interaction commands.
---@param interactionCodes string
---@return integer
local function countInteractionCommands(interactionCodes)
	local count = 0
	for interactionCode in string.gmatch(interactionCodes, "[^,]+") do
		if interactionCode:len() > 4 and tonumber(string.sub(interactionCode, 5)) then
			count = count + 1
		end
	end
	return count
end

---Records TV commands in a rolling online-time window and resets TV Junkie's elapsed time at the threshold.
---@param player IsoPlayer
---@param interactionCodes string
local function recordTVJunkieViewing(player, interactionCodes)
	if gameMode == ETW_CommonFunctions.GameMode.MP_CLIENT or not player:hasTrait(ETWTraitsRegistry.TV_JUNKIE) then
		return
	end
	local commandCount = countInteractionCommands(interactionCodes)
	if commandCount == 0 then
		return
	end
	local modData = ETW_CommonFunctions.getETWModData(player)
	if not modData then
		return
	end

	local tvJunkieSystem = modData.TVJunkieSystem
	local currentMinute = tvJunkieSystem.ActiveMinutes
	local windowMinutes = math.max(1, math.floor(SBvars.TVJunkieHoursWithoutTelevision or 24)) * 60
	local cutoffMinute = currentMinute - windowMinutes
	local recentCommandMinutes = {}
	for _, commandMinute in ipairs(tvJunkieSystem.CommandMinutes) do
		if commandMinute >= cutoffMinute and commandMinute <= currentMinute then
			table.insert(recentCommandMinutes, commandMinute)
		end
	end
	for _ = 1, commandCount do
		table.insert(recentCommandMinutes, currentMinute)
	end

	local requiredCommands = math.max(1, math.floor(SBvars.TVJunkieRequiredCommands or 3))
	if #recentCommandMinutes >= requiredCommands then
		tvJunkieSystem.MinutesSinceLastWatch = 0
		tvJunkieSystem.CommandMinutes = {}
		logETW(
			"ETW Logger | TV Junkie television "
				.. gameMode
				.. ": viewing requirement met for "
				.. tostring(player:getUsername())
				.. " (OnlineID="
				.. player:getOnlineID()
				.. "); commands received: "
				.. #recentCommandMinutes
				.. "/"
				.. requiredCommands
		)
	else
		tvJunkieSystem.CommandMinutes = recentCommandMinutes
	end
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
	local televisionSource = isTelevisionSource(x, y, z)
	if
		televisionSource
		and canReceiveMediaLine(player, guid, interactionCodes, x, y, z, line)
	then
		recordTVJunkieViewing(player, interactionCodes)
	end
	if
		SBvars.AsceticTelevisionEffect ~= false
		and player:hasTrait(ETWTraitsRegistry.ASCETIC)
		and interactionCodes
		and interactionCodes:len() > 0
		and televisionSource
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
