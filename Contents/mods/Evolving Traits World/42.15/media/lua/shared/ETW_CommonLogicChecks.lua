local ETW_CommonLogicChecks = {}

---@type EvolvingTraitsWorldSandboxVars
local SBvars = SandboxVars.EvolvingTraitsWorld
local activatedMods = getActivatedMods()

local ETWRegistries = require("ETW_Registry")

---@type ETW_CommonFunctions
local ETW_CommonFunctions = require("ETW_CommonFunctions")

---@type EvolvingTraitsWorldTraitsRegistries
local ETWTraitsRegistry = ETWRegistries.traits

local gameMode = ETW_CommonFunctions.gameMode()

---Returns true if the Immunity System should execute
---@param player IsoPlayer|nil the player to check for
---@return boolean boolean true if the Immunity System should execute, false otherwise
function ETW_CommonLogicChecks.ImmunitySystemShouldExecute(player)
	if
		SBvars.ImmunitySystem == true
		and ((player and not player:hasTrait(CharacterTrait.RESILIENT)) or gameMode == ETW_CommonFunctions.GameMode.MP_SERVER)
		and (SBvars.TraitsLockSystemCanGainPositive or SBvars.TraitsLockSystemCanLoseNegative)
	then
		return true
	else
		return false
	end
end

---Returns true if the Food Sickness System should execute
---@param player IsoPlayer|nil the player to check for
---@return boolean boolean true if the Food Sickness System should execute, false otherwise
function ETW_CommonLogicChecks.FoodSicknessSystemShouldExecute(player)
	if
		SBvars.FoodSicknessSystem == true
		and ((player and not player:hasTrait(CharacterTrait.IRON_GUT)) or gameMode == ETW_CommonFunctions.GameMode.MP_SERVER)
		and (SBvars.TraitsLockSystemCanGainPositive or SBvars.TraitsLockSystemCanLoseNegative)
	then
		return true
	else
		return false
	end
end

---Returns true if the Asthmatic System should execute
---@param player IsoPlayer|nil the player to check for
---@return boolean boolean true if the Asthmatic System should execute, false otherwise
function ETW_CommonLogicChecks.AsthmaticShouldExecute(player)
	if SBvars.Asthmatic == true and (SBvars.TraitsLockSystemCanLoseNegative or SBvars.TraitsLockSystemCanGainNegative) then
		return true
	else
		return false
	end
end

---Returns true if the Pain Tolerance System should execute
---@param player IsoPlayer|nil the player to check for
---@return boolean boolean true if the Pain Tolerance System should execute, false otherwise
function ETW_CommonLogicChecks.PainToleranceShouldExecute(player)
	if
		SBvars.PainTolerance == true
		and ((player and not player:hasTrait(ETWTraitsRegistry.PAIN_TOLERANCE)) or gameMode == ETW_CommonFunctions.GameMode.MP_SERVER)
		and SBvars.TraitsLockSystemCanGainPositive
	then
		return true
	else
		return false
	end
end

---Returns true if the Bloodlust System should execute
---@param player IsoPlayer|nil the player to check for
---@return boolean boolean true if the Bloodlust System should execute, false otherwise
function ETW_CommonLogicChecks.BloodlustShouldExecute(player)
	if SBvars.Bloodlust == true and (SBvars.TraitsLockSystemCanGainPositive or SBvars.TraitsLockSystemCanLosePositive) then
		return true
	else
		return false
	end
end

---Returns true if the Eagle Eyed System should execute
---@param player IsoPlayer|nil the player to check for
---@return boolean boolean true if the Eagle Eyed System should execute, false otherwise
function ETW_CommonLogicChecks.EagleEyedShouldExecute(player)
	if
		SBvars.EagleEyed == true
		and ((player and not player:hasTrait(CharacterTrait.EAGLE_EYED)) or gameMode == ETW_CommonFunctions.GameMode.MP_SERVER)
		and SBvars.TraitsLockSystemCanGainPositive
	then
		return true
	else
		return false
	end
