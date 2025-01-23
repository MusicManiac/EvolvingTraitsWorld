local ETWCommonLogicChecks = {};

---@type EvolvingTraitsWorldSandboxVars
local SBvars = SandboxVars.EvolvingTraitsWorld;
local activatedMods = getActivatedMods();

function ETWCommonLogicChecks.ImmunitySystemShouldExecute()
	local player = getPlayer();
	if SBvars.ImmunitySystem == true and not player:HasTrait("Resilient") and (SBvars.TraitsLockSystemCanGainPositive or SBvars.TraitsLockSystemCanLoseNegative) then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.FoodSicknessSystemShouldExecute()
	local player = getPlayer();
	if SBvars.FoodSicknessSystem == true and not player:HasTrait("IronGut") and (SBvars.TraitsLockSystemCanGainPositive or SBvars.TraitsLockSystemCanLoseNegative) then
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
	local player = getPlayer();
	if SBvars.PainTolerance == true and not player:HasTrait("PainTolerance") and SBvars.TraitsLockSystemCanGainPositive then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.BloodlustShouldExecute()
	if not getActivatedMods():contains("\\2934686936/EvolvingTraitsWorldDisableBloodlust") and SBvars.Bloodlust == true and (SBvars.TraitsLockSystemCanGainPositive or SBvars.TraitsLockSystemCanLosePositive) then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.EagleEyedShouldExecute()
	local player = getPlayer();
	if SBvars.EagleEyed == true and not player:HasTrait("EagleEyed") and SBvars.TraitsLockSystemCanGainPositive then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.BraverySystemShouldExecute()
	local player = getPlayer();
	if SBvars.BraverySystem == true and not player:HasTrait("Desensitized") and (SBvars.TraitsLockSystemCanGainPositive or SBvars.TraitsLockSystemCanLoseNegative) then
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

