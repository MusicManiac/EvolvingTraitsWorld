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
local combatTraitWeapons = {}
local antiGunWeapons = {}
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
				local speedReduction = PZMath.clamp(
					SBvars.WellFittedSpeedPenaltyReduction or 75,
					0,
					100
				) / 100
				local runSpeedPenalty = math.max(0, 1 - data.OriginalRunSpeedModifier)
				local combatSpeedPenalty = math.max(0, 1 - data.OriginalCombatSpeedModifier)
				item:setRunSpeedModifier(data.OriginalRunSpeedModifier + runSpeedPenalty * speedReduction)
				item:setCombatSpeedModifier(
					data.OriginalCombatSpeedModifier + combatSpeedPenalty * speedReduction
				)
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
							.. "; run speed modifier: "
							.. data.OriginalRunSpeedModifier
							.. "->"
							.. item:getRunSpeedModifier()
							.. "; combat speed modifier: "
							.. data.OriginalCombatSpeedModifier
							.. "->"
							.. item:getCombatSpeedModifier()
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

local function restoreCombatTraitWeapon(item)
	local data = item:getModData().ETWCombatTraits
	if data and data.Applied then
		item:setMinDamage(data.OriginalMinDamage)
		item:setMaxDamage(data.OriginalMaxDamage)
		item:setCriticalChance(data.OriginalCriticalChance)
		data.Applied = false
		data.OriginalMinDamage = nil
		data.OriginalMaxDamage = nil
		data.OriginalCriticalChance = nil
		data.ProwessName = nil
		data.RelevantSkillLevels = nil
		data.DamageBonusPercent = nil
		data.BaseCriticalChance = nil
		data.Mundane = nil
		logETW("ETW Logger | combatWeaponTraits(): restored " .. item:getFullType())
	end
end

---@param player IsoPlayer
---@param weapon HandWeapon
---@return string|nil prowessName
---@return number relevantSkillLevels
local function getMatchingMeleeProwess(player, weapon)
	if weapon:isRanged() then
		return nil, 0
	end
	if
		player:hasTrait(ETWTraitsRegistry.PROWESS_BLADE)
		and (
			weapon:isOfWeaponCategory(WeaponCategory.AXE)
			or weapon:isOfWeaponCategory(WeaponCategory.SMALL_BLADE)
			or weapon:isOfWeaponCategory(WeaponCategory.LONG_BLADE)
		)
	then
		return "Blade",
			player:getPerkLevel(Perks.Axe)
				+ player:getPerkLevel(Perks.SmallBlade)
				+ player:getPerkLevel(Perks.LongBlade)
	end
	if
		player:hasTrait(ETWTraitsRegistry.PROWESS_BLUNT)
		and (
			weapon:isOfWeaponCategory(WeaponCategory.SMALL_BLUNT)
			or weapon:isOfWeaponCategory(WeaponCategory.BLUNT)
		)
	then
		return "Blunt", player:getPerkLevel(Perks.SmallBlunt) + player:getPerkLevel(Perks.Blunt)
	end
	if
		player:hasTrait(ETWTraitsRegistry.PROWESS_SPEAR)
		and weapon:isOfWeaponCategory(WeaponCategory.SPEAR)
	then
		return "Spear", player:getPerkLevel(Perks.Spear)
	end
	return nil, 0
end

