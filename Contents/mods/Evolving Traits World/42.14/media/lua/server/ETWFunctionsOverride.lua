--require "ETWModOptions"
local ETWCommonFunctions
local ETWCommonLogicChecks
local ETWCombinedTraitChecks
local ETWExportedFunctions

--if not isServer() then
ETWCommonFunctions = require("ETWCommonFunctions")
ETWCommonLogicChecks = require("ETWCommonLogicChecks")
ETWCombinedTraitChecks = require("ETWCombinedTraitChecks")
ETWExportedFunctions = require("ETWExportedFunctions")
--end

local Commands = {}

---@type EvolvingTraitsWorldSandboxVars
local SBvars = SandboxVars.EvolvingTraitsWorld

local modOptions

if not isClient() and not isServer() then
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
	return modOptions:getOption("EnableNotifications"):getValue()
end
---@return boolean
local delayedNotification = function()
	return modOptions:getOption("EnableDelayedNotifications"):getValue()
end
---@return boolean
local detailedDebug = function()
	return modOptions:getOption("GatherDetailedDebug"):getValue()
end

local original_RecipeCodeOnEat_consumeNicotine = RecipeCodeOnEat.consumeNicotine
function RecipeCodeOnEat.consumeNicotine(item, character, ...)
	ETWExportedFunctions.smokingAddictionMath(character)
	return original_RecipeCodeOnEat_consumeNicotine(item, character, ...)
end

local original_RecipeCodeOnCreate_ripClothing = RecipeCodeOnCreate.ripClothing
---Overwriting Recipe.OnCreate.RipClothing() here to insert ETW logic catching player ripping clothing
---@param data CraftRecipeData
---@param character IsoGameCharacter
function RecipeCodeOnCreate.ripClothing(data, character)
	if not isServer() then
		local modData = ETWCommonFunctions.getETWModData(character)
		if #modData.UniqueClothingRipped < SBvars.SewerUniqueClothesRipped and ETWCommonLogicChecks.SewerShouldExecute() then
			local items = data:getAllConsumedItems()
			local item = items:get(0)
			modOptions = PZAPI.ModOptions:getOptions("ETWModOptions")
			---@type DebugAndNotificationArgs
			local DebugAndNotificationArgs =
				{ detailedDebug = detailedDebug(), notification = notification(), delayedNotification = delayedNotification() }
			---@cast item Clothing
			if detailedDebug() then
				print("ETW Logger | Recipe.OnCreate.RipClothing() item: " .. item:getName())
			end
			ETWCombinedTraitChecks.addClothingToUniqueRippedClothingList(character, item, DebugAndNotificationArgs)
		end
	end
	original_RecipeCodeOnCreate_ripClothing(data, character)
end

-- ---Function responsible for checking if current ISFixAction performed on a vehicle part
-- ---@param craftRecipeData
-- ---@param item
-- ---@param skill
-- ---@return boolean
-- local function isVehiclePart(craftRecipeData, item, skill)
-- 	print(tostring(craftRecipeData).." "..tostring(item).." ".. tostring(skill))
-- 	if craftRecipeData.vehiclePart then
-- 		return true
-- 	end
-- 	if skill then
-- 		for i = 0, skill:size() - 1 do
-- 			if skill:get(i):getSkillName() == "Mechanics" then
-- 				return true
-- 			end
-- 		end
-- 	end
-- 	return false
-- end

-- local original_CraftRecipe_Code_GenericFixer = CraftRecipeCode.GenericFixer
-- ---Overwriting  CraftRecipeCode.GenericFixer(...) here to insert ETW logic catching player doing repairs
-- ---@param craftRecipeData
-- ---@param player
-- ---@param factor
-- ---@param item
-- ---@param skill
-- ---@param head
-- function CraftRecipeCode.GenericFixer(craftRecipeData, player, factor, item, skill, head)
--     if not item then item = craftRecipeData:getFirstInputItemWithFlag("IsDamaged") end
--     if not player then player = craftRecipeData:getPlayer() end

-- 	local modData = ETWCommonFunctions.getETWModData(player)
-- 	sendClientCommand(player, 'ETW', 'debugInfoRequest', args)
-- 	---@type DebugAndNotificationArgs
-- 	local DebugAndNotificationArgs = {detailedDebug = detailedDebug(), notification = notification(), delayedNotification = delayedNotification()}
-- 	if DebugAndNotificationArgs.detailedDebug then print("ETW Logger | CraftRecipeCode.GenericFixer(): caught") end