end

---Returns true if the Bravery System should execute
---@param player IsoPlayer|nil the player to check for
---@return boolean boolean true if the Bravery System should execute, false otherwise
function ETW_CommonLogicChecks.BraverySystemShouldExecute(player)
	if
		SBvars.BraverySystem == true
		and ((player and not player:hasTrait(CharacterTrait.DESENSITIZED)) or gameMode == ETW_CommonFunctions.GameMode.MP_SERVER)
		and (SBvars.TraitsLockSystemCanGainPositive or SBvars.TraitsLockSystemCanLoseNegative)
	then
		return true
	else
		return false
	end
end

---Returns true if the Outdoorsman System should execute
---@param player IsoPlayer|nil the player to check for
---@return boolean boolean true if the Outdoorsman System should execute, false otherwise
function ETW_CommonLogicChecks.OutdoorsmanShouldExecute(player)
	if SBvars.Outdoorsman == true and (SBvars.TraitsLockSystemCanGainPositive or SBvars.TraitsLockSystemCanLosePositive) then
		return true
	else
		return false
	end
end

---Returns true if the Fear Of Locations System should execute
---@param player IsoPlayer|nil the player to check for
---@return boolean boolean true if the Fear Of Locations System should execute, false otherwise
function ETW_CommonLogicChecks.FearOfLocationsSystemShouldExecute(player)
	if SBvars.FearOfLocationsSystem == true and (SBvars.TraitsLockSystemCanGainNegative or SBvars.TraitsLockSystemCanLoseNegative) then
		return true
	else
		return false
	end
end

---Returns true if the Hoarder System should execute
---@param player IsoPlayer|nil the player to check for
---@return boolean boolean true if the Hoarder System should execute, false otherwise
function ETW_CommonLogicChecks.HoarderShouldExecute(player)
	if
		not activatedMods:contains("\\2934686936/EvolvingTraitsWorldDisableHoarder")
		and SBvars.Hoarder == true
		and ((player and not player:hasTrait(ETWTraitsRegistry.HOARDER)) or gameMode == ETW_CommonFunctions.GameMode.MP_SERVER)
		and SBvars.TraitsLockSystemCanGainPositive
	then
		return true
	else
		return false
	end
end

---Returns true if the Gym Rat System should execute
---@param player IsoPlayer|nil the player to check for
---@return boolean boolean true if the Gym Rat System should execute, false otherwise
function ETW_CommonLogicChecks.GymRatShouldExecute(player)
	if
		not activatedMods:contains("\\2934686936/EvolvingTraitsWorldDisableGymRat")
		and SBvars.GymRat == true
		and ((player and not player:hasTrait(ETWTraitsRegistry.GYM_RAT)) or gameMode == ETW_CommonFunctions.GameMode.MP_SERVER)
		and SBvars.TraitsLockSystemCanGainPositive
	then
		return true
	else
		return false
	end
end

---Returns true if the Runner System should execute
---@param player IsoPlayer|nil the player to check for
---@return boolean boolean true if the Runner System should execute, false otherwise
function ETW_CommonLogicChecks.RunnerShouldExecute(player)
	if
		SBvars.Runner == true
		and ((player and not player:hasTrait(CharacterTrait.JOGGER)) or gameMode == ETW_CommonFunctions.GameMode.MP_SERVER)
		and SBvars.TraitsLockSystemCanGainPositive
	then
		return true
	else
		return false
	end
end

---Returns true if the Hearing System should execute
---@param player IsoPlayer|nil the player to check for
---@return boolean boolean true if the Hearing System should execute, false otherwise
function ETW_CommonLogicChecks.HearingSystemShouldExecute(player)
	if
		SBvars.HearingSystem == true
		and ((player and not player:hasTrait(CharacterTrait.KEEN_HEARING)) or gameMode == ETW_CommonFunctions.GameMode.MP_SERVER)
		and (SBvars.TraitsLockSystemCanGainPositive or SBvars.TraitsLockSystemCanLoseNegative)
	then
		return true
	else
		return false
	end