---@param player IsoPlayer
local function combatWeaponTraits(player)
	local weapon = player:getPrimaryHandItem()
	if weapon and not instanceof(weapon, "HandWeapon") then
		weapon = nil
	end
	local previousWeapon = combatTraitWeapons[player]
	if previousWeapon and previousWeapon ~= weapon then
		restoreCombatTraitWeapon(previousWeapon)
		combatTraitWeapons[player] = nil
	end
	if not weapon then
		return
	end

	local hasMundane = player:hasTrait(ETWTraitsRegistry.MUNDANE)
	local prowessName, relevantSkillLevels = getMatchingMeleeProwess(player, weapon)
	local damageBonusPercent = prowessName
		and math.max(0, SBvars.ProwessMeleeDamageBonusPercent or 20)
		or 0
	local baseCriticalChance = prowessName
		and math.max(0, SBvars.ProwessMeleeBaseCriticalChance or 5)
		or 0
	local itemData = weapon:getModData()
	itemData.ETWCombatTraits = itemData.ETWCombatTraits or {}
	local data = itemData.ETWCombatTraits
	if not hasMundane and not prowessName then
		if data.Applied then
			restoreCombatTraitWeapon(weapon)
		end
		return
	end
	if
		data.Applied
		and data.Mundane == hasMundane
		and data.ProwessName == prowessName
		and data.RelevantSkillLevels == relevantSkillLevels
		and data.DamageBonusPercent == damageBonusPercent
		and data.BaseCriticalChance == baseCriticalChance
	then
		combatTraitWeapons[player] = weapon
		return
	end
	if data.Applied then
		restoreCombatTraitWeapon(weapon)
	end

	data.OriginalMinDamage = weapon:getMinDamage()
	data.OriginalMaxDamage = weapon:getMaxDamage()
	data.OriginalCriticalChance = weapon:getCriticalChance()
	data.ProwessName = prowessName
	data.RelevantSkillLevels = relevantSkillLevels
	data.DamageBonusPercent = damageBonusPercent
	data.BaseCriticalChance = baseCriticalChance
	data.Mundane = hasMundane
	if prowessName then
		local damageMultiplier = 1 + damageBonusPercent / 100
		weapon:setMinDamage(data.OriginalMinDamage * damageMultiplier)
		weapon:setMaxDamage(data.OriginalMaxDamage * damageMultiplier)
		if not hasMundane then
			local criticalBonus = baseCriticalChance + relevantSkillLevels
			weapon:setCriticalChance(PZMath.clamp(data.OriginalCriticalChance + criticalBonus, 0, 100))
		end
	end
	if hasMundane then
		weapon:setCriticalChance(0)
	end
	data.Applied = true
	combatTraitWeapons[player] = weapon
	local playerIdentifier = tostring(player:getUsername()) .. " (OnlineID=" .. player:getOnlineID() .. ")"
	logETW(
		"ETW Logger | combatWeaponTraits(): applied to "
			.. playerIdentifier
			.. "; weapon: "
			.. weapon:getFullType()
			.. "; prowess: "
			.. tostring(prowessName)
			.. "; mundane: "
			.. tostring(hasMundane)
			.. "; min damage: "
			.. data.OriginalMinDamage
			.. "->"
			.. weapon:getMinDamage()
			.. "; max damage: "
			.. data.OriginalMaxDamage
			.. "->"
			.. weapon:getMaxDamage()
			.. "; critical chance: "
			.. data.OriginalCriticalChance
			.. "->"
			.. weapon:getCriticalChance()
	)
end

local function restoreAntiGunWeapon(item)
	local data = item:getModData().ETWAntiGun
	if data and data.Applied then
		item:setAimingTime(data.OriginalAimingTime)
		item:setMaxRange(data.OriginalMaxRange)
		data.Applied = false
		data.OriginalAimingTime = nil
		data.OriginalMaxRange = nil
		logETW("ETW Logger | antiGunWeaponTrait(): restored " .. item:getFullType())
	end
end

