local ETWCombinedTraitChecks = require("ETW_CombinedTraitFunctions")
local ETW_CommonLogicChecks = require("ETW_CommonLogicChecks")
local ETW_Registry = require("ETW_Registry")
local ETW_CombatTraits = require("TraitsLogic/ETW_CombatTraits")
local ETW_HealthTraits = require("TraitsLogic/ETW_HealthTraits")

---@type ETW_CommonFunctions
local ETW_CommonFunctions = require("ETW_CommonFunctions")

local gameMode = ETW_CommonFunctions.gameMode()
local Commands = {}
---@type EvolvingTraitsWorldTraitsRegistries
local ETWTraitsRegistry = ETW_Registry.traits
---@type EvolvingTraitsWorldSandboxVars
local SBvars = SandboxVars.EvolvingTraitsWorld

local FILENAME = "ETW_ClientCommands.lua"
if
	not ETW_CommonFunctions.gameModeSafeguard(
		FILENAME,
		{ ETW_CommonFunctions.GameMode.SP, ETW_CommonFunctions.GameMode.MP_SERVER }
	)
then
	return
end

---@type fun(...: any)
local logETW = ETW_CommonFunctions.log

---@class EngineCheckArgs
---@field vehicleID number
---@field conditionBefore number

---Function to check by how much engine was repaired. If SP - updates relative moddata and checks traits. If MP - sends command back to client
---@param player IsoPlayer
---@param args EngineCheckArgs
function Commands.checkEngineCondition(player, args)
	local vehicle = getVehicleById(args.vehicleID)
	local part = vehicle:getPartById("Engine")
	if not part then
		return
	end
	local condition = part:getCondition()
	local repairedPercentage = condition - args.conditionBefore
	logETW("ETW Logger | Commands.checkEngineCondition(): args.condition: " .. condition)
	if gameMode == ETW_CommonFunctions.GameMode.SP then
		---@type EvolvingTraitsWorldModData
		local modData = player:getModData().EvolvingTraitsWorld
		modData.VehiclePartRepairs = modData.VehiclePartRepairs + repairedPercentage
		logETW(
			"ETW Logger | Commands.checkEngineCondition(): modData.VehiclePartRepairs: " .. modData.VehiclePartRepairs
		)
		if ETW_CommonLogicChecks.BodyWorkEnthusiastShouldExecute(player) then
			ETWCombinedTraitChecks.bodyworkEnthusiastCheck(player)
		end
		if ETW_CommonLogicChecks.MechanicsShouldExecute(player) then
			ETWCombinedTraitChecks.mechanicsCheck(args.DebugAndNotificationArgs)
		end
	elseif gameMode == ETW_CommonFunctions.GameMode.MP_SERVER then
		local serverArgs = { repairedPercentage = repairedPercentage }
		sendServerCommand(player, "ETW", "carRepairCheck", serverArgs)
	end
end

---Validates an MP client's aiming report and applies Anti-Gun Activist's mood effect on the server.
---@param player IsoPlayer
function Commands.applyAntiGunAimingMood(player)
	local playerIdentifier = tostring(player:getUsername()) .. " (OnlineID=" .. player:getOnlineID() .. ")"
	if not player:hasTrait(ETWTraitsRegistry.ANTI_GUN_ACTIVIST) then
		logETW("ETW Logger | antigun mood server: rejected missing trait for " .. playerIdentifier)
		return
	end
	local weapon = player:getPrimaryHandItem()
	if not weapon or not instanceof(weapon, "HandWeapon") or weapon:getSubCategory() ~= "Firearm" then
		logETW("ETW Logger | antigun mood server: rejected missing firearm for " .. playerIdentifier)
		return
	end
	ETW_CombatTraits.antiGunMentalTrait(player, player:getStats())
	logETW(
		"ETW Logger | antigun mood server: applied for "
			.. playerIdentifier
			.. " while holding "
			.. weapon:getFullType()
	)
end

---Validates an MP client's aiming report and applies Terminator's mood effect on the server.
---@param player IsoPlayer
function Commands.applyTerminatorAimingMood(player)
	local playerIdentifier = tostring(player:getUsername()) .. " (OnlineID=" .. player:getOnlineID() .. ")"
	if not player:hasTrait(ETWTraitsRegistry.TERMINATOR) then
		logETW("ETW Logger | terminator mood server: rejected missing trait for " .. playerIdentifier)
		return
	end
	local weapon = player:getPrimaryHandItem()
	if not weapon or not instanceof(weapon, "HandWeapon") or weapon:getSubCategory() ~= "Firearm" then
		logETW("ETW Logger | terminator mood server: rejected missing firearm for " .. playerIdentifier)
		return
	end
	ETW_CombatTraits.terminatorMentalTrait(player, player:getStats())
	logETW(
		"ETW Logger | terminator mood server: applied for "
			.. playerIdentifier
			.. " while aiming "
			.. weapon:getFullType()
	)