end

---Returns true if the Light Step System should execute
---@param player IsoPlayer|nil the player to check for
---@return boolean boolean true if the Light Step System should execute, false otherwise
function ETW_CommonLogicChecks.LightStepShouldExecute(player)
	if
		SBvars.LightStep == true
		and ((player and not player:hasTrait(ETWTraitsRegistry.LIGHTSTEP)) or gameMode == ETW_CommonFunctions.GameMode.MP_SERVER)
		and SBvars.TraitsLockSystemCanGainPositive
	then
		return true
	else
		return false
	end
end

---Returns true if the Gymnast System should execute
---@param player IsoPlayer|nil the player to check for
---@return boolean boolean true if the Gymnast System should execute, false otherwise
function ETW_CommonLogicChecks.GymnastShouldExecute(player)
	if
		SBvars.Gymnast == true
		and ((player and not player:hasTrait(CharacterTrait.GYMNAST)) or gameMode == ETW_CommonFunctions.GameMode.MP_SERVER)
		and SBvars.TraitsLockSystemCanGainPositive
	then
		return true
	else
		return false
	end
end

---Returns true if the Clumsy System should execute
---@param player IsoPlayer|nil the player to check for
---@return boolean boolean true if the Clumsy System should execute, false otherwise
function ETW_CommonLogicChecks.ClumsyShouldExecute(player)
	if
		SBvars.Clumsy == true
		and ((player and player:hasTrait(CharacterTrait.CLUMSY)) or gameMode == ETW_CommonFunctions.GameMode.MP_SERVER)
		and SBvars.TraitsLockSystemCanLoseNegative
	then
		return true
	else
		return false
	end
end

---Returns true if the Graceful System should execute
---@param player IsoPlayer|nil the player to check for
---@return boolean boolean true if the Graceful System should execute, false otherwise
function ETW_CommonLogicChecks.GracefulShouldExecute(player)
	if
		SBvars.Graceful == true
		and ((player and not player:hasTrait(CharacterTrait.GRACEFUL)) or gameMode == ETW_CommonFunctions.GameMode.MP_SERVER)
		and SBvars.TraitsLockSystemCanGainPositive
	then
		return true
	else
		return false
	end
end

---Returns true if the Burglar System should execute
---@param player IsoPlayer|nil the player to check for
---@return boolean boolean true if the Burglar System should execute, false otherwise
function ETW_CommonLogicChecks.BurglarShouldExecute(player)
	if
		SBvars.Burglar == true
		and ((player and not player:hasTrait(CharacterTrait.BURGLAR)) or gameMode == ETW_CommonFunctions.GameMode.MP_SERVER)
		and SBvars.TraitsLockSystemCanGainPositive
	then
		return true
	else
		return false
	end
end

---Returns true if the Low Profile System should execute
---@param player IsoPlayer|nil the player to check for
---@return boolean boolean true if the Low Profile System should execute, false otherwise
function ETW_CommonLogicChecks.LowProfileShouldExecute(player)
	if
		SBvars.LowProfile == true
		and ((player and not player:hasTrait(ETWTraitsRegistry.LOW_PROFILE)) or gameMode == ETW_CommonFunctions.GameMode.MP_SERVER)
		and SBvars.TraitsLockSystemCanGainPositive
	then
		return true
	else
		return false
	end
end

---Returns true if the Conspicuous System should execute
---@param player IsoPlayer|nil the player to check for
---@return boolean boolean true if the Conspicuous System should execute, false otherwise
function ETW_CommonLogicChecks.ConspicuousShouldExecute(player)
	if
		SBvars.Conspicuous == true
		and ((player and player:hasTrait(CharacterTrait.CONSPICUOUS)) or gameMode == ETW_CommonFunctions.GameMode.MP_SERVER)
		and SBvars.TraitsLockSystemCanLoseNegative
	then
		return true
	else
		return false
	end
