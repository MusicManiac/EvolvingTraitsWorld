local ETW_Registry = require("ETW_Registry")
local ETW_CommonFunctions = require("ETW_CommonFunctions")
local ETWCombinedTraitChecks = require("ETW_CombinedTraitFunctions")

local FILENAME = "ETW_ItemTraits.lua"
if
	not ETW_CommonFunctions.gameModeSafeguard(
		FILENAME,
		{ ETW_CommonFunctions.GameMode.SP, ETW_CommonFunctions.GameMode.MP_CLIENT, ETW_CommonFunctions.GameMode.MP_SERVER }
	)
then
	return
end

---@type EvolvingTraitsWorldSandboxVars
local SBvars = SandboxVars.EvolvingTraitsWorld
local ETWTraitsRegistry = ETW_Registry.traits
local logETW = ETW_CommonFunctions.log
local random_instance = newrandom()
local ETW_ItemTraits = {}
local gameMode = ETW_CommonFunctions.gameMode()

---Limits local execution to the current player while allowing every player on the server.
---@param player IsoPlayer|nil
---@return boolean
local function shouldProcessPlayer(player)
	return player ~= nil
		and (gameMode == ETW_CommonFunctions.GameMode.MP_SERVER or player == getPlayer())
end

---@type table<IsoPlayer, Clothing>
local leadFootShoes = {}
---@type table<IsoPlayer, HandWeapon>
local combatTraitWeapons = {}
---@type table<HandWeapon, table<string, number>>
local combatTraitAppliedValues = {}
local antiGunWeapons = {}
local actionHeroThreatCache = {}
local Commands = {}

local ACTION_HERO_SCAN_CACHE_MS = 500

local tavernBrawlerDisplayCategories = {
	Cooking = true,
	CookingWeapon = true,
	FirstAid = true,
	FirstAidWeapon = true,
	Gardening = true,
	GardeningWeapon = true,
	Household = true,
	HouseholdWeapon = true,
	Sports = true,
	SportsWeapon = true,
	ToolWeapon = true,
	WeaponCrafted = true,
	WeaponImprovised = true,
}

---Restores a clothing item's modifiers saved before Well Fitted was applied.
---@param item Clothing
---@param data table
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
			---@cast item Clothing
			local itemData = item:getModData()
			itemData.ETWWellFitted = itemData.ETWWellFitted or {}
			local data = itemData.ETWWellFitted
			local isWorn = wornItems:contains(item)
			if hasTrait and isWorn then
				-- ModData can arrive before the local item fields have been updated.
				changed = true
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
		player:OnClothingUpdated()
		player:getInventory():setDrawDirty(true)
	end
end

---Restores footwear modified by Lead Foot.
---@param item Clothing
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
	---@cast shoes Clothing
	local itemData = shoes:getModData()
	itemData.ETWLeadFoot = itemData.ETWLeadFoot or {}
	local data = itemData.ETWLeadFoot
	if not data.Applied then
		data.OriginalStompPower = shoes:getStompPower()
	end
	-- Apply from the snapshot even when another peer supplied the Applied flag.
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
	leadFootShoes[player] = shoes
end

---@param weapon HandWeapon
---@param minDamage number
---@param displayedMaxDamage number
---@return number rawMaxDamage
local function getRawMaxDamage(weapon, minDamage, displayedMaxDamage)
	if not weapon:hasSharpness() then
		return displayedMaxDamage
	end
	local sharpnessMultiplier = weapon:getSharpnessMultiplier()
	if sharpnessMultiplier <= 0 or displayedMaxDamage <= minDamage then
		return displayedMaxDamage
	end
	return minDamage + (displayedMaxDamage - minDamage) / sharpnessMultiplier
end

