---@class ETW_CommonFunctions
local ETW_CommonFunctions = {}
local ETW_ModData

---@type EvolvingTraitsWorldSandboxVars
local SBvars = SandboxVars.EvolvingTraitsWorld

local modOptions

local random_instance = newrandom()

local paranoiaManScreams = {
	"ETW_ParanoiaManScream1",
	"ETW_ParanoiaManScream2",
	"ETW_ParanoiaManScream3",
	"ETW_ParanoiaManScream4",
	"ETW_ParanoiaManScream5",
	"ETW_ParanoiaManScream6",
}

local paranoiaWomanScreams = {
	"ETW_ParanoiaWomanScream1",
	"ETW_ParanoiaWomanScream2",
	"ETW_ParanoiaWomanScream3",
	"ETW_ParanoiaWomanScream4",
	"ETW_ParanoiaWomanScream5",
	"ETW_ParanoiaWomanScream6",
}

---Returns the client-configured Paranoia scream volume as a 0-1 multiplier.
---@return number
local function paranoiaScreamVolume()
	if modOptions then
		local option = modOptions:getOption("ParanoiaScreamVolume")
		if option then
			return PZMath.clamp(option:getValue(), 0, 100) / 100
		end
	end
	return 1
end

---Plays the local false-scare sounds used by Paranoia.
---@param player IsoPlayer
---@param yell boolean
function ETW_CommonFunctions.playParanoiaScare(player, yell)
	local surprisedSoundID = player:playSound("ZombieSurprisedPlayer")
	local yellSound
	local yellSoundID
	local screamVolume = paranoiaScreamVolume()
	if yell then
		local screams = player:isFemale() and paranoiaWomanScreams or paranoiaManScreams
		yellSound = screams[random_instance:random(1, #screams)]
		if yellSound and screamVolume > 0 then
			yellSoundID = player:playSound(yellSound)
			if yellSoundID and yellSoundID >= 0 then
				player:getEmitter():setVolume(yellSoundID, screamVolume)
			end
		end
	end
	ETW_CommonFunctions.log(
		"ETW Logger | playParanoiaScare(): played ZombieSurprisedPlayer; sound ID="
			.. tostring(surprisedSoundID)
			.. "; yell: "
			.. tostring(yellSound ~= nil)
			.. "; scream volume: "
			.. screamVolume * 100
			.. "%"
			.. (yellSound and "; " .. yellSound .. " sound ID=" .. tostring(yellSoundID) or "")
			.. "; player: "
			.. tostring(player:getUsername())
	)
end

--- @type {SP: "SP", MP_CLIENT: "MP_Client", MP_SERVER: "MP_Server"}
ETW_CommonFunctions.GameMode = {
	SP = "SP",
	MP_CLIENT = "MP_Client",
	MP_SERVER = "MP_Server",
}

---Function responsible for determining the current game mode, returns "SP" for single player, "MP_Client" for multiplayer client and "MP_Server" for multiplayer server
---@return "SP"|"MP_Client"|"MP_Server"
function ETW_CommonFunctions.gameMode()
	if not isClient() and not isServer() then
		return ETW_CommonFunctions.GameMode.SP
	elseif isClient() then
		return ETW_CommonFunctions.GameMode.MP_CLIENT
	end
	return ETW_CommonFunctions.GameMode.MP_SERVER
end

local gameMode = ETW_CommonFunctions.gameMode()

---Checks if the current game mode is in the allowed list.
---Returns true if the file should load, false if it should be skipped.
---Prints a message either way using the provided filename prefix.
---@param filename string The name of the calling file, used as a log prefix
---@param allowedModes table A list of ETW_CommonFunctions.GameMode values that are allowed to load this file
---@return boolean boolean true if current gameMode is in allowedModes, false otherwise
function ETW_CommonFunctions.gameModeSafeguard(filename, allowedModes)
	for _, mode in ipairs(allowedModes) do
		if gameMode == mode then
			print(filename .. " | Detected " .. gameMode .. " environment, loading the file")
			return true
		end
	end
	print(filename .. " | Detected " .. gameMode .. " environment, skipping the file")
	return false
end

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

---Returns whether the Butterfingers popup is enabled.
---@return boolean
local butterfingersPopup = function()
	if modOptions then
		return modOptions:getOption("EnableButterfingersPopup"):getValue()
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

---Applies Affinity System gain/loss rates to progress toward either of two opposing starting traits. This function assumes that negative change = moving towards negative change, and positive change = moving towards positive change.
---@param modData EvolvingTraitsWorldModData
---@param change number the change to apply to progress, can be positive or negative
---@param negativeTrait CharacterTrait|nil Trait favored by negative progress
---@param positiveTrait CharacterTrait|nil Trait favored by positive progress
---@return number
function ETW_CommonFunctions.applyAffinityToDirectionalChange(modData, change, negativeTrait, positiveTrait)
	if not SBvars.AffinitySystem or change == 0 then
		return change
	end

	local startingTraits = modData.StartingTraits
	local startedWithNegativeTrait = negativeTrait ~= nil and startingTraits[negativeTrait:toString()] == true
	local startedWithPositiveTrait = positiveTrait ~= nil and startingTraits[positiveTrait:toString()] == true
	if change < 0 then
		if startedWithNegativeTrait then
			return change * SBvars.AffinitySystemGainMultiplier
		elseif startedWithPositiveTrait then
			return change / SBvars.AffinitySystemLoseDivider
		end
	elseif startedWithPositiveTrait then
		return change * SBvars.AffinitySystemGainMultiplier
	elseif startedWithNegativeTrait then
		return change / SBvars.AffinitySystemLoseDivider
	end

	return change
end

---Function that returns ArrayList of all players in case its called on Server, all ever loaded players in case it's called on MP Client, or local player list in case it's called on SP. If player is passed as argument, returns list with only that player.
---Later can be looped over like:
---
---    for i = 0, playerList:size() - 1 do
---        local player = playerList:get(i)
---    end
---@param player IsoPlayer|nil optional player to get list for
---@return ArrayList<IsoPlayer> ArrayList of all players in case its called on Server, all ever loaded players in case it's called on MP Client, or local player list in case it's called on SP.
function ETW_CommonFunctions.playersList(player)
	if player then
		local playerList = ArrayList.new()
		playerList:add(player)
		return playerList
	end

	local playerList = getOnlinePlayers()
	if playerList:isEmpty() then
		local localPlayer = getPlayer()
		if localPlayer then
			playerList:add(localPlayer)
		end
	end

	return playerList
end

---Resolves either a trait object or registry id string into a CharacterTrait instance.
---@param traitOrRegistryId CharacterTrait|string
---@return CharacterTrait|nil
function ETW_CommonFunctions.resolveTrait(traitOrRegistryId)
	ETW_CommonFunctions.log("Resolving type " .. tostring(type(traitOrRegistryId)))
	if instanceof(traitOrRegistryId, "CharacterTrait") then
		ETW_CommonFunctions.log("Resolving trait CharacterTrait: " .. tostring(traitOrRegistryId))
		return traitOrRegistryId
	end
	if type(traitOrRegistryId) == "string" then
		ETW_CommonFunctions.log("Resolving trait string: " .. traitOrRegistryId)
		return CharacterTrait.get(ResourceLocation.of(traitOrRegistryId))
	end
	return nil
end

---Plays a sound if enabled in settings
---@param player IsoPlayer|IsoGameCharacter the player to play sound for
function ETW_CommonFunctions.traitSound(player)
	if gameMode == ETW_CommonFunctions.GameMode.MP_SERVER then
		sendServerCommand(player, "ETW", "traitSound", {})
	else
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
			if #filteredSoundTable > 0 then
				player:playSoundLocal(filteredSoundTable[random_instance:random(1, #filteredSoundTable)])
			end
		end
	end
end

---Plays the Indefatigable theme for the owning player if enabled in their client settings.
---@param player IsoPlayer|IsoGameCharacter the player to play the theme for
function ETW_CommonFunctions.indefatigableTheme(player)
	if gameMode == ETW_CommonFunctions.GameMode.MP_SERVER then
		sendServerCommand(player, "ETW", "indefatigableTheme", {})
	elseif modOptions and modOptions:getOption("EnableIndefatigableTheme"):getValue() then
		player:playSoundLocal("ETW_IndefatigableTheme")
	end
end

---Returns ETW mod data
---@param player IsoPlayer|IsoGameCharacter the player for whom to get mod data
---@return EvolvingTraitsWorldModData|nil EvolvingTraitsWorldModData mod data for the player
function ETW_CommonFunctions.getETWModData(player)
	if not player or not player.getModData then
		return nil
	end
	local modData = player:getModData()
	if not modData then
		return nil
	end
	if not ETW_ModData then
		ETW_ModData = require("ETW_ModData")
	end
	if not modData.EvolvingTraitsWorld then
		ETW_ModData.createETWModData(player:getPlayerNum(), player)
	end
	return modData.EvolvingTraitsWorld
end

---Immediately refreshes ETW ModData on the owning multiplayer client.
---@param player IsoPlayer|IsoGameCharacter
function ETW_CommonFunctions.syncETWModDataToClient(player)
	if gameMode ~= ETW_CommonFunctions.GameMode.MP_SERVER then
		return
	end
	local modData = ETW_CommonFunctions.getETWModData(player)
	if modData then
		sendServerCommand(player, "ETW", "refreshETWModDataFromServer", { ETWModData = modData })
	end
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
				"ETW Logger | Delayed Traits System | Data Dump: "
					.. traitRegistryId
					.. ", "
					.. roll
					.. ", "
					.. tostring(gained)
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
				"ETW Logger | ETW_CommonFunctions.addRecipes(): player doesn't have "
					.. recipe
					.. ", adding it to known recipes"
			)
			playerRecipes:add(recipe)
		end
	end
end

---@class ETWAddTraitToPlayerContext
---@field player IsoPlayer|IsoGameCharacter the player to add trait to
---@field trait CharacterTrait the trait to add
---@field positiveTrait boolean whether the trait is positive or negative, used for notifications

---Adds trait to a player, its exp boosts, recipes, sound and notification.
---@param context ETWAddTraitToPlayerContext
function ETW_CommonFunctions.addTraitToPlayer(context)
	if SBvars.DisableAllDynamicTraits == true then
		return
	end
	local player = context.player
	local trait = context.trait
	if player:hasTrait(trait) then
		ETW_CommonFunctions.log(
			"ETW Logger | addTraitToPlayer() : player "
				.. player:getUsername()
				.. " already has trait "
				.. trait:toString()
				.. ", skipping"
		)
		return
	end
	ETW_CommonFunctions.log(
		"ETW Logger | addTraitToPlayer() : adding trait " .. trait:toString() .. " to player " .. player:getUsername()
	)
	player:getCharacterTraits():add(trait)
	addRecipes(player, trait)
	addXPBoostsFromTrait(player, trait)
	ETW_CommonFunctions.traitSound(player)
	local gainingTrait = true
	local color = context.positiveTrait == gainingTrait and "GREEN" or "RED"
	ETW_CommonFunctions.displayTraitNotification(player, trait:toString(), gainingTrait, color)
end

---@class ETWRemoveTraitFromPlayerContext
---@field player IsoPlayer|IsoGameCharacter the player to remove trait from
---@field trait CharacterTrait the trait to remove
---@field positiveTrait boolean whether the trait is positive or negative, used for notifications

---Removes trait from a player, plays the sound and shows notification.
---@param context ETWRemoveTraitFromPlayerContext
function ETW_CommonFunctions.removeTraitFromPlayer(context)
	if SBvars.DisableAllDynamicTraits == true then
		return
	end
	local player = context.player
	local trait = context.trait
	ETW_CommonFunctions.log(
		"ETW Logger | removeTraitFromPlayer() : removing trait "
			.. trait:toString()
			.. " from player "
			.. player:getUsername()
	)
	player:getCharacterTraits():remove(trait)
	ETW_CommonFunctions.traitSound(player)
	local gainingTrait = false
	local color = context.positiveTrait == gainingTrait and "GREEN" or "RED"
	ETW_CommonFunctions.displayTraitNotification(player, trait:toString(), gainingTrait, color)
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
	if SBvars.DisableAllDynamicTraits == true or not SBvars.DelayedTraitsSystem then
		return
	end
	local player = context.player
	local trait = context.trait
	local modData = context.modData
	local positiveTrait = context.positiveTrait
	local gainingTrait = context.gainingTrait
	local traitRegistryId = trait:toString()
	local traitIsQueued = indexOfDelayedTrait(modData.DelayedTraits, traitRegistryId) ~= -1
	local playerHasTrait = player:hasTrait(trait)
	if traitIsQueued or (gainingTrait and playerHasTrait) or (not gainingTrait and not playerHasTrait) then
		ETW_CommonFunctions.log(
			"ETW Logger | Delayed Traits System: skipping "
				.. traitRegistryId
				.. " because it is already queued or the requested change no longer applies"
		)
		return
	end
	ETW_CommonFunctions.log(
		"ETW Logger | Delayed Traits System: modData.DelayedStartingTraitsFilled =  "
			.. tostring(modData.DelayedStartingTraitsFilled)
	)
	if not modData.DelayedStartingTraitsFilled then
		ETW_CommonFunctions.log(
			"ETW Logger | Delayed Traits System: player qualifies for "
				.. traitRegistryId
				.. " from the start of the game, adding it to delayed traits table"
		)
		table.insert(modData.DelayedTraits, {
			traitRegistryId,
			SBvars.DelayedTraitsSystemDefaultDelay + SBvars.DelayedTraitsSystemDefaultStartingDelay,
			false,
			gainingTrait,
		})
		ETW_CommonFunctions.traitSound(player)
	elseif positiveTrait then
		ETW_CommonFunctions.log(
			"ETW Logger | Delayed Traits System: player qualifies for positive trait "
				.. traitRegistryId
				.. ", adding it to delayed traits table"
		)
		table.insert(
			modData.DelayedTraits,
			{ traitRegistryId, SBvars.DelayedTraitsSystemDefaultDelay, false, gainingTrait }
		)
		ETW_CommonFunctions.displayDelayedTraitNotification(player, gainingTrait, traitRegistryId, true, "GREEN")
		ETW_CommonFunctions.traitSound(player)
	elseif not positiveTrait then
		ETW_CommonFunctions.log(
			"ETW Logger | Delayed Traits System: player qualifies for removing negative trait "
				.. traitRegistryId
				.. ", adding it to delayed traits table"
		)
		table.insert(
			modData.DelayedTraits,
			{ traitRegistryId, SBvars.DelayedTraitsSystemDefaultDelay, false, gainingTrait }
		)
		ETW_CommonFunctions.displayDelayedTraitNotification(player, gainingTrait, traitRegistryId, false, "GREEN")
		ETW_CommonFunctions.traitSound(player)
	else
		ETW_CommonFunctions.log(
			"ETW Logger | Delayed Traits System: player qualifies for "
				.. traitRegistryId
				.. ", but it's already in delayed traits table or player already has the trait"
		)
	end
	if detailedDebug() then
		print(
			"ETW Logger | Delayed Traits System | Data Dump after ETW_CommonFunctions.addTraitToDelayTable() START ------------"
		)
		ETW_CommonFunctions.delayedTraitsDataDump(player)
		print(
			"ETW Logger | Delayed Traits System | Data Dump after ETW_CommonFunctions.addTraitToDelayTable() END --------------"
		)
	end
	ETW_CommonFunctions.syncETWModDataToClient(player)
end

---Function responsible for checking if specific trait should be gained/lost, returns true if yes and removes it from the table. Otherwise, returns false.
---Function assumes that trait is in Delayed Traits table, so make sure to check that before calling this function, otherwise it will throw an error
---@param player IsoPlayer|IsoGameCharacter the player to check
---@param traitToCheck CharacterTrait the trait to check
---@return boolean boolean true if trait should be gained/lost, false otherwise
function ETW_CommonFunctions.checkDelayedTraits(player, traitToCheck)
	if SBvars.DisableAllDynamicTraits == true then
		return false
	end
	if not SBvars.DelayedTraitsSystem then
		return true
	end
	ETW_CommonFunctions.log(
		"ETW Logger | ETW_CommonFunctions.checkDelayedTraits(): running for player " .. player:getUsername()
	)
	local traitRegistryId = traitToCheck:toString()
	local modData = ETW_CommonFunctions.getETWModData(player)
	local traitTable = modData.DelayedTraits
	local traitIndex = indexOfDelayedTrait(modData.DelayedTraits, traitRegistryId)
	if traitIndex == -1 then
		ETW_CommonFunctions.log(
			"ETW Logger | ETW_CommonFunctions.checkDelayedTraits(): "
				.. traitRegistryId
				.. " is not in DelayedTraits, returning false"
		)
		return false
	end
	local traitEntry = traitTable[traitIndex]
	if not traitEntry then
		ETW_CommonFunctions.log(
			"ETW Logger | ETW_CommonFunctions.checkDelayedTraits(): "
				.. traitRegistryId
				.. " has a nil DelayedTraits entry at index "
				.. traitIndex
				.. ", returning false"
		)
		return false
	end
	local traitNameInTable, gained = traitEntry[1], traitEntry[3]
	ETW_CommonFunctions.log(
		"ETW Logger | ETW_CommonFunctions.checkDelayedTraits(): caught check on " .. traitRegistryId
	)
	if traitNameInTable == traitRegistryId and gained then
		ETW_CommonFunctions.log(
			"ETW Logger | ETW_CommonFunctions.checkDelayedTraits(): caught check on "
				.. traitRegistryId
				.. ": player qualifies for it, removing it from the table"
		)
		table.remove(traitTable, traitIndex)
		ETW_CommonFunctions.syncETWModDataToClient(player)
		return true
	end
	return false
end

---Function responsible for checking if specific trait is already in Delayed Traits System
---@param player IsoPlayer|IsoGameCharacter the player to check
---@param trait CharacterTrait the trait to check
---@return boolean boolean true if trait is in Delayed Traits table, false otherwise
function ETW_CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, trait)
	ETW_CommonFunctions.log(
		"ETW Logger | checkIfTraitIsInDelayedTraitsTable(): running for player " .. player:getUsername()
	)
	local modData = ETW_CommonFunctions.getETWModData(player)
	local traitTable = modData.DelayedTraits
	local traitRegistryId = trait:toString()
	if indexOfDelayedTrait(modData.DelayedTraits, traitRegistryId) ~= -1 then
		ETW_CommonFunctions.log(
			"ETW Logger | checkIfTraitIsInDelayedTraitsTable(): checking if "
				.. traitRegistryId
				.. " is already in the table, it is."
		)
		return true
	end
	ETW_CommonFunctions.log(
		"ETW Logger | checkIfTraitIsInDelayedTraitsTable(): checking if "
			.. traitRegistryId
			.. " is already in the table, it is not."
	)
	return false
end

---Shows Butterfingers' red halo popup. In MP, the server asks the affected player's client to display it;
---the receiving client then applies its local Mod Options preference.
---@param player IsoPlayer
function ETW_CommonFunctions.displayButterfingersPopup(player)
	if gameMode == ETW_CommonFunctions.GameMode.MP_SERVER then
		sendServerCommand(player, "ETW", "displayButterfingersPopup", {})
	elseif butterfingersPopup() then
		local trait = CharacterTrait.get(ResourceLocation.of("ETW:Butterfingers"))
		local traitName = CharacterTraitDefinition.getCharacterTraitDefinition(trait):getUIName()
		HaloTextHelper.addText(player, traitName .. "!", "[br/]", HaloTextHelper.getColorRed())
		ETW_CommonFunctions.log("ETW Logger | displayButterfingersPopup(): displayed")
	end
end

---Drops held items locally, or asks the owning client to do so when called by an MP server.
---@param player IsoPlayer
function ETW_CommonFunctions.dropButterfingersHandItems(player)
	if gameMode == ETW_CommonFunctions.GameMode.MP_SERVER then
		sendServerCommand(player, "ETW", "dropButterfingersHandItems", {})
		ETW_CommonFunctions.log(
			"ETW Logger | dropButterfingersHandItems(): requested client-side drop for " .. player:getUsername()
		)
	else
		player:dropHandItems()
		ETW_CommonFunctions.log("ETW Logger | dropButterfingersHandItems(): executed locally")
	end
end

---Triggers a Noodle Legs fall locally, or asks the owning client to do so when called by an MP server.
---@param player IsoPlayer
---@param side "left"|"right"
function ETW_CommonFunctions.triggerNoodleLegsTrip(player, side)
	if gameMode == ETW_CommonFunctions.GameMode.MP_SERVER then
		sendServerCommand(player, "ETW", "triggerNoodleLegsTrip", { side = side })
		ETW_CommonFunctions.log(
			"ETW Logger | triggerNoodleLegsTrip(): requested client-side trip for "
				.. player:getUsername()
				.. "; side: "
				.. side
		)
		return
	end
	player:setBumpFallType("FallForward")
	player:setBumpType(side)
	player:setBumpDone(false)
	player:setBumpFall(true)
	player:reportEvent("wasBumped")
	ETW_CommonFunctions.log("ETW Logger | triggerNoodleLegsTrip(): executed locally; side: " .. side)
end

---Staggers a Bouncer target authoritatively and mirrors the result on the owning MP client.
---@param player IsoPlayer
---@param zombie IsoZombie
---@param knockDown boolean|nil
function ETW_CommonFunctions.triggerBouncerStagger(player, zombie, knockDown)
	zombie:setStaggerBack(true)
	if knockDown then
		zombie:setKnockedDown(true)
	end
	if gameMode == ETW_CommonFunctions.GameMode.MP_SERVER then
		local zombieOnlineID = zombie:getOnlineID()
		sendServerCommand(player, "ETW", "triggerBouncerStagger", {
			zombieOnlineID = zombieOnlineID,
			knockDown = knockDown == true,
		})
		ETW_CommonFunctions.log(
			"ETW Logger | triggerBouncerStagger(): applied on server and requested client mirror for "
				.. tostring(player:getUsername())
				.. " (OnlineID="
				.. player:getOnlineID()
				.. "); zombie OnlineID="
				.. zombieOnlineID
				.. "; knockdown: "
				.. tostring(knockDown == true)
		)
		return
	end
	ETW_CommonFunctions.log(
		"ETW Logger | triggerBouncerStagger(): executed locally; zombie OnlineID="
			.. zombie:getOnlineID()
			.. "; knockdown: "
			.. tostring(knockDown == true)
	)
end

---Captures the wound movement-speed modifiers for every body part.
---@param bodyDamage BodyDamage
---@return table[] snapshots
function ETW_CommonFunctions.captureWoundSpeedModifiers(bodyDamage)
	local snapshots = {}
	local parts = bodyDamage:getBodyParts()
	for i = 0, parts:size() - 1 do
		local part = parts:get(i)
		snapshots[i + 1] = {
			scratch = part:getScratchSpeedModifier(),
			cut = part:getCutSpeedModifier(),
			deepWound = part:getDeepWoundSpeedModifier(),
			burn = part:getBurnSpeedModifier(),
		}
	end
	return snapshots
end

---Suppresses all wound movement-speed penalties without reducing stronger existing modifiers.
---@param bodyDamage BodyDamage
function ETW_CommonFunctions.suppressWoundMovementPenalties(bodyDamage)
	local parts = bodyDamage:getBodyParts()
	for i = 0, parts:size() - 1 do
		local part = parts:get(i)
		part:setScratchSpeedModifier(math.max(100, part:getScratchSpeedModifier()))
		part:setCutSpeedModifier(math.max(100, part:getCutSpeedModifier()))
		part:setDeepWoundSpeedModifier(math.max(100, part:getDeepWoundSpeedModifier()))
		part:setBurnSpeedModifier(math.max(100, part:getBurnSpeedModifier()))
	end
end

---Removes only the temporary contribution required to raise captured wound-speed modifiers to 100.
---Modifiers added by other effects while suppression was active are preserved.
---@param current number
---@param captured unknown
---@return number
local function restoreSuppressedWoundSpeedModifier(current, captured)
	captured = tonumber(captured) or 0
	local protectedValue = math.max(100, captured)
	return captured + math.max(0, current - protectedValue)
end

---@param bodyDamage BodyDamage
---@param snapshots table[]|nil
function ETW_CommonFunctions.restoreWoundSpeedModifiers(bodyDamage, snapshots)
	if not snapshots then
		return
	end
	local parts = bodyDamage:getBodyParts()
	for i = 0, parts:size() - 1 do
		local snapshot = snapshots[i + 1]
		if snapshot then
			local part = parts:get(i)
			part:setScratchSpeedModifier(
				restoreSuppressedWoundSpeedModifier(part:getScratchSpeedModifier(), snapshot.scratch)
			)
			part:setCutSpeedModifier(restoreSuppressedWoundSpeedModifier(part:getCutSpeedModifier(), snapshot.cut))
			part:setDeepWoundSpeedModifier(
				restoreSuppressedWoundSpeedModifier(part:getDeepWoundSpeedModifier(), snapshot.deepWound)
			)
			part:setBurnSpeedModifier(restoreSuppressedWoundSpeedModifier(part:getBurnSpeedModifier(), snapshot.burn))
		end
	end
end

---Reduces the movement-speed penalties contributed by common wound types.
---@param bodyDamage BodyDamage
---@param scratchModifier number
---@param cutModifier number
---@param deepWoundModifier number
---@param burnModifier number
---@return integer affectedParts
function ETW_CommonFunctions.applyUnwaveringInjurySpeedModifiers(
	bodyDamage,
	scratchModifier,
	cutModifier,
	deepWoundModifier,
	burnModifier
)
	local parts = bodyDamage:getBodyParts()
	for i = 0, parts:size() - 1 do
		local part = parts:get(i)
		part:setScratchSpeedModifier(part:getScratchSpeedModifier() + scratchModifier)
		part:setCutSpeedModifier(part:getCutSpeedModifier() + cutModifier)
		part:setDeepWoundSpeedModifier(part:getDeepWoundSpeedModifier() + deepWoundModifier)
		part:setBurnSpeedModifier(part:getBurnSpeedModifier() + burnModifier)
	end
	return parts:size()
end

---Shows notification for trait gain/loss. If it's SP client, it's displayed trait gain/loss notification to client. If it's called on a server, it sends a command to the client to display the notification. Then the client checks if notification should be displayed based on per-client mod settings.
---@param player IsoPlayer player to show notification for
---@param traitRegistryId string the trait registry id of the trait
---@param arrowIsUp boolean whether the arrow in notification should be up or down, True for up, False for down
---@param color string color of the text in notification, "RED" or "GREEN"
function ETW_CommonFunctions.displayTraitNotification(player, traitRegistryId, arrowIsUp, color)
	if gameMode == ETW_CommonFunctions.GameMode.MP_SERVER then
		sendServerCommand(
			player,
			"ETW",
			"displayTraitNotification",
			{ traitRegistryId = traitRegistryId, arrowIsUp = arrowIsUp, color = color }
		)
	elseif notification() then
		local colorToUse = HaloTextHelper.getColorRed()
		if color == "GREEN" then
			colorToUse = HaloTextHelper.getColorGreen()
		end
		local trait = CharacterTrait.get(ResourceLocation.of(traitRegistryId))
		HaloTextHelper.addTextWithArrow(
			player,
			CharacterTraitDefinition.getCharacterTraitDefinition(trait):getUIName(),
			arrowIsUp,
			colorToUse
		)
	end
end

---Shows notification for delayed trait gain/loss. If it's SP client, it's displayed trait gain/loss notification to client. If it's called on a server, it sends a command to the client to display the notification. Then the client checks if notification should be displayed based on per-client mod settings.
---@param player IsoPlayer|IsoGameCharacter player to show notification for
---@param gainingTrait boolean true if gaining trait, false if losing trait
---@param traitRegistryId string the trait registry id of the trait
---@param arrowIsUp boolean whether the arrow in notification should be up or down, True for up, False for down
---@param color string color of the text in notification, "RED" or "GREEN"
function ETW_CommonFunctions.displayDelayedTraitNotification(player, gainingTrait, traitRegistryId, arrowIsUp, color)
	if gameMode == ETW_CommonFunctions.GameMode.MP_SERVER then
		--- can't pass java HaloTextHelper object over network, use string instead
		sendServerCommand(
			player,
			"ETW",
			"displayDelayedTraitNotification",
			{ gainingTrait = gainingTrait, traitRegistryId = traitRegistryId, arrowIsUp = arrowIsUp, color = color }
		)
	elseif delayedNotification() then
		local colorToUse = HaloTextHelper.getColorRed()
		if color == "GREEN" then
			colorToUse = HaloTextHelper.getColorGreen()
		end
		local gainingOrLosingString = gainingTrait and getText("UI_ETW_DelayedNotificationsStringAdd")
			or getText("UI_ETW_DelayedNotificationsStringRemove")
		local trait = CharacterTrait.get(ResourceLocation.of(traitRegistryId))
		HaloTextHelper.addTextWithArrow(
			player,
			gainingOrLosingString .. CharacterTraitDefinition.getCharacterTraitDefinition(trait):getUIName(),
			arrowIsUp,
			colorToUse
		)
	end
end

return ETW_CommonFunctions
