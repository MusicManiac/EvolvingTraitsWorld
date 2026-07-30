require("TimedActions/ISEatFoodAction")

local ETW_Registry = require("ETW_Registry")

---@type EvolvingTraitsWorldSandboxVars
local SBvars = SandboxVars.EvolvingTraitsWorld

local original_ISEatFoodAction_getDuration = ISEatFoodAction.getDuration

---Applies the Fast Eater trait after vanilla has calculated the duration so
---portion sizes, utensils, and item-specific EatTime values keep working.
---@return number
function ISEatFoodAction:getDuration()
	local duration = original_ISEatFoodAction_getDuration(self)
	if duration <= 1 then
		return duration
	end

	local item = self.item
	local isDrink = item:getCustomMenuOption() == getText("ContextMenu_Drink")
	local isSmokable = item:hasTag(ItemTag.SMOKABLE)
	if not isDrink and not isSmokable and self.character:hasTrait(ETW_Registry.traits.FAST_EATER) then
		local reduction = PZMath.clamp(SBvars.FastEaterSpeed or 25, 0, 90) / 100
		return math.max(1, duration * (1 - reduction))
	end

	return duration
end