function ETWCommonLogicChecks.LuckSystemShouldExecute()
	local player = getPlayer();
	if SBvars.LuckSystem == true and not player:HasTrait("Lucky") and (SBvars.TraitsLockSystemCanGainPositive or SBvars.TraitsLockSystemCanLoseNegative) then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.HoarderShouldExecute()
	local player = getPlayer();
	if not activatedMods:contains("\\2934686936/EvolvingTraitsWorldDisableHoarder") and SBvars.Hoarder == true and not player:HasTrait("Hoarder") and SBvars.TraitsLockSystemCanGainPositive then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.GymRatShouldExecute()
	local player = getPlayer();
	if not activatedMods:contains("\\2934686936/EvolvingTraitsWorldDisableGymRat") and SBvars.GymRat == true and not player:HasTrait("GymRat") and SBvars.TraitsLockSystemCanGainPositive then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.RunnerShouldExecute()
	local player = getPlayer();
	if SBvars.Runner == true and not player:HasTrait("Jogger") and SBvars.TraitsLockSystemCanGainPositive then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.HearingSystemShouldExecute()
	local player = getPlayer();
	if SBvars.HearingSystem == true and not player:HasTrait("KeenHearing") and (SBvars.TraitsLockSystemCanGainPositive or SBvars.TraitsLockSystemCanLoseNegative) then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.LightStepShouldExecute()
	local player = getPlayer();
	if not activatedMods:contains("\\2934686936/EvolvingTraitsWorldDisableLightStep") and SBvars.LightStep == true and not player:HasTrait("LightStep") and SBvars.TraitsLockSystemCanGainPositive then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.GymnastShouldExecute()
	local player = getPlayer();
	if SBvars.Gymnast == true and not player:HasTrait("Gymnast") and SBvars.TraitsLockSystemCanGainPositive then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.ClumsyShouldExecute()
	local player = getPlayer();
	if SBvars.Clumsy == true and player:HasTrait("Clumsy") and SBvars.TraitsLockSystemCanLoseNegative then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.GracefulShouldExecute()
	local player = getPlayer();
	if SBvars.Graceful == true and not player:HasTrait("Graceful") and SBvars.TraitsLockSystemCanGainPositive then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.BurglarShouldExecute()
	local player = getPlayer();
	if SBvars.Burglar == true and not player:HasTrait("Burglar") and SBvars.TraitsLockSystemCanGainPositive then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.LowProfileShouldExecute()
	local player = getPlayer();
	if not activatedMods:contains("\\2934686936/EvolvingTraitsWorldDisableLowProfile") and SBvars.LowProfile == true and not player:HasTrait("LowProfile") and SBvars.TraitsLockSystemCanGainPositive then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.ConspicuousShouldExecute()
	local player = getPlayer();
	if SBvars.Conspicuous == true and player:HasTrait("Conspicuous") and SBvars.TraitsLockSystemCanLoseNegative then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.InconspicuousShouldExecute()
	local player = getPlayer();
	if SBvars.Inconspicuous == true and not player:HasTrait("Conspicuous") and not player:HasTrait("Inconspicuous") and SBvars.TraitsLockSystemCanGainPositive then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.HunterShouldExecute()
	local player = getPlayer();
	if SBvars.Hunter == true and not player:HasTrait("Hunter") and SBvars.TraitsLockSystemCanGainPositive then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.BrawlerShouldExecute()
	local player = getPlayer();
	if SBvars.Brawler == true and not player:HasTrait("Brawler") and SBvars.TraitsLockSystemCanGainPositive then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.AxeThrowerShouldExecute()
	local player = getPlayer();
	if not activatedMods:contains("\\2934686936/EvolvingTraitsWorldDisableAxeThrower") and SBvars.AxeThrower == true and not player:HasTrait("AxeThrower") and SBvars.TraitsLockSystemCanGainPositive then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.BaseballPlayerShouldExecute()
	local player = getPlayer();
	if SBvars.BaseballPlayer == true and not player:HasTrait("BaseballPlayer") and SBvars.TraitsLockSystemCanGainPositive then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.StickFighterShouldExecute()
	local player = getPlayer();
	if not activatedMods:contains("\\2934686936/EvolvingTraitsWorldDisableStickFighter") and SBvars.StickFighter == true and not player:HasTrait("StickFighter") and SBvars.TraitsLockSystemCanGainPositive then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.BladeEnthusiastShouldExecute()
	local player = getPlayer();
	if not activatedMods:contains("\\2934686936/EvolvingTraitsWorldDisableBladeEnthusiast") and SBvars.BladeEnthusiast == true and not player:HasTrait("BladeEnthusiast") and SBvars.TraitsLockSystemCanGainPositive then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.BlacksmithShouldExecute()
	local player = getPlayer();
	if SBvars.Blacksmith == true and not player:HasTrait("Blacksmith") and SBvars.TraitsLockSystemCanGainPositive then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.KnifeFighterShouldExecute()
	local player = getPlayer();
	if not activatedMods:contains("\\2934686936/EvolvingTraitsWorldDisableKnifeFighter") and SBvars.KnifeFighter == true and not player:HasTrait("KnifeFighter") and SBvars.TraitsLockSystemCanGainPositive then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.PolearmFighterShouldExecute()
	local player = getPlayer();
	if not activatedMods:contains("\\2934686936/EvolvingTraitsWorldDisablePolearmFighter") and SBvars.PolearmFighter == true and not player:HasTrait("PolearmFighter") and SBvars.TraitsLockSystemCanGainPositive then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.RestorationExpertShouldExecute()
	local player = getPlayer();
	if not activatedMods:contains("\\2934686936/EvolvingTraitsWorldDisableRestorationExpert") and SBvars.RestorationExpert == true and not player:HasTrait("RestorationExpert") and SBvars.TraitsLockSystemCanGainPositive then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.HandyShouldExecute()
	local player = getPlayer();
	if SBvars.Handy == true and not player:HasTrait("Handy") and  SBvars.TraitsLockSystemCanGainPositive then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.LearnerSystemShouldExecute()
	local player = getPlayer();
	if SBvars.LearnerSystem == true and not player:HasTrait("FastLearner") and (SBvars.TraitsLockSystemCanLoseNegative or SBvars.TraitsLockSystemCanGainPositive) then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.FurnitureAssemblerShouldExecute()
	local player = getPlayer();
	if not activatedMods:contains("\\2934686936/EvolvingTraitsWorldDisableFurnitureAssembler") and SBvars.FurnitureAssembler == true and not player:HasTrait("FurnitureAssembler") and SBvars.TraitsLockSystemCanGainPositive then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.HomeCookShouldExecute()
	local player = getPlayer();
	if not activatedMods:contains("\\2934686936/EvolvingTraitsWorldDisableHomeCook") and SBvars.HomeCook == true and not player:HasTrait("HomeCook") and SBvars.TraitsLockSystemCanGainPositive then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.CookShouldExecute()
	local player = getPlayer();
	if SBvars.Cook == true and not player:HasTrait("Cook") and SBvars.TraitsLockSystemCanGainPositive then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.GardenerShouldExecute()
	local player = getPlayer();
	if SBvars.Gardener == true and not player:HasTrait("Gardener") and SBvars.TraitsLockSystemCanGainPositive then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.FirstAidShouldExecute()
	local player = getPlayer();
	if SBvars.FirstAid == true and not player:HasTrait("FirstAid") and SBvars.TraitsLockSystemCanGainPositive then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.AVClubShouldExecute()
	local player = getPlayer();
	if not activatedMods:contains("\\2934686936/EvolvingTraitsWorldDisableAVClub") and SBvars.AVClub == true and not player:HasTrait("AVClub") and SBvars.TraitsLockSystemCanGainPositive then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.BodyWorkEnthusiastShouldExecute()
	local player = getPlayer();
	if not activatedMods:contains("\\2934686936/EvolvingTraitsWorldDisableBodyWorkEnthusiast") and SBvars.BodyworkEnthusiast == true and not player:HasTrait("BodyWorkEnthusiast") and SBvars.TraitsLockSystemCanGainPositive then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.MechanicsShouldExecute()
	local player = getPlayer();
	if SBvars.Mechanics == true and not player:HasTrait("Mechanics") and SBvars.TraitsLockSystemCanGainPositive then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.SewerShouldExecute()
	local player = getPlayer();
	if SBvars.Sewer == true and not player:HasTrait("Tailor") and SBvars.TraitsLockSystemCanGainPositive then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.GunEnthusiastShouldExecute()
	local player = getPlayer();
	if not activatedMods:contains("\\2934686936/EvolvingTraitsWorldDisableGunEnthusiast") and SBvars.GunEnthusiast == true and not player:HasTrait("GunEnthusiast") and SBvars.TraitsLockSystemCanGainPositive then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.AnglerShouldExecute()
	local player = getPlayer();
	if SBvars.Fishing == true and not player:HasTrait("Fishing") and SBvars.TraitsLockSystemCanGainPositive then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.HikerShouldExecute()
	local player = getPlayer();
	if SBvars.Hiker == true and not player:HasTrait("Hiker") and SBvars.TraitsLockSystemCanGainPositive then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.CatEyesShouldExecute()
	local player = getPlayer();
	if SBvars.CatEyes == true and not player:HasTrait("NightVision") and SBvars.TraitsLockSystemCanGainPositive then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.SleepSystemShouldExecute()
	if SBvars.SleepSystem == true and (SBvars.TraitsLockSystemCanGainNegative or SBvars.TraitsLockSystemCanLoseNegative or SBvars.TraitsLockSystemCanGainPositive or SBvars.TraitsLockSystemCanLosePositive) then
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
	if not activatedMods:contains("\\2934686936/EvolvingTraitsWorldDisableRainTraits") and SBvars.RainSystem == true and (SBvars.TraitsLockSystemCanGainNegative or SBvars.TraitsLockSystemCanLoseNegative or SBvars.TraitsLockSystemCanGainPositive or SBvars.TraitsLockSystemCanLosePositive) then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.FogSystemShouldExecute()
	if not activatedMods:contains("\\2934686936/EvolvingTraitsWorldDisableFogTraits") and SBvars.FogSystem == true and (SBvars.TraitsLockSystemCanGainNegative or SBvars.TraitsLockSystemCanLoseNegative or SBvars.TraitsLockSystemCanGainPositive or SBvars.TraitsLockSystemCanLosePositive) then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.PetTherapyShouldExecute()
	if not activatedMods:contains("\\2934686936/EvolvingTraitsWorldDisablePetTherapy") and SBvars.PetTherapy == true and (SBvars.TraitsLockSystemCanGainPositive or SBvars.TraitsLockSystemCanLosePositive) then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.WildernessKnowledgeShouldExecute()
	local player = getPlayer();
	if SBvars.Blacksmith == true and not player:HasTrait("WildernessKnowledge") and SBvars.TraitsLockSystemCanGainPositive then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.WhittlerShouldExecute()
	local player = getPlayer();
	if SBvars.Whittler == true and not player:HasTrait("Whittler") and SBvars.TraitsLockSystemCanGainPositive then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.AxemanShouldExecute()
	local player = getPlayer();
	if SBvars.Axeman and not player:HasTrait("Axeman") and SBvars.TraitsLockSystemCanGainPositive then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.InventoryTransferSystemShouldExecute()
	local player = getPlayer();
	if SBvars.InventoryTransferSystem == true and (not player:HasTrait("Dextrous") or not player:HasTrait("Organized") or player:HasTrait("butterfingers")) and (SBvars.TraitsLockSystemCanGainNegative or SBvars.TraitsLockSystemCanLoseNegative or SBvars.TraitsLockSystemCanGainPositive or SBvars.TraitsLockSystemCanLosePositive) then
		return true
	else
		return false
	end
end

return ETWCommonLogicChecks;
