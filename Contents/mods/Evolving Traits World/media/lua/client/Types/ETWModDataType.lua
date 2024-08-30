--- @class EvolvingTraitsWorldModData
--- @field VehiclePartRepairs number
--- @field EagleEyedKills number
--- @field CatEyesCounter number
--- @field FoodSicknessWeathered number
--- @field TreesChopped number
--- @field PainToleranceCounter number
--- @field MentalStateInLast60Min number[]
--- @field MentalStateInLast24Hours number[]
--- @field MentalStateInLast31Days number[]
--- @field RecentAverageMental number
--- @field StartingTraits table<string, boolean>
--- @field DelayedStartingTraitsFilled boolean
--- @field DelayedTraits table<string, number, boolean>
--- @field AsthmaticCounter number
--- @field HerbsPickedUp number
--- @field RainCounter number
--- @field FogCounter number
--- @field OutdoorsmanSystem OutdoorsmanSystem
--- @field LocationFearSystem LocationFearSystem
--- @field SleepSystem SleepSystem
--- @field SmokeSystem SmokeSystem
--- @field ColdSystem ColdSystem
--- @field TransferSystem TransferSystem
--- @field BloodlustSystem BloodlustSystem
--- @field KillCount KillCount

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

--- @class ColdSystem
--- @field CurrentlySick boolean
--- @field ColdsWeathered number
--- @field CurrentColdCounterContribution number

--- @class TransferSystem
--- @field ItemsTransferred number
--- @field WeightTransferred number

--- @class BloodlustSystem
--- @field LastKillTimestamp number
--- @field BloodlustProgress number
--- @field BloodlustMeter number

--- @class KillCount
--- @field WeaponCategory table<string, WeaponCategory>

--- @class WeaponCategory
--- @field count number
--- @field WeaponType table<string, boolean>