end

---Returns true if the Inconspicuous System should execute
---@param player IsoPlayer|nil the player to check for
---@return boolean boolean true if the Inconspicuous System should execute, false otherwise
function ETW_CommonLogicChecks.InconspicuousShouldExecute(player)
	if
		SBvars.Inconspicuous == true
		and ((player and not player:hasTrait(CharacterTrait.INCONSPICUOUS)) or gameMode == ETW_CommonFunctions.GameMode.MP_SERVER)
		and SBvars.TraitsLockSystemCanGainPositive
	then
		return true
	else
		return false
	end
end

---Returns true if the Hunter System should execute
---@param player IsoPlayer|nil the player to check for
---@return boolean boolean true if the Hunter System should execute, false otherwise
function ETW_CommonLogicChecks.HunterShouldExecute(player)
	if
		SBvars.Hunter == true
		and ((player and not player:hasTrait(CharacterTrait.HUNTER)) or gameMode == ETW_CommonFunctions.GameMode.MP_SERVER)
		and SBvars.TraitsLockSystemCanGainPositive
	then
		return true
	else
		return false
	end
end

---Returns true if the Brawler System should execute
---@param player IsoPlayer|nil the player to check for
---@return boolean boolean true if the Brawler System should execute, false otherwise
function ETW_CommonLogicChecks.BrawlerShouldExecute(player)
	if
		SBvars.Brawler == true
		and ((player and not player:hasTrait(CharacterTrait.BRAWLER)) or gameMode == ETW_CommonFunctions.GameMode.MP_SERVER)
		and SBvars.TraitsLockSystemCanGainPositive
	then
		return true
	else
		return false
	end
end

---Returns true if the Axe Thrower System should execute
---@param player IsoPlayer|nil the player to check for
---@return boolean boolean true if the Axe Thrower System should execute, false otherwise
function ETW_CommonLogicChecks.AxeThrowerShouldExecute(player)
	if
		SBvars.AxeThrower == true
		and ((player and not player:hasTrait(ETWTraitsRegistry.AXE_THROWER)) or gameMode == ETW_CommonFunctions.GameMode.MP_SERVER)
		and SBvars.TraitsLockSystemCanGainPositive
	then
		return true
	else
		return false
	end
end

---Returns true if the Baseball Player System should execute
---@param player IsoPlayer|nil the player to check for
---@return boolean boolean true if the Baseball Player System should execute, false otherwise
function ETW_CommonLogicChecks.BaseballPlayerShouldExecute(player)
	if
		SBvars.BaseballPlayer == true
		and ((player and not player:hasTrait(CharacterTrait.BASEBALL_PLAYER)) or gameMode == ETW_CommonFunctions.GameMode.MP_SERVER)
		and SBvars.TraitsLockSystemCanGainPositive
	then
		return true
	else
		return false
	end
end

---Returns true if the Stick Fighter System should execute
---@param player IsoPlayer|nil the player to check for
---@return boolean boolean true if the Stick Fighter System should execute, false otherwise
function ETW_CommonLogicChecks.StickFighterShouldExecute(player)
	if
		SBvars.StickFighter == true
		and ((player and not player:hasTrait(ETWTraitsRegistry.STICK_FIGHTER)) or gameMode == ETW_CommonFunctions.GameMode.MP_SERVER)
		and SBvars.TraitsLockSystemCanGainPositive
	then
		return true
	else
		return false
	end
end

