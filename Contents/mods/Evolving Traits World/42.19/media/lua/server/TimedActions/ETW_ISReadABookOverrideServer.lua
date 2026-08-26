local ETW_CommonFunctions = require("ETW_CommonFunctions")
local ETW_CommonLogicChecks = require("ETW_CommonLogicChecks")
local ETW_Registry = require("ETW_Registry")

---@type EvolvingTraitsWorldSandboxVars
local SBvars = SandboxVars.EvolvingTraitsWorld

---@type fun(...: string)
local logETW = ETW_CommonFunctions.log

---@type EvolvingTraitsWorldTraitsRegistries
local ETWTraitsRegistry = ETW_Registry.traits

local FILENAME = "ETW_ISReadABookOverrideServer.lua"

if
	not ETW_CommonFunctions.gameModeSafeguard(
		FILENAME,
		{ ETW_CommonFunctions.GameMode.SP, ETW_CommonFunctions.GameMode.MP_SERVER }
	)
then
	return
end

local currentlyReadingBook = {}
local DEFAULT_NUMBER_OF_PAGES = 5

local asceticComicTypes = {
	["Base.ComicBook"] = true,
	["Base.ComicBook_Retail"] = true,
}

---@class AsceticComicMoodSnapshot
---@field boredom number
---@field stress number
---@field unhappiness number

---Captures the mood state that reading a comic must not improve for an Ascetic.
---@param action ISReadABook
---@param completed boolean
---@return AsceticComicMoodSnapshot|nil
local function captureAsceticComicMood(action, completed)
	if
		not completed
		or SBvars.AsceticReadingEffect == false
		or not action.character:hasTrait(ETWTraitsRegistry.ASCETIC)
		or not asceticComicTypes[action.item:getFullType()]
	then
		return nil
	end

	local stats = action.character:getStats()
	return {
		boredom = stats:get(CharacterStat.BOREDOM),
		stress = stats:get(CharacterStat.STRESS),
		unhappiness = stats:get(CharacterStat.UNHAPPINESS),
	}
end

---Restores any mood reductions granted by a completed comic.
---@param action ISReadABook
---@param snapshot AsceticComicMoodSnapshot|nil
local function suppressAsceticComicMood(action, snapshot)
	if not snapshot then
		return
	end

	local stats = action.character:getStats()
	local boredomAfter = stats:get(CharacterStat.BOREDOM)
	local stressAfter = stats:get(CharacterStat.STRESS)
	local unhappinessAfter = stats:get(CharacterStat.UNHAPPINESS)
	stats:set(CharacterStat.BOREDOM, math.max(boredomAfter, snapshot.boredom))
	stats:set(CharacterStat.STRESS, math.max(stressAfter, snapshot.stress))
	stats:set(CharacterStat.UNHAPPINESS, math.max(unhappinessAfter, snapshot.unhappiness))
	logETW(
		"ETW Logger | Ascetic comic: suppressed mood benefits for "
			.. tostring(action.character:getUsername())
			.. " (OnlineID="
			.. action.character:getOnlineID()
			.. "); item: "
			.. action.item:getFullType()
			.. "; boredom: "
			.. boredomAfter
			.. "->"
			.. stats:get(CharacterStat.BOREDOM)
			.. "; stress: "
			.. stressAfter
			.. "->"
			.. stats:get(CharacterStat.STRESS)
			.. "; unhappiness: "
			.. unhappinessAfter
			.. "->"
			.. stats:get(CharacterStat.UNHAPPINESS)
	)
end

