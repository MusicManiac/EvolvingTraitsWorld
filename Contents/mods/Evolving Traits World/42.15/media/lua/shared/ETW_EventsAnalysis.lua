---@type ETW_CommonFunctions
local ETW_CommonFunctions = require("ETW_CommonFunctions")

local gameMode = ETW_CommonFunctions.gameMode()

local function onZombieDeadCheck(...)
	print("ETW Logger | onZombieDead fired in gameMode: " .. gameMode)
end

Events.OnZombieDead.Add(onZombieDeadCheck)