---Returns true if the Blade Enthusiast System should execute
---@param player IsoPlayer|nil the player to check for
---@return boolean boolean true if the Blade Enthusiast System should execute, false otherwise
function ETW_CommonLogicChecks.BladeEnthusiastShouldExecute(player)
	if
		SBvars.BladeEnthusiast == true
		and ((player and not player:hasTrait(ETWTraitsRegistry.BLADE_ENTHUSIAST)) or gameMode == ETW_CommonFunctions.GameMode.MP_SERVER)
		and SBvars.TraitsLockSystemCanGainPositive
	then
		return true
	else
		return false
	end
end

---Returns true if the Blacksmith System should execute
---@param player IsoPlayer|nil the player to check for
---@return boolean boolean true if the Blacksmith System should execute, false otherwise
function ETW_CommonLogicChecks.BlacksmithShouldExecute(player)
	if
		SBvars.Blacksmith == true
		and ((player and not player:hasTrait(CharacterTrait.BLACKSMITH)) or gameMode == ETW_CommonFunctions.GameMode.MP_SERVER)
		and SBvars.TraitsLockSystemCanGainPositive
	then
		return true
	else
		return false
	end
end

---Returns true if the Knife Fighter System should execute
---@param player IsoPlayer|nil the player to check for
---@return boolean boolean true if the Knife Fighter System should execute, false otherwise
function ETW_CommonLogicChecks.KnifeFighterShouldExecute(player)
	if
		SBvars.KnifeFighter == true
		and ((player and not player:hasTrait(ETWTraitsRegistry.KNIFE_FIGHTER)) or gameMode == ETW_CommonFunctions.GameMode.MP_SERVER)
		and SBvars.TraitsLockSystemCanGainPositive
	then
		return true
	else
		return false
	end
end

---Returns true if the Polearm Fighter System should execute
---@param player IsoPlayer|nil the player to check for
---@return boolean boolean true if the Polearm Fighter System should execute, false otherwise
function ETW_CommonLogicChecks.PolearmFighterShouldExecute(player)
	if
		SBvars.PolearmFighter == true
		and ((player and not player:hasTrait(ETWTraitsRegistry.POLEARM_FIGHTER)) or gameMode == ETW_CommonFunctions.GameMode.MP_SERVER)
		and SBvars.TraitsLockSystemCanGainPositive
	then
		return true
	else
		return false
	end
end

---Returns true if the Restoration Expert System should execute
---@param player IsoPlayer|nil the player to check for
---@return boolean boolean true if the Restoration Expert System should execute, false otherwise
function ETW_CommonLogicChecks.RestorationExpertShouldExecute(player)
	if
		SBvars.RestorationExpert == true
		and (player and not player:hasTrait(ETWTraitsRegistry.RESTORATION_EXPERT))
		and SBvars.TraitsLockSystemCanGainPositive
	then
		return true
	else
		return false
	end
end

---Returns true if the Handy System should execute
---@param player IsoPlayer|nil the player to check for
---@return boolean boolean true if the Handy System should execute, false otherwise
function ETW_CommonLogicChecks.HandyShouldExecute(player)
	if
		SBvars.Handy == true
		and ((player and not player:hasTrait(CharacterTrait.HANDY)) or gameMode == ETW_CommonFunctions.GameMode.MP_SERVER)
		and SBvars.TraitsLockSystemCanGainPositive
	then
		return true
	else
		return false
	end
end

---Returns true if the Learner System should execute
---@param player IsoPlayer|nil the player to check for
---@return boolean boolean true if the Learner System should execute, false otherwise
function ETW_CommonLogicChecks.LearnerSystemShouldExecute(player)
	if
		SBvars.LearnerSystem == true
		and ((player and not player:hasTrait(CharacterTrait.FAST_LEARNER)) or gameMode == ETW_CommonFunctions.GameMode.MP_SERVER)
		and (SBvars.TraitsLockSystemCanLoseNegative or SBvars.TraitsLockSystemCanGainPositive)
	then
		return true
	else
		return false
	end
end

