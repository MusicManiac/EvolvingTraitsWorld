---@class ETW_CommonFunctions
local ETW_CommonFunctions = {}

---@type EvolvingTraitsWorldSandboxVars
local SBvars = SandboxVars.EvolvingTraitsWorld

local modOptions

local random_instance = newrandom()

--- @field GameMode {SP: '"SP"', MP_CLIENT: '"MP_Client"', MP_SERVER: '"MP_Server"'}
ETW_CommonFunctions.GameMode = {
	SP = "SP",
	MP_CLIENT = "MP_Client",
	MP_SERVER = "MP_Server",
}

---Function responsible for determining the current game mode, returns "SP" for single player, "MP_Client" for multiplayer client and "MP_Server" for multiplayer server
---@return '"SP"'|'"MP_Client"'|'"MP_Server"'
function ETW_CommonFunctions.gameMode()
	if not isClient() and not isServer() then
		return ETW_CommonFunctions.GameMode.SP
	elseif isClient() then
		return ETW_CommonFunctions.GameMode.MP_CLIENT
	end
	return ETW_CommonFunctions.GameMode.MP_SERVER
end

local gameMode = ETW_CommonFunctions.gameMode()

if gameMode ~= ETW_CommonFunctions.GameMode.MP_SERVER then
	---Function responsible for setting up mod options on character load
	---@param playerIndex number
	---@param player IsoPlayer
	local function initializeModOptions(playerIndex, player)
		modOptions = PZAPI.ModOptions:getOptions("ETWModOptions")
	end

	Events.OnCreatePlayer.Remove(initializeModOptions)
	Events.OnCreatePlayer.Add(initializeModOptions)
end

---Returns whether notifications are enabled
---@return boolean boolean true if notifications are enabled, false otherwise
local notification = function()
    if modOptions then
        return modOptions:getOption("EnableNotifications"):getValue()
    end
    return false
end

---Returns whether delayed notifications are enabled
---@return boolean boolean true if delayed notifications are enabled, false otherwise
local delayedNotification = function()
    if modOptions then
        return modOptions:getOption("EnableDelayedNotifications"):getValue()
    end
    return false
end

---Returns whether detailed debug is enabled. If called on server, returns server logs sandbox variable, otherwise returns mod option
---@return boolean boolean true if detailed debug is enabled, false otherwise
local detailedDebug = function()
	if gameMode == ETW_CommonFunctions.GameMode.MP_SERVER then
		return SBvars.ServerLogs
	end
	if modOptions then
		return modOptions:getOption("GatherDetailedDebug"):getValue()
	end
	return false
end

---Prints out debugs inside console if detailedDebug is enabled
---@param ... any Optional boolean followed by strings to log, if boolean is set to true, prints all strings in a single line otherwise prints each string in a new line
function ETW_CommonFunctions.log(...)
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

---Function responsible for finding index of delayed trait in Delayed Traits Table
---@param tbl table the table to search in
---@param value any the value to search for
---@return integer integer the index of the value in the table, or -1 if not found
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
---@param tbl table the table to search in
---@param value any the value to search for
---@return integer integer the index of the value in the table, or -1 if not found
function ETW_CommonFunctions.indexOf(tbl, value)
	for i = 1, #tbl do
		if tbl[i] == value then
			return i
		end
	end
	return -1
end

---Function that returns ArrayList of all players in case its called on Server, all ever loaded players in case it's called on MP Client, or just the list with 1 entry - player itself in case it's called on SP.
---Later can be looped over like:
---
---    for i = 0, playerList:size() - 1 do
---        local player = playerList:get(i)
---    end
---@return ArrayList<IsoPlayer> ArrayList of all players in case its called on Server, all ever loaded players in case it's called on MP Client, or just the list with 1 entry - player itself in case it's called on SP.
function ETW_CommonFunctions.playersList()
	local playerList = getOnlinePlayers()

	if playerList:isEmpty() then
		playerList = { getPlayer() }
	end
	return playerList
end

---Plays a sound if enabled in settings
---@param player IsoPlayer|IsoGameCharacter the player to play sound for
function ETW_CommonFunctions.traitSound(player)
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
---@param player IsoPlayer|IsoGameCharacter the player for whom to get mod data
---@return EvolvingTraitsWorldModData EvolvingTraitsWorldModData mod data for the player
function ETW_CommonFunctions.getETWModData(player)
	return player:getModData().EvolvingTraitsWorld
