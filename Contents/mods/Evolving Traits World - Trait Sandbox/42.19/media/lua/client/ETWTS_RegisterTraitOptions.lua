local StarlitTraits = require("Starlit/sandbox/Traits")

-- Starlit uses the sandbox value as the character-creation point adjustment,
-- then negates it to obtain CharacterTraitDefinition:getCost(). Therefore each
-- default below is the inverse of the Cost in ETW_Traits.txt.
local traits = {
	{ id = "ActionHero", pointValue = -8 },
	{ id = "AntiGunActivist", pointValue = 6 },
	{ id = "AVClub", pointValue = -4 },
	{ id = "Anemic", pointValue = 4 },
	{ id = "BadTeeth", pointValue = 3 },
	{ id = "Blissful", pointValue = -3 },
	{ id = "Bouncer", pointValue = -5 },
	{ id = "Indefatigable", pointValue = -10 },
	{ id = "Butterfingers", pointValue = 12 },
	{ id = "Depressive", pointValue = 4 },
	{ id = "Gourmand", pointValue = -4 },
	{ id = "Gordonite", pointValue = -6 },
	{ id = "Hardy", pointValue = -6 },
	{ id = "IdealWeight", pointValue = -4 },
	{ id = "LeadFoot", pointValue = -2 },
	{ id = "Mundane", pointValue = 9 },
	{ id = "NaturalEater", pointValue = -4 },
	{ id = "NoodleLegs", pointValue = 6 },
	{ id = "Olympian", pointValue = -5 },
	{ id = "PackMouse", pointValue = 7 },
	{ id = "PackMule", pointValue = -7 },
	{ id = "ProwessBlade", pointValue = -7 },
	{ id = "ProwessBlunt", pointValue = -7 },
	{ id = "ProwessGuns", pointValue = -7 },
	{ id = "ProwessSpear", pointValue = -7 },
	{ id = "PracticedSwordsman", pointValue = -5 },
	{ id = "Thuggish", pointValue = -5 },
	{ id = "Unwavering", pointValue = -6 },
	{ id = "QuickRest", pointValue = -3 },
	{ id = "Quiet", pointValue = -2 },
	{ id = "Scrapper", pointValue = -3 },
	{ id = "SunSensitivity", pointValue = 5 },
	{ id = "TavernBrawler", pointValue = -3 },
	{ id = "WellFitted", pointValue = -4 },
	{ id = "ThickBlooded", pointValue = -4 },
	{ id = "AxeThrower", pointValue = -4 },
	{ id = "Bloodlust", pointValue = -4 },
	{ id = "BodyWorkEnthusiast", pointValue = -6 },
	{ id = "FastEater", pointValue = -1, toggle = "EatingSpeedTraitsEnabled" },
	{ id = "FurnitureAssembler", pointValue = -4 },
	{ id = "GunEnthusiast", pointValue = -6 },
	{ id = "GymRat", pointValue = -8 },
	{ id = "Hoarder", pointValue = -4 },
	{ id = "HomeCook", pointValue = -2 },
	{ id = "Homichlophobia", pointValue = 1, toggle = "FogTraitsEnabled" },
	{ id = "Homichlophile", pointValue = -1, toggle = "FogTraitsEnabled" },
	{ id = "BladeEnthusiast", pointValue = -4 },
	{ id = "KnifeFighter", pointValue = -3 },
	{ id = "LightStep", pointValue = -3 },
	{ id = "LowProfile", pointValue = -3 },
	{ id = "Pluviophile", pointValue = -2, toggle = "RainTraitsEnabled" },
	{ id = "Pluviophobia", pointValue = 2, toggle = "RainTraitsEnabled" },
	{ id = "PainTolerance", pointValue = -2 },
	{ id = "PetTherapy", pointValue = -3 },
	{ id = "PolearmFighter", pointValue = -3 },
	{ id = "RestorationExpert", pointValue = -8 },
	{ id = "SlowEater", pointValue = 1, toggle = "EatingSpeedTraitsEnabled" },
	{ id = "StickFighter", pointValue = -3 },
}

local registeredTraits = {}

for _, traitOptions in ipairs(traits) do
	-- The ETW trait is already registered by ETW_Traits.txt. CharacterTrait.register()
	-- would try to mutate the registry again and can throw for duplicate IDs.
	local traitId = "ETW:" .. traitOptions.id
	local characterTrait = CharacterTrait.get(ResourceLocation.of(traitId))
	local definition = characterTrait and CharacterTraitDefinition.getCharacterTraitDefinition(characterTrait)

	if definition then
		-- Starlit's 42.15 compatibility layer (used by PZ 42.19) keys this
		-- table by CharacterTrait. It resolves the definition itself when the
		-- sandbox screen applies its values.
		local info = StarlitTraits.getOrCreateInfo(characterTrait)
		info.toggleOption = "ETWTraitSandbox." .. (traitOptions.toggle or (traitOptions.id .. "Enabled"))
		info.costOption = "ETWTraitSandbox." .. traitOptions.id .. "PointValue"
		table.insert(registeredTraits, { definition = definition, info = info })
	else
		print("[ETW Trait Sandbox] Could not find ETW trait definition: " .. traitId)
	end
end

-- Starlit 42.15 clears lastCost when a trait is disabled, but subtracts from
-- lastCost without restoring it when the trait is enabled again or its cost is
-- changed. Restore the previous (pre-apply) cost before Starlit applies the new
-- SandboxVars, preventing its updateTraits() from subtracting nil.
-- local starlitSetSandboxVars = SandboxOptionsScreen.setSandboxVars
-- SandboxOptionsScreen.setSandboxVars = function(...)
-- 	for _, registeredTrait in ipairs(registeredTraits) do
-- 		if registeredTrait.info.lastCost == nil then
-- 			registeredTrait.info.lastCost = registeredTrait.definition:getCost()
-- 		end
-- 	end

-- 	return starlitSetSandboxVars(...)
-- end
