---@type ETW_CommonFunctions
local ETW_CommonFunctions = require("ETW_CommonFunctions")

---@type ETW_ModData
local ETW_ModData = require("ETW_ModData")
local ETW_EagleEyedTracking = require("ETW_EagleEyedTracking")
local ETW_CommonLogicChecks = require("ETW_CommonLogicChecks")

local ETW_BySkills = require("ETW_BySkillsServer")

local Commands = {}

local gameMode = ETW_CommonFunctions.gameMode()

local FILENAME = "ETW_ModDataServer.lua"
if not ETW_CommonFunctions.gameModeSafeguard(FILENAME, { ETW_CommonFunctions.GameMode.MP_SERVER }) then
	return
end

local function refreshETWModDataForAllClients()
	local onlinePlayers = getOnlinePlayers()

	for i = 0, onlinePlayers:size() - 1 do
		local player = onlinePlayers:get(i)
		ETW_CommonFunctions.log("ETW Logger | System: refreshing modData for player " .. player:getUsername())
		local modData = ETW_CommonFunctions.getETWModData(player)
		sendServerCommand(player, "ETW", "refreshETWModDataFromServer", { ETWModData = modData })
	end
end

Events.EveryOneMinute.Remove(refreshETWModDataForAllClients)
Events.EveryOneMinute.Add(refreshETWModDataForAllClients)

---@param player IsoPlayer
---@param args any
function Commands.createETWModData(player, args)
	ETW_CommonFunctions.log(
		"ETW Logger | System: character "
			.. player:getUsername()
			.. " was created, received command to create its ETW modData"
	)
	ETW_ModData.createETWModData(player:getPlayerNum(), player)
	ETW_BySkills.traitsGainsBySkill(player, "characterInitialization")
end

---@param player IsoPlayer
---@param args any
function Commands.clearETWModData(player, args)
	ETW_CommonFunctions.log(
		"ETW Logger | System: character " .. player:getUsername() .. " died, received command to clear its ETW modData"
	)
	ETW_ModData.clearETWModData(player)
end

---@param player IsoPlayer
---@param args {zombieId:string, distance:number}|nil
function Commands.eagleEyedRecordHit(player, args)
	if not args or type(args.zombieId) ~= "string" or type(args.distance) ~= "number" then
		ETW_CommonFunctions.log(
			"ETW Logger | Commands.eagleEyedRecordHit(): invalid args from player "
				.. tostring(player and player:getUsername() or "nil")
		)
		return
	end
	if ETW_EagleEyedTracking.isRecentCompletedZombieId(args.zombieId) then
		ETW_CommonFunctions.log(
			"ETW Logger | Commands.eagleEyedRecordHit(): ignoring late hit for completed zombieId="
				.. tostring(args.zombieId)
				.. " player="
				.. tostring(player:getUsername())
		)
		return
	end
	ETW_CommonFunctions.log(
		"ETW Logger | Commands.eagleEyedRecordHit(): server received player="
			.. tostring(player:getUsername())
			.. " zombieId="
			.. tostring(args.zombieId)
			.. " distance="
			.. tostring(args.distance)
	)
	ETW_EagleEyedTracking.recordHitById(player, args.zombieId, args.distance)
end

---@param player IsoPlayer
---@param args {progressIncrease:number, isKill:boolean}|nil
function Commands.catEyesRecordProgress(player, args)
	if not args or type(args.progressIncrease) ~= "number" then
		ETW_CommonFunctions.log(
			"ETW Logger | Commands.catEyesRecordProgress(): invalid args from player "
				.. tostring(player and player:getUsername() or "nil")
		)
		return
	end
	if not ETW_CommonLogicChecks.CatEyesShouldExecute(player) then
		return
	end

	local modData = ETW_CommonFunctions.getETWModData(player)
	if not modData then
		ETW_CommonFunctions.log("ETW Logger | Commands.catEyesRecordProgress(): modData is nil, returning early")
		return
	end

	modData.CatEyesCounter = modData.CatEyesCounter + args.progressIncrease
	if args.isKill then
		ETW_CommonFunctions.log("ETW Logger | Commands.catEyesRecordProgress(): was triggered by a kill")
	end
	ETW_CommonFunctions.log(
		"ETW Logger | Commands.catEyesRecordProgress(): server received player="
			.. tostring(player:getUsername())
			.. " progressIncrease="
			.. tostring(args.progressIncrease)
			.. " CatEyesCounter="
			.. tostring(modData.CatEyesCounter)
	)

	if player:hasTrait(CharacterTrait.NIGHT_VISION) or modData.CatEyesCounter < SandboxVars.EvolvingTraitsWorld.CatEyesCounter then
		return
	end

	if
		SandboxVars.EvolvingTraitsWorld.DelayedTraitsSystem
		and not ETW_CommonFunctions.checkIfTraitIsInDelayedTraitsTable(player, CharacterTrait.NIGHT_VISION)
	then
		ETW_CommonFunctions.addTraitToDelayTable({
			modData = modData,
			trait = CharacterTrait.NIGHT_VISION,
			player = player,
			positiveTrait = true,
			gainingTrait = true,
		})
	elseif
		not SandboxVars.EvolvingTraitsWorld.DelayedTraitsSystem
		or (
			SandboxVars.EvolvingTraitsWorld.DelayedTraitsSystem
			and ETW_CommonFunctions.checkDelayedTraits(player, CharacterTrait.NIGHT_VISION)
		)
	then
		ETW_CommonFunctions.addTraitToPlayer({
			player = player,
			trait = CharacterTrait.NIGHT_VISION,
			positiveTrait = true,
		})
	end
end

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
