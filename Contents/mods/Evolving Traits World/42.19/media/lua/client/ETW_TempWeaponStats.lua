-- TEMPORARY: remove this file after checking server -> client weapon replication.
-- Prints actual client item values every two real seconds, even when unchanged.
-- Does not modify the weapon or request synchronization from the server.
local PRINT_INTERVAL_MS = 2000
local lastPrintAt = 0

---Print the local player's primary-hand weapon stats for comparison with server logs.
local function printCurrentWeaponStats()
	local now = getTimestampMs()
	if now - lastPrintAt < PRINT_INTERVAL_MS then
		return
	end
	lastPrintAt = now
	local player = getPlayer()
	if not player then
		return
	end
	local weapon = player:getPrimaryHandItem()
	if not weapon or not instanceof(weapon, "HandWeapon") then
		print("[ETW TEMP WeaponStats CLIENT] No primary-hand weapon")
		return
	end
	---@cast weapon HandWeapon
	print(
		"[ETW TEMP WeaponStats CLIENT] timeMs=" .. tostring(now)
			.. "; player=" .. tostring(player:getUsername())
			.. "; weapon=" .. weapon:getFullType()
			.. "; itemID=" .. tostring(weapon:getID())
			.. "; minDamage=" .. tostring(weapon:getMinDamage())
			.. "; maxDamage=" .. tostring(weapon:getMaxDamage())
			.. "; criticalChance=" .. tostring(weapon:getCriticalChance())
			.. "; condition=" .. tostring(weapon:getCondition())
			.. "; conditionLowerChance=" .. tostring(weapon:getConditionLowerChance())
			.. "; aimingTime=" .. tostring(weapon:getAimingTime())
			.. "; maxRange=" .. tostring(weapon:getMaxRange())
			.. "; jamGunChance=" .. tostring(weapon:getJamGunChance())
	)
end

Events.OnTick.Add(printCurrentWeaponStats)
