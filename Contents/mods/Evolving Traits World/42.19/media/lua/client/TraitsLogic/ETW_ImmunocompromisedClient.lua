local ETW_CommonFunctions = require("ETW_CommonFunctions")
local ETW_Registry = require("ETW_Registry")
local ETWCombinedTraitChecks = require("ETW_CombinedTraitFunctions")
local ETW_NearbyZombieScanner = require("TraitsLogic/ETW_NearbyZombieScanner")

local FILENAME = "ETW_ImmunocompromisedClient.lua"
if
	not ETW_CommonFunctions.gameModeSafeguard(
		FILENAME,
		{ ETW_CommonFunctions.GameMode.SP, ETW_CommonFunctions.GameMode.MP_CLIENT }
	)
then
	return
end

---@type EvolvingTraitsWorldTraitsRegistries
local ETWTraitsRegistry = ETW_Registry.traits
local gameMode = ETW_CommonFunctions.gameMode()
local logETW = ETW_CommonFunctions.log
local knownInjuries = {}
local pendingZombieAttackExpiresAt
local PENDING_ZOMBIE_ATTACK_DURATION_MS = 1000
local ZOMBIE_ATTACK_SCAN_RADIUS = 3
local ATTACK_OUTCOME_MOD_DATA_KEY = "ETWImmunocompromisedAttackOutcome"
local ZOMBIE_SCANNER_CONSUMER_ID = "Immunocompromised"

---@class ImmunocompromisedInjuryState
---@field scratched boolean
---@field scratchTime number
---@field cut boolean
---@field cutTime number
---@field bitten boolean
---@field biteTime number

---Captures zombie-inflicted wound types for one body part.
---@param part BodyPart
---@return ImmunocompromisedInjuryState
local function captureZombieInjuryState(part)
	return {
		scratched = part:scratched(),
		scratchTime = part:getScratchTime(),
		cut = part:isCut(),
		cutTime = part:getCutTime(),
		bitten = part:bitten(),
		biteTime = part:getBiteTime(),
	}
end

---Returns whether a scratch, laceration, or bite is new or has increased on this body part.
---@param current ImmunocompromisedInjuryState
---@param previous ImmunocompromisedInjuryState|nil
---@return boolean
local function isNewZombieInjury(current, previous)
	if not previous then
		return current.scratched or current.cut or current.bitten
	end
	return (current.scratched and (not previous.scratched or current.scratchTime > previous.scratchTime))
		or (current.cut and (not previous.cut or current.cutTime > previous.cutTime))
		or (current.bitten and (not previous.bitten or current.biteTime > previous.biteTime))
end

---Records all zombie-wound states currently present so pre-existing wounds are not treated as new.
---@param player IsoPlayer
local function initializeKnownInjuries(player)
	knownInjuries = {}
	local parts = player:getBodyDamage():getBodyParts()
	for i = 0, parts:size() - 1 do
		knownInjuries[i] = captureZombieInjuryState(parts:get(i))
	end
end

---Rolls each body part newly injured by the current zombie attack.
---@param player IsoPlayer
---@return integer detectedInjuries
local function processNewZombieInjuries(player)
	local detectedInjuries = 0
	local parts = player:getBodyDamage():getBodyParts()
	for i = 0, parts:size() - 1 do
		local currentInjury = captureZombieInjuryState(parts:get(i))
		if isNewZombieInjury(currentInjury, knownInjuries[i]) then
			detectedInjuries = detectedInjuries + 1
			if gameMode == ETW_CommonFunctions.GameMode.MP_CLIENT then
				sendClientCommand(player, "ETW", "immunocompromisedKnoxInjury", { bodyPartIndex = i })
			else
				ETWCombinedTraitChecks.immunocompromisedKnoxInfectionRoll(player)
			end
			logETW(
				"ETW Logger | Immunocompromised | processNewZombieInjuries(): detected new zombie injury for "
					.. tostring(player:getUsername())
					.. " (OnlineID="
					.. player:getOnlineID()
					.. "); body part index: "
					.. i
					.. "; scratch: "
					.. tostring(currentInjury.scratched)
					.. "; laceration: "
					.. tostring(currentInjury.cut)
					.. "; bite: "
					.. tostring(currentInjury.bitten)
					.. "; sent to server: "
					.. tostring(gameMode == ETW_CommonFunctions.GameMode.MP_CLIENT)
			)
		end
		knownInjuries[i] = currentInjury
	end
	return detectedInjuries
end

---@type Callback_OnTick
local processPendingZombieAttack

---Stops the temporary tick check after the attack reaches a terminal state.
local function stopPendingZombieAttackCheck()
	pendingZombieAttackExpiresAt = nil
	Events.OnTick.Remove(processPendingZombieAttack)
end

