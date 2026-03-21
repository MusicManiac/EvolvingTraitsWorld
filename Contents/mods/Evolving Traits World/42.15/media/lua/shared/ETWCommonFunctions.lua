---@class ETWCommonFunctions
local ETWCommonFunctions = {}

---@type EvolvingTraitsWorldSandboxVars
local SBvars = SandboxVars.EvolvingTraitsWorld

local modOptions

local random_instance = newrandom()

---Enum-like table for game mode
---@return boolean
ETWCommonFunctions.GameMode = {
	SP = "SP",
	MP_CLIENT = "MP_Client",
	MP_SERVER = "MP_Server",
}

---Function responsible for determining the current game mode, returns "SP" for single player, "MP_Client" for multiplayer client and "MP_Server" for multiplayer server
---@return '"SP"'|'"MP_Client"'|'"MP_Server"'
function ETWCommonFunctions.gameMode()
	if not isClient() and not isServer() then
		return ETWCommonFunctions.GameMode.SP
	elseif isClient() then
		return ETWCommonFunctions.GameMode.MP_CLIENT
	end
	return ETWCommonFunctions.GameMode.MP_SERVER
end

local gameMode = ETWCommonFunctions.gameMode()

if gameMode ~= ETWCommonFunctions.GameMode.MP_SERVER then
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

---Prints out debugs inside console if detailedDebug is enabled
---@param ... any Optional boolean followed by strings to log, if boolean is set to true, prints all strings in a single line otherwise prints each string in a new line
function ETWCommonFunctions.log(...)
	if detailedDebug() then
		local args = { ... }
		if #args == 0 then
			return
		end

		local function toStr(v)
			return tostring(v)
		end

		if type(args[1]) == "boolean" then
			local singleLine = args[1]
			table.remove(args, 1)

			if singleLine then
				for i = 1, #args do
					args[i] = toStr(args[i])
				end
				print(table.concat(args, " "))
			else
				for _, v in ipairs(args) do
					print(toStr(v))
				end
			end
		else
			for _, v in ipairs(args) do
				print(toStr(v))
			end
		end
	end
end

---Prints out debugs inside console if detailedDebug is enabled
---@param ... any Optional boolean followed by strings to log, if set to true, prints all strings in a single line otherwise prints each string in a new line
local logETW = function(...)
	ETWCommonFunctions.log(...)
end

---Function responsible for finding index of delayed trait in Delayed Traits Table
---@param tbl table
---@param value any
---@return integer
local function indexOfDelayedTrait(tbl, value)
	for i = 1, #tbl do
		local subTable = tbl[i]
		if subTable[1] == value then
			return i
		end
	end
	return -1
end

---Function responsible for finding index of a specific item in a flat table
---@param tbl table
---@param value any
---@return integer
function ETWCommonFunctions.indexOf(tbl, value)
	for i = 1, #tbl do
		if tbl[i] == value then
			return i
		end
	end
	return -1
end

