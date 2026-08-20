local ETW_Registry = require("ETW_Registry")
local ETW_CommonFunctions = require("ETW_CommonFunctions")

local FILENAME = "ETW_ItemTraits.lua"
if
	not ETW_CommonFunctions.gameModeSafeguard(
		FILENAME,
		{ ETW_CommonFunctions.GameMode.SP, ETW_CommonFunctions.GameMode.MP_SERVER }
	)
then
	return
end

---@type EvolvingTraitsWorldSandboxVars
local SBvars = SandboxVars.EvolvingTraitsWorld
local ETWTraitsRegistry = ETW_Registry.traits
local logETW = ETW_CommonFunctions.log
local random_instance = newrandom()

local leadFootShoes = {}
local mundaneWeapons = {}
local Commands = {}

local function restoreWellFittedItem(item, data)
	if data.OriginalActualWeight ~= nil then
		item:setActualWeight(data.OriginalActualWeight)
	end
	if data.OriginalRunSpeedModifier ~= nil then
		item:setRunSpeedModifier(data.OriginalRunSpeedModifier)
	end
	if data.OriginalCombatSpeedModifier ~= nil then
		item:setCombatSpeedModifier(data.OriginalCombatSpeedModifier)
	end
	data.Applied = false
end

---@param player IsoPlayer
local function wellFittedTrait(player)
	local hasTrait = player:hasTrait(ETWTraitsRegistry.WELL_FITTED)
	local wornItems = player:getWornItems()
	local items = player:getInventory():getItems()
	local changed = false

	for i = 0, items:size() - 1 do
		local item = items:get(i)
		if item:IsClothing() then
			local itemData = item:getModData()
			itemData.ETWWellFitted = itemData.ETWWellFitted or {}
			local data = itemData.ETWWellFitted
			local isWorn = wornItems:contains(item)
			if hasTrait and isWorn then
				if data.OriginalActualWeight == nil then
					data.OriginalActualWeight = item:getActualWeight()
					data.OriginalRunSpeedModifier = item:getRunSpeedModifier()
					data.OriginalCombatSpeedModifier = item:getCombatSpeedModifier()
				end
				local reduction = PZMath.clamp(SBvars.WellFittedWeightReduction or 50, 0, 100) / 100
				item:setActualWeight(data.OriginalActualWeight * (1 - reduction))
				if SBvars.WellFittedNegatesSpeedPenalties ~= false then
					if data.OriginalRunSpeedModifier < 1 then
						item:setRunSpeedModifier(1)
					end
					if data.OriginalCombatSpeedModifier < 1 then
						item:setCombatSpeedModifier(1)
					end
				else
					item:setRunSpeedModifier(data.OriginalRunSpeedModifier)
					item:setCombatSpeedModifier(data.OriginalCombatSpeedModifier)
				end
				if not data.Applied then
					data.Applied = true
					changed = true
					logETW(
						"ETW Logger | wellFittedTrait(): applied to "
							.. item:getFullType()
							.. "; actual weight: "
							.. data.OriginalActualWeight
							.. "->"
							.. item:getActualWeight()
					)
				end
			elseif data.Applied then
				restoreWellFittedItem(item, data)
				changed = true
				logETW("ETW Logger | wellFittedTrait(): restored " .. item:getFullType())
			end
		end
	end

	if changed then
		player:setWornItems(wornItems)
	end
end

local function restoreLeadFootItem(item)
	local data = item:getModData().ETWLeadFoot
	if data and data.Applied then
		item:setStompPower(data.OriginalStompPower)
		data.Applied = false
		data.OriginalStompPower = nil
		logETW("ETW Logger | leadFootTrait(): restored " .. item:getFullType())
	end
end

---@param player IsoPlayer
local function leadFootTrait(player)
	local shoes = player:getClothingItem_Feet()
	local previousShoes = leadFootShoes[player]
	if previousShoes and (previousShoes ~= shoes or not player:hasTrait(ETWTraitsRegistry.LEAD_FOOT)) then
		restoreLeadFootItem(previousShoes)
		leadFootShoes[player] = nil
	end
	if not player:hasTrait(ETWTraitsRegistry.LEAD_FOOT) or not shoes then
		return
	end
	local itemData = shoes:getModData()
	itemData.ETWLeadFoot = itemData.ETWLeadFoot or {}
	local data = itemData.ETWLeadFoot
	if not data.Applied then
		data.OriginalStompPower = shoes:getStompPower()
		local multiplier = math.max(0, SBvars.LeadFootStompPowerMultiplier or 2)
		local bonus = math.max(0, SBvars.LeadFootStompPowerBonus or 1)
		shoes:setStompPower(data.OriginalStompPower * multiplier + bonus)
		data.Applied = true
		logETW(
			"ETW Logger | leadFootTrait(): applied to "
				.. shoes:getFullType()
				.. "; stomp power: "
				.. data.OriginalStompPower
				.. "->"
				.. shoes:getStompPower()
		)
	end
	leadFootShoes[player] = shoes
end

local function restoreMundaneWeapon(item)
	local data = item:getModData().ETWMundane
	if data and data.Applied then
		item:setCriticalChance(data.OriginalCriticalChance)
		data.Applied = false
		data.OriginalCriticalChance = nil
		logETW("ETW Logger | mundaneTrait(): restored " .. item:getFullType())
	end