---Returns true if the Furniture Assembler System should execute
---@param player IsoPlayer|nil the player to check for
---@return boolean boolean true if the Furniture Assembler System should execute, false otherwise
function ETW_CommonLogicChecks.FurnitureAssemblerShouldExecute(player)
	if
		SBvars.FurnitureAssembler == true
		and ((player and not player:hasTrait(ETWTraitsRegistry.FURNITURE_ASSEMBLER)) or gameMode == ETW_CommonFunctions.GameMode.MP_SERVER)
		and SBvars.TraitsLockSystemCanGainPositive
	then
		return true
	else
		return false
	end
end

---Returns true if the Home Cook System should execute
---@param player IsoPlayer|nil the player to check for
---@return boolean boolean true if the Home Cook System should execute, false otherwise
function ETW_CommonLogicChecks.HomeCookShouldExecute(player)
	if
		SBvars.HomeCook == true
		and ((player and not player:hasTrait(ETWTraitsRegistry.HOME_COOK)) or gameMode == ETW_CommonFunctions.GameMode.MP_SERVER)
		and SBvars.TraitsLockSystemCanGainPositive
	then
		return true
	else
		return false
	end
end

---Returns true if the Cook System should execute
---@param player IsoPlayer|nil the player to check for
---@return boolean boolean true if the Cook System should execute, false otherwise
function ETW_CommonLogicChecks.CookShouldExecute(player)
	if
		SBvars.Cook == true
		and ((player and not player:hasTrait(CharacterTrait.COOK)) or gameMode == ETW_CommonFunctions.GameMode.MP_SERVER)
		and SBvars.TraitsLockSystemCanGainPositive
	then
		return true
	else
		return false
	end
end

---Returns true if the Gardener System should execute
---@param player IsoPlayer|nil the player to check for
---@return boolean boolean true if the Gardener System should execute, false otherwise
function ETW_CommonLogicChecks.GardenerShouldExecute(player)
	if
		SBvars.Gardener == true
		and ((player and not player:hasTrait(CharacterTrait.GARDENER)) or gameMode == ETW_CommonFunctions.GameMode.MP_SERVER)
		and SBvars.TraitsLockSystemCanGainPositive
	then
		return true
	else
		return false
	end
end

---Returns true if the First Aid System should execute
---@param player IsoPlayer|nil the player to check for
---@return boolean boolean true if the First Aid System should execute, false otherwise
function ETW_CommonLogicChecks.FirstAidShouldExecute(player)
	if
		SBvars.FirstAid == true
		and ((player and not player:hasTrait(CharacterTrait.FIRST_AID)) or gameMode == ETW_CommonFunctions.GameMode.MP_SERVER)
		and SBvars.TraitsLockSystemCanGainPositive
	then
		return true
	else
		return false
	end
end

---Returns true if the AV Club System should execute
---@param player IsoPlayer|nil the player to check for
---@return boolean boolean true if the AV Club System should execute, false otherwise
function ETW_CommonLogicChecks.AVClubShouldExecute(player)
	if
		SBvars.AVClub == true
		and ((player and not player:hasTrait(ETWTraitsRegistry.AV_CLUB)) or gameMode == ETW_CommonFunctions.GameMode.MP_SERVER)
		and SBvars.TraitsLockSystemCanGainPositive
	then
		return true
	else
		return false
	end
end

---Returns true if the Body Work Enthusiast System should execute
---@param player IsoPlayer|nil the player to check for
---@return boolean boolean true if the Body Work Enthusiast System should execute, false otherwise
function ETW_CommonLogicChecks.BodyWorkEnthusiastShouldExecute(player)
	if
		SBvars.BodyworkEnthusiast == true
		and ((player and not player:hasTrait(ETWTraitsRegistry.BODYWORK_ENTHUSIAST)) or gameMode == ETW_CommonFunctions.GameMode.MP_SERVER)
		and SBvars.TraitsLockSystemCanGainPositive
	then
		return true
	else
		return false
	end
end