---@param weapon HandWeapon
---@param displayedCriticalChance number
---@return number rawCriticalChance
local function getRawCriticalChance(weapon, displayedCriticalChance)
	if not weapon:hasSharpness() then
		return displayedCriticalChance
	end
	local sharpness = weapon:getSharpness()
	if sharpness > 0 then
		return displayedCriticalChance / sharpness
	end
	local probeSharpness = weapon:getMaxSharpness()
	if probeSharpness > 0 then
		weapon:setSharpness(probeSharpness)
		local appliedProbeSharpness = weapon:getSharpness()
		local rawCriticalChance = appliedProbeSharpness > 0
			and weapon:getCriticalChance() / appliedProbeSharpness
			or displayedCriticalChance
		weapon:setSharpness(sharpness)
		return rawCriticalChance
	end
	return displayedCriticalChance
end

---Restores a weapon's values saved before combat trait modifiers were applied.
---@param item HandWeapon
local function restoreCombatTraitWeapon(item)
	combatTraitAppliedValues[item] = nil
	local data = item:getModData().ETWCombatTraits
	if data and data.Applied then
		if not data.SnapshotUsesRawValues then
			data.OriginalMaxDamage = getRawMaxDamage(
				item,
				data.OriginalMinDamage,
				data.OriginalMaxDamage
			)
			data.OriginalCriticalChance = getRawCriticalChance(item, data.OriginalCriticalChance)
		end
		item:setMinDamage(data.OriginalMinDamage)
		item:setMaxDamage(data.OriginalMaxDamage)
		local criticalChanceModified = data.CriticalChanceModified
		if criticalChanceModified == nil then
			criticalChanceModified = data.ProwessName ~= nil
				or data.Mundane == true
				or data.TavernBrawler == true
				or data.Gordonite == true
				or data.ActionHero == true
		end
		if criticalChanceModified then
			item:setCriticalChance(data.OriginalCriticalChance)
		end
		if data.OriginalConditionLowerChance ~= nil then
			item:setConditionLowerChance(data.OriginalConditionLowerChance)
		end
		if data.OriginalAimingTime ~= nil then
			item:setAimingTime(data.OriginalAimingTime)
			item:setMaxRange(data.OriginalMaxRange)
			item:setJamGunChance(data.OriginalJamGunChance)
		end
		data.Applied = false
		data.OriginalMinDamage = nil
		data.OriginalMaxDamage = nil
		data.OriginalCriticalChance = nil
		data.OriginalConditionLowerChance = nil
		data.SnapshotUsesRawValues = nil
		data.CriticalChanceModified = nil
		data.ProwessName = nil
		data.RelevantSkillLevels = nil
		data.DamageBonusPercent = nil
		data.BaseCriticalChance = nil
		data.Mundane = nil
		data.TavernBrawler = nil
		data.TavernBrawlerDamageBonusPercent = nil
		data.TavernBrawlerConditionLossReductionPercent = nil
		data.Gordonite = nil
		data.GordoniteRelevantSkillLevels = nil
		data.GordoniteEffectiveness = nil
		data.GordoniteDamageBonus = nil
		data.GordoniteCriticalChanceBonus = nil
		data.ActionHero = nil
		data.ActionHeroDamageMultiplier = nil
		data.ActionHeroCriticalChanceBonus = nil
		data.UnwaveringDamageMultiplier = nil
		data.Terminator = nil
		data.TerminatorDamageMultiplier = nil
		data.TerminatorAimingTimeMultiplier = nil
		data.TerminatorMaxRangeBonus = nil
		data.TerminatorJamChanceMultiplier = nil
		data.OriginalAimingTime = nil
		data.OriginalMaxRange = nil
		data.OriginalJamGunChance = nil
		logETW("ETW Logger | combatWeaponTraits(): restored " .. item:getFullType())
	end
end

---@param weapon HandWeapon
---@return boolean
local function isTavernBrawlerWeapon(weapon)
	return not weapon:isRanged()
		and (
			weapon:isOfWeaponCategory(WeaponCategory.IMPROVISED)
			or tavernBrawlerDisplayCategories[weapon:getDisplayCategory()] == true
		)