end

---Function responsible printing whole Delayed Traits table into console
---@param player IsoPlayer|IsoGameCharacter the player to dump mod data for
function ETW_CommonFunctions.delayedTraitsDataDump(player)
	if SBvars.DelayedTraitsSystem then
		ETW_CommonFunctions.log("ETW Logger | delayedTraitsDataDump() for player " .. player:getUsername())
		local traitTable = player:getModData().EvolvingTraitsWorld.DelayedTraits
		for index = 1, #traitTable do
			local traitEntry = traitTable[index]
			local traitRegistryId, roll, gained = traitEntry[1], traitEntry[2], traitEntry[3]
			ETW_CommonFunctions.log(
				"ETW Logger | Delayed Traits System | Data Dump: " .. traitRegistryId .. ", " .. roll .. ", " .. tostring(gained)
			)
		end
	end
end

---Adds xp boosts from a trait to a player
---@param player IsoPlayer the player to add xp boosts to
---@param trait CharacterTrait the trait to get xp boosts from
local function addXPBoostsFromTrait(player, trait)
	ETW_CommonFunctions.log(
		"ETW Logger | ETW_CommonFunctions.addXPBoostsFromTrait(): adding xp boosts for trait "
			.. trait:toString()
			.. " to player "
			.. player:getUsername()
	)
	local xpBoostMap = CharacterTraitDefinition.getCharacterTraitDefinition(trait):getXpBoosts()
	if xpBoostMap then
		local table = transformIntoKahluaTable(xpBoostMap)
		for perk, boostLevel in pairs(table) do
			ETW_CommonFunctions.log(
				"ETW Logger | ETW_CommonFunctions.addXPBoostsFromTrait(): perk:"
					.. tostring(perk)
					.. ", boostLevel:"
					.. tostring(boostLevel)
			)
			local oldBoost = player:getXp():getPerkBoost(perk)
			local newBoost = math.min(oldBoost + tonumber(tostring(boostLevel)), 3)
			---@cast newBoost integer
			player:getXp():setPerkBoost(perk, newBoost)
			ETW_CommonFunctions.log(
				"ETW Logger | ETW_CommonFunctions.addXPBoostsFromTrait(): "
					.. tostring(perk)
					.. "old/new boost level:"
					.. oldBoost
					.. player:getXp():getPerkBoost(perk)
			)
		end
	end
end

---Add recipes from a trait to player
---@param player IsoPlayer the player to add recipes to
---@param trait CharacterTrait the trait to get recipes from
local function addRecipes(player, trait)
	local traitDefinition = CharacterTraitDefinition.getCharacterTraitDefinition(trait)
	local freeRecipes = traitDefinition:getGrantedRecipes()
	local playerRecipes = player:getKnownRecipes()
	ETW_CommonFunctions.log(
		"ETW Logger | ETW_CommonFunctions.addRecipes(): adding recipes for trait "
			.. trait:toString()
			.. " to player "
			.. player:getUsername()
	)
	for i = 0, freeRecipes:size() - 1 do
		local recipe = freeRecipes:get(i)
		if not playerRecipes:contains(recipe) then
			ETW_CommonFunctions.log(
				"ETW Logger | ETW_CommonFunctions.addRecipes(): player doesn't have " .. recipe .. ", adding it to known recipes"
			)
			playerRecipes:add(recipe)
		end
	end
end

---Adds trait to a player, it's exp boosts, recipes and plays the sound
---@param player IsoPlayer the player to add trait to
---@param trait CharacterTrait the trait to add
function ETW_CommonFunctions.addTraitToPlayer(player, trait)
	ETW_CommonFunctions.log("ETW Logger | addTraitToPlayer() : adding trait " .. trait:toString() .. " to player " .. player:getUsername())
	player:getCharacterTraits():add(trait)
	addRecipes(player, trait)
	addXPBoostsFromTrait(player, trait)
	ETW_CommonFunctions.traitSound(player)
end

---Removes trait from a player and plays the sound
---@param player IsoPlayer the player to remove trait from
---@param trait CharacterTrait the trait to remove
function ETW_CommonFunctions.removeTraitFromPlayer(player, trait)
	ETW_CommonFunctions.log(
		"ETW Logger | removeTraitFromPlayer() : removing trait " .. trait:toString() .. " from player " .. player:getUsername()
	)
	player:getCharacterTraits():remove(trait)
	ETW_CommonFunctions.traitSound(player)
