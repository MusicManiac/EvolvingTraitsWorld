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
	registerTraits({
		ETW_Registry.traits.AV_CLUB,
		ETW_Registry.traits.AXE_THROWER,
		ETW_Registry.traits.BLADE_ENTHUSIAST,
		ETW_Registry.traits.BLOODLUST,
		ETW_Registry.traits.BODYWORK_ENTHUSIAST,
		ETW_Registry.traits.FAST_EATER,
		ETW_Registry.traits.FURNITURE_ASSEMBLER,
		ETW_Registry.traits.GUN_ENTHUSIAST,
		ETW_Registry.traits.GYM_RAT,
		ETW_Registry.traits.HOARDER,
		ETW_Registry.traits.HOME_COOK,
		ETW_Registry.traits.HOMICHLOPHILE,
		ETW_Registry.traits.HOMICHLOPHOBIA,
		ETW_Registry.traits.KNIFE_FIGHTER,
		ETW_Registry.traits.LIGHTSTEP,
		ETW_Registry.traits.LOW_PROFILE,
		ETW_Registry.traits.PAIN_TOLERANCE,
		ETW_Registry.traits.PET_THERAPY,
		ETW_Registry.traits.PLUVIOPHILE,
		ETW_Registry.traits.PLUVIOPHOBIA,
		ETW_Registry.traits.POLEARM_FIGHTER,
		ETW_Registry.traits.RESTORATION_EXPERT,
		ETW_Registry.traits.SLOW_EATER,
		ETW_Registry.traits.STICK_FIGHTER,
	})

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

	-- server/TimedActions/ETW_ISChopTreeActionOverrideServer.lua
	registerTraits({
		CharacterTrait.AXEMAN,
	})

	-- server/Foraging/ETW_forageSystemOverrideServer.lua
	registerTraits({
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
