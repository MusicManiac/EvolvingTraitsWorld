xpSystemText.ETW = getText("UI_ETW");

---Function responsible for opening up ETW UI
---@param keynum number
local function ETWShowUI(keynum)
	if keynum == PZAPI.ModOptions:getOptions("ETWModOptions"):getOption("UIToggle"):getValue() and getPlayer() then
		local playerObj = getSpecificPlayer(0)
		xpUpdate.characterInfo = getPlayerInfoPanel(playerObj:getPlayerNum());
		xpUpdate.characterInfo:toggleView(xpSystemText.ETW);
	end
end

Events.OnKeyPressed.Add(ETWShowUI);