require "ETWModData";

ETWCommonLogicChecks = {};

---@type EvolvingTraitsWorldSandboxVars
local SBvars = SandboxVars.EvolvingTraitsWorld;
local activatedMods = getActivatedMods();

local strength;
local fitness;
local sprinting;
local lightfooted ;
local nimble;
local sneaking;
local axe;
local longBlunt;
local shortBlunt;
local longBlade;
local shortBlade;
local spear;
local maintenance;
local carpentry;
local cooking;
local farming;
local firstAid;
local electrical;
local metalworking;
local mechanics;
local tailoring;
local aiming;
local reloading;
local fishing;
local trapping;
local foraging;

local function populateSkills()
	local player = getPlayer();
	strength = player:getPerkLevel(Perks.Strength);
	fitness = player:getPerkLevel(Perks.Fitness);
	sprinting = player:getPerkLevel(Perks.Sprinting);
	lightfooted = player:getPerkLevel(Perks.Lightfoot);
	nimble = player:getPerkLevel(Perks.Nimble);
	sneaking = player:getPerkLevel(Perks.Sneak);
	axe = player:getPerkLevel(Perks.Axe);
	longBlunt = player:getPerkLevel(Perks.Blunt);
	shortBlunt = player:getPerkLevel(Perks.SmallBlunt);
	longBlade = player:getPerkLevel(Perks.LongBlade);
	shortBlade = player:getPerkLevel(Perks.SmallBlade);
	spear = player:getPerkLevel(Perks.Spear);
	maintenance = player:getPerkLevel(Perks.Maintenance);
	carpentry = player:getPerkLevel(Perks.Woodwork);
	cooking = player:getPerkLevel(Perks.Cooking);
	farming = player:getPerkLevel(Perks.Farming);
	firstAid = player:getPerkLevel(Perks.Doctor);
	electrical = player:getPerkLevel(Perks.Electricity);
	metalworking = player:getPerkLevel(Perks.MetalWelding);
	mechanics = player:getPerkLevel(Perks.Mechanics);
	tailoring = player:getPerkLevel(Perks.Tailoring);
	aiming = player:getPerkLevel(Perks.Aiming);
	reloading = player:getPerkLevel(Perks.Reloading);
	fishing = player:getPerkLevel(Perks.Fishing);
	trapping = player:getPerkLevel(Perks.Trapping);
	foraging = player:getPerkLevel(Perks.PlantScavenging);
end

Events.OnCreatePlayer.Remove(populateSkills);
Events.OnCreatePlayer.Add(populateSkills);
Events.LevelPerk.Remove(populateSkills);
Events.LevelPerk.Add(populateSkills);

