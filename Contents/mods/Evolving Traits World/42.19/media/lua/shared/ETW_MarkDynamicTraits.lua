if not getActivatedMods():contains("MarkDynamicTraitsFramework") then
	return
end

local MarkDynamicTraitsFramework = require "MDTF_Main"
local ETW_Registry = require "ETW_Registry"

---@param traits CharacterTrait[]
local function registerTraits(traits)
	for i = 1, #traits do
		MarkDynamicTraitsFramework.registerTrait(traits[i])
	end
end

local function registerDynamicTraits()
	-- Custom ETW Traits
	for _, trait in pairs(ETW_Registry.traits) do
		MarkDynamicTraitsFramework.registerTrait(trait)
	end

	-- ETW_ByTimeClient.lua
	registerTraits({
		CharacterTrait.NIGHT_VISION,
	})

	-- server/ETW_ByHealth.lua
	registerTraits({
		CharacterTrait.PRONE_TO_ILLNESS,
		CharacterTrait.RESILIENT,
		CharacterTrait.WEAK_STOMACH,
		CharacterTrait.IRON_GUT,
		CharacterTrait.HEARTY_APPETITE,
		CharacterTrait.LIGHT_EATER,
		CharacterTrait.HIGH_THIRST,
		CharacterTrait.LOW_THIRST,
		CharacterTrait.SLOW_HEALER,
		CharacterTrait.THIN_SKINNED,
		CharacterTrait.THICK_SKINNED,
		CharacterTrait.FAST_HEALER,
		CharacterTrait.ASTHMATIC,
	})

	-- server/ETW_ByKills.lua
	registerTraits({
		CharacterTrait.EAGLE_EYED,
		CharacterTrait.COWARDLY,
		CharacterTrait.HEMOPHOBIC,
		CharacterTrait.PACIFIST,
		CharacterTrait.ADRENALINE_JUNKIE,
		CharacterTrait.BRAVE,
		CharacterTrait.DESENSITIZED,
	})

	-- server/ETW_ByLocation.lua
	registerTraits({
		CharacterTrait.OUTDOORSMAN,
		CharacterTrait.AGORAPHOBIC,
		CharacterTrait.CLAUSTROPHOBIC,
	})

	-- server/ETW_BySkillsServer.lua
	registerTraits({
		CharacterTrait.HARD_OF_HEARING,
		CharacterTrait.KEEN_HEARING,
		CharacterTrait.JOGGER,
		CharacterTrait.GYMNAST,
		CharacterTrait.CLUMSY,
		CharacterTrait.GRACEFUL,
		CharacterTrait.BURGLAR,
		CharacterTrait.CONSPICUOUS,
		CharacterTrait.INCONSPICUOUS,
		CharacterTrait.HUNTER,
		CharacterTrait.BRAWLER,
		CharacterTrait.BASEBALL_PLAYER,
		CharacterTrait.HANDY,
		CharacterTrait.SLOW_LEARNER,
		CharacterTrait.FAST_LEARNER,
		CharacterTrait.COOK,
		CharacterTrait.GARDENER,
		CharacterTrait.WHITTLER,
		CharacterTrait.BLACKSMITH,
		CharacterTrait.WILDERNESS_KNOWLEDGE,
		CharacterTrait.FIRST_AID,
		CharacterTrait.FISHING,
		CharacterTrait.HIKER,
		CharacterTrait.ARTISAN,
		CharacterTrait.MASON,
		CharacterTrait.CRAFTY,
		CharacterTrait.TINKERER,
		CharacterTrait.TARGET_SHOOTER,
		CharacterTrait.BLACKSMITH2,
	})

	-- server/ETW_ByTime.lua
	registerTraits({
		CharacterTrait.NEEDS_LESS_SLEEP,
		CharacterTrait.NEEDS_MORE_SLEEP,
		CharacterTrait.SMOKER,
	})

	-- server/TimedActions/ETW_ActionsOverrideServer.lua
	registerTraits({
		CharacterTrait.AXEMAN,
		CharacterTrait.HERBALIST,
	})

	-- server/TimedActions/ETW_ISReadABookOverrideServer.lua
	registerTraits({
		CharacterTrait.SLOW_READER,
		CharacterTrait.FAST_READER,
	})

	-- shared/ETW_CombinedTraitChecks.lua
	registerTraits({
		CharacterTrait.MECHANICS,
		CharacterTrait.TAILOR,
	})

	-- shared/TimedActions/ETW_TimedActionsSharedLogic.lua
	registerTraits({
		CharacterTrait.DISORGANIZED,
		CharacterTrait.ORGANIZED,
		CharacterTrait.ALL_THUMBS,
		CharacterTrait.DEXTROUS,
	})
end

Events.OnMainMenuEnter.Remove(registerDynamicTraits)
Events.OnMainMenuEnter.Add(registerDynamicTraits)
