local ETWCommonLogicChecks = {}

---@type EvolvingTraitsWorldSandboxVars
local SBvars = SandboxVars.EvolvingTraitsWorld
local activatedMods = getActivatedMods()

local ETWRegistries = require("ETWRegistry")

---@type EvolvingTraitsWorldTraitsRegistries
local ETWTraitsRegistry = ETWRegistries.traits

function ETWCommonLogicChecks.ImmunitySystemShouldExecute()
	local player = getPlayer()
	if
		SBvars.ImmunitySystem == true
		and not player:hasTrait(CharacterTrait.RESILIENT)
		and (SBvars.TraitsLockSystemCanGainPositive or SBvars.TraitsLockSystemCanLoseNegative)
	then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.FoodSicknessSystemShouldExecute()
	local player = getPlayer()
	if
		SBvars.FoodSicknessSystem == true
		and not player:hasTrait(CharacterTrait.IRON_GUT)
		and (SBvars.TraitsLockSystemCanGainPositive or SBvars.TraitsLockSystemCanLoseNegative)
	then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.AsthmaticShouldExecute()
	if SBvars.Asthmatic == true and (SBvars.TraitsLockSystemCanLoseNegative or SBvars.TraitsLockSystemCanGainNegative) then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.PainToleranceShouldExecute()
	local player = getPlayer()
	if
		SBvars.PainTolerance == true
		and not player:hasTrait(ETWTraitsRegistry.PAIN_TOLERANCE)
		and SBvars.TraitsLockSystemCanGainPositive
	then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.BloodlustShouldExecute()
	if
		not getActivatedMods():contains("\\2934686936/EvolvingTraitsWorldDisableBloodlust")
		and SBvars.Bloodlust == true
		and (SBvars.TraitsLockSystemCanGainPositive or SBvars.TraitsLockSystemCanLosePositive)
	then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.EagleEyedShouldExecute()
	local player = getPlayer()
	if SBvars.EagleEyed == true and not player:hasTrait(CharacterTrait.EAGLE_EYED) and SBvars.TraitsLockSystemCanGainPositive then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.BraverySystemShouldExecute()
	local player = getPlayer()
	if
		SBvars.BraverySystem == true
		and not player:hasTrait(CharacterTrait.DESENSITIZED)
		and (SBvars.TraitsLockSystemCanGainPositive or SBvars.TraitsLockSystemCanLoseNegative)
	then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.OutdoorsmanShouldExecute()
	if SBvars.Outdoorsman == true and (SBvars.TraitsLockSystemCanGainPositive or SBvars.TraitsLockSystemCanLosePositive) then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.FearOfLocationsSystemShouldExecute()
	if SBvars.FearOfLocationsSystem == true and (SBvars.TraitsLockSystemCanGainNegative or SBvars.TraitsLockSystemCanLoseNegative) then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.HoarderShouldExecute()
	local player = getPlayer()
	if
		not activatedMods:contains("\\2934686936/EvolvingTraitsWorldDisableHoarder")
		and SBvars.Hoarder == true
		and not player:hasTrait(ETWTraitsRegistry.HOARDER)
		and SBvars.TraitsLockSystemCanGainPositive
	then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.GymRatShouldExecute()
	local player = getPlayer()
	if
		not activatedMods:contains("\\2934686936/EvolvingTraitsWorldDisableGymRat")
		and SBvars.GymRat == true
		and not player:hasTrait(ETWTraitsRegistry.GYM_RAT)
		and SBvars.TraitsLockSystemCanGainPositive
	then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.RunnerShouldExecute()
	local player = getPlayer()
	if SBvars.Runner == true and not player:hasTrait(CharacterTrait.JOGGER) and SBvars.TraitsLockSystemCanGainPositive then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.HearingSystemShouldExecute()
	local player = getPlayer()
	if
		SBvars.HearingSystem == true
		and not player:hasTrait(CharacterTrait.KEEN_HEARING)
		and (SBvars.TraitsLockSystemCanGainPositive or SBvars.TraitsLockSystemCanLoseNegative)
	then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.LightStepShouldExecute()
	local player = getPlayer()
	if
		not activatedMods:contains("\\2934686936/EvolvingTraitsWorldDisableLightStep")
		and SBvars.LightStep == true
		and not player:hasTrait(ETWTraitsRegistry.LIGHTSTEP)
		and SBvars.TraitsLockSystemCanGainPositive
	then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.GymnastShouldExecute()
	local player = getPlayer()
	if SBvars.Gymnast == true and not player:hasTrait(CharacterTrait.GYMNAST) and SBvars.TraitsLockSystemCanGainPositive then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.ClumsyShouldExecute()
	local player = getPlayer()
	if SBvars.Clumsy == true and player:hasTrait(CharacterTrait.CLUMSY) and SBvars.TraitsLockSystemCanLoseNegative then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.GracefulShouldExecute()
	local player = getPlayer()
	if SBvars.Graceful == true and not player:hasTrait(CharacterTrait.GRACEFUL) and SBvars.TraitsLockSystemCanGainPositive then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.BurglarShouldExecute()
	local player = getPlayer()
	if SBvars.Burglar == true and not player:hasTrait(CharacterTrait.BURGLAR) and SBvars.TraitsLockSystemCanGainPositive then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.LowProfileShouldExecute()
	local player = getPlayer()
	if
		not activatedMods:contains("\\2934686936/EvolvingTraitsWorldDisableLowProfile")
		and SBvars.LowProfile == true
		and not player:hasTrait(ETWTraitsRegistry.LOW_PROFILE)
		and SBvars.TraitsLockSystemCanGainPositive
	then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.ConspicuousShouldExecute()
	local player = getPlayer()
	if SBvars.Conspicuous == true and player:hasTrait(CharacterTrait.CONSPICUOUS) and SBvars.TraitsLockSystemCanLoseNegative then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.InconspicuousShouldExecute()
	local player = getPlayer()
	if SBvars.Inconspicuous == true and not player:hasTrait(CharacterTrait.INCONSPICUOUS) and SBvars.TraitsLockSystemCanGainPositive then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.HunterShouldExecute()
	local player = getPlayer()
	if SBvars.Hunter == true and not player:hasTrait(CharacterTrait.HUNTER) and SBvars.TraitsLockSystemCanGainPositive then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.BrawlerShouldExecute()
	local player = getPlayer()
	if SBvars.Brawler == true and not player:hasTrait(CharacterTrait.BRAWLER) and SBvars.TraitsLockSystemCanGainPositive then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.AxeThrowerShouldExecute()
	local player = getPlayer()
	if
		not activatedMods:contains("\\2934686936/EvolvingTraitsWorldDisableAxeThrower")
		and SBvars.AxeThrower == true
		and not player:hasTrait(ETWTraitsRegistry.AXE_THROWER)
		and SBvars.TraitsLockSystemCanGainPositive
	then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.BaseballPlayerShouldExecute()
	local player = getPlayer()
	if SBvars.BaseballPlayer == true and not player:hasTrait(CharacterTrait.BASEBALL_PLAYER) and SBvars.TraitsLockSystemCanGainPositive then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.StickFighterShouldExecute()
	local player = getPlayer()
	if
		not activatedMods:contains("\\2934686936/EvolvingTraitsWorldDisableStickFighter")
		and SBvars.StickFighter == true
		and not player:hasTrait(ETWTraitsRegistry.STICK_FIGHTER)
		and SBvars.TraitsLockSystemCanGainPositive
	then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.BladeEnthusiastShouldExecute()
	local player = getPlayer()
	if
		not activatedMods:contains("\\2934686936/EvolvingTraitsWorldDisableBladeEnthusiast")
		and SBvars.BladeEnthusiast == true
		and not player:hasTrait(ETWTraitsRegistry.BLADE_ENTHUSIAST)
		and SBvars.TraitsLockSystemCanGainPositive
	then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.BlacksmithShouldExecute()
	local player = getPlayer()
	if SBvars.Blacksmith == true and not player:hasTrait(CharacterTrait.BLACKSMITH) and SBvars.TraitsLockSystemCanGainPositive then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.KnifeFighterShouldExecute()
	local player = getPlayer()
	if
		not activatedMods:contains("\\2934686936/EvolvingTraitsWorldDisableKnifeFighter")
		and SBvars.KnifeFighter == true
		and not player:hasTrait(ETWTraitsRegistry.KNIFE_FIGHTER)
		and SBvars.TraitsLockSystemCanGainPositive
	then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.PolearmFighterShouldExecute()
	local player = getPlayer()
	if
		not activatedMods:contains("\\2934686936/EvolvingTraitsWorldDisablePolearmFighter")
		and SBvars.PolearmFighter == true
		and not player:hasTrait(ETWTraitsRegistry.POLEARM_FIGHTER)
		and SBvars.TraitsLockSystemCanGainPositive
	then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.RestorationExpertShouldExecute()
	local player = getPlayer()
	if
		not activatedMods:contains("\\2934686936/EvolvingTraitsWorldDisableRestorationExpert")
		and SBvars.RestorationExpert == true
		and not player:hasTrait(ETWTraitsRegistry.RESTORATION_EXPERT)
		and SBvars.TraitsLockSystemCanGainPositive
	then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.HandyShouldExecute()
	local player = getPlayer()
	if SBvars.Handy == true and not player:hasTrait(CharacterTrait.HANDY) and SBvars.TraitsLockSystemCanGainPositive then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.LearnerSystemShouldExecute()
	local player = getPlayer()
	if
		SBvars.LearnerSystem == true
		and not player:hasTrait(CharacterTrait.FAST_LEARNER)
		and (SBvars.TraitsLockSystemCanLoseNegative or SBvars.TraitsLockSystemCanGainPositive)
	then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.FurnitureAssemblerShouldExecute()
	local player = getPlayer()
	if
		not activatedMods:contains("\\2934686936/EvolvingTraitsWorldDisableFurnitureAssembler")
		and SBvars.FurnitureAssembler == true
		and not player:hasTrait(ETWTraitsRegistry.FURNITURE_ASSEMBLER)
		and SBvars.TraitsLockSystemCanGainPositive
	then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.HomeCookShouldExecute()
	local player = getPlayer()
	if
		not activatedMods:contains("\\2934686936/EvolvingTraitsWorldDisableHomeCook")
		and SBvars.HomeCook == true
		and not player:hasTrait(ETWTraitsRegistry.HOME_COOK)
		and SBvars.TraitsLockSystemCanGainPositive
	then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.CookShouldExecute()
	local player = getPlayer()
	if SBvars.Cook == true and not player:hasTrait(CharacterTrait.COOK) and SBvars.TraitsLockSystemCanGainPositive then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.GardenerShouldExecute()
	local player = getPlayer()
	if SBvars.Gardener == true and not player:hasTrait(CharacterTrait.GARDENER) and SBvars.TraitsLockSystemCanGainPositive then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.FirstAidShouldExecute()
	local player = getPlayer()
	if SBvars.FirstAid == true and not player:hasTrait(CharacterTrait.FIRST_AID) and SBvars.TraitsLockSystemCanGainPositive then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.AVClubShouldExecute()
	local player = getPlayer()
	if
		not activatedMods:contains("\\2934686936/EvolvingTraitsWorldDisableAVClub")
		and SBvars.AVClub == true
		and not player:hasTrait(ETWTraitsRegistry.AV_CLUB)
		and SBvars.TraitsLockSystemCanGainPositive
	then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.BodyWorkEnthusiastShouldExecute()
	local player = getPlayer()
	if
		not activatedMods:contains("\\2934686936/EvolvingTraitsWorldDisableBodyWorkEnthusiast")
		and SBvars.BodyworkEnthusiast == true
		and not player:hasTrait(ETWTraitsRegistry.BODYWORK_ENTHUSIAST)
		and SBvars.TraitsLockSystemCanGainPositive
	then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.MechanicsShouldExecute()
	local player = getPlayer()
	if SBvars.Mechanics == true and not player:hasTrait(CharacterTrait.MECHANICS) and SBvars.TraitsLockSystemCanGainPositive then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.SewerShouldExecute()
	local player = getPlayer()
	if SBvars.Sewer == true and not player:hasTrait(CharacterTrait.TAILOR) and SBvars.TraitsLockSystemCanGainPositive then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.GunEnthusiastShouldExecute()
	local player = getPlayer()
	if
		not activatedMods:contains("\\2934686936/EvolvingTraitsWorldDisableGunEnthusiast")
		and SBvars.GunEnthusiast == true
		and not player:hasTrait(ETWTraitsRegistry.GUN_ENTHUSIAST)
		and SBvars.TraitsLockSystemCanGainPositive
	then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.AnglerShouldExecute()
	local player = getPlayer()
	if SBvars.Fishing == true and not player:hasTrait(CharacterTrait.FISHING) and SBvars.TraitsLockSystemCanGainPositive then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.HikerShouldExecute()
	local player = getPlayer()
	if SBvars.Hiker == true and not player:hasTrait(CharacterTrait.HIKER) and SBvars.TraitsLockSystemCanGainPositive then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.CatEyesShouldExecute()
	local player = getPlayer()
	if SBvars.CatEyes == true and not player:hasTrait(CharacterTrait.NIGHT_VISION) and SBvars.TraitsLockSystemCanGainPositive then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.SleepSystemShouldExecute()
	if
		SBvars.SleepSystem == true
		and (
			SBvars.TraitsLockSystemCanGainNegative
			or SBvars.TraitsLockSystemCanLoseNegative
			or SBvars.TraitsLockSystemCanGainPositive
			or SBvars.TraitsLockSystemCanLosePositive
		)
	then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.SmokerShouldExecute()
	if SBvars.Smoker == true and (SBvars.TraitsLockSystemCanGainNegative or SBvars.TraitsLockSystemCanLoseNegative) then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.HerbalistShouldExecute()
	if SBvars.Herbalist == true and (SBvars.TraitsLockSystemCanGainPositive or SBvars.TraitsLockSystemCanLosePositive) then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.RainSystemShouldExecute()
	if
		not activatedMods:contains("\\2934686936/EvolvingTraitsWorldDisableRainTraits")
		and SBvars.RainSystem == true
		and (
			SBvars.TraitsLockSystemCanGainNegative
			or SBvars.TraitsLockSystemCanLoseNegative
			or SBvars.TraitsLockSystemCanGainPositive
			or SBvars.TraitsLockSystemCanLosePositive
		)
	then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.FogSystemShouldExecute()
	if
		not activatedMods:contains("\\2934686936/EvolvingTraitsWorldDisableFogTraits")
		and SBvars.FogSystem == true
		and (
			SBvars.TraitsLockSystemCanGainNegative
			or SBvars.TraitsLockSystemCanLoseNegative
			or SBvars.TraitsLockSystemCanGainPositive
			or SBvars.TraitsLockSystemCanLosePositive
		)
	then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.PetTherapyShouldExecute()
	local player = getPlayer()
	if
		not activatedMods:contains("\\2934686936/EvolvingTraitsWorldDisablePetTherapy")
		and not player:hasTrait(ETWTraitsRegistry.PET_THERAPY)
		and SBvars.PetTherapy == true
		and (SBvars.TraitsLockSystemCanGainPositive or SBvars.TraitsLockSystemCanLosePositive)
	then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.WildernessKnowledgeShouldExecute()
	local player = getPlayer()
	if
		SBvars.Blacksmith == true
		and not player:hasTrait(CharacterTrait.WILDERNESS_KNOWLEDGE)
		and SBvars.TraitsLockSystemCanGainPositive
	then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.WhittlerShouldExecute()
	local player = getPlayer()
	if SBvars.Whittler == true and not player:hasTrait(CharacterTrait.WHITTLER) and SBvars.TraitsLockSystemCanGainPositive then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.AxemanShouldExecute()
	local player = getPlayer()
	if SBvars.Axeman and not player:hasTrait(CharacterTrait.AXEMAN) and SBvars.TraitsLockSystemCanGainPositive then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.InventoryTransferSystemShouldExecute()
	local player = getPlayer()
	if
		SBvars.InventoryTransferSystem == true
		and (not player:hasTrait(CharacterTrait.DEXTROUS) or not player:hasTrait(CharacterTrait.ORGANIZED))
		and (
			SBvars.TraitsLockSystemCanGainNegative
			or SBvars.TraitsLockSystemCanLoseNegative
			or SBvars.TraitsLockSystemCanGainPositive
			or SBvars.TraitsLockSystemCanLosePositive
		)
	then
		return true
	else
		return false
	end
end

return ETWCommonLogicChecks
