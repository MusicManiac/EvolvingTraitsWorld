---@meta

--- @class ETWDelayedTraitEntry
--- @field [1] string Trait registry id.
--- @field [2] number Current one-in-N roll.
--- @field [3] boolean Whether the roll succeeded and the entry is waiting for its trait trigger.
--- @field [4] boolean Whether the requested change is gaining rather than removing the trait.

--- @class EvolvingTraitsWorldModData
--- @field VehiclePartRepairs number
--- @field EagleEyedKills number
--- @field CatEyesCounter number
--- @field FoodSicknessWeathered number
--- @field TreesChopped number
--- @field PainToleranceCounter number
--- @field UniqueClothingRipped string[]
--- @field ImmunitySystemCounter number
--- @field PagesReadCounter number
--- @field EatingSpeedSystemCounter number
--- @field HoarderCounter number
--- @field HardyReserve number
--- @field QuickRestLastEndurance number
--- @field IdealWeightLastCalories number
--- @field DepressiveEpisodeActive boolean
--- @field ParanoiaCooldownMinutes integer
--- @field AntiGunLastRecordedAimingXP number
--- @field AntiGunAimingXPCheckPending boolean
--- @field BouncerCooldownTicks integer
--- @field IndefatigableUses integer
--- @field IndefatigableCooldownUntilHours number
--- @field IndefatigableProtectionExpiresAt number
--- @field IndefatigableWoundSpeedModifiers table[]
--- @field MadeOfGlass MadeOfGlassSystem
--- @field UnwaveringInjurySpeedApplied boolean
--- @field SunSensitivityExposure number
--- @field SunSensitivityAppliedPain number
--- @field injuriesCounter number
--- @field healerCounter number
--- @field MentalStateInLast60Min number[]
--- @field MentalStateInLast24Hours number[]
--- @field MentalStateInLast31Days number[]
--- @field RecentAverageMental number
--- @field FoodStateInLast60Min number[]
--- @field FoodStateInLast24Hours number[]
--- @field FoodStateInLast31Days number[]
--- @field RecentAverageFood number
--- @field ThirstStateInLast60Min number[]
--- @field ThirstStateInLast24Hours number[]
--- @field ThirstStateInLast31Days number[]
--- @field RecentAverageThirst number
--- @field StartingTraits table<string, boolean>
--- @field DelayedStartingTraitsFilled boolean
--- @field DelayedTraits ETWDelayedTraitEntry[]
--- @field AsthmaticCounter number
--- @field HerbsPickedUp number
--- @field RainCounter number
--- @field FogCounter number
--- @field OutdoorsmanSystem OutdoorsmanSystem
--- @field LocationFearSystem LocationFearSystem
--- @field SleepSystem SleepSystem
--- @field SmokeSystem SmokeSystem
--- @field TransferSystem TransferSystem
--- @field BloodlustSystem BloodlustSystem
--- @field AnimalsSystem AnimalsSystem
--- @field KillCount KillCount

--- @class MadeOfGlassSystem
--- @field LastHealth number
--- @field PendingExtraDamage number
--- @field LogWindowStartedAt number
--- @field LogEventCount integer
--- @field LogObservedDamage number
--- @field LogIgnoredDamage number
--- @field LogOriginalDamage number
--- @field LogExtraDamage number

--- @class OutdoorsmanSystem
--- @field OutdoorsmanCounter number
--- @field MinutesSinceOutside number

--- @class LocationFearSystem
--- @field FearOfInside number
--- @field FearOfOutside number

--- @class SleepSystem
--- @field CurrentlySleeping boolean
--- @field HoursSinceLastSleep number
--- @field LastMidpoint number
--- @field WentToSleepAt number
--- @field SleepHealthinessBar number

--- @class SmokeSystem
--- @field SmokingAddiction number
--- @field MinutesSinceLastSmoke number

--- @class TransferSystem
--- @field ItemsTransferred number
--- @field WeightTransferred number

--- @class BloodlustSystem
--- @field LastKillTimestamp number
--- @field BloodlustProgress number
--- @field BloodlustMeter number

--- @class AnimalsSystem
--- @field UniqueAnimalsPetted integer[]
--- @field LastMinuteTimestampWhenPettedWithBoost integer

--- @class KillCount
--- @field WeaponCategory table<string, WeaponCategory>

--- @class WeaponCategory
--- @field count number
--- @field WeaponType table<string, boolean>