---Plays a sound if enabled in settings
---@param player IsoPlayer|IsoGameCharacter
function ETWCommonFunctions.traitSound(player)
	if modOptions:getOption("EnableSoundNotifications"):getValue() then
		local soundTable = {
			"ETW_b42",
			"ETW_b41",
			"ETW_TLOU",
			"ETW_SkyrimSkill",
			"ETW_SkyrimLevel",
			"ETW_Oblivion",
			"ETW_Diablo2",
			"ETW_Witcher3",
			"ETW_FalloutNV",
			"ETW_AoE3",
			"ETW_WoW",
		}
		local filteredSoundTable = {}
		for index = 1, #soundTable do
			if modOptions:getOption("SoundNotificationSoundSelect"):getValue(index) then
				table.insert(filteredSoundTable, soundTable[index])
			end
		end
		player:playSoundLocal(filteredSoundTable[random_instance:random(1, #filteredSoundTable)])
	end
end

---Returns ETW mod data
---@param player IsoPlayer|IsoGameCharacter
---@return EvolvingTraitsWorldModData
function ETWCommonFunctions.getETWModData(player)
	return player:getModData().EvolvingTraitsWorld
end

---Function responsible printing whole Delayed Traits table into console
function ETWCommonFunctions.delayedTraitsDataDump()
	if SBvars.DelayedTraitsSystem then
		local traitTable = getPlayer():getModData().EvolvingTraitsWorld.DelayedTraits
		for index = 1, #traitTable do
			local traitEntry = traitTable[index]
			local traitRegistryId, roll, gained = traitEntry[1], traitEntry[2], traitEntry[3]
			print("ETW Logger | Delayed Traits System | Data Dump: " .. traitRegistryId .. ", " .. roll .. ", " .. tostring(gained))
		end
	end
end

---Adds xp boosts from a trait to a player
---@param trait CharacterTrait
local function addXPBoostsFromTrait(trait)
	local player = getPlayer()
	local xpBoostMap = CharacterTraitDefinition.getCharacterTraitDefinition(trait):getXpBoosts()
	if xpBoostMap then
		local table = transformIntoKahluaTable(xpBoostMap)
		for perk, boostLevel in pairs(table) do
			logETW(
				"ETW Logger | ETWCommonFunctions.addXPBoostsFromTrait(): perk:" .. tostring(perk) .. ", boostLevel:" .. tostring(boostLevel)
			)
			local oldBoost = player:getXp():getPerkBoost(perk)
			local newBoost = math.min(oldBoost + tonumber(tostring(boostLevel)), 3)
			---@cast newBoost integer
			player:getXp():setPerkBoost(perk, newBoost)
			logETW(
				"ETW Logger | ETWCommonFunctions.addXPBoostsFromTrait(): "
					.. tostring(perk)
					.. "old/new boost level:"
					.. oldBoost
					.. player:getXp():getPerkBoost(perk)
			)
		end
	end
end

---Add recipes from a trait to player
---@param trait CharacterTrait
local function addRecipes(trait)
	local player = getPlayer()
	local traitDefinition = CharacterTraitDefinition.getCharacterTraitDefinition(trait)
	local freeRecipes = traitDefinition:getGrantedRecipes()
	local playerRecipes = player:getKnownRecipes()
	logETW("ETW Logger | ETWCommonFunctions.addRecipes(): adding recipes for trait " .. trait:toString())
	for i = 0, freeRecipes:size() - 1 do
		local recipe = freeRecipes:get(i)
		if not playerRecipes:contains(recipe) then
			logETW("ETW Logger | ETWCommonFunctions.addRecipes(): player doesn't have " .. recipe .. ", adding it to known recipes")
			playerRecipes:add(recipe)
		end
	end
end

---Adds trait to a player, it's exp boosts, recipes and plays the sound
---@param trait CharacterTrait
function ETWCommonFunctions.addTraitToPlayer(trait)
	local player = getPlayer()
	logETW("ETW Logger | addTraitToPlayer() : adding trait " .. trait:toString())
	player:getCharacterTraits():add(trait)
	addRecipes(trait)
	addXPBoostsFromTrait(trait)
	ETWCommonFunctions.traitSound(player)
end

---Removes trait from a player and plays the sound
---@param trait CharacterTrait
function ETWCommonFunctions.removeTraitFromPlayer(trait)
	local player = getPlayer()
	logETW("ETW Logger | removeTraitFromPlayer() : removing trait " .. trait:toString())
	player:getCharacterTraits():remove(trait)
	ETWCommonFunctions.traitSound(player)
end

---@class ETWAddTraitToDelayTableContext
---@field player IsoPlayer|IsoGameCharacter
---@field trait CharacterTrait
---@field modData EvolvingTraitsWorldModData
---@field positiveTrait boolean whether the trait is positive or negative, used for notifications
---@field gainingTrait boolean whether the trait is being gained or lost, used for notifications
---@field delayedNotification boolean whether to show delayed notification, used for notifications

---Function responsible for adding a trait to a Delayed Traits System. Plays a sound as well.
---@param context ETWAddTraitToDelayTableContext
function ETWCommonFunctions.addTraitToDelayTable(context)
	if not SBvars.DelayedTraitsSystem then
		return
	end
	local player = context.player
	local trait = context.trait
	local modData = context.modData
	local positiveTrait = context.positiveTrait
	local gainingTrait = context.gainingTrait
	local delayedNotification = context.delayedNotification ~= nil and context.delayedNotification or delayedNotification()
	local traitRegistryId = trait:toString()
	local traitDisplayName = CharacterTraitDefinition.getCharacterTraitDefinition(trait):getUIName()
	local textColor = (positiveTrait and gainingTrait)
		or (not positiveTrait and not gainingTrait) and HaloTextHelper.getColorGreen()
		or HaloTextHelper.getColorRed()
	local gainingOrLosingString = gainingTrait and getText("UI_ETW_DelayedNotificationsStringGain")
		or getText("UI_ETW_DelayedNotificationsStringRemove")
	logETW("ETW Logger | Delayed Traits System: modData.DelayedStartingTraitsFilled =  " .. tostring(modData.DelayedStartingTraitsFilled))

	ETWCommonFunctions.traitSound(player)
	if not modData.DelayedStartingTraitsFilled then
		logETW(
			"ETW Logger | Delayed Traits System: player qualifies for "
				.. traitRegistryId
				.. " from the start of the game, adding it to delayed traits table"
		)
		table.insert(
			modData.DelayedTraits,
			{ traitRegistryId, SBvars.DelayedTraitsSystemDefaultDelay + SBvars.DelayedTraitsSystemDefaultStartingDelay, false }
		)
	elseif indexOfDelayedTrait(modData.DelayedTraits, traitRegistryId) == -1 and not player:hasTrait(trait) and positiveTrait then
		logETW(
			"ETW Logger | Delayed Traits System: player qualifies for positive trait "
				.. traitRegistryId
				.. ", adding it to delayed traits table"
		)
		table.insert(modData.DelayedTraits, { traitRegistryId, SBvars.DelayedTraitsSystemDefaultDelay, false })
		if delayedNotification then
			HaloTextHelper.addTextWithArrow(player, gainingOrLosingString .. traitDisplayName, gainingTrait, textColor)
		end
	elseif indexOfDelayedTrait(modData.DelayedTraits, traitRegistryId) == -1 and player:hasTrait(trait) and not positiveTrait then
		logETW(
			"ETW Logger | Delayed Traits System: player qualifies for removing negative trait "
				.. traitRegistryId
				.. ", adding it to delayed traits table"
		)
		table.insert(modData.DelayedTraits, { traitRegistryId, SBvars.DelayedTraitsSystemDefaultDelay, false })
		if delayedNotification then
			HaloTextHelper.addTextWithArrow(player, gainingOrLosingString .. traitDisplayName, gainingTrait, textColor)
		end
	else
		logETW(
			"ETW Logger | Delayed Traits System: player qualifies for "
				.. traitRegistryId
				.. ", but it's already in delayed traits table or player already has the trait"
		)
	end
	if detailedDebug() then
		print("ETW Logger | Delayed Traits System | Data Dump after ETWCommonFunctions.addTraitToDelayTable() START ------------")
		ETWCommonFunctions.delayedTraitsDataDump()
		print("ETW Logger | Delayed Traits System | Data Dump after ETWCommonFunctions.addTraitToDelayTable() END --------------")
	end
end

---Function responsible for checking if specific trait should be gained/lost, returns true if yes and removes it from the table. Otherwise, returns false.
---Function assumes that trait is in Delayed Traits table, so make sure to check that before calling this function, otherwise it will throw an error
---@param trait CharacterTrait
---@return boolean
function ETWCommonFunctions.checkDelayedTraits(traitToCheck)
	if not SBvars.DelayedTraitsSystem then
		return true
	end
	local traitRegistryId = traitToCheck:toString()
	local player = getPlayer()
	local modData = ETWCommonFunctions.getETWModData(player)
	local traitTable = modData.DelayedTraits
	local traitEntry = traitTable[indexOfDelayedTrait(modData.DelayedTraits, traitRegistryId)]
	local traitNameInTable, gained = traitEntry[1], traitEntry[3]
	logETW("ETW Logger | Delayed Traits System: caught check on " .. traitRegistryId)
	if traitNameInTable == traitRegistryId and gained then
		logETW(
			"ETW Logger | Delayed Traits System: caught check on "
				.. traitRegistryId
				.. ": player qualifies for it, removing it from the table"
		)
		table.remove(traitTable, indexOfDelayedTrait(modData.DelayedTraits, traitRegistryId))
		return true
	end
	return false
end

---Function responsible for checking if specific trait is already in Delayed Traits System
---@param trait CharacterTrait
---@return boolean
function ETWCommonFunctions.checkIfTraitIsInDelayedTraitsTable(trait)
	local player = getPlayer()
	local modData = ETWCommonFunctions.getETWModData(player)
	local traitTable = modData.DelayedTraits
	local traitRegistryId = trait:toString()
	if indexOfDelayedTrait(modData.DelayedTraits, traitRegistryId) ~= -1 then
		logETW("ETW Logger | Delayed Traits System: checking if " .. traitRegistryId .. " is already in the table, it is.")
		return true
	end
	logETW("ETW Logger | Delayed Traits System: checking if " .. traitRegistryId .. " is already in the table, it is not.")
	return false
end

return ETWCommonFunctions