---Returns true if the Mechanics System should execute
---@param player IsoPlayer|nil the player to check for
---@return boolean boolean true if the Mechanics System should execute, false otherwise
function ETW_CommonLogicChecks.MechanicsShouldExecute(player)
	if
		SBvars.Mechanics == true
		and ((player and not player:hasTrait(CharacterTrait.MECHANICS)) or gameMode == ETW_CommonFunctions.GameMode.MP_SERVER)
		and SBvars.TraitsLockSystemCanGainPositive
	then
		return true
	else
		return false
	end
end

---Returns true if the Sewer System should execute
---@param player IsoPlayer|nil the player to check for
---@return boolean boolean true if the Sewer System should execute, false otherwise
function ETW_CommonLogicChecks.SewerShouldExecute(player)
	if
		SBvars.Sewer == true
		and ((player and not player:hasTrait(CharacterTrait.TAILOR)) or gameMode == ETW_CommonFunctions.GameMode.MP_SERVER)
		and SBvars.TraitsLockSystemCanGainPositive
	then
		return true
	else
		return false
	end
end

---Returns true if the Gun Enthusiast System should execute
---@param player IsoPlayer|nil the player to check for
---@return boolean boolean true if the Gun Enthusiast System should execute, false otherwise
function ETW_CommonLogicChecks.GunEnthusiastShouldExecute(player)
	if
		SBvars.GunEnthusiast == true
		and ((player and not player:hasTrait(ETWTraitsRegistry.GUN_ENTHUSIAST)) or gameMode == ETW_CommonFunctions.GameMode.MP_SERVER)
		and SBvars.TraitsLockSystemCanGainPositive
	then
		return true
	else
		return false
	end
end

---Returns true if the Angler System should execute
---@param player IsoPlayer|nil the player to check for
---@return boolean boolean true if the Angler System should execute, false otherwise
function ETW_CommonLogicChecks.AnglerShouldExecute(player)
	if SBvars.Fishing == true and ((player and not player:hasTrait(CharacterTrait.FISHING)) or gameMode == ETW_CommonFunctions.GameMode.MP_SERVER) and SBvars.TraitsLockSystemCanGainPositive then
		return true
	else
		return false
	end
end

---Returns true if the Hiker System should execute
---@param player IsoPlayer|nil the player to check for
---@return boolean boolean true if the Hiker System should execute, false otherwise
function ETW_CommonLogicChecks.HikerShouldExecute(player)
	if SBvars.Hiker == true and ((player and not player:hasTrait(CharacterTrait.HIKER)) or gameMode == ETW_CommonFunctions.GameMode.MP_SERVER) and SBvars.TraitsLockSystemCanGainPositive then
		return true
	else
		return false
	end
end

---Returns true if the Cat Eyes System should execute
---@param player IsoPlayer|nil the player to check for
---@return boolean boolean true if the Cat Eyes System should execute, false otherwise
function ETW_CommonLogicChecks.CatEyesShouldExecute(player)
	if SBvars.CatEyes == true and ((player and not player:hasTrait(CharacterTrait.NIGHT_VISION)) or gameMode == ETW_CommonFunctions.GameMode.MP_SERVER) and SBvars.TraitsLockSystemCanGainPositive then
		return true
	else
		return false
	end
end

---Returns true if the Sleep System should execute
---@param player IsoPlayer|nil the player to check for
---@return boolean boolean true if the Sleep System should execute, false otherwise
function ETW_CommonLogicChecks.SleepSystemShouldExecute(player)
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

---Returns true if the Smoker System should execute
---@param player IsoPlayer|nil the player to check for
---@return boolean boolean true if the Smoker System should execute, false otherwise
function ETW_CommonLogicChecks.SmokerShouldExecute(player)
	if SBvars.Smoker == true and (SBvars.TraitsLockSystemCanGainNegative or SBvars.TraitsLockSystemCanLoseNegative) then
		return true
	else
		return false
	end
end

