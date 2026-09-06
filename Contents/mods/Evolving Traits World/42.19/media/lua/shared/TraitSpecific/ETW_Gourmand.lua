local ETW_Registry = require("ETW_Registry")
local ETW_CommonFunctions = require("ETW_CommonFunctions")

local FILENAME = "TraitSpecific/ETW_Gourmand.lua"
if
	not ETW_CommonFunctions.gameModeSafeguard(
		FILENAME,
		{ ETW_CommonFunctions.GameMode.SP, ETW_CommonFunctions.GameMode.MP_CLIENT, ETW_CommonFunctions.GameMode.MP_SERVER }
	)
then
	return
end

---@type EvolvingTraitsWorldSandboxVars
local SBvars = SandboxVars.EvolvingTraitsWorld
local ETWTraitsRegistry = ETW_Registry.traits
local logETW = ETW_CommonFunctions.log
local gameMode = ETW_CommonFunctions.gameMode()
local ETW_Gourmand = {}

---Returns whether a food item was prepared through a recipe.
---@param food Food
---@return boolean
local function isPreparedFood(food)
	local ingredients = food:getExtraItems()
	local spices = food:getSpices()
	return (ingredients and not ingredients:isEmpty()) or (spices and not spices:isEmpty())
end

---Restores a food item's original values after Gourmand modification.
---@param food Food
---@param player IsoPlayer
local function restoreGourmandFood(food, player)
	local itemData = food:getModData()
	local data = itemData.ETWGourmand
	if not data or not data.Applied then
		return
	end
	food:setMinutesToCook(data.OriginalMinutesToCook)
	food:setMinutesToBurn(data.OriginalMinutesToBurn)
	food:setHungChange(data.OriginalHungChange)
	food:setUnhappyChange(data.OriginalUnhappyChange)
	food:setBoredomChange(data.OriginalBoredomChange)
	food:setThirstChange(data.OriginalThirstChange)
	food:setGoodHot(data.OriginalGoodHot)
	food:setBadInMicrowave(data.OriginalBadInMicrowave)
	food:setBadCold(data.OriginalBadCold)
	itemData.ETWGourmand = nil
	if gameMode ~= ETW_CommonFunctions.GameMode.MP_CLIENT then
		food:syncItemFields()
	end
	logETW(
		"ETW Logger | gourmandTrait(): restored "
			.. food:getFullType()
			.. " for "
			.. tostring(player:getUsername())
			.. " (OnlineID="
			.. player:getOnlineID()
			.. ")"
	)
end
ETW_Gourmand.restoreGourmandFood = restoreGourmandFood

---Stores the original mutable values of a food item before Gourmand modifies it.
---@param food Food
---@param data table
local function snapshotGourmandFood(food, data)
	data.OriginalMinutesToCook = food:getMinutesToCook()
	data.OriginalMinutesToBurn = food:getMinutesToBurn()
	data.OriginalHungChange = food:getHungChange()
	data.OriginalUnhappyChange = food:getUnhappyChangeUnmodified()
	data.OriginalBoredomChange = food:getBoredomChangeUnmodified()
	data.OriginalThirstChange = food:getThirstChangeUnmodified()
	data.OriginalGoodHot = food:isGoodHot()
	data.OriginalBadInMicrowave = food:isBadInMicrowave()
	data.OriginalBadCold = food:isBadCold()
	data.Applied = true
end

---@class GourmandSettings
---@field CookingTimeMultiplier number
---@field BurnTimeMultiplier number
---@field BenefitMultiplier number
---@field PlayerIdentifier string

---Builds the Gourmand multipliers and ownership identifier for a player.
---@param player IsoPlayer
---@return GourmandSettings
local function getGourmandSettings(player)
	return {
		CookingTimeMultiplier = math.max(0.1, SBvars.GourmandCookingTimeMultiplier or 0.5),
		BurnTimeMultiplier = math.max(0.1, SBvars.GourmandBurnTimeMultiplier or 2),
		BenefitMultiplier = math.max(1, SBvars.GourmandCookedFoodBenefitMultiplier or 1.5),
		PlayerIdentifier = tostring(player:getUsername()) .. " (OnlineID=" .. player:getOnlineID() .. ")",
	}
end

