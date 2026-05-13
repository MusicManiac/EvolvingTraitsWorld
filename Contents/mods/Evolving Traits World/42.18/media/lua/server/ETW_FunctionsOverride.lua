local ETW_CommonLogicChecks
local ETWCombinedTraitChecks
local ETW_ExportedFunctions

---@type ETW_CommonFunctions
local ETW_CommonFunctions = require("ETW_CommonFunctions")

local gameMode = ETW_CommonFunctions.gameMode()

local FILENAME = "ETW_FunctionsOverride.lua"
if
	not ETW_CommonFunctions.gameModeSafeguard(
		FILENAME,
		{ ETW_CommonFunctions.GameMode.SP, ETW_CommonFunctions.GameMode.MP_SERVER }
	)
then
	return
end

ETW_CommonLogicChecks = require("ETW_CommonLogicChecks")
ETW_CombinedTraitChecks = require("ETW_CombinedTraitChecks")
ETW_ExportedFunctions = require("ETW_ExportedFunctions")

---@type EvolvingTraitsWorldSandboxVars
local SBvars = SandboxVars.EvolvingTraitsWorld

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
	local modData = character and ETW_CommonFunctions.getETWModData(character)
	if
		modData
		and #modData.UniqueClothingRipped < SBvars.SewerUniqueClothesRipped
		and ETW_CommonLogicChecks.SewerShouldExecute(character)
	then
		logETW("ETW Logger | RecipeCodeOnCreate.ripClothing() Executing for player " .. character:getUsername())
		local items = data:getAllConsumedItems()
		local item = items and items:get(0)
		if item then
			---@cast item Clothing
			local itemName = item:getClothingItemName()
			if itemName then
				ETW_CommonFunctions.log("ETW Logger | RecipeCodeOnCreate.ripClothing() item: " .. itemName)
				ETW_CombinedTraitChecks.addClothingToUniqueRippedClothingList(character, itemName)
				if gameMode == ETW_CommonFunctions.GameMode.MP_SERVER then
					sendServerCommand(character, "ETW", "refreshETWModDataFromServer", { ETWModData = modData })
				end
			end
		end
	end
	original_RecipeCodeOnCreate_ripClothing(data, character)
end
