local ETW_CommonLogicChecks
local ETWCombinedTraitChecks
local ETW_ExportedFunctions

---@type ETW_CommonFunctions
local ETW_CommonFunctions = require("ETW_CommonFunctions")

local gameMode = ETW_CommonFunctions.gameMode()

ETW_CommonLogicChecks = require("ETW_CommonLogicChecks")
ETWCombinedTraitChecks = require("ETWCombinedTraitChecks")
ETW_ExportedFunctions = require("ETW_ExportedFunctions")

---@type EvolvingTraitsWorldSandboxVars
local SBvars = SandboxVars.EvolvingTraitsWorld

local modOptions

if gameMode == ETW_CommonFunctions.GameMode.SP then
	---Function responsible for setting up mod options on character load
	---@param playerIndex number
	---@param player IsoPlayer
	local function initializeModOptions(playerIndex, player)
		modOptions = PZAPI.ModOptions:getOptions("ETWModOptions")
	end
	Events.OnCreatePlayer.Remove(initializeModOptions)
	Events.OnCreatePlayer.Add(initializeModOptions)
end

---@return boolean
local notification = function()
	if modOptions then
		return modOptions:getOption("EnableNotifications"):getValue()
	end
	return false
end

---@return boolean
local delayedNotification = function()
	if modOptions then
		return modOptions:getOption("EnableDelayedNotifications"):getValue()
	end
	return false
end

---@return boolean
local detailedDebug = function()
	if modOptions then
		return modOptions:getOption("GatherDetailedDebug"):getValue()
	end
	return false
end

local original_RecipeCodeOnEat_consumeNicotine = RecipeCodeOnEat.consumeNicotine
function RecipeCodeOnEat.consumeNicotine(item, character, ...)
	ETW_ExportedFunctions.smokingAddictionMath(character)
	return original_RecipeCodeOnEat_consumeNicotine(item, character, ...)
end

local original_RecipeCodeOnCreate_ripClothing = RecipeCodeOnCreate.ripClothing
---Overwriting RecipeCodeOnCreate.ripClothing() here to insert ETW logic catching player ripping clothing
---@param data CraftRecipeData
---@param character IsoGameCharacter
function RecipeCodeOnCreate.ripClothing(data, character)
	if gameMode ~= ETW_CommonFunctions.GameMode.MP_SERVER then
		local modData = ETW_CommonFunctions.getETWModData(character)
		if #modData.UniqueClothingRipped < SBvars.SewerUniqueClothesRipped and ETW_CommonLogicChecks.SewerShouldExecute(character) then
			local items = data:getAllConsumedItems()
			local item = items:get(0)
			modOptions = PZAPI.ModOptions:getOptions("ETWModOptions")
			---@type DebugAndNotificationArgs
			local DebugAndNotificationArgs =
				{ detailedDebug = detailedDebug(), notification = notification(), delayedNotification = delayedNotification() }
			---@cast item Clothing
			if detailedDebug() then
				print("ETW Logger | RecipeCodeOnCreate.ripClothing() item: " .. item:getName())
			end
			ETWCombinedTraitChecks.addClothingToUniqueRippedClothingList(character, item, DebugAndNotificationArgs)
		end
	end
	original_RecipeCodeOnCreate_ripClothing(data, character)
end