-- 	local conditionBefore = item:getCondition()

-- 	original_CraftRecipe_Code_GenericFixer(craftRecipeData, player, factor, item, skill, head)

-- 	local conditionAfter = item:getCondition()
-- 	local mechanicsShouldExecute = ETWCommonLogicChecks.MechanicsShouldExecute()
-- 	local bodyWorkEnthusiastShouldExecute = ETWCommonLogicChecks.BodyWorkEnthusiastShouldExecute()
-- 	if conditionAfter > conditionBefore and isVehiclePart(craftRecipeData, item, skill) and (mechanicsShouldExecute or bodyWorkEnthusiastShouldExecute) then
-- 		modData.VehiclePartRepairs = modData.VehiclePartRepairs + (conditionAfter - conditionBefore)
-- 		if detailedDebug() then
-- 			print(
-- 				"ETW Logger | ISFixAction.perform(): car part " .. conditionBefore .. "->" .. conditionAfter
-- 				.. " VehiclePartRepairs=" .. modData.VehiclePartRepairs
-- 			)
-- 		end
-- 		if bodyWorkEnthusiastShouldExecute then ETWCombinedTraitChecks.bodyworkEnthusiastCheck(DebugAndNotificationArgs) end
-- 		if mechanicsShouldExecute then ETWCombinedTraitChecks.mechanicsCheck(DebugAndNotificationArgs) end
-- 	end
-- 	if player:hasTrait("RestorationExpert") then
-- 		if detailedDebug() then print("ETW Logger | ISFixAction.perform(): RestorationExpert present") end
-- 		local chance = SBvars.RestorationExpertChance - 1
-- 		if ZombRand(100) <= chance then
-- 			item:setHaveBeenRepaired(item:getHaveBeenRepaired() - 1)
-- 			item:syncItemFields()
-- 		end
-- 	end
-- end

-- ---Function to check by how much engine was repaired. If SP - updates relative moddata and checks traits. If MP - sends command back to client
-- ---@param player IsoPlayer
-- ---@param args
-- function Commands.checkEngineCondition(player, args)
-- 	---@return boolean
-- 	notification = function() return args.notification end
-- 	---@return boolean
-- 	delayedNotification = function() return args.delayedNotification end
-- 	---@return boolean
-- 	detailedDebug = function() return args.detailedDebug end
-- 	-- local vehicle = getVehicleById(args.vehicleID)
-- 	-- local part = vehicle:getPartById("Engine")
-- 	-- if not part then return end
-- 	-- local condition = part:getCondition()
-- 	-- local repairedPercentage = condition - args.conditionBefore
-- 	-- if args.DebugAndNotificationArgs.detailedDebug then print("ETW Logger | Commands.checkEngineCondition(): args.condition: " .. condition) end
-- 	-- if not isClient() and not isServer() then
-- 	-- 	local modData = player:getModData().EvolvingTraitsWorld
-- 	-- 	---@cast modData EvolvingTraitsWorldModData
-- 	-- 	modData.VehiclePartRepairs = modData.VehiclePartRepairs + repairedPercentage
-- 	-- 	if args.DebugAndNotificationArgs.detailedDebug then print("ETW Logger | Commands.checkEngineCondition(): modData.VehiclePartRepairs: " .. modData.VehiclePartRepairs) end
-- 	-- 	if ETWCommonLogicChecks.BodyWorkEnthusiastShouldExecute() then ETWCombinedTraitChecks.bodyworkEnthusiastCheck(args.DebugAndNotificationArgs) end
-- 	-- 	if ETWCommonLogicChecks.MechanicsShouldExecute() then ETWCombinedTraitChecks.mechanicsCheck(args.DebugAndNotificationArgs) end
-- 	-- end
-- end

Commands.OnClientCommand = function(module, command, player, args)
	if module == "ETW" and Commands[command] then
		local argStr = ""
		args = args or {}
		for k, v in pairs(args) do
			argStr = argStr .. " " .. k .. "=" .. tostring(v)
		end
		Commands[command](player, args)
	end
end

Events.OnClientCommand.Add(Commands.OnClientCommand)