---Applies a Gourmand player's cooking modifiers to a food item once per stage.
---@param food Food
---@param player IsoPlayer|nil
---@param settings GourmandSettings|nil
---@return boolean changed
function ETW_Gourmand.applyGourmandFood(food, player, settings)
	local itemData = food:getModData()
	local data = itemData.ETWGourmand
	if
		(not data and (not player or not player:hasTrait(ETWTraitsRegistry.GOURMAND)))
		or (not food:isIsCookable() and not food:isCooked() and not isPreparedFood(food))
	then
		return false
	end
	if not settings then
		if data then
			settings = {
				CookingTimeMultiplier = data.CookingTimeMultiplier,
				BurnTimeMultiplier = data.BurnTimeMultiplier,
				BenefitMultiplier = data.BenefitMultiplier,
				PlayerIdentifier = data.AuthorIdentifier,
			}
		elseif player then
			settings = getGourmandSettings(player)
		else
			return false
		end
	end
	local settingsChanged = data
		and player
		and data.Applied
		and (
			data.CookingTimeMultiplier ~= settings.CookingTimeMultiplier
			or data.BurnTimeMultiplier ~= settings.BurnTimeMultiplier
			or data.BenefitMultiplier ~= settings.BenefitMultiplier
		)
	if settingsChanged and player then
		restoreGourmandFood(food, player)
		data = nil
	end
	if not data then
		if not player then
			return false
		end
		data = {}
		itemData.ETWGourmand = data
		snapshotGourmandFood(food, data)
		data.CookingTimeMultiplier = settings.CookingTimeMultiplier
		data.BurnTimeMultiplier = settings.BurnTimeMultiplier
		data.BenefitMultiplier = settings.BenefitMultiplier
		data.AuthorUsername = player:getUsername()
		data.AuthorIdentifier = settings.PlayerIdentifier
	end

	local changed = false
	if food:isIsCookable() and not food:isCooked() and not data.CookingApplied then
		food:setMinutesToCook(data.OriginalMinutesToCook * settings.CookingTimeMultiplier)
		food:setMinutesToBurn(data.OriginalMinutesToBurn * settings.BurnTimeMultiplier)
		data.CookingApplied = true
		changed = true
		logETW(
			"ETW Logger | gourmandTrait(): adjusted cooking for "
				.. settings.PlayerIdentifier
				.. "; food: "
				.. food:getFullType()
				.. "; minutes to cook: "
				.. data.OriginalMinutesToCook
				.. "->"
				.. food:getMinutesToCook()
				.. "; minutes to burn: "
				.. data.OriginalMinutesToBurn
				.. "->"
				.. food:getMinutesToBurn()
		)
	end
	if (food:isCooked() or isPreparedFood(food)) and not food:isRotten() and not data.CookedFoodApplied then
		local thirstChange = data.OriginalThirstChange
		if thirstChange < 0 then
			thirstChange = thirstChange * settings.BenefitMultiplier
		elseif thirstChange > 0 then
			thirstChange = thirstChange * math.max(0, 2 - settings.BenefitMultiplier)
		end
		food:setHungChange(data.OriginalHungChange * settings.BenefitMultiplier)
		food:setUnhappyChange(
			data.OriginalUnhappyChange < 0 and data.OriginalUnhappyChange * settings.BenefitMultiplier or 0
		)
		food:setBoredomChange(
			data.OriginalBoredomChange < 0 and data.OriginalBoredomChange * settings.BenefitMultiplier or 0
		)
		food:setThirstChange(thirstChange)
		food:setGoodHot(false)
		food:setBadInMicrowave(false)
		food:setBadCold(false)
		data.CookedFoodApplied = true
		changed = true
		logETW(
			"ETW Logger | gourmandTrait(): improved cooked/prepared food for "
				.. settings.PlayerIdentifier
				.. "; food: "
				.. food:getFullType()
				.. "; hunger: "
				.. data.OriginalHungChange
				.. "->"
				.. food:getHungChange()
				.. "; unhappiness: "
				.. data.OriginalUnhappyChange
				.. "->"
				.. food:getUnhappyChangeUnmodified()
				.. "; boredom: "
				.. data.OriginalBoredomChange
				.. "->"
				.. food:getBoredomChangeUnmodified()
				.. "; thirst: "
				.. data.OriginalThirstChange
				.. "->"
				.. food:getThirstChangeUnmodified()
		)
	end
	if changed and gameMode ~= ETW_CommonFunctions.GameMode.MP_CLIENT then
		food:syncItemFields()
	end
	return changed
end

---Returns whether a food item is currently being heated in an active appliance.
---@param food Food
---@return boolean
local function isFoodHeating(food)
	local container = food:getContainer()
	return container ~= nil and container:getTemprature() > 1
end

---Processes Gourmand food currently tracked by the cell.
---@param players ArrayList<IsoPlayer>
local function updateGourmandFoods(players)
	local gourmandsByChef = {}
	for i = 0, players:size() - 1 do
		local player = players:get(i)
		if player:hasTrait(ETWTraitsRegistry.GOURMAND) then
			gourmandsByChef[player:getUsername()] = player
			gourmandsByChef[player:getFullName()] = player
		end
	end

	local processItems = getCell():getProcessItems()
	for i = 0, processItems:size() - 1 do
		local item = processItems:get(i)
		if instanceof(item, "Food") then
			---@cast item Food
			local food = item
			local data = food:getModData().ETWGourmand
			if data and data.Applied then
				ETW_Gourmand.applyGourmandFood(food, nil)
			elseif food:isIsCookable() and not food:isCooked() and isFoodHeating(food) then
				local chef = food:getChef()
				local gourmand = chef and gourmandsByChef[chef]
				if gourmand then
					ETW_Gourmand.applyGourmandFood(food, gourmand)
					logETW(
						"ETW Logger | updateGourmandFoods(): attributed cooking of "
							.. food:getFullType()
							.. " to "
							.. tostring(gourmand:getUsername())
							.. " (OnlineID="
							.. gourmand:getOnlineID()
							.. "); container temperature: "
							.. food:getContainer():getTemprature()
					)
				end
			end
		end
	end
end

---Updates Gourmand food for the current local player or all players on the server.
local function everyOneMinute()
	local currentPlayer
	if gameMode ~= ETW_CommonFunctions.GameMode.MP_SERVER then
		currentPlayer = getPlayer()
		if not currentPlayer then
			return
		end
	end
	updateGourmandFoods(ETW_CommonFunctions.playersList(currentPlayer))
end

Events.EveryOneMinute.Remove(everyOneMinute)
Events.EveryOneMinute.Add(everyOneMinute)

return ETW_Gourmand
