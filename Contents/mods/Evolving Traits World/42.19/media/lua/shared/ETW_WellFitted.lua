local ETW_Registry = require("ETW_Registry")
local ETW_CommonFunctions = require("ETW_CommonFunctions")

---@type EvolvingTraitsWorldSandboxVars
local SBvars = SandboxVars.EvolvingTraitsWorld
local WELL_FITTED = ETW_Registry.traits.WELL_FITTED
local logETW = ETW_CommonFunctions.log

local function restoreItem(item, data)
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
local function updateWellFitted(player)
	if not player then
		return
	end
	local hasTrait = player:hasTrait(WELL_FITTED)
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
				local reduction = math.max(0, math.min(100, SBvars.WellFittedWeightReduction or 50)) / 100
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
						"ETW Logger | updateWellFitted(): applied to "
							.. item:getFullType()
							.. "; actual weight: "
							.. data.OriginalActualWeight
							.. "->"
							.. item:getActualWeight()
					)
				end
			elseif data.Applied then
				restoreItem(item, data)
				changed = true
				logETW("ETW Logger | updateWellFitted(): restored " .. item:getFullType())
			end
		end
	end

	if changed then
		player:setWornItems(wornItems)
	end
end

local function everyOneMinute()
	if isServer() then
		local players = getOnlinePlayers()
		for i = 0, players:size() - 1 do
			updateWellFitted(players:get(i))
		end
	else
		local player = getPlayer()
		if player then
			updateWellFitted(player)
		end
	end
end

Events.EveryOneMinute.Remove(everyOneMinute)
Events.EveryOneMinute.Add(everyOneMinute)