---Returns true if the Herbalist System should execute
---@param player IsoPlayer|nil the player to check for
---@return boolean boolean true if the Herbalist System should execute, false otherwise
function ETW_CommonLogicChecks.HerbalistShouldExecute(player)
	if SBvars.Herbalist == true and (SBvars.TraitsLockSystemCanGainPositive or SBvars.TraitsLockSystemCanLosePositive) then
		return true
	else
		return false
	end
end

---Returns true if the Rain System should execute
---@param player IsoPlayer|nil the player to check for
---@return boolean boolean true if the Rain System should execute, false otherwise
function ETW_CommonLogicChecks.RainSystemShouldExecute(player)
	if
		SBvars.RainSystem == true
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

---Returns true if the Fog System should execute
---@param player IsoPlayer|nil the player to check for
---@return boolean boolean true if the Fog System should execute, false otherwise
function ETW_CommonLogicChecks.FogSystemShouldExecute(player)
	if
		SBvars.FogSystem == true
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

---Returns true if the Pet Therapy System should execute
---@param player IsoPlayer|nil the player to check for
---@return boolean boolean true if the Pet Therapy System should execute, false otherwise
function ETW_CommonLogicChecks.PetTherapyShouldExecute(player)
	if
		SBvars.PetTherapy == true
		and ((player and not player:hasTrait(ETWTraitsRegistry.PET_THERAPY)) or gameMode == ETW_CommonFunctions.GameMode.MP_SERVER)
		and (SBvars.TraitsLockSystemCanGainPositive or SBvars.TraitsLockSystemCanLosePositive)
	then
		return true
	else
		return false
	end
end

---Returns true if the Wilderness Knowledge System should execute
---@param player IsoPlayer|nil the player to check for
---@return boolean boolean true if the Wilderness Knowledge System should execute, false otherwise
function ETW_CommonLogicChecks.WildernessKnowledgeShouldExecute(player)
	if
		SBvars.WildernessKnowledge == true
		and ((player and not player:hasTrait(CharacterTrait.WILDERNESS_KNOWLEDGE)) or gameMode == ETW_CommonFunctions.GameMode.MP_SERVER)
		and SBvars.TraitsLockSystemCanGainPositive
	then
		return true
	else
		return false
	end
end

---Returns true if the Whittler System should execute
---@param player IsoPlayer|nil the player to check for
---@return boolean boolean true if the Whittler System should execute, false otherwise
function ETW_CommonLogicChecks.WhittlerShouldExecute(player)
	if SBvars.Whittler == true and ((player and not player:hasTrait(CharacterTrait.WHITTLER)) or gameMode == ETW_CommonFunctions.GameMode.MP_SERVER) and SBvars.TraitsLockSystemCanGainPositive then
		return true
	else
		return false
	end
end

---Returns true if the Axeman System should execute
---@param player IsoPlayer|nil the player to check for
---@return boolean boolean true if the Axeman System should execute, false otherwise
function ETW_CommonLogicChecks.AxemanShouldExecute(player)
	if 
		SBvars.Axeman == true 
		and ((player and not player:hasTrait(CharacterTrait.AXEMAN)) or gameMode == ETW_CommonFunctions.GameMode.MP_SERVER) 
		and SBvars.TraitsLockSystemCanGainPositive 
	then
		return true
	else
		return false
	end
end

---Returns true if the Inventory Transfer System should execute
---@param player IsoPlayer|nil the player to check for
---@return boolean boolean true if the Inventory Transfer System should execute, false otherwise
function ETW_CommonLogicChecks.InventoryTransferSystemShouldExecute(player)
	if
		SBvars.InventoryTransferSystem == true
		and ((player and not player:hasTrait(CharacterTrait.DEXTROUS)) or (player and not player:hasTrait(CharacterTrait.ORGANIZED)) or gameMode == ETW_CommonFunctions.GameMode.MP_SERVER)
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

return ETW_CommonLogicChecks