end

---@class ETWAddTraitToDelayTableContext
---@field player IsoPlayer|IsoGameCharacter the player to add trait to
---@field trait CharacterTrait the trait to add
---@field modData EvolvingTraitsWorldModData the mod data to add trait to
---@field positiveTrait boolean whether the trait is positive or negative, used for notifications
---@field gainingTrait boolean whether the trait is being gained or lost, used for notifications

---Function responsible for adding a trait to a Delayed Traits System. Plays a sound as well.
---@param context ETWAddTraitToDelayTableContext
function ETW_CommonFunctions.addTraitToDelayTable(context)
	if not SBvars.DelayedTraitsSystem then
		return
	end
	local player = context.player
	local trait = context.trait
	local modData = context.modData
	local positiveTrait = context.positiveTrait
	local gainingTrait = context.gainingTrait
	local traitRegistryId = trait:toString()
	local traitDisplayName = CharacterTraitDefinition.getCharacterTraitDefinition(trait):getUIName()
	local textColor = ((positiveTrait and gainingTrait) or (not positiveTrait and not gainingTrait)) and HaloTextHelper.getColorGreen()
		or HaloTextHelper.getColorRed()
	local gainingOrLosingString = gainingTrait and getText("UI_ETW_DelayedNotificationsStringAdd")
		or getText("UI_ETW_DelayedNotificationsStringRemove")
	ETW_CommonFunctions.log(
		"ETW Logger | Delayed Traits System: modData.DelayedStartingTraitsFilled =  " .. tostring(modData.DelayedStartingTraitsFilled)
	)

	ETW_CommonFunctions.traitSound(player)
	if not modData.DelayedStartingTraitsFilled then
		ETW_CommonFunctions.log(
			"ETW Logger | Delayed Traits System: player qualifies for "
				.. traitRegistryId
				.. " from the start of the game, adding it to delayed traits table"
		)
		table.insert(
			modData.DelayedTraits,
			{ traitRegistryId, SBvars.DelayedTraitsSystemDefaultDelay + SBvars.DelayedTraitsSystemDefaultStartingDelay, false }
		)
	elseif indexOfDelayedTrait(modData.DelayedTraits, traitRegistryId) == -1 and not player:hasTrait(trait) and positiveTrait then
		ETW_CommonFunctions.log(
			"ETW Logger | Delayed Traits System: player qualifies for positive trait "
				.. traitRegistryId
				.. ", adding it to delayed traits table"
		)
        table.insert(modData.DelayedTraits, { traitRegistryId, SBvars.DelayedTraitsSystemDefaultDelay, false })
		ETW_CommonFunctions.displayDelayedTraitNotification(player, gainingOrLosingString .. traitDisplayName, gainingTrait, textColor)
	elseif indexOfDelayedTrait(modData.DelayedTraits, traitRegistryId) == -1 and player:hasTrait(trait) and not positiveTrait then
		ETW_CommonFunctions.log(
			"ETW Logger | Delayed Traits System: player qualifies for removing negative trait "
				.. traitRegistryId
				.. ", adding it to delayed traits table"
		)
		table.insert(modData.DelayedTraits, { traitRegistryId, SBvars.DelayedTraitsSystemDefaultDelay, false })
		ETW_CommonFunctions.displayDelayedTraitNotification(player, gainingOrLosingString .. traitDisplayName, gainingTrait, textColor)
	else
		ETW_CommonFunctions.log(
			"ETW Logger | Delayed Traits System: player qualifies for "
				.. traitRegistryId
				.. ", but it's already in delayed traits table or player already has the trait"
		)
	end
	if detailedDebug() then
		print("ETW Logger | Delayed Traits System | Data Dump after ETW_CommonFunctions.addTraitToDelayTable() START ------------")
		ETW_CommonFunctions.delayedTraitsDataDump(player)
		print("ETW Logger | Delayed Traits System | Data Dump after ETW_CommonFunctions.addTraitToDelayTable() END --------------")
	end
end

