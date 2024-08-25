xpSystemText.ETW = getText("UI_ETW");

function EvolvingTraitsWorld.KeyPressed(keynum)
	if EvolvingTraitsWorld.KEYS_Toggle.key and keynum == EvolvingTraitsWorld.KEYS_Toggle.key and getPlayer() then
		local playerObj = getSpecificPlayer(0)
		xpUpdate.characterInfo = getPlayerInfoPanel(playerObj:getPlayerNum());
		xpUpdate.characterInfo:toggleView(xpSystemText.ETW);
	end
end

Events.OnKeyPressed.Add(EvolvingTraitsWorld.KeyPressed);