end

---Validates an MP client's MT-style Indefatigable crowd trigger.
---@param player IsoPlayer
---@param args table
function Commands.triggerIndefatigableCrowd(player, args)
	local playerIdentifier = tostring(player:getUsername()) .. " (OnlineID=" .. player:getOnlineID() .. ")"
	if not player:hasTrait(ETWTraitsRegistry.INDEFATIGABLE) then
		logETW("ETW Logger | triggerIndefatigableCrowd(): rejected missing trait for " .. playerIdentifier)
		return
	end
	local modData = ETW_CommonFunctions.getETWModData(player)
	if not modData then
		logETW("ETW Logger | triggerIndefatigableCrowd(): rejected missing modData for " .. playerIdentifier)
		return
	end
	logETW(
		"ETW Logger | triggerIndefatigableCrowd(): received crowd report for "
			.. playerIdentifier
			.. "; client count within 1.5: "
			.. tostring(args.nearbyCount)
	)
	ETW_HealthTraits.indefatigableTrait(player, player:getBodyDamage(), modData, true)
end

---@class GymRatStiffnessIncrementArgs
---@field group string
---@field increments number

---Validates and mirrors a Gym Rat client's suppressed stiffness increments on the server.
---@param player IsoPlayer
---@param args GymRatStiffnessIncrementArgs
function Commands.undoGymRatStiffnessIncrements(player, args)
	local playerIdentifier = tostring(player:getUsername()) .. " (OnlineID=" .. player:getOnlineID() .. ")"
	local increments = math.floor(tonumber(args.increments) or 0)
	if
		not player:hasTrait(ETWTraitsRegistry.GYM_RAT)
		or PZMath.clamp(SBvars.GymRatExerciseFatigueReductionPercent or 50, 0, 100) <= 0
		or increments < 1
		or increments > 10
	then
		logETW("ETW Logger | Gym Rat fatigue server: rejected undo request for " .. playerIdentifier)
		return
	end
	local groupName = tostring(args.group)
	local removedStiffness = ETWCombinedTraitChecks.undoGymRatStiffnessIncrements(player, groupName, increments)
	if removedStiffness == nil then
		logETW("ETW Logger | Gym Rat fatigue server: rejected invalid group for " .. playerIdentifier)
		return
	end
	logETW(
		"ETW Logger | Gym Rat fatigue server: suppressed "
			.. increments
			.. " "
			.. groupName
			.. " increment(s) for "
			.. playerIdentifier
			.. "; applied stiffness removed: "
			.. removedStiffness
	)
end

---@class GymRatStiffnessDecayArgs
---@field group string
---@field amountPerPart number

---Validates and mirrors accumulated vanilla-rate Gym Rat stiffness decay on the server.
---@param player IsoPlayer
---@param args GymRatStiffnessDecayArgs
function Commands.applyGymRatStiffnessDecay(player, args)
	local playerIdentifier = tostring(player:getUsername()) .. " (OnlineID=" .. player:getOnlineID() .. ")"
	local amountPerPart = tonumber(args.amountPerPart) or 0
	if
		not player:hasTrait(ETWTraitsRegistry.GYM_RAT)
		or PZMath.clamp(SBvars.GymRatExerciseFatigueReductionPercent or 50, 0, 100) <= 0
		or amountPerPart <= 0
		or amountPerPart > 100
	then
		logETW("ETW Logger | Gym Rat fatigue server: rejected decay request for " .. playerIdentifier)
		return
	end
	local groupName = tostring(args.group)
	local removedStiffness = ETWCombinedTraitChecks.reduceGymRatStiffness(player, groupName, amountPerPart)
	if removedStiffness == nil then
		logETW("ETW Logger | Gym Rat fatigue server: rejected invalid decay group for " .. playerIdentifier)
		return
	end
	logETW(
		"ETW Logger | Gym Rat fatigue server: applied accumulated "
			.. groupName
			.. " decay for "
			.. playerIdentifier
			.. "; amount per part: "
			.. amountPerPart
			.. ", stiffness removed: "
			.. removedStiffness
	)
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
