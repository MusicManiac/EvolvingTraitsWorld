---@meta

--- @class ETWDelayedTraitEntry
--- @field [1] string Trait registry id.
--- @field [2] number Current one-in-N roll.
--- @field [3] boolean Whether the roll succeeded and the entry is waiting for its trait trigger.
--- @field [4] boolean Whether the requested change is gaining rather than removing the trait.

--- @alias ETWTraitEventType "qualified_for_gaining"|"qualified_for_losing"|"gained"|"lost"

--- @class ETWRecentTraitEvent
--- @field trait string Serialized trait registry id.
--- @field event ETWTraitEventType Serialized event type.
--- @field timestamp number In-game world-age hours when the event occurred.

--- @class EvolvingTraitsWorldModData
--- @field ModDataVersion number
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
--- @field CarryWeightCounter number
--- @field OlympianCounter number
--- @field NaturalEaterFoodsEaten integer
--- @field NoodleLegs NoodleLegs
--- @field HardyReserve number
--- @field QuickRestLastEndurance number
--- @field IdealWeightCounter number
--- @field IdealWeightLastCalories number
--- @field DepressiveEpisodeActive boolean
--- @field TVJunkieSystem TVJunkieSystem
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
--- @field InjurySnapshotSystem InjurySnapshotSystem
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
--- @field RecentTraitEvents ETWRecentTraitEvent[]
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

--- @class TVJunkieSystem
--- @field ActiveMinutes integer
--- @field MinutesSinceLastWatch integer
--- @field CommandMinutes integer[]

--- @class NoodleLegs
--- @field Distance number
--- @field LastX number
--- @field LastY number
--- @field LastZ number

---Serializable wound snapshot used to detect new wounds and timer increases without storing PZ objects.
--- @class InjuryStateSnapshot
--- @field Scratched boolean Whether a scratch was active in the previous update.
--- @field ScratchTime number Previous scratch duration.
--- @field Cut boolean Whether a laceration was active in the previous update.
--- @field CutTime number Previous laceration duration.
--- @field DeepWounded boolean Whether a deep wound was active in the previous update.
--- @field DeepWoundTime number Previous deep-wound duration.
--- @field Burned boolean Whether a burn was active in the previous update.
--- @field BurnTime number Previous burn duration.
--- @field Bitten boolean Whether a bite was active in the previous update.
--- @field BiteTime number Previous bite duration.
--- @field FractureTime number Previous fracture duration.

---Persistent injury snapshots and starting-trait body-part sets keyed by serialized BodyPartType names.
--- @class InjurySnapshotSystem
--- @field InjuredBodyParts table<string, boolean> Parts randomly injured at character creation.
--- @field BurnedBodyParts table<string, boolean> Parts burned by Burned Ward Patient at character creation.
--- @field BrokenBodyParts table<string, boolean> Parts fractured by Broken Leg at character creation.
--- @field LastStates table<string, InjuryStateSnapshot> Previous wound snapshot for each remembered part.
--- @field FractureTimeSnapshots table<string, number> Previous fracture duration for every body part.

--- @class MadeOfGlassSystem
--- @field LastHealth number
--- @field PendingExtraDamage number
--- @field WasAsleep boolean
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
--- @field BloodlustProgress number
--- @field KillsLastHour integer[]

--- @class AnimalsSystem
--- @field UniqueAnimalsPetted integer[]
--- @field LastMinuteTimestampWhenPettedWithBoost integer

--- @class KillCount
--- @field WeaponCategory table<string, KillCountWeaponCategory>

--- @class KillCountSharedAPI
--- @field getLocalKills fun(player: IsoPlayer): KillCount|nil

--- @class KillCountWeaponCategory
--- @field count number
--- @field WeaponType table<string, number>