---Function responsible for checking if specific trait should be gained/lost, returns true if yes and removes it from the table. Otherwise, returns false.
---Function assumes that trait is in Delayed Traits table, so make sure to check that before calling this function, otherwise it will throw an error
---@param player IsoPlayer|IsoGameCharacter the player to check
---@param traitToCheck CharacterTrait the trait to check
---@return boolean boolean true if trait should be gained/lost, false otherwise
function ETW_CommonFunctions.checkDelayedTraits(player, traitToCheck)
    if not SBvars.DelayedTraitsSystem then
        return true
    end
	ETW_CommonFunctions.log("ETW Logger | ETW_CommonFunctions.checkDelayedTraits(): running for player " .. player:getUsername())	
	local traitRegistryId = traitToCheck:toString()
	local modData = ETW_CommonFunctions.getETWModData(player)
	local traitTable = modData.DelayedTraits
	local traitEntry = traitTable[indexOfDelayedTrait(modData.DelayedTraits, traitRegistryId)]
	local traitNameInTable, gained = traitEntry[1], traitEntry[3]
	ETW_CommonFunctions.log("ETW Logger | ETW_CommonFunctions.checkDelayedTraits(): caught check on " .. traitRegistryId)
	if traitNameInTable == traitRegistryId and gained then
		ETW_CommonFunctions.log(
			"ETW Logger | ETW_CommonFunctions.checkDelayedTraits(): caught check on "
				.. traitRegistryId
				.. ": player qualifies for it, removing it from the table"
		)
		table.remove(traitTable, indexOfDelayedTrait(modData.DelayedTraits, traitRegistryId))
		return true
	end
	return false
end

---Function responsible for checking if specific trait is already in Delayed Traits System
---@param player IsoPlayer|IsoGameCharacter the player to check
---@param trait CharacterTrait the trait to check
---@return boolean boolean true if trait is in Delayed Traits table, false otherwise
function ETW_CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, trait)
	ETW_CommonFunctions.log("ETW Logger | checkIfTraitIsInDelayedTraitsTable(): running for player " .. player:getUsername())
	local modData = ETW_CommonFunctions.getETWModData(player)
	local traitTable = modData.DelayedTraits
	local traitRegistryId = trait:toString()
	if indexOfDelayedTrait(modData.DelayedTraits, traitRegistryId) ~= -1 then
		ETW_CommonFunctions.log("ETW Logger | checkIfTraitIsInDelayedTraitsTable(): checking if " .. traitRegistryId .. " is already in the table, it is.")	
		return true
	end
	ETW_CommonFunctions.log("ETW Logger | checkIfTraitIsInDelayedTraitsTable(): checking if " .. traitRegistryId .. " is already in the table, it is not.")
	return false
end

---Shows notification for trait gain/loss. If it's SP client, it's displayed trait gain/loss notification to client. If it's called on a server, it sends a command to the client to display the notification. Then the client checks if notification should be displayed based on per-client mod settings.
---@param player IsoPlayer player to show notification for
---@param text string text to show in notification
---@param arrowIsUp boolean whether the arrow in notification should be up or down, True for up, False for down
---@param color HaloTextHelper.ColorRGB color of the text in notification
function ETW_CommonFunctions.displayTraitNotification(player, text, arrowIsUp, color)
	if gameMode == ETW_CommonFunctions.GameMode.MP_SERVER then
		sendServerCommand(player, "ETW", "displayTraitNotification", { text = text, arrowIsUp = arrowIsUp, color = color })
	elseif notification() then
		HaloTextHelper.addTextWithArrow(player, text, arrowIsUp, color)
	end
end

---Shows notification for delayed trait gain/loss. If it's SP client, it's displayed trait gain/loss notification to client. If it's called on a server, it sends a command to the client to display the notification. Then the client checks if notification should be displayed based on per-client mod settings.
---@param player IsoPlayer|IsoGameCharacter player to show notification for
---@param text string text to show in notification
---@param arrowIsUp boolean whether the arrow in notification should be up or down, True for up, False for down
---@param color HaloTextHelper.ColorRGB color of the text in notification
function ETW_CommonFunctions.displayDelayedTraitNotification(player, text, arrowIsUp, color)
	---@cast player IsoPlayer
	if gameMode == ETW_CommonFunctions.GameMode.MP_SERVER then
		sendServerCommand(player, "ETW", "displayDelayedTraitNotification", { text = text, arrowIsUp = arrowIsUp, color = color })
	elseif delayedNotification() then
		HaloTextHelper.addTextWithArrow(player, text, arrowIsUp, color)
	end
end

return ETW_CommonFunctions
