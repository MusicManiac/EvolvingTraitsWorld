local ETW_CommonFunctions = require("ETW_CommonFunctions")
local ETW_Registry = require("ETW_Registry")

local FILENAME = "ETW_StartingTraits.lua"
if
	not ETW_CommonFunctions.gameModeSafeguard(
		FILENAME,
		{ ETW_CommonFunctions.GameMode.SP, ETW_CommonFunctions.GameMode.MP_SERVER }
	)
then
	return
end

---@class ETW_StartingTraits
local ETW_StartingTraits = {}

---@type EvolvingTraitsWorldTraitsRegistries
local ETWTraitsRegistry = ETW_Registry.traits
---@type EvolvingTraitsWorldSandboxVars
local SBvars = SandboxVars.EvolvingTraitsWorld
local random_instance = newrandom()

local STARTING_DAMAGE = 20
local BANDAGE_STRENGTH = 5
local FRACTURE_TIME = 50
local SPLINT_STRENGTH = 0.9

---Returns the serializable state used to remember body parts affected at character creation.
---Body parts are stored by name because player mod data must not contain Java/PZ objects.
---@param player IsoPlayer Character whose persistent ETW data should be initialized.
---@return StartingInjurySystem system Persistent starting-injury state.
local function getStartingInjurySystem(player)
	local modData = ETW_CommonFunctions.getETWModData(player)
	modData.StartingInjurySystem = modData.StartingInjurySystem or {}
	local system = modData.StartingInjurySystem
	system.InjuredBodyParts = system.InjuredBodyParts or {}
	system.BrokenBodyParts = system.BrokenBodyParts or {}
	system.LastStates = system.LastStates or {}
	return system
end

--- TODO: Made of Glass also snapshots stuff, maybe can be combined.
---Snapshots every relevant timed wound on a remembered body part.
---Later comparisons use both the active flag and timer increases to detect new or refreshed wounds.
---@param system StartingInjurySystem Persistent state that owns the snapshot.
---@param bodyPart BodyPart Body part whose primitive wound values should be recorded.
local function rememberCurrentState(system, bodyPart)
	local bodyPartName = BodyPartType.ToString(bodyPart:getType())
	system.LastStates[bodyPartName] = {
		Scratched = bodyPart:scratched() or bodyPart:getScratchTime() > 0,
		ScratchTime = bodyPart:getScratchTime(),
		Cut = bodyPart:isCut() or bodyPart:getCutTime() > 0,
		CutTime = bodyPart:getCutTime(),
		DeepWounded = bodyPart:deepWounded() or bodyPart:getDeepWoundTime() > 0,
		DeepWoundTime = bodyPart:getDeepWoundTime(),
		Burned = bodyPart:isBurnt() or bodyPart:getBurnTime() > 0,
		BurnTime = bodyPart:getBurnTime(),
		Bitten = bodyPart:bitten() or bodyPart:getBiteTime() > 0,
		BiteTime = bodyPart:getBiteTime(),
		FractureTime = bodyPart:getFractureTime(),
	}
end

---Applies the common clean alcohol-bandage treatment used by starting injuries.
---@param bodyPart BodyPart Body part to bandage.
local function bandageStartingInjury(bodyPart)
	bodyPart:setBandaged(true, BANDAGE_STRENGTH, true, "Base.AlcoholBandage")
end

---Creates an item in the main inventory and equips it in its declared body location.
---@param player IsoPlayer Character who should wear the item.
---@param inventory ItemContainer Main inventory in which the item is created.
---@param fullType string Full item type to create.
---@return InventoryItem? item Created item, or nil when creation failed.
local function addAndWear(player, inventory, fullType)
	local item = inventory:AddItem(fullType)
	if item then
		player:setWornItem(item:getBodyLocation(), item)
	end
	return item
end

---Replaces the character's starting possessions with Deprived's minimal clothing and supplies.
---@param player IsoPlayer Newly created character receiving the Deprived loadout.
local function applyDeprived(player)
	player:clearWornItems()
	local inventory = player:getInventory()
	inventory:removeAllItems()

	local underwearType = player:isFemale() and "Base.Underpants_White" or "Base.Boxers_White"
	local underwear = addAndWear(player, inventory, underwearType)
	local tshirt = addAndWear(player, inventory, "Base.Tshirt_DefaultTEXTURE_TINT")
	local sneakers = addAndWear(player, inventory, "Base.Shoes_TrainerTINT")
	if underwear then
		underwear:setCondition(1)
	end
	if tshirt then
		tshirt:setCondition(1)
	end
	if sneakers then
		sneakers:setCondition(1)
	end

	inventory:AddItem("Base.Garbagebag")
	player:createKeyRing()
