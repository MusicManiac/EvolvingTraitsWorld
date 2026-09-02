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

---@type EvolvingTraitsWorldTraitsRegistries
local ETWTraitsRegistry = ETW_Registry.traits
---@type EvolvingTraitsWorldSandboxVars
local SBvars = SandboxVars.EvolvingTraitsWorld
local random_instance = newrandom()

local STARTING_DAMAGE = 20
local BANDAGE_STRENGTH = 5
local FRACTURE_TIME = 50
local SPLINT_STRENGTH = 0.9

---@param bodyPart BodyPart
local function bandageStartingInjury(bodyPart)
	bodyPart:setBandaged(true, BANDAGE_STRENGTH, true, "Base.AlcoholBandage")
end

---@param player IsoPlayer
---@param inventory ItemContainer
---@param fullType string
---@return InventoryItem?
local function addAndWear(player, inventory, fullType)
	local item = inventory:AddItem(fullType)
	if item then
		player:setWornItem(item:getBodyLocation(), item)
	end
	return item
end

---@param player IsoPlayer
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

---@param bodyPart BodyPart
---@param injuryType integer
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

---@param player IsoPlayer
local function applyInjured(player)
	local bodyDamage = player:getBodyDamage()
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
	end
	bodyDamage:setInfected(false)
end

---@param player IsoPlayer
local function applyBrokenLeg(player)
	local bodyDamage = player:getBodyDamage()
	local lowerRightLeg = bodyDamage:getBodyPart(BodyPartType.LowerLeg_R)
	lowerRightLeg:AddDamage(STARTING_DAMAGE)
	lowerRightLeg:setFractureTime(FRACTURE_TIME)
	lowerRightLeg:setSplint(true, SPLINT_STRENGTH)
	lowerRightLeg:setSplintItem("Base.Splint")
	bandageStartingInjury(lowerRightLeg)
	bodyDamage:setInfected(false)
end

---@param player IsoPlayer
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