end

---@param player IsoPlayer
local function mundaneTrait(player)
	local weapon = player:getPrimaryHandItem()
	if weapon and not instanceof(weapon, "HandWeapon") then
		weapon = nil
	end
	local previousWeapon = mundaneWeapons[player]
	if previousWeapon and (previousWeapon ~= weapon or not player:hasTrait(ETWTraitsRegistry.MUNDANE)) then
		restoreMundaneWeapon(previousWeapon)
		mundaneWeapons[player] = nil
	end
	if not player:hasTrait(ETWTraitsRegistry.MUNDANE) or not weapon then
		if weapon then
			restoreMundaneWeapon(weapon)
		end
		return
	end
	local itemData = weapon:getModData()
	itemData.ETWMundane = itemData.ETWMundane or {}
	local data = itemData.ETWMundane
	if not data.Applied then
		data.OriginalCriticalChance = weapon:getCriticalChance()
		weapon:setCriticalChance(0)
		data.Applied = true
		logETW(
			"ETW Logger | mundaneTrait(): disabled critical hits for "
				.. weapon:getFullType()
				.. "; critical chance: "
				.. data.OriginalCriticalChance
				.. "->0"
		)
	end
	mundaneWeapons[player] = weapon
end

---Rolls for Butterfingers to drop held items while moving.
---@param player IsoPlayer
local function butterfingersTrait(player)
	if not player:hasTrait(ETWTraitsRegistry.BUTTERFINGERS) or not player:isPlayerMoving() then
		return
	end
	if player:getPrimaryHandItem() == nil and player:getSecondaryHandItem() == nil then
		return
	end

	local chanceIn = math.max(1, SBvars.ButterfingersChanceOneIn or 2000)
	local chance = 3 + math.floor(player:getInventoryWeight() / 5)
	if player:hasTrait(CharacterTrait.ALL_THUMBS) then
		chance = chance + 1
	elseif player:hasTrait(CharacterTrait.DEXTROUS) then
		chance = chance - 1
	end
	if player:isSprinting() then
		chance = chance + 10
	elseif player:isRunning() then
		chance = chance + 5
	end

	if random_instance:random(1, chanceIn) <= math.min(chanceIn, math.max(1, chance)) then
		local primaryItem = player:getPrimaryHandItem()
		local secondaryItem = player:getSecondaryHandItem()
		player:dropHandItems()
		ETW_CommonFunctions.displayButterfingersPopup(player)
		logETW(
			"ETW Logger | butterfingersTrait(): dropped held items; primary: "
				.. (primaryItem and primaryItem:getFullType() or "nil")
				.. ", secondary: "
				.. (secondaryItem and secondaryItem:getFullType() or "nil")
				.. ", chance: "
				.. math.max(1, chance)
				.. "/"
				.. chanceIn
		)
	end
end

---@param player IsoPlayer
local function updateItemTraits(player)
	if not player then
		return
	end
	wellFittedTrait(player)
	leadFootTrait(player)
	mundaneTrait(player)
	butterfingersTrait(player)
end

local function everyOneMinute()
	if isServer() then
		local players = getOnlinePlayers()
		for i = 0, players:size() - 1 do
			updateItemTraits(players:get(i))
		end
	else
		updateItemTraits(getPlayer())
	end
end

---@param player IsoPlayer
local function onEquipmentChanged(player)
	updateItemTraits(player)
end

---@param player IsoPlayer
local function onPlayerDeath(player)
	local shoes = leadFootShoes[player]
	if shoes then
		restoreLeadFootItem(shoes)
		leadFootShoes[player] = nil
	end
	local weapon = mundaneWeapons[player]
	if weapon then
		restoreMundaneWeapon(weapon)
		mundaneWeapons[player] = nil
	end

	local wornItems = player:getWornItems()
	local items = player:getInventory():getItems()
	local restoredWellFitted = false
	for i = 0, items:size() - 1 do
		local item = items:get(i)
		local data = item:getModData().ETWWellFitted
		if data and data.Applied then
			restoreWellFittedItem(item, data)
			restoredWellFitted = true
		end
	end
	if restoredWellFitted then
		player:setWornItems(wornItems)
		logETW("ETW Logger | onPlayerDeath(): restored Well-Fitted clothing state")
	end
end

---@param player IsoPlayer
---@param args table
function Commands.refreshClothingTraits(player, args)
	wellFittedTrait(player)
	leadFootTrait(player)
	logETW(
		"ETW Logger | Commands.refreshClothingTraits(): refreshed clothing traits for " .. player:getUsername()
	)
end

local function onClientCommand(module, command, player, args)
	if module == "ETW" and Commands[command] then
		Commands[command](player, args or {})
	end
end

Events.EveryOneMinute.Remove(everyOneMinute)
Events.EveryOneMinute.Add(everyOneMinute)
Events.OnEquipPrimary.Remove(onEquipmentChanged)
Events.OnEquipPrimary.Add(onEquipmentChanged)
Events.OnClientCommand.Remove(onClientCommand)
Events.OnClientCommand.Add(onClientCommand)