---Waits briefly for the body-part wound to appear after a zombie AttackOutcome transition.
processPendingZombieAttack = function()
	local player = getPlayer()
	if not player or player:isDead() or not player:hasTrait(ETWTraitsRegistry.IMMUNOCOMPROMISED) then
		stopPendingZombieAttackCheck()
		return
	end
	if processNewZombieInjuries(player) > 0 then
		stopPendingZombieAttackCheck()
		return
	end
	if getTimestampMs() >= pendingZombieAttackExpiresAt then
		logETW(
			"ETW Logger | Immunocompromised | processPendingZombieAttack(): attack check expired without a new injury"
		)
		stopPendingZombieAttackCheck()
	end
end

---Starts or extends the temporary wound check for a changed zombie AttackOutcome.
---@param player IsoPlayer
---@param zombie IsoZombie
---@param attackOutcome string
---@param hitReaction string
local function queueZombieAttackCheck(player, zombie, attackOutcome, hitReaction)
	local alreadyPending = pendingZombieAttackExpiresAt ~= nil
	pendingZombieAttackExpiresAt = getTimestampMs() + PENDING_ZOMBIE_ATTACK_DURATION_MS
	if not alreadyPending then
		Events.OnTick.Remove(processPendingZombieAttack)
		Events.OnTick.Add(processPendingZombieAttack)
	end
	logETW(
		"ETW Logger | Immunocompromised | queueZombieAttackCheck(): zombie attack outcome changed for "
			.. tostring(player:getUsername())
			.. " (OnlineID="
			.. player:getOnlineID()
			.. "); zombie OnlineID="
			.. zombie:getOnlineID()
			.. "; outcome: "
			.. attackOutcome
			.. "; hit reaction: "
			.. tostring(hitReaction)
	)
end

---Detects an observed zombie's attack transitions using its target and AttackOutcome animation variable.
---@param player IsoPlayer
---@param zombie IsoZombie
local function detectZombieAttack(player, zombie)
	local zombieModData = zombie:getModData()
	local target = zombie:getTarget()
	if target ~= player then
		zombieModData[ATTACK_OUTCOME_MOD_DATA_KEY] = nil
		return
	end
	local currentAttackOutcome = zombie:getVariableString("AttackOutcome")
	if currentAttackOutcome == "" then
		zombieModData[ATTACK_OUTCOME_MOD_DATA_KEY] = nil
		return
	end
	if zombieModData[ATTACK_OUTCOME_MOD_DATA_KEY] == currentAttackOutcome then
		return
	end

	zombieModData[ATTACK_OUTCOME_MOD_DATA_KEY] = currentAttackOutcome
	queueZombieAttackCheck(player, zombie, currentAttackOutcome, player:getHitReaction())
end

---Passes a nearby zombie from the shared scanner to Immunocompromised's attack detector.
---@param player IsoPlayer
---@param zombie IsoZombie
local function inspectNearbyZombie(player, zombie)
	detectZombieAttack(player, zombie)
end

---@param player IsoPlayer
---@return boolean
local function immunocompromisedScanEnabled(player)
	return player:hasTrait(ETWTraitsRegistry.IMMUNOCOMPROMISED)
end

---Refreshes the injury baseline so healed wounds and their decreasing timers are forgotten.
local function refreshKnownInjuries()
	local player = getPlayer()
	if
		not pendingZombieAttackExpiresAt
		and player
		and player:hasTrait(ETWTraitsRegistry.IMMUNOCOMPROMISED)
	then
		initializeKnownInjuries(player)
	end
end

---Registers zombie scanning only for a character who has Immunocompromised.
---@param playerIndex integer
---@param player IsoPlayer
local function onCreatePlayer(playerIndex, player)
	ETW_NearbyZombieScanner.unregister(ZOMBIE_SCANNER_CONSUMER_ID)
	Events.EveryOneMinute.Remove(refreshKnownInjuries)
	initializeKnownInjuries(player)
	ETW_NearbyZombieScanner.register(ZOMBIE_SCANNER_CONSUMER_ID, {
		radius = ZOMBIE_ATTACK_SCAN_RADIUS,
		isEnabled = immunocompromisedScanEnabled,
		onZombie = inspectNearbyZombie,
	})
	Events.EveryOneMinute.Add(refreshKnownInjuries)
	logETW(
		"ETW Logger | Immunocompromised | onCreatePlayer(): registered nearby zombie attack scan for player index "
			.. playerIndex
			.. "; radius: "
			.. ZOMBIE_ATTACK_SCAN_RADIUS
	)
end

Events.OnCreatePlayer.Remove(onCreatePlayer)
Events.OnCreatePlayer.Add(onCreatePlayer)

local player = getPlayer()
if player then
	onCreatePlayer(player:getPlayerNum(), player)
end
