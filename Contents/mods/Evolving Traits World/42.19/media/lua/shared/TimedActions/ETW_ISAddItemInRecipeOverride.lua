require("TimedActions/ISAddItemInRecipe")

local ETW_CommonFunctions = require("ETW_CommonFunctions")
local ETW_Registry = require("ETW_Registry")
local ETW_Gourmand = require("TraitSpecific/ETW_Gourmand")

local FILENAME = "TimedActions/ETW_ISAddItemInRecipeOverride.lua"
if
	not ETW_CommonFunctions.gameModeSafeguard(
		FILENAME,
		{ ETW_CommonFunctions.GameMode.SP, ETW_CommonFunctions.GameMode.MP_SERVER }
	)
then
	return
end

local ETWTraitsRegistry = ETW_Registry.traits
local logETW = ETW_CommonFunctions.log
local original_ISAddItemInRecipe_complete = ISAddItemInRecipe.complete

---Restores the raw dish before vanilla adds an ingredient, then reapplies Gourmand to the result.
---@return unknown
function ISAddItemInRecipe:complete()
	local player = self.character
	local baseItem = self.baseItem
	if player and baseItem and instanceof(baseItem, "Food") then
		ETW_Gourmand.restoreGourmandFood(baseItem, player)
	end

	local originalReturn = original_ISAddItemInRecipe_complete(self)
	local result = self.baseItem
	if
		player
		and result
		and instanceof(result, "Food")
		and player:hasTrait(ETWTraitsRegistry.GOURMAND)
		and ETW_Gourmand.applyGourmandFood(result, player)
	then
		logETW(
			"ETW Logger | ISAddItemInRecipe: applied Gourmand after adding ingredient for "
				.. tostring(player:getUsername())
				.. " (OnlineID="
				.. player:getOnlineID()
				.. "); food: "
				.. result:getFullType()
		)
	end
	return originalReturn
end
