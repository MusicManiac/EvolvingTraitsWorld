require('NPCs/MainCreationMethods');

-- Special thanks to Albion and Chuck for this function
local altNames = {};
local altNamesSpecial = {};

--base game
if true then
	altNames.Athletic = true;
	altNames.Feeble = true;
	altNames.Fit = true;
	altNames.Obese = true;
	altNames.Overweight = true;
	altNames.Stout = true;
	altNames.Strong = true;
	altNames.Underweight = true;
	altNames.Unfit = true;
	altNames.Weak = true;
	altNames["Out of Shape"] = true;
	altNames["Very Underweight"] = true;
end

if getActivatedMods():contains('EvolvingTraitsWorld') or getActivatedMods():contains('EvolvingTraitsWorldBeta') then
	altNames.AdrenalineJunkie = true;
	altNames.Agoraphobic = true;
	altNames.AllThumbs = true;
	altNames.Axeman = true;
	altNames.BaseballPlayer = true;
	altNames.Brave = true;
	altNames.Brawler = true;
	altNames.Burgler = true;
	altNames.Claustophobic = true;
	altNames.Clumsy = true;
	altNames.Conspicuous = true;
	altNames.Cook = true;
	altNames.Cowardly = true;
	altNames.Dextrous = true;
	altNames.Disorganized = true;
	altNames.EagleEyed = true;
	altNames.FastLearner = true;
	altNames.FirstAid = true;
	altNames.Fishing = true;
	altNames.Gardener = true;
	altNames.Graceful = true;
	altNames.Gymnast = true;
	altNames.Handy = true;
	altNames.HardOfHearing = true;
	altNames.Hemophobic = true;
	altNames.Herbalist = true;
	altNames.Hiker = true;
	altNames.Hunter = true;
	altNames.Inconspicuous = true;
	altNames.IronGut = true;
	altNames.Jogger = true;
	altNames.KeenHearing = true;
	altNames.Lucky = true;
	altNames.Mechanics = true;
	altNames.NeedsLessSleep = true;
	altNames.NeedsMoreSleep = true;
	altNames.NightVision = true;
	altNames.Organized = true;
	altNames.Outdoorsman = true;
	altNames.Pacifist = true;
	altNames.PainTolerance = true;
	altNames.ProneToIllness = true;
	altNames.Resilient = true;
	altNames.SlowLearner = true;
	altNames.Smoker = true;
	altNames.Tailor = true;
	altNames.Unlucky = true;
	altNames.WeakStomach = true;
	altNamesSpecial.Asthmatic = true;
	altNamesSpecial.FastHealer = true;
	altNamesSpecial.HeartyAppitite = true;
	altNamesSpecial.HighThirst = true;
	altNamesSpecial.LightEater = true;
	altNamesSpecial.LowThirst = true;
	altNamesSpecial.SlowHealer = true;
	altNamesSpecial.ThickSkinned = true;
	altNamesSpecial.Thinskinned = true;
end

if false and getActivatedMods():contains('Literacy') then
	-- pending Literacy update first
	altNames.FastReader = true;
	altNames.SlowReader = true;
	altNames.PoorReader = true;
end

if getActivatedMods():contains('ToadTraitsDynamic') then
	altNames.antigun = true;
	altNames.ascetic = true;
	altNames.bladetwirl = true;
	altNames.blunttwirl = true;
	altNames.bouncer = true;
	altNames.butterfingers = true;
	altNames.evasive = true;
	altNames.fitted = true;
	altNames.flexible = true;
	altNames.gordanite = true;
	altNames.gourmand = true;
	altNames.grunt = true;
	altNames.gymgoer = true;
	altNames.hardy = true;
	altNames.idealweight = true;
	altNames.immunocompromised = true;
	altNames.indefatigable = true;
	altNames.leadfoot = true;
	altNames.martial = true;
	altNames.mundane = true;
	altNames.natural = true;
	altNames.noodlelegs = true;
	altNames.olympian = true;
	altNames.packmouse = true;
	altNames.packmule = true;
	altNames.paranoia = true;
	altNames.problade = true;
	altNames.problunt = true;
	altNames.progun = true;
	altNames.prospear = true;
	altNames.quickworker = true;
	altNames.quiet = true;
	altNames.scrapper = true;
	altNames.secondwind = true;
	altNames.slowworker = true;
	altNames.superimmune = true;
	altNames.swift = true;
	altNames.tavernbrawler = true;
	altNames.terminator = true;
	altNames.tinkerer = true;
	altNames.unwavering = true;
	altNames.wildsman = true;
	if getActivatedMods():contains('DrivingSkill') then
		altNames.motionsickness = true;
	end
	if getActivatedMods():contains('ScavengingSkill') or getActivatedMods():contains("ScavengingSkillFixed") then
		altNames.incomprehensive = true;
		altNames.vagabond = true;
		altNames.graverobber = true;
		altNames.antique = true;
	end
end

if getActivatedMods():contains('MoreSimpleTraits') then
	altNames.AMCarpenter = true;
	altNames.AMCook = true;
	altNames.AMElectrician = true;
	altNames.AMForager = true;
	altNames.AMMechanic = true;
	altNames.AMMetalworker = true;
	altNames.AMTrapper = true;
	altNames.Cutter = true;
	altNames.Durabile = true;
	altNames.Gunfan = true;
	altNames.Lightfooted = true;
	altNames.MarathonRunner = true;
	altNames.Nimble = true;
	altNames.NinjaWay = true;
	altNames.Sharpshooter = true;
	altNames.Shortbladefan = true;
	altNames.Shortbluntfan = true;
	altNames.Sneaky = true;
	altNames.Spearman = true;
	altNames.StrongNimble = true;
	altNames.Swordsman = true;
