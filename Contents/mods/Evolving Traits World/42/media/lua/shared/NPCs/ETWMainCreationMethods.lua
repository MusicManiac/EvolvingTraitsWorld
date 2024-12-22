---@diagnostic disable: missing-parameter
require('NPCs/MainCreationMethods');

---Function creating trait with set parameters
---@param name string
---@param cost number
---@param isProfExclusive boolean
---@param isDisabled boolean
---@return Trait
local function createTrait(name, cost, isProfExclusive, isDisabled)
	isProfExclusive = isProfExclusive or false;
	isDisabled = isDisabled or false;
	if getActivatedMods():contains("EvolvingTraitsWorldMarkDynamicTraits") then
		return TraitFactory.addTrait(name, getText("UI_trait_" .. name) .. " (D)", cost, getText("UI_trait_" .. name .. "Desc"), isProfExclusive, isDisabled);
	else
		return TraitFactory.addTrait(name, getText("UI_trait_" .. name), cost, getText("UI_trait_" .. name .. "Desc"), isProfExclusive, isDisabled);
	end
end

---Function responsible for creating all traits
local function addTraits()
	local activatedMods = getActivatedMods();
	local newTraits = {};

	if not activatedMods:contains("EvolvingTraitsWorldDisableAVClub") then
		local AVClub = createTrait("AVClub", 4);
		AVClub:addXPBoost(Perks.Electricity, 1);
		AVClub:getFreeRecipes():add("Make Remote Controller V1");
		AVClub:getFreeRecipes():add("Make Remote Controller V2");
		AVClub:getFreeRecipes():add("Make Remote Controller V3");
		AVClub:getFreeRecipes():add("Make Remote Trigger");
		AVClub:getFreeRecipes():add("Make Timer");
		AVClub:getFreeRecipes():add("Craft Makeshift Radio");
		AVClub:getFreeRecipes():add("Craft Makeshift HAM Radio");
		AVClub:getFreeRecipes():add("Craft Makeshift Walkie Talkie");
		AVClub:getFreeRecipes():add("Make Noise generator");
		table.insert(newTraits, AVClub);
	end

	if not activatedMods:contains("EvolvingTraitsWorldDisableAxeThrower") then
		local AxeThrower = createTrait("AxeThrower", 4);
		AxeThrower:addXPBoost(Perks.Axe, 1);
		table.insert(newTraits, AxeThrower);
	end

	if not activatedMods:contains("EvolvingTraitsWorldDisableBloodlust") then
		local Bloodlust = createTrait("Bloodlust", 4);
		table.insert(newTraits, Bloodlust);
	end


	if not activatedMods:contains("EvolvingTraitsWorldDisableBodyWorkEnthusiast") then
		local BodyWorkEnthusiast = createTrait("BodyWorkEnthusiast", 6);
		BodyWorkEnthusiast:addXPBoost(Perks.Mechanics, 1);
		BodyWorkEnthusiast:addXPBoost(Perks.MetalWelding, 1);
		BodyWorkEnthusiast:getFreeRecipes():add("Make Metal Walls");
		BodyWorkEnthusiast:getFreeRecipes():add("Make Metal Fences");
		BodyWorkEnthusiast:getFreeRecipes():add("Make Metal Containers");
		BodyWorkEnthusiast:getFreeRecipes():add("Make Metal Sheet");
		BodyWorkEnthusiast:getFreeRecipes():add("Make Small Metal Sheet");
		BodyWorkEnthusiast:getFreeRecipes():add("Make Metal Roof");
		BodyWorkEnthusiast:getFreeRecipes():add("Make Metal Pipe");
		table.insert(newTraits, BodyWorkEnthusiast);
	end

	if not activatedMods:contains("EvolvingTraitsWorldDisableFurnitureAssembler") then
		local FurnitureAssembler = createTrait("FurnitureAssembler", 4);
		FurnitureAssembler:addXPBoost(Perks.Woodwork, 1);
		table.insert(newTraits, FurnitureAssembler);
	end

	if not activatedMods:contains("EvolvingTraitsWorldDisableGunEnthusiast") then
		local GunEnthusiast = createTrait("GunEnthusiast", 6);
		GunEnthusiast:addXPBoost(Perks.Aiming, 1);
		GunEnthusiast:addXPBoost(Perks.Reloading, 1);
		table.insert(newTraits, GunEnthusiast);
	end

	if not activatedMods:contains("EvolvingTraitsWorldDisableGymRat") then
		local GymRat = createTrait("GymRat", 6);
		GymRat:addXPBoost(Perks.Fitness, 1);
		GymRat:addXPBoost(Perks.Strength, 1);
		table.insert(newTraits, GymRat);
	end

	if not activatedMods:contains("EvolvingTraitsWorldDisableHoarder") then
		local Hoarder = createTrait("Hoarder", 4);
		table.insert(newTraits, Hoarder);
	end

	if not activatedMods:contains("EvolvingTraitsWorldDisableHomeCook") then
		local HomeCook = createTrait("HomeCook", 3);
		HomeCook:addXPBoost(Perks.Cooking, 1);
		HomeCook:getFreeRecipes():add("Make Cake Batter");
		table.insert(newTraits, HomeCook);
	end

	if not activatedMods:contains("EvolvingTraitsWorldDisableFogTraits") then
		local Homichlophobia = createTrait("Homichlophobia", -1);
		local Homichlophile = createTrait("Homichlophile", 1);
		table.insert(newTraits, Homichlophobia);
		table.insert(newTraits, Homichlophile);
	end

	if not activatedMods:contains("EvolvingTraitsWorldDisableKenshi") then
		local Kenshi = createTrait("Kenshi", 4);
		Kenshi:addXPBoost(Perks.LongBlade, 1);
		table.insert(newTraits, Kenshi);
	end

	if not activatedMods:contains("EvolvingTraitsWorldDisableKnifeFighter") then
		local KnifeFighter = createTrait("KnifeFighter", 3);
		KnifeFighter:addXPBoost(Perks.SmallBlade, 1);
		table.insert(newTraits, KnifeFighter);
	end

	if not activatedMods:contains("EvolvingTraitsWorldDisableLightStep") then
		local LightStep = createTrait("LightStep", 3);
		LightStep:addXPBoost(Perks.Lightfoot, 1);
		table.insert(newTraits, LightStep);
	end

	if not activatedMods:contains("EvolvingTraitsWorldDisableLowProfile") then
		local LowProfile = createTrait("LowProfile", 3);
		LowProfile:addXPBoost(Perks.Sneak, 1);
		table.insert(newTraits, LowProfile);
	end

	if not activatedMods:contains("EvolvingTraitsWorldDisableRainTraits") then
		local Pluviophile = createTrait("Pluviophile", 2);
		local Pluviophobia = createTrait("Pluviophobia", -2);
		table.insert(newTraits, Pluviophile);
		table.insert(newTraits, Pluviophobia);
	end

	if not activatedMods:contains("EvolvingTraitsWorldDisablePainTolerance") then
		local PainTolerance = createTrait("PainTolerance", 2);
		table.insert(newTraits, PainTolerance);
	end

	if not activatedMods:contains("EvolvingTraitsWorldDisableRestorationExpert") then
		local RestorationExpert = createTrait("RestorationExpert", 8);
		RestorationExpert:addXPBoost(Perks.Maintenance, 1);
		table.insert(newTraits, RestorationExpert);
	end

	if not activatedMods:contains("EvolvingTraitsWorldDisableSojutsu") then
		local Sojutsu = createTrait("Sojutsu", 3);
		Sojutsu:addXPBoost(Perks.Spear, 1);
		table.insert(newTraits, Sojutsu);
	end

	if not activatedMods:contains("EvolvingTraitsWorldDisableStickFighter") then
		local StickFighter = createTrait("StickFighter", 3);
		StickFighter:addXPBoost(Perks.SmallBlunt, 1);
		table.insert(newTraits, StickFighter);
	end

	--Exclusives
	if not activatedMods:contains("EvolvingTraitsWorldDisableGymRat") then
		TraitFactory.setMutualExclusive("GymRat", "Unfit");
		TraitFactory.setMutualExclusive("GymRat", "Out of Shape");
		TraitFactory.setMutualExclusive("GymRat", "Weak");
		TraitFactory.setMutualExclusive("GymRat", "Feeble");
		TraitFactory.setMutualExclusive("GymRat", "Obese");
		TraitFactory.setMutualExclusive("GymRat", "Very Underweight");
	end
	if not activatedMods:contains("EvolvingTraitsWorldDisableRainTraits") then
		TraitFactory.setMutualExclusive("Pluviophobia", "Pluviophile");
	end
	if not activatedMods:contains("EvolvingTraitsWorldDisableFogTraits") then
		TraitFactory.setMutualExclusive("Homichlophobia", "Homichlophile");
	end

	for i = 1, #newTraits do
		local trait = newTraits[i];
		BaseGameCharacterDetails.SetTraitDescription(trait);
	end

	TraitFactory.sortList();
end

Events.OnGameBoot.Add(addTraits);