end

---@param weapon HandWeapon
---@return boolean
local function isGordoniteCrowbar(weapon)
	local itemType = weapon:getType()
	return itemType == "Crowbar" or itemType == "CrowbarForged"
end

---@param weapon HandWeapon
---@param conditionLowerChance integer
---@return number damageBonusPercent
---@return number conditionLossReductionPercent
local function getTavernBrawlerBonuses(weapon, conditionLowerChance)
	local baseDamageBonusPercent = math.max(0, SBvars.TavernBrawlerDamageBonusPercent or 10)
	local baseConditionLossReductionPercent = PZMath.clamp(
		SBvars.TavernBrawlerConditionLossReductionPercent or 50,
		0,
		95
	)
	local damageBonusPercent = baseDamageBonusPercent
	local conditionLossReductionPercent = baseConditionLossReductionPercent
	if conditionLowerChance <= 2 then
		damageBonusPercent = damageBonusPercent * 1.5
		conditionLossReductionPercent = conditionLossReductionPercent * 1.5
	end
	if weapon:getConditionMax() <= 5 then
		damageBonusPercent = damageBonusPercent + baseDamageBonusPercent * 0.5
		conditionLossReductionPercent = conditionLossReductionPercent
			+ baseConditionLossReductionPercent * 0.5
	end
	if weapon:isOfWeaponCategory(WeaponCategory.SPEAR) then
		return damageBonusPercent * 0.25, 0
	end
	return damageBonusPercent, PZMath.clamp(conditionLossReductionPercent, 0, 95)
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
---@return number damageMultiplier
local function getUnwaveringDamageMultiplier(player)
	local stats = player:getStats()
	local endurance = stats:get(CharacterStat.ENDURANCE)
	local fatigue = stats:get(CharacterStat.FATIGUE)
	local pain = stats:get(CharacterStat.PAIN)
	local maximumMultiplier = math.max(1, SBvars.UnwaveringMaximumDamageMultiplier or 2)
	local bonus = maximumMultiplier - 1
	if endurance <= 0.25 or fatigue >= 0.8 or pain >= 75 then
		return maximumMultiplier
	elseif endurance <= 0.5 or fatigue >= 0.7 or pain >= 50 then
		return 1 + bonus * 0.5
	elseif endurance <= 0.75 or fatigue >= 0.6 or pain >= 20 then
		return 1 + bonus * 0.25
	end
	return 1
end

---Calculates Action Hero's weapon bonuses from nearby living zombies.
---@param player IsoPlayer
---@return number damageMultiplier
---@return number criticalChanceBonus
---@return integer nearbyZombies
local function getActionHeroBonuses(player)
	local now = getTimestampMs()
	local cached = actionHeroThreatCache[player]
	if cached and now < cached.timestamp + ACTION_HERO_SCAN_CACHE_MS then
		return cached.damageMultiplier, cached.criticalChanceBonus, cached.nearbyZombies
	end

	local damageMultiplier = math.max(0, SBvars.ActionHeroBaseDamagePercent or 50) / 100
	local criticalChanceBonus = math.max(0, SBvars.ActionHeroBaseCriticalChance or 10)
	local closeDamageBonus = math.max(0, SBvars.ActionHeroCloseDamageBonusPercent or 10) / 100
	local closeCriticalChanceBonus = math.max(
		0,
		SBvars.ActionHeroCloseCriticalChanceBonus or 10
	)
	local nearbyZombies = 0
	local weightedDamageThreat = 0.0
	local weightedCriticalThreat = 0.0
	nearbyZombies = ETWCombinedTraitChecks.forEachNearbyLivingZombieCachedThisFrame(
		player,
		10,
		function(_, distanceSquared)
			if distanceSquared < 4 then
				weightedDamageThreat = weightedDamageThreat + 1
				weightedCriticalThreat = weightedCriticalThreat + 1
			elseif distanceSquared < 25 then
				weightedDamageThreat = weightedDamageThreat + 0.4
				weightedCriticalThreat = weightedCriticalThreat + 0.5
			else
				weightedDamageThreat = weightedDamageThreat + 0.2
				weightedCriticalThreat = weightedCriticalThreat + 0.2
			end
		end
	)
	damageMultiplier = damageMultiplier + closeDamageBonus * weightedDamageThreat
	criticalChanceBonus = criticalChanceBonus
		+ closeCriticalChanceBonus * weightedCriticalThreat
	criticalChanceBonus = PZMath.clamp(criticalChanceBonus, 0, 100)
	actionHeroThreatCache[player] = {
		timestamp = now,
		damageMultiplier = damageMultiplier,
		criticalChanceBonus = criticalChanceBonus,
		nearbyZombies = nearbyZombies,
	}
	return damageMultiplier, criticalChanceBonus, nearbyZombies