end

if getActivatedMods():contains('DynamicTraits') then
	altNames.AMCarpenter = true;
	altNames.AMCook = true;
	altNames.AMElectrician = true;
	altNames.AMForager = true;
	altNames.AMMechanic = true;
	altNames.AMMetalworker = true;
	altNames.AMTrapper = true;
	altNames.AdrenalineJunkie = true;
	altNames.Agoraphobic = true;
	altNames.Alcoholic = true;
	altNames.AllThumbs = true;
	altNames.AmateurElectrician = true;
	altNames.Anorexy = true;
	altNames.Asthmatic = true;
	altNames.Axeman = true;
	altNames.BaseballPlayer = true;
	altNames.Bloodlust = true;
	altNames.Brave = true;
	altNames.Brawler = true;
	altNames.Burglar = true;
	altNames.Claustophobic = true;
	altNames.Clumsy = true;
	altNames.Conspicuous = true;
	altNames.Cook = true;
	altNames.Cowardly = true;
	altNames.Cutter = true;
	altNames.Desensitized = true;
	altNames.Dextrous = true;
	altNames.Disorganized = true;
	altNames.Durabile = true;
	altNames.EagleEyed = true;
	altNames.FastHealer = true;
	altNames.FastLearner = true;
	altNames.FirstAid = true;
	altNames.Fishing = true;
	altNames.Flimsy = true;
	altNames.Formerscout = true;
	altNames.Frail = true;
	altNames.Gardener = true;
	altNames.Graceful = true;
	altNames.Gunfan = true;
	altNames.Gymnast = true;
	altNames.Handy = true;
	altNames.HardOfHearing = true;
	altNames.HeartyAppitite = true;
	altNames.Hemophobic = true;
	altNames.HighThirst = true;
	altNames.Hiker = true;
	altNames.Hunter = true;
	altNames.Inconspicuous = true;
	altNames.Insomniac = true;
	altNames.Jogger = true;
	altNames.KeenHearing = true;
	altNames.LightEater = true;
	altNames.Lightfooted = true;
	altNames.LowThirst = true;
	altNames.Mechanics = true;
	altNames.Melancholic = true;
	altNames.NeedsLessSleep = true;
	altNames.NeedsMoreSleep = true;
	altNames.NightVision = true;
	altNames.Nightmares = true;
	altNames.Nimble = true;
	altNames.Nutritionist = true;
	altNames.Organized = true;
	altNames.Outdoorsman = true;
	altNames.Pacifist = true;
	altNames.PhysicallyActive = true;
	altNames.Pluviophile = true;
	altNames.Pluviophobia = true;
	altNames.ProneToIllness = true;
	altNames.Resilient = true;
	altNames.Sedentary = true;
	altNames.Shortbladefan = true;
	altNames.Shortbluntfan = true;
	altNames.SlowHealer = true;
	altNames.SlowLearner = true;
	altNames.Smoker = true;
	altNames.Sneaky = true;
	altNames.Spearman = true;
	altNames.Swordsman = true;
	altNames.Tailor = true;
	altNames.ThickSkinned = true;
	altNames.Thinskinned = true;
	altNames.AmateurElectrician = true;
	altNames.Herbalist = true;
	altNames.Melancholic = true;
	altNames.NervousWreck = true;
end

if getActivatedMods():contains('SimpleOverhaulTraitsAndOccupations') then
	altNames.AllThumbs = true;
	altNames.AutoMechanic = true;
	altNames.Axeman = true;
	altNames.BaseballPlayer = true;
	altNames.Brave = true;
	altNames.BreathingTech = true;
	altNames.Burglar = true;
	altNames.Carpenter = true;
	altNames.Clumsy = true;
	altNames.Conspicuous = true;
	altNames.Cowardly = true;
	altNames.Crusher = true;
	altNames.Cutter = true;
	altNames.Desensitized = true;
	altNames.Disorganized = true;
	altNames.Durab = true;
	altNames.ElectricTech = true;
	altNames.ExpShooter = true;
	altNames.FearoftheDark = true;
	altNames.FirstAid = true;
	altNames.Fishing = true;
	altNames.Forager = true;
	altNames.Gardener = true;
	altNames.Graceful = true;
	altNames.Handy = true;
	altNames.Hemophobic = true;
	altNames.Inconspicuous = true;
	altNames.Jogger = true;
	altNames.Lightfooted = true;
	altNames.MarathonRunner = true;
	altNames.MetalWelder = true;
	altNames.Nimble = true;
	altNames.NinjaWay = true;
	altNames.Nutritionist = false;
	altNames.Pacifist = true;
	altNames.Relentless = true;
	altNames.Scullion = true;
	altNames.Shooter = true;
	altNames.Smoker = true;
	altNames.Sneaky = true;
	altNames.Spearman = true;
	altNames.Stabber = true;
	altNames.SundayDriver = true;
	altNames.Swordsman = true;
	altNames.Tailor = true;
	altNames.Trapper = true;
end

if getActivatedMods():contains('SixthSenseMoodle') then
	altNames.SixthSense = true
end

if getActivatedMods():contains('ExplorerTrait') then
	altNames.Explorer = true
end

local old_addTrait = TraitFactory.addTrait
---Overwriting TraitFactory.addTrait() to insert ETW logic to modify trait name during generation
---@diagnostic disable-next-line: duplicate-set-field
function TraitFactory.addTrait(type, name, ...)
	if altNamesSpecial[type] == true then
		name = name .. " (P/D)";
	elseif altNames[type] == true then
		name = name .. " (D)";
	end
	return old_addTrait(type, name, ...)
end