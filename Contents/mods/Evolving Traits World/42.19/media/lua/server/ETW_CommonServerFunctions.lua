local ETW_CommonFunctions = require("ETW_CommonFunctions")

local ETW_Registry = require("ETW_Registry")
local ETWTraitsRegistry = ETW_Registry.traits

---@type EvolvingTraitsWorldSandboxVars
local SBvars = SandboxVars.EvolvingTraitsWorld

local ETW_CommonServerFunctions = {}

local BLOODLUST_KILLS_FOR_BASE_MULTIPLIER = 10
local BLOODLUST_KILLS_PER_ADDITIONAL_MULTIPLIER = 20

---Returns the average blood level of blood-compatible worn clothing.
---@param player IsoPlayer
---@return number -- value between 0 and 1
local function bloodiedClothesLevel(player)
	local wornItems = player:getWornItems()
	local totalBloodLevelPercentage = 0.0
	local amountOfWornItems = 0
	if wornItems ~= nil and wornItems:size() > 1 then
		for i = 0, wornItems:size() - 1 do
			local item = wornItems:getItemByIndex(i)
			if instanceof(item, "Clothing") then
				---@cast item Clothing
				if item:getBloodClothingType() ~= nil then
					local bloodLevel = item:getBloodLevel() or 0
					amountOfWornItems = amountOfWornItems + 1
					totalBloodLevelPercentage = totalBloodLevelPercentage + bloodLevel
					ETW_CommonFunctions.log(
						"ETW Logger | bloodiedClothesLevel(): Clothing = "
							.. item:getClothingItemName()
							.. " | blood clothing type = "
							.. tostring(item:getBloodClothingType())
							.. " | blood level = "
							.. bloodLevel
					)
				end
			end
		end
	end
	if amountOfWornItems == 0 then
		return 0
	end
	local avg = totalBloodLevelPercentage / 100 / amountOfWornItems
	ETW_CommonFunctions.log("ETW Logger | bloodiedClothesLevel(): avg = " .. avg)
	return avg
end

---Returns the Bloodlust activity multiplier for the given rolling-hour kill count.
---@param killsLastHour integer
---@return number
local function bloodlustKillMultiplier(killsLastHour)
	if killsLastHour <= BLOODLUST_KILLS_FOR_BASE_MULTIPLIER then
		return killsLastHour / BLOODLUST_KILLS_FOR_BASE_MULTIPLIER
	end
	return 1
		+ (killsLastHour - BLOODLUST_KILLS_FOR_BASE_MULTIPLIER)
			/ BLOODLUST_KILLS_PER_ADDITIONAL_MULTIPLIER
end

---Prunes Bloodlust timestamps outside the rolling hour and records the current event.
---@param bloodlust BloodlustSystem
---@return integer
local function refreshBloodlustKillsLastHour(bloodlust)
	local currentMinute = GameTime.getInstance():getMinutesStamp()
	local cutoffMinute = currentMinute - 60
	for i = #bloodlust.KillsLastHour, 1, -1 do
		if bloodlust.KillsLastHour[i] <= cutoffMinute then
			table.remove(bloodlust.KillsLastHour, i)
		end
	end
	table.insert(bloodlust.KillsLastHour, currentMinute)
	return #bloodlust.KillsLastHour
end

---Adds Bloodlust progress for a qualifying zombie kill or animal action.
---@param player IsoPlayer
---@param baseContribution number -- point-blank zombie kill is 1
---@param source string
function ETW_CommonServerFunctions.addBloodlustProgress(player, baseContribution, source)
	local modData = ETW_CommonFunctions.getETWModData(player)
	if not modData then
		return
	end

	local bloodlust = modData.BloodlustSystem
	local killsLastHour = refreshBloodlustKillsLastHour(bloodlust)
	local killMultiplier = bloodlustKillMultiplier(killsLastHour)
	local progressIncrease = baseContribution
		* SBvars.BloodlustGainMultiplier
		* (1 + bloodiedClothesLevel(player))
		* killMultiplier
	progressIncrease = ETW_CommonFunctions.applyAffinityToDirectionalChange(
		modData,
		progressIncrease,
		nil,
		ETWTraitsRegistry.BLOODLUST
	)
	bloodlust.BloodlustProgress = math.min(
		SBvars.BloodlustProgress,
		bloodlust.BloodlustProgress + progressIncrease
	)
	ETW_CommonFunctions.log(
		"ETW Logger | "
			.. source
			.. ": KillsLastHour="
			.. killsLastHour
			.. " | multiplier="
			.. killMultiplier
			.. " | BloodlustProgress="
			.. bloodlust.BloodlustProgress
	)
end

return ETW_CommonServerFunctions