end

---@param player IsoPlayer
local function combatWeaponTraits(player)
	if not shouldProcessPlayer(player) then
		return
	end
	local primaryItem = player:getPrimaryHandItem()
	---@type HandWeapon?
	local weapon
	if primaryItem and instanceof(primaryItem, "HandWeapon") then
		---@cast primaryItem HandWeapon
		weapon = primaryItem
	end
	local previousWeapon = combatTraitWeapons[player]
	if previousWeapon and previousWeapon ~= weapon then
		restoreCombatTraitWeapon(previousWeapon)
		combatTraitWeapons[player] = nil
	end
	if not weapon then
		return
	end

	local itemData = weapon:getModData()
	itemData.ETWCombatTraits = itemData.ETWCombatTraits or {}
	local data = itemData.ETWCombatTraits
	local hasMundane = player:hasTrait(ETWTraitsRegistry.MUNDANE)
	local prowessName, relevantSkillLevels = getMatchingMeleeProwess(player, weapon)
	local hasTavernBrawler = player:hasTrait(ETWTraitsRegistry.TAVERN_BRAWLER)
		and isTavernBrawlerWeapon(weapon)
	local hasGordonite = player:hasTrait(ETWTraitsRegistry.GORDONITE)
		and isGordoniteCrowbar(weapon)
	local gordoniteRelevantSkillLevels = hasGordonite
		and player:getPerkLevel(Perks.Blunt) + player:getPerkLevel(Perks.Strength)
		or 0
	local gordoniteEffectiveness = hasGordonite
		and math.max(0, SBvars.GordoniteEffectiveness or 100) / 100
		or 0
	local gordoniteDamageBonus = hasGordonite
		and (0.1 + gordoniteRelevantSkillLevels * 0.025) * gordoniteEffectiveness
		or 0
	local gordoniteCriticalChanceBonus = hasGordonite
		and gordoniteRelevantSkillLevels / 2 * gordoniteEffectiveness
		or 0
	local hasActionHero = player:hasTrait(ETWTraitsRegistry.ACTION_HERO)
	if not hasActionHero then
		actionHeroThreatCache[player] = nil
	end
	local actionHeroDamageMultiplier, actionHeroCriticalChanceBonus, actionHeroNearbyZombies =
		1.0, 0.0, 0
	if hasActionHero then
		actionHeroDamageMultiplier, actionHeroCriticalChanceBonus, actionHeroNearbyZombies =
			getActionHeroBonuses(player)
	end
	local hasUnwavering = player:hasTrait(ETWTraitsRegistry.UNWAVERING)
	local unwaveringDamageMultiplier = hasUnwavering
		and getUnwaveringDamageMultiplier(player)
		or 1
	local hasUnwaveringDamageBoost = unwaveringDamageMultiplier > 1
	local hasTerminator = player:hasTrait(ETWTraitsRegistry.TERMINATOR)
		and weapon:getSubCategory() == "Firearm"
	local terminatorDamageMultiplier = hasTerminator
		and 1 + math.max(0, SBvars.TerminatorDamageBonusPercent or 25) / 100
		or 1
	local terminatorAimingTimeMultiplier = hasTerminator
		and math.max(0, SBvars.TerminatorAimingTimeMultiplier or 2)
		or 1
	local terminatorMaxRangeBonus = hasTerminator
		and math.max(0, SBvars.TerminatorMaxRangeBonus or 5)
		or 0
	local terminatorJamChanceMultiplier = hasTerminator
		and PZMath.clamp(SBvars.TerminatorJamChanceMultiplier or 0.5, 0, 1)
		or 1
	local tavernBrawlerDamageBonusPercent, tavernBrawlerConditionLossReductionPercent = 0.0, 0.0
	if hasTavernBrawler then
		local originalConditionLowerChance = data.Applied and data.OriginalConditionLowerChance
			or weapon:getConditionLowerChance()
		tavernBrawlerDamageBonusPercent, tavernBrawlerConditionLossReductionPercent =
			getTavernBrawlerBonuses(weapon, originalConditionLowerChance)
	end
	local damageBonusPercent = prowessName
		and math.max(0, SBvars.ProwessMeleeDamageBonusPercent or 20)
		or 0
	local baseCriticalChance = prowessName
		and math.max(0, SBvars.ProwessMeleeBaseCriticalChance or 5)
		or 0
	local criticalChanceModified = prowessName ~= nil
		or hasMundane
		or hasGordonite
		or hasActionHero
	if
		not hasMundane
		and not prowessName
		and not hasTavernBrawler
		and not hasGordonite
		and not hasActionHero
		and not hasUnwaveringDamageBoost
		and not hasTerminator
	then
		if data.Applied then
			restoreCombatTraitWeapon(weapon)
		end
		return
	end
	local appliedValues = combatTraitAppliedValues[weapon]
	if
		data.Applied
		and appliedValues
		and weapon:getMinDamage() == appliedValues.MinDamage
		and weapon:getMaxDamage() == appliedValues.MaxDamage
		and weapon:getConditionLowerChance() == appliedValues.ConditionLowerChance
		and (not criticalChanceModified or weapon:getCriticalChance() == appliedValues.CriticalChance)
		and (
			not hasTerminator
			or (
				weapon:getAimingTime() == appliedValues.AimingTime
				and weapon:getMaxRange() == appliedValues.MaxRange
				and weapon:getJamGunChance() == appliedValues.JamGunChance
			)
		)
		and data.Mundane == hasMundane
		and data.ProwessName == prowessName
		and data.RelevantSkillLevels == relevantSkillLevels
		and data.DamageBonusPercent == damageBonusPercent
		and data.BaseCriticalChance == baseCriticalChance
		and data.TavernBrawler == hasTavernBrawler
		and data.TavernBrawlerDamageBonusPercent == tavernBrawlerDamageBonusPercent
		and data.TavernBrawlerConditionLossReductionPercent
			== tavernBrawlerConditionLossReductionPercent
		and data.Gordonite == hasGordonite
		and data.GordoniteRelevantSkillLevels == gordoniteRelevantSkillLevels
		and data.GordoniteEffectiveness == gordoniteEffectiveness
		and data.GordoniteDamageBonus == gordoniteDamageBonus
		and data.GordoniteCriticalChanceBonus == gordoniteCriticalChanceBonus
		and data.ActionHero == hasActionHero
		and data.ActionHeroDamageMultiplier == actionHeroDamageMultiplier
		and data.ActionHeroCriticalChanceBonus == actionHeroCriticalChanceBonus
		and data.UnwaveringDamageMultiplier == unwaveringDamageMultiplier
		and data.Terminator == hasTerminator
		and data.TerminatorDamageMultiplier == terminatorDamageMultiplier
		and data.TerminatorAimingTimeMultiplier == terminatorAimingTimeMultiplier
		and data.TerminatorMaxRangeBonus == terminatorMaxRangeBonus
		and data.TerminatorJamChanceMultiplier == terminatorJamChanceMultiplier
		and data.SnapshotUsesRawValues == true
		and data.CriticalChanceModified == criticalChanceModified
	then
		combatTraitWeapons[player] = weapon
		return
	end
	if data.Applied then
		restoreCombatTraitWeapon(weapon)
	end

	local originalDisplayedMinDamage = weapon:getMinDamage()
	local originalDisplayedMaxDamage = weapon:getMaxDamage()
	local originalDisplayedCriticalChance = weapon:getCriticalChance()
	data.OriginalMinDamage = originalDisplayedMinDamage
	data.OriginalMaxDamage = getRawMaxDamage(
		weapon,
		originalDisplayedMinDamage,
		originalDisplayedMaxDamage
	)
	data.OriginalCriticalChance = criticalChanceModified
		and getRawCriticalChance(weapon, originalDisplayedCriticalChance)
		or nil
	data.OriginalConditionLowerChance = weapon:getConditionLowerChance()
	data.SnapshotUsesRawValues = true
	data.CriticalChanceModified = criticalChanceModified
	data.ProwessName = prowessName
	data.RelevantSkillLevels = relevantSkillLevels
	data.DamageBonusPercent = damageBonusPercent
	data.BaseCriticalChance = baseCriticalChance
	data.Mundane = hasMundane
	data.TavernBrawler = hasTavernBrawler
	data.TavernBrawlerDamageBonusPercent = tavernBrawlerDamageBonusPercent
	data.TavernBrawlerConditionLossReductionPercent = tavernBrawlerConditionLossReductionPercent
	data.Gordonite = hasGordonite
	data.GordoniteRelevantSkillLevels = gordoniteRelevantSkillLevels
	data.GordoniteEffectiveness = gordoniteEffectiveness
	data.GordoniteDamageBonus = gordoniteDamageBonus
	data.GordoniteCriticalChanceBonus = gordoniteCriticalChanceBonus
	data.ActionHero = hasActionHero
	data.ActionHeroDamageMultiplier = actionHeroDamageMultiplier
	data.ActionHeroCriticalChanceBonus = actionHeroCriticalChanceBonus
	data.UnwaveringDamageMultiplier = unwaveringDamageMultiplier
	data.Terminator = hasTerminator
	data.TerminatorDamageMultiplier = terminatorDamageMultiplier
	data.TerminatorAimingTimeMultiplier = terminatorAimingTimeMultiplier
	data.TerminatorMaxRangeBonus = terminatorMaxRangeBonus
	data.TerminatorJamChanceMultiplier = terminatorJamChanceMultiplier
	if hasTerminator then
		data.OriginalAimingTime = weapon:getAimingTime()
		data.OriginalMaxRange = weapon:getMaxRange()
		data.OriginalJamGunChance = weapon:getJamGunChance()
	end
	if
		prowessName
		or hasTavernBrawler
		or hasGordonite
		or hasActionHero
		or hasUnwaveringDamageBoost
		or hasTerminator
	then
		local damageMultiplier = 1 + (damageBonusPercent + tavernBrawlerDamageBonusPercent) / 100
		weapon:setMinDamage(
			(data.OriginalMinDamage * damageMultiplier + gordoniteDamageBonus)
				* actionHeroDamageMultiplier
				* unwaveringDamageMultiplier
				* terminatorDamageMultiplier
		)
		weapon:setMaxDamage(
			(data.OriginalMaxDamage * damageMultiplier + gordoniteDamageBonus)
				* actionHeroDamageMultiplier
				* unwaveringDamageMultiplier
				* terminatorDamageMultiplier
		)
		if (prowessName or hasGordonite or hasActionHero) and not hasMundane then
			local criticalBonus = gordoniteCriticalChanceBonus + actionHeroCriticalChanceBonus
			if prowessName then
				criticalBonus = criticalBonus + baseCriticalChance + relevantSkillLevels
			end
			local originalCriticalChance = data.OriginalCriticalChance
			if originalCriticalChance ~= nil then
				weapon:setCriticalChance(PZMath.clamp(originalCriticalChance + criticalBonus, 0, 100))
			end
		end
	end
	if hasTavernBrawler and tavernBrawlerConditionLossReductionPercent > 0 then
		local conditionChanceMultiplier = 100 / (100 - tavernBrawlerConditionLossReductionPercent)
		weapon:setConditionLowerChance(
			math.floor(data.OriginalConditionLowerChance * conditionChanceMultiplier + 0.5)
		)
	end
	if hasMundane then
		weapon:setCriticalChance(0)
	end
	if hasTerminator then
		local aimingTime = math.floor(data.OriginalAimingTime * terminatorAimingTimeMultiplier + 0.5)
		weapon:setAimingTime(aimingTime)
		weapon:setMaxRange(data.OriginalMaxRange + terminatorMaxRangeBonus)
		weapon:setJamGunChance(data.OriginalJamGunChance * terminatorJamChanceMultiplier)
	end
	data.Applied = true
	combatTraitWeapons[player] = weapon
	-- Keep this confirmation local: synchronized ModData alone cannot confirm item fields.
	combatTraitAppliedValues[weapon] = {
		MinDamage = weapon:getMinDamage(),
		MaxDamage = weapon:getMaxDamage(),
		CriticalChance = criticalChanceModified and weapon:getCriticalChance() or nil,
		ConditionLowerChance = weapon:getConditionLowerChance(),
		AimingTime = hasTerminator and weapon:getAimingTime() or nil,
		MaxRange = hasTerminator and weapon:getMaxRange() or nil,
		JamGunChance = hasTerminator and weapon:getJamGunChance() or nil,
	}
	local playerIdentifier = tostring(player:getUsername()) .. " (OnlineID=" .. player:getOnlineID() .. ")"
	local terminatorDetails = ""
	if hasTerminator then
		terminatorDetails = "; terminator: true; terminator damage multiplier: "
			.. terminatorDamageMultiplier
			.. "; aiming time: "
			.. data.OriginalAimingTime
			.. "->"
			.. weapon:getAimingTime()
			.. "; max range: "
			.. data.OriginalMaxRange
			.. "->"
			.. weapon:getMaxRange()
			.. "; jam chance: "
			.. data.OriginalJamGunChance
			.. "->"
			.. weapon:getJamGunChance()
	end
	logETW(
		"ETW Logger | combatWeaponTraits(): applied to "
			.. playerIdentifier
			.. "; weapon: "
			.. weapon:getFullType()
			.. "; prowess: "
			.. tostring(prowessName)
			.. "; mundane: "
			.. tostring(hasMundane)
			.. "; tavern brawler: "
			.. tostring(hasTavernBrawler)
			.. "; gordonite: "
			.. tostring(hasGordonite)
			.. "; gordonite skill levels: "
			.. gordoniteRelevantSkillLevels
			.. "; gordonite effectiveness: "
			.. gordoniteEffectiveness * 100
			.. "%"
			.. "; action hero: "
			.. tostring(hasActionHero)
			.. "; nearby zombies: "
			.. actionHeroNearbyZombies
			.. "; action hero damage multiplier: "
			.. actionHeroDamageMultiplier
			.. "; action hero critical chance bonus: "
			.. actionHeroCriticalChanceBonus
			.. "; unwavering damage multiplier: "
			.. unwaveringDamageMultiplier
			.. terminatorDetails
			.. "; min damage: "
			.. originalDisplayedMinDamage
			.. "->"
			.. weapon:getMinDamage()
			.. "; max damage: "
			.. originalDisplayedMaxDamage
			.. "->"
			.. weapon:getMaxDamage()
			.. "; critical chance: "
			.. originalDisplayedCriticalChance
			.. "->"
			.. weapon:getCriticalChance()
			.. "; condition lower chance: "
			.. data.OriginalConditionLowerChance
			.. "->"
			.. weapon:getConditionLowerChance()
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
	local equippedItem = player:getPrimaryHandItem()
	---@type HandWeapon|nil
	local weapon
	if equippedItem and instanceof(equippedItem, "HandWeapon") then
		---@cast equippedItem HandWeapon
		if equippedItem:getSubCategory() == "Firearm" then
			weapon = equippedItem
		end
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
	end
	-- Reapply locally from the original values, never from an already modified value.
	local aimingTimeMultiplier = math.max(0, SBvars.AntiGunAimingTimeMultiplier or 0.8)
	local rangePenalty = math.max(0, SBvars.AntiGunMaxRangePenalty or 5)
	local aimingTime = math.floor(data.OriginalAimingTime * aimingTimeMultiplier + 0.5)
	weapon:setAimingTime(aimingTime)
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
	if not shouldProcessPlayer(player) then
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
	if gameMode ~= ETW_CommonFunctions.GameMode.MP_CLIENT then
		butterfingersTrait(player)
	end
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
	actionHeroThreatCache[player] = nil
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
	for player in pairs(actionHeroThreatCache) do
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

---Updates the current player's items locally, or all connected players' items on the server.
local function everyOneMinute()
	local currentPlayer
	if gameMode ~= ETW_CommonFunctions.GameMode.MP_SERVER then
		currentPlayer = getPlayer()
		if not currentPlayer then
			return
		end
	end
	local players = ETW_CommonFunctions.playersList(currentPlayer)
	local activePlayers = {}
	for i = 0, players:size() - 1 do
		local player = players:get(i)
		activePlayers[player] = true
		updateItemTraits(player)
	end
	cleanupDisconnectedPlayers(activePlayers)
end

---@param player IsoPlayer
---@param args table
function Commands.refreshEquippedItemTraits(player, args)
	logETW(
		"ETW Logger | Commands.refreshEquippedItemTraits(): refreshed equipped item traits for "
			.. tostring(player:getUsername())
			.. " (OnlineID="
			.. player:getOnlineID()
			.. ")"
	)
	refreshEquippedItemTraits(player)
end

---@param player IsoPlayer
---@param args table
function Commands.refreshEquippedWeaponTraits(player, args)
	logETW(
		"ETW Logger | Commands.refreshEquippedWeaponTraits(): refreshed equipped weapon traits for "
			.. tostring(player:getUsername())
			.. " (OnlineID="
			.. player:getOnlineID()
			.. ")"
	)
	combatWeaponTraits(player)
end

---Handles item refresh requests on the multiplayer server.
---@param module string
---@param command string
---@param player IsoPlayer
---@param args table|nil
local function onClientCommand(module, command, player, args)
	if module == "ETW" and Commands[command] then
		Commands[command](player, args or {})
	end
end

Events.EveryOneMinute.Remove(everyOneMinute)
Events.EveryOneMinute.Add(everyOneMinute)
Events.OnEquipPrimary.Remove(refreshEquippedItemTraits)
Events.OnEquipPrimary.Add(refreshEquippedItemTraits)
if gameMode == ETW_CommonFunctions.GameMode.MP_SERVER then
	Events.OnClientCommand.Remove(onClientCommand)
	Events.OnClientCommand.Add(onClientCommand)
else
	Events.OnWeaponSwing.Remove(combatWeaponTraits)
	Events.OnWeaponSwing.Add(combatWeaponTraits)
	Events.OnClothingUpdated.Remove(refreshEquippedItemTraits)
	Events.OnClothingUpdated.Add(refreshEquippedItemTraits)
end

return ETW_ItemTraits
