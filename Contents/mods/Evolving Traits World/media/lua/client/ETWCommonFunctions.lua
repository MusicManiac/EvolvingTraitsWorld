require "ETWModData";
ETWCommonFunctions = {};

local SBvars = SandboxVars.EvolvingTraitsWorld;
local debug = function() return EvolvingTraitsWorld.settings.GatherDebug end
local detailedDebug = function() return EvolvingTraitsWorld.settings.GatherDetailedDebug end

local function indexOf(tbl, value)
	for i, subTable in ipairs(tbl) do
		for j, v in ipairs(subTable) do
			if v == value then
				return i
			end
		end
	end
	return -1
end

function ETWCommonFunctions.dataDump()
	if not SBvars.DelayedTraitsSystem then return true end;
	local traitTable = getPlayer():getModData().EvolvingTraitsWorld.DelayedTraits;
	for index, traitEntry in ipairs(traitTable) do
		local traitName, roll, gained = traitEntry[1], traitEntry[2], traitEntry[3];
		print("ETW Logger | Delayed Traits System | Data Dump: "..traitName.. ", "..roll..", "..tostring(gained))
	end
end

function ETWCommonFunctions.addTraitToDelayTable(modData, traitName, player, positiveTrait)
	if not SBvars.DelayedTraitsSystem then return end;
	if detailedDebug() then print("ETW Logger | Delayed Traits System: modData.DelayedStartingTraitsFilled =  "..tostring(modData.DelayedStartingTraitsFilled)) end;
	if not modData.DelayedStartingTraitsFilled then
		if debug() then print("ETW Logger | Delayed Traits System: player qualifies for "..traitName.." from the start of the game, adding it to delayed traits table") end;
		table.insert(modData.DelayedTraits, {traitName, SBvars.DelayedTraitsSystemDefaultDelay + SBvars.DelayedTraitsSystemDefaultStartingDelay, false})
	elseif indexOf(modData.DelayedTraits, traitName) == -1 and not player:HasTrait(traitName) and positiveTrait then
		if debug() then print("ETW Logger | Delayed Traits System: player qualifies for positive trait "..traitName..", adding it to delayed traits table") end;
		table.insert(modData.DelayedTraits, {traitName, SBvars.DelayedTraitsSystemDefaultDelay, false})
	elseif indexOf(modData.DelayedTraits, traitName) == -1 and player:HasTrait(traitName) and not positiveTrait then
		if debug() then print("ETW Logger | Delayed Traits System: player qualifies for removing negative trait "..traitName..", adding it to delayed traits table") end;
		table.insert(modData.DelayedTraits, {traitName, SBvars.DelayedTraitsSystemDefaultDelay, false})
	else
		if debug() then print("ETW Logger | Delayed Traits System: player qualifies for "..traitName..", but it's already in delayed traits table or player already has the trait") end;
	end
	if detailedDebug() then
		print("ETW Logger | Delayed Traits System | Data Dump after ETWCommonFunctions.addTraitToDelayTable() ------------");
		ETWCommonFunctions.dataDump();
		print("ETW Logger | Delayed Traits System | Data Dump after ETWCommonFunctions.addTraitToDelayTable() done --------------");
	end
end

function ETWCommonFunctions.checkDelayedTraits(name)
	if not SBvars.DelayedTraitsSystem then return true end;
	local traitTable = getPlayer():getModData().EvolvingTraitsWorld.DelayedTraits;
	for index, traitEntry in ipairs(traitTable) do
		local traitName, gained = traitEntry[1], traitEntry[3];
		if detailedDebug() then print("ETW Logger | Delayed Traits System: caught check on "..traitName) end;
		if traitName == name and gained then
			if detailedDebug() then print("ETW Logger | Delayed Traits System: caught check on "..traitName..": player qualifies for it; removing it from the table") end;
			table.remove(traitTable, index);
			return true;
		end
	end
	return false;
end

return ETWCommonFunctions;