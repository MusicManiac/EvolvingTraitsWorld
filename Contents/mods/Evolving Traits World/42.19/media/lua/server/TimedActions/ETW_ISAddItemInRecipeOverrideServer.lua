require("TimedActions/ISAddItemInRecipe")

local ETW_CommonFunctions = require("ETW_CommonFunctions")
local ETW_Registry = require("ETW_Registry")
local ETW_ItemTraits = require("TraitsLogic/ETW_ItemTraits")

local FILENAME = "ETW_ISAddItemInRecipeOverrideServer.lua"
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

---Restores the raw dish before vanilla adds an ingredient, then reapplies Gourmand to the new total.
function ISAddItemInRecipe:complete()
	local player = self.character
	local baseItem = self.baseItem
	if player and baseItem and instanceof(baseItem, "Food") then
		ETW_ItemTraits.restoreGourmandFood(baseItem, player)
	end

	local originalReturn = original_ISAddItemInRecipe_complete(self)
	local result = self.baseItem
	if
		player
		and result
		and instanceof(result, "Food")
		and player:hasTrait(ETWTraitsRegistry.GOURMAND)
	then
		if ETW_ItemTraits.applyGourmandFood(result, player) then
			logETW(
				"ETW Logger | ISAddItemInRecipe:complete(): reapplied Gourmand after adding ingredient for "
					.. tostring(player:getUsername())
					.. " (OnlineID="
					.. player:getOnlineID()
					.. "); food: "
					.. result:getFullType()
			)
		end
	end
	return originalReturn
end
