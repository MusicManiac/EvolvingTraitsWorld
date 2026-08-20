local ETW_CommonFunctions = require("ETW_CommonFunctions")

local FILENAME = "ETW_ClientEventTriggers.lua"
if not ETW_CommonFunctions.gameModeSafeguard(FILENAME, { ETW_CommonFunctions.GameMode.MP_CLIENT }) then
	return
end

local logETW = ETW_CommonFunctions.log

---@param character IsoGameCharacter
local function clothingRefreshOnServer(character)
	if not character or not instanceof(character, "IsoPlayer") or not character:isLocalPlayer() then
		return
	end
	local player = character
	---@cast player IsoPlayer
	sendClientCommand(player, "ETW", "refreshClothingTraits", {})
	logETW("ETW Logger | clothingRefreshOnServer(): requested server clothing-trait refresh")
end

Events.OnClothingUpdated.Remove(clothingRefreshOnServer)
Events.OnClothingUpdated.Add(clothingRefreshOnServer)
Events.OnPlayerDeath.Remove(clothingRefreshOnServer)
Events.OnPlayerDeath.Add(clothingRefreshOnServer)