---@param player IsoPlayer
---@param hasTrait boolean
local function antiGunWeaponTrait(player, hasTrait)
	local weapon = player:getPrimaryHandItem()
	if
		weapon
		and (not instanceof(weapon, "HandWeapon") or weapon:getSubCategory() ~= "Firearm")
	then
		weapon = nil
	end
	local previousWeapon = antiGunWeapons[player]
	if previousWeapon and (previousWeapon ~= weapon or not hasTrait) then
		restoreAntiGunWeapon(previousWeapon)
		antiGunWeapons[player] = nil
	end
	if not hasTrait then
		if weapon then
			restoreAntiGunWeapon(weapon)
		end
		return
	end
	if not weapon then
		return
	end

	local itemData = weapon:getModData()
	itemData.ETWAntiGun = itemData.ETWAntiGun or {}
	local data = itemData.ETWAntiGun
	if not data.Applied then
		data.OriginalAimingTime = weapon:getAimingTime()
		data.OriginalMaxRange = weapon:getMaxRange()
		local aimingTimeMultiplier = math.max(0, SBvars.AntiGunAimingTimeMultiplier or 0.8)
		local rangePenalty = math.max(0, SBvars.AntiGunMaxRangePenalty or 5)
		weapon:setAimingTime(data.OriginalAimingTime * aimingTimeMultiplier)
		weapon:setMaxRange(math.max(5, data.OriginalMaxRange - rangePenalty))
		data.Applied = true
		logETW(
			"ETW Logger | antiGunWeaponTrait(): applied to "
				.. weapon:getFullType()
				.. "; aiming time: "
				.. data.OriginalAimingTime
				.. "->"
				.. weapon:getAimingTime()
				.. ", max range: "
				.. data.OriginalMaxRange
				.. "->"
				.. weapon:getMaxRange()
		)
	end
	antiGunWeapons[player] = weapon
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
		ETW_CommonFunctions.dropButterfingersHandItems(player)
		ETW_CommonFunctions.displayButterfingersPopup(player)
		logETW(
			"ETW Logger | butterfingersTrait(): triggered held-item drop; primary: "
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
local function refreshEquippedItemTraits(player)
	if not player then
		return
	end
	wellFittedTrait(player)
	leadFootTrait(player)
	combatWeaponTraits(player)
	local primaryItem = player:getPrimaryHandItem()
	local antiGunData = primaryItem and primaryItem:getModData().ETWAntiGun
	local hasAntiGunTrait = player:hasTrait(ETWTraitsRegistry.ANTI_GUN_ACTIVIST)
	if
		hasAntiGunTrait
		or antiGunWeapons[player]
		or (antiGunData and antiGunData.Applied)
	then
		antiGunWeaponTrait(player, hasAntiGunTrait)
	end
end

---@param player IsoPlayer
local function updateItemTraits(player)
	if not player then
		return
	end
	refreshEquippedItemTraits(player)
	butterfingersTrait(player)
end

---@param player IsoPlayer
local function restoreTrackedItemTraits(player)
	local shoes = leadFootShoes[player]
	if shoes then
		restoreLeadFootItem(shoes)
		leadFootShoes[player] = nil
	end
	local weapon = combatTraitWeapons[player]
	if weapon then
		restoreCombatTraitWeapon(weapon)
		combatTraitWeapons[player] = nil
	end
	local antiGunWeapon = antiGunWeapons[player]
	if antiGunWeapon then
		restoreAntiGunWeapon(antiGunWeapon)
		antiGunWeapons[player] = nil
	end
end

---@param activePlayers table<IsoPlayer, boolean>
local function cleanupDisconnectedPlayers(activePlayers)
	local trackedPlayers = {}
	for player in pairs(leadFootShoes) do
		trackedPlayers[player] = true
	end
	for player in pairs(combatTraitWeapons) do
		trackedPlayers[player] = true
	end
	for player in pairs(antiGunWeapons) do
		trackedPlayers[player] = true
	end
	for player in pairs(trackedPlayers) do
		if not activePlayers[player] then
			restoreTrackedItemTraits(player)
			logETW(
				"ETW Logger | cleanupDisconnectedPlayers(): restored tracked item traits for "
					.. tostring(player:getUsername())
					.. " (OnlineID="
					.. player:getOnlineID()
					.. ")"
			)
		end
	end
end

local function everyOneMinute()
	if isServer() then
		local players = getOnlinePlayers()
		local activePlayers = {}
		for i = 0, players:size() - 1 do
			local player = players:get(i)
			activePlayers[player] = true
			updateItemTraits(player)
		end
		cleanupDisconnectedPlayers(activePlayers)
	else
		updateItemTraits(getPlayer())
	end
end

---@param player IsoPlayer
local function onEquipmentChanged(player)
	refreshEquippedItemTraits(player)
end

---@param player IsoPlayer
---@param args table
function Commands.refreshEquippedItemTraits(player, args)
	refreshEquippedItemTraits(player)
	logETW(
		"ETW Logger | Commands.refreshEquippedItemTraits(): refreshed equipped item traits for "
			.. tostring(player:getUsername())
			.. " (OnlineID="
			.. player:getOnlineID()
			.. ")"
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