end

---Applies one randomized Injured wound, starting damage, and a clean bandage.
---Values 1-2 create a scratch, 3 a burn, 4 a laceration, and 5 a stitched deep wound.
---@param bodyPart BodyPart Selected unique body part to injure.
---@param injuryType integer Random wound selector in the range 1-5.
local function applyRandomInjury(bodyPart, injuryType)
	bodyPart:AddDamage(STARTING_DAMAGE)
	if injuryType <= 2 then
		bodyPart:setScratched(true, true)
	elseif injuryType == 3 then
		bodyPart:setBurned()
		bodyPart:setBurnTime(random_instance:random(50, 99) + STARTING_DAMAGE)
		bodyPart:setNeedBurnWash(false)
	elseif injuryType == 4 then
		bodyPart:setCut(true, true)
	else
		bodyPart:setDeepWounded(true)
		bodyPart:setStitched(true)
	end
	bandageStartingInjury(bodyPart)
end

---Applies Injured's random starting wounds and remembers their exact body-part names and initial states.
---Recording after wound creation prevents starting wounds from being mistaken for future wounds.
---@param player IsoPlayer Newly created character with the Injured trait.
local function applyInjured(player)
	local bodyDamage = player:getBodyDamage()
	local injurySystem = getStartingInjurySystem(player)
	injurySystem.InjuredBodyParts = {}
	local bodyParts = bodyDamage:getBodyParts()
	local availableParts = {}
	for i = 0, bodyParts:size() - 1 do
		availableParts[#availableParts + 1] = bodyParts:get(i)
	end

	local injuryCount = math.min(#availableParts, random_instance:random(3, 5))
	local burnsEnabled = SBvars.InjuredBurns ~= false
	for _ = 1, injuryCount do
		local availableIndex = random_instance:random(1, #availableParts)
		local bodyPart = table.remove(availableParts, availableIndex)
		local injuryType = random_instance:random(1, burnsEnabled and 5 or 4)
		if not burnsEnabled and injuryType >= 3 then
			injuryType = injuryType + 1
		end
		applyRandomInjury(bodyPart, injuryType)
		local bodyPartName = BodyPartType.ToString(bodyPart:getType())
		injurySystem.InjuredBodyParts[bodyPartName] = true
		rememberCurrentState(injurySystem, bodyPart)
	end
	bodyDamage:setInfected(false)
end

---Applies Broken Leg to the right lower leg and records the initial fracture state.
---The initial snapshot prevents the starting fracture from receiving the repeat-fracture multiplier.
---@param player IsoPlayer Newly created character with the Broken Leg trait.
local function applyBrokenLeg(player)
	local bodyDamage = player:getBodyDamage()
	local lowerRightLeg = bodyDamage:getBodyPart(BodyPartType.LowerLeg_R)
	local injurySystem = getStartingInjurySystem(player)
	injurySystem.BrokenBodyParts = {}
	lowerRightLeg:AddDamage(STARTING_DAMAGE)
	lowerRightLeg:setFractureTime(FRACTURE_TIME)
	lowerRightLeg:setSplint(true, SPLINT_STRENGTH)
	lowerRightLeg:setSplintItem("Base.Splint")
	bandageStartingInjury(lowerRightLeg)
	local bodyPartName = BodyPartType.ToString(lowerRightLeg:getType())
	injurySystem.BrokenBodyParts[bodyPartName] = true
	rememberCurrentState(injurySystem, lowerRightLeg)
	bodyDamage:setInfected(false)
end

---Compares one remembered body part with its previous snapshot and strengthens newly detected wounds.
---Injured escalates at most one scratch/laceration/deep-wound branch per update, then independently
---handles burns, bites, and fractures. Replacement wounds are snapshotted after their duration is
---multiplied, preventing scratch -> laceration -> deep-wound chaining on later ticks.
---@param player IsoPlayer Character being monitored; used for diagnostic logging.
---@param bodyDamage BodyDamage Character body-damage container used to resolve the stored part name.
---@param system StartingInjurySystem Persistent remembered-part and previous-state data.
---@param bodyPartName string Serialized BodyPartType name recorded at character creation.
---@param worsensInjuries boolean Whether Injured wound escalation and duration rules apply.
---@param worsensFractures boolean Whether Broken Leg's repeat-fracture rule applies.
---@param fractureMultiplier number Broken Leg fracture-duration multiplier.
---@param injuryDurationMultiplier number Injured duration multiplier for all timed wounds.
local function updateRememberedBodyPart(
	player,
	bodyDamage,
	system,
	bodyPartName,
	worsensInjuries,
	worsensFractures,
	fractureMultiplier,
	injuryDurationMultiplier
)
	local bodyPart = bodyDamage:getBodyPart(BodyPartType.FromString(bodyPartName))
	if not bodyPart then
		return
	end
	local currentScratch = bodyPart:scratched() or bodyPart:getScratchTime() > 0
	local currentScratchTime = bodyPart:getScratchTime()
	local currentCut = bodyPart:isCut() or bodyPart:getCutTime() > 0
	local currentCutTime = bodyPart:getCutTime()
	local currentDeepWound = bodyPart:deepWounded() or bodyPart:getDeepWoundTime() > 0
	local currentDeepWoundTime = bodyPart:getDeepWoundTime()
	local currentBurn = bodyPart:isBurnt() or bodyPart:getBurnTime() > 0
	local currentBurnTime = bodyPart:getBurnTime()
	local currentBite = bodyPart:bitten() or bodyPart:getBiteTime() > 0
	local currentBiteTime = bodyPart:getBiteTime()
	local currentFractureTime = bodyPart:getFractureTime()
	local previous = system.LastStates[bodyPartName]
	if previous then
		local isNewScratch = currentScratch
			and (not previous.Scratched or currentScratchTime > (previous.ScratchTime or 0) + 0.001)
		local isNewLaceration = currentCut
			and (not previous.Cut or currentCutTime > (previous.CutTime or 0) + 0.001)
		local isNewDeepWound = currentDeepWound
			and (
				not previous.DeepWounded
				or currentDeepWoundTime > (previous.DeepWoundTime or 0) + 0.001
			)
		if worsensInjuries and isNewDeepWound then
			currentDeepWoundTime = currentDeepWoundTime * injuryDurationMultiplier
			bodyPart:setDeepWoundTime(currentDeepWoundTime)
			ETW_CommonFunctions.log(
				"ETW Logger | Injured: multiplied a new deep wound on "
					.. bodyPartName
					.. " by "
					.. injuryDurationMultiplier
					.. " for "
					.. tostring(player:getUsername())
			)
		elseif worsensInjuries and isNewLaceration then
			bodyPart:setCut(false)
			bodyPart:setCutTime(0)
			bodyPart:generateDeepWound()
			currentCut = false
			currentCutTime = 0
			-- Record the deep wound we just created so it is not multiplied next tick.
			currentDeepWound = bodyPart:deepWounded() or bodyPart:getDeepWoundTime() > 0
			currentDeepWoundTime = bodyPart:getDeepWoundTime() * injuryDurationMultiplier
			bodyPart:setDeepWoundTime(currentDeepWoundTime)
			ETW_CommonFunctions.log(
				"ETW Logger | Injured: replaced a new laceration with a deep wound and multiplied its duration on "
					.. bodyPartName
					.. " by "
					.. injuryDurationMultiplier
					.. " for "
					.. tostring(player:getUsername())
			)
		elseif worsensInjuries and isNewScratch then
			bodyPart:setScratched(false, true)
			bodyPart:setScratchTime(0)
			bodyPart:setCut(true)
			currentScratch = false
			currentScratchTime = 0
			-- Record the laceration we just created so it is not promoted again next tick.
			currentCut = bodyPart:isCut() or bodyPart:getCutTime() > 0
			currentCutTime = bodyPart:getCutTime() * injuryDurationMultiplier
			bodyPart:setCutTime(currentCutTime)
			ETW_CommonFunctions.log(
				"ETW Logger | Injured: replaced a new scratch with a laceration and multiplied its duration on "
					.. bodyPartName
					.. " by "
					.. injuryDurationMultiplier
					.. " for "
					.. tostring(player:getUsername())
			)
		end
		local isNewBurn = currentBurn
			and (not previous.Burned or currentBurnTime > (previous.BurnTime or 0) + 0.001)
		if worsensInjuries and isNewBurn then
			currentBurnTime = currentBurnTime * injuryDurationMultiplier
			bodyPart:setBurnTime(currentBurnTime)
			ETW_CommonFunctions.log(
				"ETW Logger | Injured: multiplied a new burn on "
					.. bodyPartName
					.. " by "
					.. injuryDurationMultiplier
					.. " for "
					.. tostring(player:getUsername())
			)
		end
		local isNewBite = currentBite
			and (not previous.Bitten or currentBiteTime > (previous.BiteTime or 0) + 0.001)
		if worsensInjuries and isNewBite then
			currentBiteTime = currentBiteTime * injuryDurationMultiplier
			bodyPart:setBiteTime(currentBiteTime)
			ETW_CommonFunctions.log(
				"ETW Logger | Injured: multiplied a new bite on "
					.. bodyPartName
					.. " by "
					.. injuryDurationMultiplier
					.. " for "
					.. tostring(player:getUsername())
			)
		end
		local isNewFracture = currentFractureTime > 0
			and (
				(previous.FractureTime or 0) <= 0
				or currentFractureTime > (previous.FractureTime or 0) + 0.001
			)
		if (worsensInjuries or worsensFractures) and isNewFracture then
			local appliedFractureMultiplier = 1
			if worsensInjuries then
				appliedFractureMultiplier = appliedFractureMultiplier * injuryDurationMultiplier
			end
			if worsensFractures then
				appliedFractureMultiplier = appliedFractureMultiplier * fractureMultiplier
			end
			currentFractureTime = currentFractureTime * appliedFractureMultiplier
			bodyPart:setFractureTime(currentFractureTime)
			ETW_CommonFunctions.log(
				"ETW Logger | Starting injury: multiplied a repeat fracture on "
					.. bodyPartName
					.. " by "
					.. appliedFractureMultiplier
					.. " for "
					.. tostring(player:getUsername())
			)
		end
	end
	system.LastStates[bodyPartName] = {
		Scratched = currentScratch,
		ScratchTime = currentScratchTime,
		Cut = currentCut,
		CutTime = currentCutTime,
		DeepWounded = currentDeepWound,
		DeepWoundTime = currentDeepWoundTime,
		Burned = currentBurn,
		BurnTime = currentBurnTime,
		Bitten = currentBite,
		BiteTime = currentBiteTime,
		FractureTime = currentFractureTime,
	}
end

---Updates only body parts recorded by Injured or Broken Leg at character creation.
---A part shared by both traits is processed once with both rule sets enabled; fracture multipliers stack.
---@param player IsoPlayer Character whose remembered parts should be checked.
---@param bodyDamage BodyDamage Character body-damage container.
---@param modData EvolvingTraitsWorldModData Persistent ETW data containing starting-injury state.
function ETW_StartingTraits.updateStartingInjuries(player, bodyDamage, modData)
	local system = modData.StartingInjurySystem
	if not system then
		return
	end
	local injuredBodyParts = system.InjuredBodyParts or {}
	local brokenBodyParts = system.BrokenBodyParts or {}
	system.LastStates = system.LastStates or {}
	local fractureMultiplier = math.max(1, SBvars.BrokenLegFractureTimeMultiplier or 2)
	local injuryDurationMultiplier = math.max(1, SBvars.InjuredWoundTimeMultiplier or 2)
	for bodyPartName in pairs(injuredBodyParts) do
		updateRememberedBodyPart(
			player,
			bodyDamage,
			system,
			bodyPartName,
			true,
			brokenBodyParts[bodyPartName] == true,
			fractureMultiplier,
			injuryDurationMultiplier
		)
	end
	for bodyPartName in pairs(brokenBodyParts) do
		if not injuredBodyParts[bodyPartName] then
			updateRememberedBodyPart(
				player,
				bodyDamage,
				system,
				bodyPartName,
				false,
				true,
				fractureMultiplier,
				injuryDurationMultiplier
			)
		end
	end
end

---Adds the configured per-minute unhappiness when Deprived exceeds its carry-capacity threshold.
---The calculation uses the character's current maximum weight, including compatible framework changes.
---@param player IsoPlayer Deprived character whose carried weight should be evaluated.
---@param stats Stats Character stats receiving the unhappiness penalty.
function ETW_StartingTraits.updateDeprivedMood(player, stats)
	local maxWeight = player:getMaxWeight()
	local capacityThreshold = PZMath.clamp(SBvars.DeprivedCapacityThresholdPercent or 50, 0, 100) / 100
	if maxWeight <= 0 or player:getInventoryWeight() <= maxWeight * capacityThreshold then
		return
	end
	local increase = math.max(0, SBvars.DeprivedUnhappinessPerMinute or 0.1)
	stats:set(CharacterStat.UNHAPPINESS, math.min(100, stats:get(CharacterStat.UNHAPPINESS) + increase))
end

---Dispatches one-time starting effects for each supported character-creation trait.
---@param player IsoPlayer Newly created character.
local function applyStartingTraits(player)
	if player:hasTrait(ETWTraitsRegistry.DEPRIVED) then
		applyDeprived(player)
	end
	if player:hasTrait(ETWTraitsRegistry.INJURED) then
		applyInjured(player)
	end
	if player:hasTrait(ETWTraitsRegistry.BROKEN_LEG) then
		applyBrokenLeg(player)
	end
end

Events.OnNewGame.Add(applyStartingTraits)

return ETW_StartingTraits