---@param action ISReadABook
local function startReadingSession(action)
	local username = action.character:getUsername()
	currentlyReadingBook[username] = nil
	if ETW_CommonLogicChecks.ReaderSystemShouldExecute(action.character) then
		local itemNumberOfPages = action.item:getNumberOfPages()
		local hasDefinedPages = itemNumberOfPages > 0
		local numberOfPages = hasDefinedPages and itemNumberOfPages or DEFAULT_NUMBER_OF_PAGES
		local numberOfAlreadyReadPages = hasDefinedPages and action.item:getAlreadyReadPages() or 0
		logETW(
			"ETW Logger | ISReadABook: reading session started: numberOfPages = "
				.. numberOfPages
				.. ", numberOfAlreadyReadPages = "
				.. numberOfAlreadyReadPages
		)

		currentlyReadingBook[username] = {
			itemId = action.item:getID(),
			itemType = action.item:getFullType(),
			numberOfPages = numberOfPages,
			hasDefinedPages = hasDefinedPages,
			startPage = numberOfAlreadyReadPages,
		}
	end
end

local original_ISReadABook_start = ISReadABook.start
---Overwriting ISReadABook:start() here to insert ETW logic catching player reading books
function ISReadABook:start()
	logETW("ETW Logger | ISReadABook:start(): caught")
	startReadingSession(self)
	local originalReturn = original_ISReadABook_start(self)
	return originalReturn
end

local original_ISReadABook_serverStart = ISReadABook.serverStart
---The MP server starts networked timed actions through serverStart(), not start().
function ISReadABook:serverStart()
	logETW("ETW Logger | ISReadABook:serverStart(): caught")
	startReadingSession(self)
	return original_ISReadABook_serverStart(self)
end

---Returns and removes the reading session for this action when it matches the book that was opened.
---@param action ISReadABook
---@return table|nil
local function takeReadingSession(action)
	local username = action.character:getUsername()
	local readingSession = currentlyReadingBook[username]
	currentlyReadingBook[username] = nil

	if
		readingSession
		and readingSession.itemId == action.item:getID()
		and readingSession.itemType == action.item:getFullType()
	then
		return readingSession
	end

	if readingSession then
		logETW("ETW Logger | ISReadABook: reading session does not match the current book; ignoring it")
	end
	return nil
end

---Removes Slow Reader and adds Fast Reader when the Reader System thresholds are reached.
---@param player IsoPlayer
---@param modData EvolvingTraitsWorldModData
local function checkReaderTraits(player, modData)
	if
		player:hasTrait(CharacterTrait.SLOW_READER)
		and modData.PagesReadCounter >= SBvars.ReaderSystemCounter / 2
		and SBvars.TraitsLockSystemCanLoseNegative
	then
		if
			SBvars.DelayedTraitsSystem
			and not ETW_CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, CharacterTrait.SLOW_READER)
		then
			ETW_CommonFunctions.addTraitToDelayTable({
				modData = modData,
				trait = CharacterTrait.SLOW_READER,
				player = player,
				positiveTrait = false,
				gainingTrait = false,
			})
		elseif
			not SBvars.DelayedTraitsSystem
			or (
				SBvars.DelayedTraitsSystem
				and ETW_CommonFunctions.checkDelayedTraits(player, CharacterTrait.SLOW_READER)
			)
		then
			ETW_CommonFunctions.removeTraitFromPlayer({
				player = player,
				trait = CharacterTrait.SLOW_READER,
				positiveTrait = false,
			})
		end
	elseif
		not player:hasTrait(CharacterTrait.SLOW_READER)
		and not player:hasTrait(CharacterTrait.FAST_READER)
		and modData.PagesReadCounter >= SBvars.ReaderSystemCounter
		and SBvars.TraitsLockSystemCanGainPositive
	then
		if
			SBvars.DelayedTraitsSystem
			and not ETW_CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, CharacterTrait.FAST_READER)
		then
			ETW_CommonFunctions.addTraitToDelayTable({
				modData = modData,
				trait = CharacterTrait.FAST_READER,
				player = player,
				positiveTrait = true,
				gainingTrait = true,
			})
		elseif
			not SBvars.DelayedTraitsSystem
			or (
				SBvars.DelayedTraitsSystem
				and ETW_CommonFunctions.checkDelayedTraits(player, CharacterTrait.FAST_READER)
			)
		then
			ETW_CommonFunctions.addTraitToPlayer({
				player = player,
				trait = CharacterTrait.FAST_READER,
				positiveTrait = true,
			})
		end
	end