function ETWCommonLogicChecks.ColdIllnessSystemShouldExecute()
	local player = getPlayer();
	if SBvars.ColdIllnessSystem == true and not player:HasTrait("Resilient") and (SBvars.TraitsLockSystemCanGainPositive or SBvars.TraitsLockSystemCanLoseNegative) then
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
	if not getActivatedMods():contains("EvolvingTraitsWorldDisableBloodlust") and SBvars.Bloodlust == true and (SBvars.TraitsLockSystemCanGainPositive or SBvars.TraitsLockSystemCanLosePositive) then
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
	if not activatedMods:contains("EvolvingTraitsWorldDisableHoarder") and SBvars.Hoarder == true and not player:HasTrait("Hoarder") and SBvars.TraitsLockSystemCanGainPositive then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.GymRatShouldExecute()
	local player = getPlayer();
	if not activatedMods:contains("EvolvingTraitsWorldDisableGymRat") and SBvars.GymRat == true and not player:HasTrait("GymRat") and SBvars.TraitsLockSystemCanGainPositive then
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
	if not activatedMods:contains("EvolvingTraitsWorldDisableLightStep") and SBvars.LightStep == true and not player:HasTrait("LightStep") and SBvars.TraitsLockSystemCanGainPositive then
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
	if not activatedMods:contains("EvolvingTraitsWorldDisableLowProfile") and SBvars.LowProfile == true and not player:HasTrait("LowProfile") and SBvars.TraitsLockSystemCanGainPositive then
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
	if not activatedMods:contains("EvolvingTraitsWorldDisableAxeThrower") and SBvars.AxeThrower == true and not player:HasTrait("AxeThrower") and SBvars.TraitsLockSystemCanGainPositive then
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
	if not activatedMods:contains("EvolvingTraitsWorldDisableStickFighter") and SBvars.StickFighter == true and not player:HasTrait("StickFighter") and SBvars.TraitsLockSystemCanGainPositive then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.KenshiShouldExecute()
	local player = getPlayer();
	if not activatedMods:contains("EvolvingTraitsWorldDisableKenshi") and SBvars.Kenshi == true and not player:HasTrait("Kenshi") and SBvars.TraitsLockSystemCanGainPositive then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.KnifeFighterShouldExecute()
	local player = getPlayer();
	if not activatedMods:contains("EvolvingTraitsWorldDisableKnifeFighter") and SBvars.KnifeFighter == true and not player:HasTrait("KnifeFighter") and SBvars.TraitsLockSystemCanGainPositive then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.SojutsuShouldExecute()
	local player = getPlayer();
	if not activatedMods:contains("EvolvingTraitsWorldDisableSojutsu") and SBvars.Sojutsu == true and not player:HasTrait("Sojutsu") and SBvars.TraitsLockSystemCanGainPositive then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.RestorationExpertShouldExecute()
	local player = getPlayer();
	if not activatedMods:contains("EvolvingTraitsWorldDisableRestorationExpert") and SBvars.RestorationExpert == true and not player:HasTrait("RestorationExpert") and SBvars.TraitsLockSystemCanGainPositive then
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
	if not activatedMods:contains("EvolvingTraitsWorldDisableFurnitureAssembler") and SBvars.FurnitureAssembler == true and not player:HasTrait("FurnitureAssembler") and SBvars.TraitsLockSystemCanGainPositive then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.HomeCookShouldExecute()
	local player = getPlayer();
	if not activatedMods:contains("EvolvingTraitsWorldDisableHomeCook") and SBvars.HomeCook == true and not player:HasTrait("HomeCook") and SBvars.TraitsLockSystemCanGainPositive then
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
	if not activatedMods:contains("EvolvingTraitsWorldDisableAVClub") and SBvars.AVClub == true and not player:HasTrait("AVClub") and SBvars.TraitsLockSystemCanGainPositive then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.BodyWorkEnthusiastShouldExecute()
	local player = getPlayer();
	if not activatedMods:contains("EvolvingTraitsWorldDisableBodyWorkEnthusiast") and SBvars.BodyworkEnthusiast == true and not player:HasTrait("BodyWorkEnthusiast") and SBvars.TraitsLockSystemCanGainPositive then
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

function ETWCommonLogicChecks.TailorShouldExecute()
	local player = getPlayer();
	if SBvars.Sewer == true and not player:HasTrait("Tailor") and SBvars.TraitsLockSystemCanGainPositive then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.GunEnthusiastShouldExecute()
	local player = getPlayer();
	if not activatedMods:contains("EvolvingTraitsWorldDisableGunEnthusiast") and SBvars.GunEnthusiast == true and not player:HasTrait("GunEnthusiast") and SBvars.TraitsLockSystemCanGainPositive then
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
	if not activatedMods:contains("EvolvingTraitsWorldDisableRainTraits") and SBvars.RainSystem == true and (SBvars.TraitsLockSystemCanGainNegative or SBvars.TraitsLockSystemCanLoseNegative or SBvars.TraitsLockSystemCanGainPositive or SBvars.TraitsLockSystemCanLosePositive) then
		return true
	else
		return false
	end
end

function ETWCommonLogicChecks.FogSystemShouldExecute()
	if not activatedMods:contains("EvolvingTraitsWorldDisableFogTraits") and SBvars.FogSystem == true and (SBvars.TraitsLockSystemCanGainNegative or SBvars.TraitsLockSystemCanLoseNegative or SBvars.TraitsLockSystemCanGainPositive or SBvars.TraitsLockSystemCanLosePositive) then
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