end

---Credits the pages read during a completed or interrupted reading session.
---@param action ISReadABook
---@param completed boolean
local function creditReadingSession(action, completed)
	local readingSession = takeReadingSession(action)
	if not readingSession or not ETW_CommonLogicChecks.ReaderSystemShouldExecute(action.character) then
		return
	end

	local pagesRead = 0
	if readingSession.hasDefinedPages then
		local endPage = completed and readingSession.numberOfPages or action.item:getAlreadyReadPages()
		pagesRead = math.max(
			0,
			math.min(endPage, readingSession.numberOfPages) - readingSession.startPage
		)
	elseif completed then
		pagesRead = readingSession.numberOfPages
	end

	if pagesRead > 0 then
		local modData = ETW_CommonFunctions.getETWModData(action.character)
		modData.PagesReadCounter = modData.PagesReadCounter + pagesRead
		logETW(
			"ETW Logger | ISReadABook: pagesRead = " .. pagesRead,
			"ETW Logger | ISReadABook: modData.PagesReadCounter = " .. modData.PagesReadCounter
		)
		checkReaderTraits(action.character, modData)
	end
end

local original_ISReadABook_complete = ISReadABook.complete
---Overwriting ISReadABook:complete() here to insert ETW logic catching player reading books
function ISReadABook:complete()
	logETW("ETW Logger | ISReadABook:complete(): caught")
	local completed = not (isServer() and self.forceStopped)
	local asceticComicMood = captureAsceticComicMood(self, completed)
	local learnedRecipes = self.item:getLearnedRecipes()
	local isHerbalistJournal = learnedRecipes
		and not learnedRecipes:isEmpty()
		and learnedRecipes:contains("Herbalist")
	local herbalistJournalAlreadyRead = isHerbalistJournal
		and self.character:getAlreadyReadBook():contains(self.item:getFullType())
	local originalReturn = original_ISReadABook_complete(self)
	suppressAsceticComicMood(self, asceticComicMood)
	local modData = ETW_CommonFunctions.getETWModData(self.character)
	creditReadingSession(self, completed)
	if
		ETW_CommonLogicChecks.HerbalistShouldExecute(self.character)
		and isHerbalistJournal
		and not herbalistJournalAlreadyRead
		and not (isServer() and self.forceStopped)
	then
		modData.HerbsPickedUp = modData.HerbsPickedUp
			+ SBvars.HerbalistHerbsPicked * SBvars.HerbalistJournalCounterIncrease / 100
		logETW(
			"ETW Logger | ISReadABook:complete() first Herbalist journal read: modData.HerbsPickedUp: "
				.. modData.HerbsPickedUp
		)
		if
			not self.character:hasTrait(CharacterTrait.HERBALIST)
			and modData.HerbsPickedUp >= SBvars.HerbalistHerbsPicked
		then
			ETW_CommonFunctions.addTraitToPlayer({
				player = self.character,
				trait = CharacterTrait.HERBALIST,
				positiveTrait = true,
			})
		end
	end
	return originalReturn
end

local original_ISReadABook_stop = ISReadABook.stop
---Overwriting ISReadABook:stop() here to insert ETW logic catching player reading books
function ISReadABook:stop()
	logETW("ETW Logger | ISReadABook:stop(): caught")
	creditReadingSession(self, false)
	local originalReturn = original_ISReadABook_stop(self)
	return originalReturn
end

local original_ISReadABook_serverStop = ISReadABook.serverStop
---The MP server reports interrupted networked timed actions through serverStop().
function ISReadABook:serverStop()
	logETW("ETW Logger | ISReadABook:serverStop(): caught")
	creditReadingSession(self, false)
	if original_ISReadABook_serverStop then
		return original_ISReadABook_serverStop(self)
	end
end
