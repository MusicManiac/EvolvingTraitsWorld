require "ISUI/ISPanelJoypad"
require "UI/CharacterInfoAddTab"
require "ETWModOptions"

local ETWCommonLogicChecks = require "ETWCommonLogicChecks";

local MOvars = EvolvingTraitsWorld.settings;

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)
local WINDOW_WIDTH = 700;
local WINDOW_HEIGHT = 200;
local WINDOW_HEIGHT_AFTER_CHILDREN = 700;

local lineStartPosition = 5;

local x;
local y = 12;

local columnGap;

local nonBarsEntriesPerRow = MOvars.TraitColumns or 4;
local nonBarsEntryNumber = 0;

--- @type EvolvingTraitsWorldSandboxVars
local SBvars = SandboxVars.EvolvingTraitsWorld;

ISETWProgressUI = ISPanelJoypad:derive("ISETWUI")

local function percentile(minValue, maxValue, currentValue)
	return (currentValue - minValue) / (maxValue - minValue)
end

local function strLen(textManager, str)
	return textManager:MeasureStringX(UIFont.Small, str)
end

local function arrangeColumnsInTable()
	x = lineStartPosition;
	nonBarsEntryNumber = nonBarsEntryNumber + 1;
	if (nonBarsEntryNumber > nonBarsEntriesPerRow) then
		y = y + FONT_HGT_SMALL;
		nonBarsEntryNumber = 1;
	end
	if nonBarsEntryNumber ~= 1 then
		x = lineStartPosition + columnGap * (nonBarsEntryNumber - 1);
	end
end

function ISETWProgressUI:initialise()

end

function ISETWProgressUI:createChildren()
	if SBvars.UIPage then
		local barStartPosition = 150; -- TODO : add modoption to adjust this
		local barEndPosition = WINDOW_WIDTH - lineStartPosition;
		local barMidPosition = barStartPosition + (barEndPosition - barStartPosition) / 2;
		local barLength = barEndPosition - barStartPosition;
		local barOneFourthPosition = barMidPosition - barLength / 4;
		local barThreeFourthPosition = barMidPosition + barLength / 4;
		local barOneThirdPosition = barStartPosition + barLength / 3;
		local barTwoThirdPosition = barOneThirdPosition + barLength / 3;
		local highlightRadius = 20;

		columnGap = (WINDOW_WIDTH - 2 * lineStartPosition) / nonBarsEntriesPerRow;

		local yellowGreenGradient = getTexture("media/ui/GradientBars/yellowGreenGradient.png");
		local greenYellowRedGradient = getTexture("media/ui/GradientBars/greenYellowRedGradient.png");
		local redYellowGreenGradient = getTexture("media/ui/GradientBars/redYellowGreenGradient.png");

		self.TextColor = { r = 1, g = 1, b = 1, a = 1 }
		self.DimmedTextColor = { r = 0.7, g = 0.7, b = 0.7, a = 1 }

		local textManager = getTextManager();
		local str;

		local player = getPlayer();
		local modData = ETWCommonFunctions.getETWModData(player);
		local strength = player:getPerkLevel(Perks.Strength);
		local fitness = player:getPerkLevel(Perks.Fitness);
		local sprinting = player:getPerkLevel(Perks.Sprinting);
		local lightfooted = player:getPerkLevel(Perks.Lightfoot);
		local nimble = player:getPerkLevel(Perks.Nimble);
		local sneaking = player:getPerkLevel(Perks.Sneak);
		local axe = player:getPerkLevel(Perks.Axe);
		local longBlunt = player:getPerkLevel(Perks.Blunt);
		local shortBlunt = player:getPerkLevel(Perks.SmallBlunt);
		local longBlade = player:getPerkLevel(Perks.LongBlade);
		local shortBlade = player:getPerkLevel(Perks.SmallBlade);
		local spear = player:getPerkLevel(Perks.Spear);
		local maintenance = player:getPerkLevel(Perks.Maintenance);
		local carpentry = player:getPerkLevel(Perks.Woodwork);
		local cooking = player:getPerkLevel(Perks.Cooking);
		local farming = player:getPerkLevel(Perks.Farming);
		local firstAid = player:getPerkLevel(Perks.Doctor);
		local electrical = player:getPerkLevel(Perks.Electricity);
		local metalworking = player:getPerkLevel(Perks.MetalWelding);
		local mechanics = player:getPerkLevel(Perks.Mechanics);
		local tailoring = player:getPerkLevel(Perks.Tailoring);
		local aiming = player:getPerkLevel(Perks.Aiming);
		local reloading = player:getPerkLevel(Perks.Reloading);
		local fishing = player:getPerkLevel(Perks.Fishing);
		local trapping = player:getPerkLevel(Perks.Trapping);
		local foraging = player:getPerkLevel(Perks.PlantScavenging);

		local killCountModData;
		local axeKills = 0;
		local longBluntKills = 0;
		local shortBluntKills = 0;
		local longBladeKills = 0;
		local shortBladeKills = 0;
		local spearKills = 0;
		local firearmKills = 0;
		if modData and modData.KillCount and modData.KillCount.WeaponCategory then
			killCountModData = modData.KillCount.WeaponCategory;
			axeKills = killCountModData["Axe"].count or 0;
			longBluntKills = killCountModData["Blunt"].count or 0;
			shortBluntKills = killCountModData["SmallBlunt"].count or 0;
			longBladeKills = killCountModData["LongBlade"].count or 0;
			shortBladeKills = killCountModData["SmallBlade"].count or 0;
			spearKills = killCountModData["Spear"].count or 0;
			firearmKills = killCountModData["Firearm"].count or 0;
		end

		if ETWCommonLogicChecks.ColdIllnessSystemShouldExecute() then
			str = "- " .. getText("UI_trait_pronetoillness")
			self.labelProneToIllness = ISLabel:new(barMidPosition - strLen(textManager, str)/2, y, FONT_HGT_SMALL, str, self.DimmedTextColor.r, self.DimmedTextColor.g, self.DimmedTextColor.b, self.DimmedTextColor.a, UIFont.Small, true)
			self.labelProneToIllness:setTooltip(getText("UI_ETW_LooseTooltip"))
			self:addChild(self.labelProneToIllness)

			self.labelResilient = ISLabel:new(barEndPosition, y, FONT_HGT_SMALL, "+ " .. getText("UI_trait_resilient"), self.DimmedTextColor.r, self.DimmedTextColor.g, self.DimmedTextColor.b, self.DimmedTextColor.a, UIFont.Small, false)
			self.labelResilient:setTooltip(getText("UI_ETW_GainTooltip"))
			self:addChild(self.labelResilient)

			y = y + FONT_HGT_SMALL

			self.labelColdIllnessSystem = ISLabel:new(barStartPosition - lineStartPosition, y, FONT_HGT_SMALL, getText("Sandbox_ETW_ColdIllnessSystem"), self.TextColor.r, self.TextColor.g, self.TextColor.b, self.TextColor.a, UIFont.Small, false)
			self.labelColdIllnessSystem:setTooltip(getText("Sandbox_ETW_ColdIllnessSystemColdsWeathered_tooltip"))
			self:addChild(self.labelColdIllnessSystem)

			self.barColdIllnessSystem = ISGradientBar:new(barStartPosition, y, barLength, FONT_HGT_SMALL)
			self.barColdIllnessSystem:setGradientTexture(redYellowGreenGradient)
			self.barColdIllnessSystem:setHighlightRadius(highlightRadius)
			self.barColdIllnessSystem:setDoKnob(false)
			self:addChild(self.barColdIllnessSystem)

			y = y + FONT_HGT_SMALL
		end

		if ETWCommonLogicChecks.FoodSicknessSystemShouldExecute() then
			self.labelWeakStomach = ISLabel:new(barMidPosition, y, FONT_HGT_SMALL, "- " .. getText("UI_trait_WeakStomach"), self.DimmedTextColor.r, self.DimmedTextColor.g, self.DimmedTextColor.b, self.DimmedTextColor.a, UIFont.Small, true)
			self.labelWeakStomach.center = true;
			self.labelWeakStomach:setTooltip(getText("UI_ETW_LooseTooltip"))
			self:addChild(self.labelWeakStomach)

			self.labelIronGut = ISLabel:new(barEndPosition, y, FONT_HGT_SMALL, "+ " .. getText("UI_trait_IronGut"), self.DimmedTextColor.r, self.DimmedTextColor.g, self.DimmedTextColor.b, self.DimmedTextColor.a, UIFont.Small, false)
			self.labelIronGut:setTooltip(getText("UI_ETW_GainTooltip"))
			self:addChild(self.labelIronGut)

			y = y + FONT_HGT_SMALL

			self.labelSicknessSystem = ISLabel:new(barStartPosition - lineStartPosition, y, FONT_HGT_SMALL, getText("Sandbox_ETW_FoodSicknessSystem"), self.TextColor.r, self.TextColor.g, self.TextColor.b, self.TextColor.a, UIFont.Small, false)
			self.labelSicknessSystem:setTooltip(getText("Sandbox_ETW_FoodSicknessSystemCounter_tooltip"))
			self:addChild(self.labelSicknessSystem)

			self.barSicknessSystem = ISGradientBar:new(barStartPosition, y, barLength, FONT_HGT_SMALL)
			self.barSicknessSystem:setGradientTexture(redYellowGreenGradient)
			self.barSicknessSystem:setHighlightRadius(highlightRadius)
			self.barSicknessSystem:setDoKnob(false)
			self:addChild(self.barSicknessSystem)

			y = y + FONT_HGT_SMALL
		end

		if ETWCommonLogicChecks.PainToleranceShouldExecute() then
			self.labelPainTolerance = ISLabel:new(barEndPosition, y, FONT_HGT_SMALL, "+ " .. getText("UI_trait_PainTolerance"), self.DimmedTextColor.r, self.DimmedTextColor.g, self.DimmedTextColor.b, self.DimmedTextColor.a, UIFont.Small, false)
			self.labelPainTolerance:setTooltip(getText("UI_ETW_GainTooltip"))
			self:addChild(self.labelPainTolerance)

			y = y + FONT_HGT_SMALL

			self.labelPainToleranceBarName = ISLabel:new(barStartPosition - lineStartPosition, y, FONT_HGT_SMALL, getText("UI_trait_PainTolerance"), self.TextColor.r, self.TextColor.g, self.TextColor.b, self.TextColor.a, UIFont.Small, false)
			self.labelPainToleranceBarName:setTooltip(getText("Sandbox_ETW_PainToleranceCounter_tooltip"))
			self:addChild(self.labelPainToleranceBarName)

			self.barPainTolerance = ISGradientBar:new(barStartPosition, y, barLength, FONT_HGT_SMALL)
			self.barPainTolerance:setGradientTexture(redYellowGreenGradient)
			self.barPainTolerance:setHighlightRadius(highlightRadius)
			self.barPainTolerance:setDoKnob(false)
			self:addChild(self.barPainTolerance)

			y = y + FONT_HGT_SMALL
		end

		if ETWCommonLogicChecks.AsthmaticShouldExecute() then
			str = "+ " .. getText("UI_trait_Asthmatic")
			self.labelAsthmaticGain = ISLabel:new(barOneFourthPosition - strLen(textManager, str)/2, y, FONT_HGT_SMALL, str, self.DimmedTextColor.r, self.DimmedTextColor.g, self.DimmedTextColor.b, self.DimmedTextColor.a, UIFont.Small, true)
			self.labelAsthmaticGain:setTooltip(getText("UI_ETW_GainTooltip"))
			self:addChild(self.labelAsthmaticGain)

			str = "- " .. getText("UI_trait_Asthmatic")
			self.labelAsthmaticLose = ISLabel:new(barThreeFourthPosition - strLen(textManager, str)/2, y, FONT_HGT_SMALL, str, self.DimmedTextColor.r, self.DimmedTextColor.g, self.DimmedTextColor.b, self.DimmedTextColor.a, UIFont.Small, true)
			self.labelAsthmaticLose:setTooltip(getText("UI_ETW_LooseTooltip"))
			self:addChild(self.labelAsthmaticLose)

			y = y + FONT_HGT_SMALL

			self.labelAsthmaticBarName = ISLabel:new(barStartPosition - lineStartPosition, y, FONT_HGT_SMALL, getText("UI_trait_Asthmatic"), self.TextColor.r, self.TextColor.g, self.TextColor.b, self.TextColor.a, UIFont.Small, false)
			self.labelAsthmaticBarName:setTooltip(getText("Sandbox_ETW_AsthmaticCounter_tooltip"))
			self:addChild(self.labelAsthmaticBarName)

			self.barAsthmatic = ISGradientBar:new(barStartPosition, y, barLength, FONT_HGT_SMALL)
			self.barAsthmatic:setGradientTexture(redYellowGreenGradient)
			self.barAsthmatic:setHighlightRadius(highlightRadius)
			self.barAsthmatic:setDoKnob(false)
			self:addChild(self.barAsthmatic)

			y = y + FONT_HGT_SMALL
		end

		if ETWCommonLogicChecks.BloodlustShouldExecute() then
			str = "- " .. getText("UI_trait_Bloodlust")
			self.labelBloodlustLose = ISLabel:new(barOneThirdPosition - strLen(textManager, str)/2, y, FONT_HGT_SMALL, str, self.DimmedTextColor.r, self.DimmedTextColor.g, self.DimmedTextColor.b, self.DimmedTextColor.a, UIFont.Small, true)
			self.labelBloodlustLose:setTooltip(getText("UI_ETW_LooseTooltip"))
			self:addChild(self.labelBloodlustLose)

			str = "+ " .. getText("UI_trait_Bloodlust")
			self.labelBloodlustGain = ISLabel:new(barTwoThirdPosition, y, FONT_HGT_SMALL, str, self.DimmedTextColor.r, self.DimmedTextColor.g, self.DimmedTextColor.b, self.DimmedTextColor.a, UIFont.Small, true)
			self.labelBloodlustGain:setTooltip(getText("UI_ETW_GainTooltip"))
			self:addChild(self.labelBloodlustGain)

			y = y + FONT_HGT_SMALL

			self.labelBloodlustBarName = ISLabel:new(barStartPosition - lineStartPosition, y, FONT_HGT_SMALL, getText("UI_trait_Bloodlust"), self.TextColor.r, self.TextColor.g, self.TextColor.b, self.TextColor.a, UIFont.Small, false)
			self.labelBloodlustBarName:setTooltip(getText("Sandbox_ETW_BloodlustProgress_tooltip"))
			self:addChild(self.labelBloodlustBarName)

			self.barBloodlust = ISGradientBar:new(barStartPosition, y, barLength, FONT_HGT_SMALL)
			self.barBloodlust:setGradientTexture(redYellowGreenGradient)
			self.barBloodlust:setHighlightRadius(highlightRadius)
			self.barBloodlust:setDoKnob(false)
			self:addChild(self.barBloodlust)

			y = y + FONT_HGT_SMALL
		end

		if ETWCommonLogicChecks.OutdoorsmanShouldExecute() then
			str = "- " .. getText("UI_trait_outdoorsman")
			self.labelOutdoorsmanLose = ISLabel:new(barOneThirdPosition - strLen(textManager, str)/2, y, FONT_HGT_SMALL, str, self.DimmedTextColor.r, self.DimmedTextColor.g, self.DimmedTextColor.b, self.DimmedTextColor.a, UIFont.Small, true)
			self.labelOutdoorsmanLose:setTooltip(getText("UI_ETW_LooseTooltip"))
			self:addChild(self.labelOutdoorsmanLose)

			str = "+ " .. getText("UI_trait_outdoorsman")
			self.labelOutdoorsmanGain = ISLabel:new(barTwoThirdPosition - strLen(textManager, str)/2, y, FONT_HGT_SMALL, str, self.DimmedTextColor.r, self.DimmedTextColor.g, self.DimmedTextColor.b, self.DimmedTextColor.a, UIFont.Small, true)
			self.labelOutdoorsmanGain:setTooltip(getText("UI_ETW_GainTooltip"))
			self:addChild(self.labelOutdoorsmanGain)

			y = y + FONT_HGT_SMALL

			self.labelOutdoorsmanBarName = ISLabel:new(barStartPosition - lineStartPosition, y, FONT_HGT_SMALL, getText("UI_trait_outdoorsman"), self.TextColor.r, self.TextColor.g, self.TextColor.b, self.TextColor.a, UIFont.Small, false)
			self.labelOutdoorsmanBarName:setTooltip(getText("Sandbox_ETW_OutdoorsmanCounter_tooltip"))
			self:addChild(self.labelOutdoorsmanBarName)

			self.barOutdoorsman = ISGradientBar:new(barStartPosition, y, barLength, FONT_HGT_SMALL)
			self.barOutdoorsman:setGradientTexture(redYellowGreenGradient)
			self.barOutdoorsman:setHighlightRadius(highlightRadius)
			self.barOutdoorsman:setDoKnob(false)
			self:addChild(self.barOutdoorsman)

			y = y + FONT_HGT_SMALL
		end

		if ETWCommonLogicChecks.FearOfLocationsSystemShouldExecute() then
			str = "+ " .. getText("UI_trait_agoraphobic")
			self.labelAgoraphobicGain = ISLabel:new(barOneThirdPosition - strLen(textManager, str)/2, y, FONT_HGT_SMALL, str, self.DimmedTextColor.r, self.DimmedTextColor.g, self.DimmedTextColor.b, self.DimmedTextColor.a, UIFont.Small, true)
			self.labelAgoraphobicGain:setTooltip(getText("UI_ETW_GainTooltip"))
			self:addChild(self.labelAgoraphobicGain)

			str = "- " .. getText("UI_trait_agoraphobic")
			self.labelAgoraphobicLose = ISLabel:new(barTwoThirdPosition - strLen(textManager, str)/2, y, FONT_HGT_SMALL, str, self.DimmedTextColor.r, self.DimmedTextColor.g, self.DimmedTextColor.b, self.DimmedTextColor.a, UIFont.Small, true)
			self.labelAgoraphobicLose:setTooltip(getText("UI_ETW_LooseTooltip"))
			self:addChild(self.labelAgoraphobicLose)

			y = y + FONT_HGT_SMALL

			self.labelAgoraphobicBarName = ISLabel:new(barStartPosition - lineStartPosition, y, FONT_HGT_SMALL, getText("UI_trait_agoraphobic"), self.TextColor.r, self.TextColor.g, self.TextColor.b, self.TextColor.a, UIFont.Small, false)
			self.labelAgoraphobicBarName:setTooltip(getText("Sandbox_ETW_FearOfLocationsSystemCounter_tooltip"))
			self:addChild(self.labelAgoraphobicBarName)

			self.barAgoraphobic = ISGradientBar:new(barStartPosition, y, barLength, FONT_HGT_SMALL)
			self.barAgoraphobic:setGradientTexture(redYellowGreenGradient)
			self.barAgoraphobic:setHighlightRadius(highlightRadius)
			self.barAgoraphobic:setDoKnob(false)
			self:addChild(self.barAgoraphobic)

			y = y + FONT_HGT_SMALL

			str = "+ " .. getText("UI_trait_claustro")
			self.labelClaustrophobicGain = ISLabel:new(barOneThirdPosition - strLen(textManager, str)/2, y, FONT_HGT_SMALL, str, self.DimmedTextColor.r, self.DimmedTextColor.g, self.DimmedTextColor.b, self.DimmedTextColor.a, UIFont.Small, true)
			self.labelClaustrophobicGain:setTooltip(getText("UI_ETW_GainTooltip"))
			self:addChild(self.labelClaustrophobicGain)

			str = "- " .. getText("UI_trait_claustro")
			self.labelClaustrophobicLose = ISLabel:new(barTwoThirdPosition - strLen(textManager, str)/2, y, FONT_HGT_SMALL, str, self.DimmedTextColor.r, self.DimmedTextColor.g, self.DimmedTextColor.b, self.DimmedTextColor.a, UIFont.Small, true)
			self.labelClaustrophobicLose:setTooltip(getText("UI_ETW_LooseTooltip"))
			self:addChild(self.labelClaustrophobicLose)

			y = y + FONT_HGT_SMALL

			self.labelClaustrophobicBarName = ISLabel:new(barStartPosition - lineStartPosition, y, FONT_HGT_SMALL, getText("UI_trait_claustro"), self.TextColor.r, self.TextColor.g, self.TextColor.b, self.TextColor.a, UIFont.Small, false)
			self.labelClaustrophobicBarName:setTooltip(getText("Sandbox_ETW_FearOfLocationsSystemCounter_tooltip"))
			self:addChild(self.labelClaustrophobicBarName)

			self.barClaustrophobic = ISGradientBar:new(barStartPosition, y, barLength, FONT_HGT_SMALL)
			self.barClaustrophobic:setGradientTexture(redYellowGreenGradient)
			self.barClaustrophobic:setHighlightRadius(highlightRadius)
			self.barClaustrophobic:setDoKnob(false)
			self:addChild(self.barClaustrophobic)

			y = y + FONT_HGT_SMALL
		end

		if ETWCommonLogicChecks.LuckSystemShouldExecute() then
			str = "- " .. getText("UI_trait_unlucky")
			self.labelUnluckyLose = ISLabel:new(barMidPosition - strLen(textManager, str)/2, y, FONT_HGT_SMALL, str, self.DimmedTextColor.r, self.DimmedTextColor.g, self.DimmedTextColor.b, self.DimmedTextColor.a, UIFont.Small, true)
			self.labelUnluckyLose:setTooltip(getText("UI_ETW_LooseTooltip"))
			self:addChild(self.labelUnluckyLose)

			self.labelLuckyGain = ISLabel:new(barEndPosition, y, FONT_HGT_SMALL, "+ " .. getText("UI_trait_lucky"), self.DimmedTextColor.r, self.DimmedTextColor.g, self.DimmedTextColor.b, self.DimmedTextColor.a, UIFont.Small, false)
			self.labelLuckyGain:setTooltip(getText("UI_ETW_GainTooltip"))
			self:addChild(self.labelLuckyGain)

			y = y + FONT_HGT_SMALL

			self.labelLuckSystemBarName = ISLabel:new(barStartPosition - lineStartPosition, y, FONT_HGT_SMALL, getText("Sandbox_ETW_LuckSystem"), self.TextColor.r, self.TextColor.g, self.TextColor.b, self.TextColor.a, UIFont.Small, false)
			self.labelLuckSystemBarName:setTooltip(getText("Sandbox_ETW_LuckSystemSkill_tooltip"))
			self:addChild(self.labelLuckSystemBarName)

			self.barLuckSystem = ISGradientBar:new(barStartPosition, y, barLength, FONT_HGT_SMALL)
			self.barLuckSystem:setGradientTexture(redYellowGreenGradient)
			self.barLuckSystem:setHighlightRadius(highlightRadius)
			self.barLuckSystem:setDoKnob(false)
			self:addChild(self.barLuckSystem)

			y = y + FONT_HGT_SMALL
		end

		if ETWCommonLogicChecks.HearingSystemShouldExecute() then
			str = "- " .. getText("UI_trait_hardhear")
			self.labelHardOfHearingLose = ISLabel:new(barMidPosition - strLen(textManager, str)/2, y, FONT_HGT_SMALL, str, self.DimmedTextColor.r, self.DimmedTextColor.g, self.DimmedTextColor.b, self.DimmedTextColor.a, UIFont.Small, true)
			self.labelHardOfHearingLose:setTooltip(getText("UI_ETW_LooseTooltip"))
			self:addChild(self.labelHardOfHearingLose)

			self.labelKeenHearingGain = ISLabel:new(barEndPosition, y, FONT_HGT_SMALL, "+ " .. getText("UI_trait_keenhearing"), self.DimmedTextColor.r, self.DimmedTextColor.g, self.DimmedTextColor.b, self.DimmedTextColor.a, UIFont.Small, false)
			self.labelKeenHearingGain:setTooltip(getText("UI_ETW_GainTooltip"))
			self:addChild(self.labelKeenHearingGain)

			y = y + FONT_HGT_SMALL

			self.labelHearingSystemBarName = ISLabel:new(barStartPosition - lineStartPosition, y, FONT_HGT_SMALL, getText("Sandbox_ETW_HearingSystem"), self.TextColor.r, self.TextColor.g, self.TextColor.b, self.TextColor.a, UIFont.Small, false)
			self.labelHearingSystemBarName:setTooltip(getText("Sandbox_ETW_HearingSystemSkill_tooltip"))
			self:addChild(self.labelHearingSystemBarName)

			self.barHearingSystem = ISGradientBar:new(barStartPosition, y, barLength, FONT_HGT_SMALL)
			self.barHearingSystem:setGradientTexture(redYellowGreenGradient)
			self.barHearingSystem:setHighlightRadius(highlightRadius)
			self.barHearingSystem:setDoKnob(false)
			self:addChild(self.barHearingSystem)

			y = y + FONT_HGT_SMALL
		end

		if ETWCommonLogicChecks.LearnerSystemShouldExecute() then
			str = "- " .. getText("UI_trait_SlowLearner")
			self.labelSlowLearnerLose = ISLabel:new(barMidPosition - strLen(textManager, str)/2, y, FONT_HGT_SMALL, str, self.DimmedTextColor.r, self.DimmedTextColor.g, self.DimmedTextColor.b, self.DimmedTextColor.a, UIFont.Small, true)
			self.labelSlowLearnerLose:setTooltip(getText("UI_ETW_LooseTooltip"))
			self:addChild(self.labelSlowLearnerLose)

			self.labelFastLearnerGain = ISLabel:new(barEndPosition, y, FONT_HGT_SMALL, "+ " .. getText("UI_trait_FastLearner"), self.DimmedTextColor.r, self.DimmedTextColor.g, self.DimmedTextColor.b, self.DimmedTextColor.a, UIFont.Small, false)
			self.labelFastLearnerGain:setTooltip(getText("UI_ETW_GainTooltip"))
			self:addChild(self.labelFastLearnerGain)

			y = y + FONT_HGT_SMALL

			self.labelLearnerSystemBarName = ISLabel:new(barStartPosition - lineStartPosition, y, FONT_HGT_SMALL, getText("Sandbox_ETW_LearnerSystem"), self.TextColor.r, self.TextColor.g, self.TextColor.b, self.TextColor.a, UIFont.Small, false)
			self.labelLearnerSystemBarName:setTooltip(getText("Sandbox_ETW_LearnerSystemSkill_tooltip"))
			self:addChild(self.labelLearnerSystemBarName)

			self.barLearnerSystem = ISGradientBar:new(barStartPosition, y, barLength, FONT_HGT_SMALL)
			self.barLearnerSystem:setGradientTexture(redYellowGreenGradient)
			self.barLearnerSystem:setHighlightRadius(highlightRadius)
			self.barLearnerSystem:setDoKnob(false)
			self:addChild(self.barLearnerSystem)

			y = y + FONT_HGT_SMALL
		end

		if ETWCommonLogicChecks.SleepSystemShouldExecute() then
			str = "+ " .. getText("UI_trait_MoreSleep")
			self.labelMoreSleepGain = ISLabel:new(barOneFourthPosition - strLen(textManager, str)/2, y, FONT_HGT_SMALL, str, self.DimmedTextColor.r, self.DimmedTextColor.g, self.DimmedTextColor.b, self.DimmedTextColor.a, UIFont.Small, true)
			self.labelMoreSleepGain:setTooltip(getText("UI_ETW_GainTooltip"))
			self:addChild(self.labelMoreSleepGain)

			str = "+ " .. getText("UI_trait_LessSleep")
			self.labelLessSleepGain = ISLabel:new(barThreeFourthPosition - strLen(textManager, str)/2, y, FONT_HGT_SMALL, str, self.DimmedTextColor.r, self.DimmedTextColor.g, self.DimmedTextColor.b, self.DimmedTextColor.a, UIFont.Small, true)
			self.labelLessSleepGain:setTooltip(getText("UI_ETW_GainTooltip"))
			self:addChild(self.labelLessSleepGain)

			y = y + FONT_HGT_SMALL

			self.labelSleepSystemBarName = ISLabel:new(barStartPosition - lineStartPosition, y, FONT_HGT_SMALL, getText("Sandbox_ETW_SleepSystem"), self.TextColor.r, self.TextColor.g, self.TextColor.b, self.TextColor.a, UIFont.Small, false)
			self.labelSleepSystemBarName:setTooltip(getText("Sandbox_ETW_SleepSystem_tooltip"))
			self:addChild(self.labelSleepSystemBarName)

			self.barSleepSystem = ISGradientBar:new(barStartPosition, y, barLength, FONT_HGT_SMALL)
			self.barSleepSystem:setGradientTexture(redYellowGreenGradient)
			self.barSleepSystem:setHighlightRadius(highlightRadius)
			self.barSleepSystem:setDoKnob(false)
			self:addChild(self.barSleepSystem)

			y = y + FONT_HGT_SMALL
		end

		if ETWCommonLogicChecks.RainSystemShouldExecute() then
			str = "+/- " .. getText("UI_trait_Pluviophobia")
			self.labelPluviophobia = ISLabel:new(barOneFourthPosition - strLen(textManager, str)/2, y, FONT_HGT_SMALL, str, self.DimmedTextColor.r, self.DimmedTextColor.g, self.DimmedTextColor.b, self.DimmedTextColor.a, UIFont.Small, true)
			self.labelPluviophobia:setTooltip(getText("UI_ETW_GainLoseTooltip"))
			self:addChild(self.labelPluviophobia)

			str = "+/- " .. getText("UI_trait_Pluviophile")
			self.labelPluviophile = ISLabel:new(barThreeFourthPosition - strLen(textManager, str)/2, y, FONT_HGT_SMALL, str, self.DimmedTextColor.r, self.DimmedTextColor.g, self.DimmedTextColor.b, self.DimmedTextColor.a, UIFont.Small, true)
			self.labelPluviophile:setTooltip(getText("UI_ETW_GainLoseTooltip"))
			self:addChild(self.labelPluviophile)

			y = y + FONT_HGT_SMALL

			self.labelRainSystemBarName = ISLabel:new(barStartPosition - lineStartPosition, y, FONT_HGT_SMALL, getText("Sandbox_ETW_RainSystem"), self.TextColor.r, self.TextColor.g, self.TextColor.b, self.TextColor.a, UIFont.Small, false)
			self.labelRainSystemBarName:setTooltip(getText("Sandbox_ETW_RainSystemCounter_tooltip"))
			self:addChild(self.labelRainSystemBarName)

			self.barRainSystem = ISGradientBar:new(barStartPosition, y, barLength, FONT_HGT_SMALL)
			self.barRainSystem:setGradientTexture(redYellowGreenGradient)
			self.barRainSystem:setHighlightRadius(highlightRadius)
			self.barRainSystem:setDoKnob(false)
			self:addChild(self.barRainSystem)

			y = y + FONT_HGT_SMALL
		end

		if ETWCommonLogicChecks.FogSystemShouldExecute() then
			str = "+/- " .. getText("UI_trait_Homichlophobia")
			self.labelHomichlophobia = ISLabel:new(barOneFourthPosition - strLen(textManager, str)/2, y, FONT_HGT_SMALL, str, self.DimmedTextColor.r, self.DimmedTextColor.g, self.DimmedTextColor.b, self.DimmedTextColor.a, UIFont.Small, true)
			self.labelHomichlophobia:setTooltip(getText("UI_ETW_GainLoseTooltip"))
			self:addChild(self.labelHomichlophobia)

			str = "+/- " .. getText("UI_trait_Homichlophile")
			self.labelHomichlophile = ISLabel:new(barThreeFourthPosition - strLen(textManager, str)/2, y, FONT_HGT_SMALL, str, self.DimmedTextColor.r, self.DimmedTextColor.g, self.DimmedTextColor.b, self.DimmedTextColor.a, UIFont.Small, true)
			self.labelHomichlophile:setTooltip(getText("UI_ETW_GainLoseTooltip"))
			self:addChild(self.labelHomichlophile)

			y = y + FONT_HGT_SMALL

			self.labelFogSystemBarName = ISLabel:new(barStartPosition - lineStartPosition, y, FONT_HGT_SMALL, getText("Sandbox_ETW_FogSystem"), self.TextColor.r, self.TextColor.g, self.TextColor.b, self.TextColor.a, UIFont.Small, false)
			self.labelFogSystemBarName:setTooltip(getText("Sandbox_ETW_FogSystemCounter_tooltip"))
			self:addChild(self.labelFogSystemBarName)

			self.barFogSystem = ISGradientBar:new(barStartPosition, y, barLength, FONT_HGT_SMALL)
			self.barFogSystem:setGradientTexture(redYellowGreenGradient)
			self.barFogSystem:setHighlightRadius(highlightRadius)
			self.barFogSystem:setDoKnob(false)
			self:addChild(self.barFogSystem)

			y = y + FONT_HGT_SMALL
		end

		if ETWCommonLogicChecks.InventoryTransferSystemShouldExecute() then
			y = y + FONT_HGT_SMALL / 2

			local weightTransferred = (modData and modData.TransferSystem and modData.TransferSystem.WeightTransferred) or 0;
			local targetWeight = (player:HasTrait("butterfingers") and SBvars.InventoryTransferSystemWeight * 1.5) or SBvars.InventoryTransferSystemWeight;
			if weightTransferred < targetWeight then
				str = "- " .. getText("UI_trait_AllThumbs")
				local labelX = barOneThirdPosition - strLen(textManager, str)/2
				if player:HasTrait("butterfingers") then
					labelX = barStartPosition + barLength * 0.66 * 0.33 - strLen(textManager, str)/2
				end
				self.labelAllThumbsWeightLose = ISLabel:new(labelX, y, FONT_HGT_SMALL, str, self.DimmedTextColor.r, self.DimmedTextColor.g, self.DimmedTextColor.b, self.DimmedTextColor.a, UIFont.Small, true)
				self.labelAllThumbsWeightLose:setTooltip(getText("UI_ETW_LooseTooltip"))
				self:addChild(self.labelAllThumbsWeightLose)

				str = "- " .. getText("UI_trait_Disorganized")
				labelX = barTwoThirdPosition - strLen(textManager, str)/2
				if player:HasTrait("butterfingers") then
					labelX = barStartPosition + barLength * 0.66 * 0.66 - strLen(textManager, str)/2
				end
				self.labelDisorganizedWeightLose = ISLabel:new(labelX, y, FONT_HGT_SMALL, str, self.DimmedTextColor.r, self.DimmedTextColor.g, self.DimmedTextColor.b, self.DimmedTextColor.a, UIFont.Small, true)
				self.labelDisorganizedWeightLose:setTooltip(getText("UI_ETW_LooseTooltip"))
				self:addChild(self.labelDisorganizedWeightLose)

				if player:HasTrait("butterfingers") then
					str = "- " .. getText("UI_trait_butterfingers")
					self.labelButterfingersWeightLose = ISLabel:new(barEndPosition, y, FONT_HGT_SMALL, str, self.DimmedTextColor.r, self.DimmedTextColor.g, self.DimmedTextColor.b, self.DimmedTextColor.a, UIFont.Small, false)
					self.labelButterfingersWeightLose:setTooltip(getText("UI_ETW_LooseTooltip"))
					self:addChild(self.labelButterfingersWeightLose)
				end

				y = y + FONT_HGT_SMALL

				self.labelInventoryTransferSystemWeightBarName = ISLabel:new(barStartPosition - lineStartPosition, y, FONT_HGT_SMALL, getText("Sandbox_ETW_InventoryTransferSystemWeight"), self.TextColor.r, self.TextColor.g, self.TextColor.b, self.TextColor.a, UIFont.Small, false)
				self.labelInventoryTransferSystemWeightBarName:setTooltip(getText("Sandbox_ETW_InventoryTransferSystemWeight_tooltip"))
				self:addChild(self.labelInventoryTransferSystemWeightBarName)

				self.barInventoryTransferSystemWeight = ISGradientBar:new(barStartPosition, y, barLength, FONT_HGT_SMALL)
				self.barInventoryTransferSystemWeight:setGradientTexture(redYellowGreenGradient)
				self.barInventoryTransferSystemWeight:setHighlightRadius(highlightRadius)
				self.barInventoryTransferSystemWeight:setDoKnob(false)
				self:addChild(self.barInventoryTransferSystemWeight)

				y = y + FONT_HGT_SMALL

				str = "+ " .. getText("UI_trait_Dexterous")
				labelX = barTwoThirdPosition - strLen(textManager, str)/2
				if player:HasTrait("butterfingers") then
					labelX = barStartPosition + barLength * 0.66 * 0.66 - strLen(textManager, str)/2
				end
				self.labelDexterousWeightGain = ISLabel:new(labelX, y, FONT_HGT_SMALL, str, self.DimmedTextColor.r, self.DimmedTextColor.g, self.DimmedTextColor.b, self.DimmedTextColor.a, UIFont.Small, true)
				self.labelDexterousWeightGain:setTooltip(getText("UI_ETW_GainTooltip"))
				self:addChild(self.labelDexterousWeightGain)

				-- UI_trait_Packmule is internal string name
				str = "+ " .. getText("UI_trait_Packmule")
				labelX = barEndPosition
				if player:HasTrait("butterfingers") then
					labelX = barStartPosition + barLength * 0.66 - strLen(textManager, str)/2
					self.labelPackmuleWeightGain = ISLabel:new(labelX, y, FONT_HGT_SMALL, str, self.DimmedTextColor.r, self.DimmedTextColor.g, self.DimmedTextColor.b, self.DimmedTextColor.a, UIFont.Small, true)
				else
					self.labelPackmuleWeightGain = ISLabel:new(labelX, y, FONT_HGT_SMALL, str, self.DimmedTextColor.r, self.DimmedTextColor.g, self.DimmedTextColor.b, self.DimmedTextColor.a, UIFont.Small, false)
				end
				self.labelPackmuleWeightGain:setTooltip(getText("UI_ETW_GainTooltip"))
				self:addChild(self.labelPackmuleWeightGain)
				y = y + FONT_HGT_SMALL
			end

			local itemsTransferred = (modData and modData.TransferSystem and modData.TransferSystem.ItemsTransferred) or 0;
			local targetItems = (player:HasTrait("butterfingers") and SBvars.InventoryTransferSystemItems * 1.5) or SBvars.InventoryTransferSystemItems;
			if itemsTransferred < targetItems then
				str = "- " .. getText("UI_trait_Disorganized")
				local labelX = barOneThirdPosition - strLen(textManager, str)/2
				if player:HasTrait("butterfingers") then
					labelX = barStartPosition + barLength * 0.66 * 0.33 - strLen(textManager, str)/2
				end
				self.labelDisorganizedItemsLose = ISLabel:new(labelX, y, FONT_HGT_SMALL, str, self.DimmedTextColor.r, self.DimmedTextColor.g, self.DimmedTextColor.b, self.DimmedTextColor.a, UIFont.Small, true)
				self.labelDisorganizedItemsLose:setTooltip(getText("UI_ETW_LooseTooltip"))
				self:addChild(self.labelDisorganizedItemsLose)

				str = "- " .. getText("UI_trait_AllThumbs")
				labelX = barTwoThirdPosition - strLen(textManager, str)/2
				if player:HasTrait("butterfingers") then
					labelX = barStartPosition + barLength * 0.66 * 0.66 - strLen(textManager, str)/2
				end
				self.labelAllThumbsItemsLose = ISLabel:new(labelX, y, FONT_HGT_SMALL, str, self.DimmedTextColor.r, self.DimmedTextColor.g, self.DimmedTextColor.b, self.DimmedTextColor.a, UIFont.Small, true)
				self.labelAllThumbsItemsLose:setTooltip(getText("UI_ETW_LooseTooltip"))
				self:addChild(self.labelAllThumbsItemsLose)

				if player:HasTrait("butterfingers") then
					str = "- " .. getText("UI_trait_butterfingers")
					self.labelButterfingersItemsLose = ISLabel:new(barEndPosition, y, FONT_HGT_SMALL, str, self.DimmedTextColor.r, self.DimmedTextColor.g, self.DimmedTextColor.b, self.DimmedTextColor.a, UIFont.Small, false)
					self.labelButterfingersItemsLose:setTooltip(getText("UI_ETW_LooseTooltip"))
					self:addChild(self.labelButterfingersItemsLose)
				end

				y = y + FONT_HGT_SMALL

				self.labelInventoryTransferSystemItemsBarName = ISLabel:new(barStartPosition - lineStartPosition, y, FONT_HGT_SMALL, getText("Sandbox_ETW_InventoryTransferSystemItems"), self.TextColor.r, self.TextColor.g, self.TextColor.b, self.TextColor.a, UIFont.Small, false)
				self.labelInventoryTransferSystemItemsBarName:setTooltip(getText("Sandbox_ETW_InventoryTransferSystemItems_tooltip"))
				self:addChild(self.labelInventoryTransferSystemItemsBarName)

				self.barInventoryTransferSystemItems = ISGradientBar:new(barStartPosition, y, barLength, FONT_HGT_SMALL)
				self.barInventoryTransferSystemItems:setGradientTexture(redYellowGreenGradient)
				self.barInventoryTransferSystemItems:setHighlightRadius(highlightRadius)
				self.barInventoryTransferSystemItems:setDoKnob(false)
				self:addChild(self.barInventoryTransferSystemItems)

				y = y + FONT_HGT_SMALL

				str = "+ " .. getText("UI_trait_Packmule")
				labelX = barTwoThirdPosition - strLen(textManager, str)/2
				if player:HasTrait("butterfingers") then
					labelX = barStartPosition + barLength * 0.66 * 0.66 - strLen(textManager, str)/2
				end
				self.labelPackmuleItemsGain = ISLabel:new(labelX, y, FONT_HGT_SMALL, str, self.DimmedTextColor.r, self.DimmedTextColor.g, self.DimmedTextColor.b, self.DimmedTextColor.a, UIFont.Small, true)
				self.labelPackmuleItemsGain:setTooltip(getText("UI_ETW_GainTooltip"))
				self:addChild(self.labelPackmuleItemsGain)

				-- UI_trait_Packmule is internal string name
				str = "+ " .. getText("UI_trait_Dexterous")
				labelX = barEndPosition
				if player:HasTrait("butterfingers") then
					labelX = barStartPosition + barLength * 0.66 - strLen(textManager, str)/2
					self.labelDexterousItemsGain = ISLabel:new(labelX, y, FONT_HGT_SMALL, str, self.DimmedTextColor.r, self.DimmedTextColor.g, self.DimmedTextColor.b, self.DimmedTextColor.a, UIFont.Small, true)
				else
					self.labelDexterousItemsGain = ISLabel:new(labelX, y, FONT_HGT_SMALL, str, self.DimmedTextColor.r, self.DimmedTextColor.g, self.DimmedTextColor.b, self.DimmedTextColor.a, UIFont.Small, false)
				end
				self.labelDexterousItemsGain:setTooltip(getText("UI_ETW_GainTooltip"))
				self:addChild(self.labelDexterousItemsGain)
				y = y + FONT_HGT_SMALL
			end

			y = y + FONT_HGT_SMALL / 2
		end

		if ETWCommonLogicChecks.BraverySystemShouldExecute() then
			str = "- " .. getText("UI_trait_cowardly")
			self.labelCowardlyLose = ISLabel:new(barStartPosition + (barLength / 6) - strLen(textManager, str)/2, y, FONT_HGT_SMALL, str, self.DimmedTextColor.r, self.DimmedTextColor.g, self.DimmedTextColor.b, self.DimmedTextColor.a, UIFont.Small, true)
			self.labelCowardlyLose:setTooltip(getText("UI_ETW_LooseTooltip"))
			self:addChild(self.labelCowardlyLose)

			str = "- " .. getText("UI_trait_Pacifist")
			self.labelPacifistLose = ISLabel:new(barStartPosition + (barLength / 6) * 3 - strLen(textManager, str)/2, y, FONT_HGT_SMALL, str, self.DimmedTextColor.r, self.DimmedTextColor.g, self.DimmedTextColor.b, self.DimmedTextColor.a, UIFont.Small, true)
			self.labelPacifistLose:setTooltip(getText("UI_ETW_LooseTooltip"))
			self:addChild(self.labelPacifistLose)

			str = "+ " .. getText("UI_trait_brave")
			self.labelBraveryGain = ISLabel:new(barStartPosition + (barLength / 6) * 5 - strLen(textManager, str)/2, y, FONT_HGT_SMALL, str, self.DimmedTextColor.r, self.DimmedTextColor.g, self.DimmedTextColor.b, self.DimmedTextColor.a, UIFont.Small, true)
			self.labelBraveryGain:setTooltip(getText("Sandbox_ETW_BraverySystemKills_tooltip"))
			self:addChild(self.labelBraveryGain)

			y = y + FONT_HGT_SMALL

			self.labelBraveryBarName = ISLabel:new(barStartPosition - lineStartPosition, y, FONT_HGT_SMALL, getText("Sandbox_ETW_BraverySystem"), self.TextColor.r, self.TextColor.g, self.TextColor.b, self.TextColor.a, UIFont.Small, false)
			self.labelBraveryBarName:setTooltip(getText("UI_ETW_GainTooltip"))
			self:addChild(self.labelBraveryBarName)

			self.barBravery = ISGradientBar:new(barStartPosition, y, barLength, FONT_HGT_SMALL)
			self.barBravery:setGradientTexture(redYellowGreenGradient)
			self.barBravery:setValue(1)
			self.barBravery:setHighlightRadius(highlightRadius)
			self.barBravery:setDoKnob(false)
			self:addChild(self.barBravery)

			y = y + FONT_HGT_SMALL

			str = "- " .. getText("UI_trait_Hemophobic")
			self.labelHemophobicLose = ISLabel:new(barStartPosition + (barLength / 6) * 2 - strLen(textManager, str)/2, y, FONT_HGT_SMALL, str, self.DimmedTextColor.r, self.DimmedTextColor.g, self.DimmedTextColor.b, self.DimmedTextColor.a, UIFont.Small, true)
			self.labelHemophobicLose:setTooltip(getText("UI_ETW_LooseTooltip"))
			self:addChild(self.labelHemophobicLose)

			str = "+ " .. getText("UI_trait_AdrenalineJunkie")
			self.labelAdrenalineJunkieGain = ISLabel:new(barStartPosition + (barLength / 6) * 4 - strLen(textManager, str)/2, y, FONT_HGT_SMALL, str, self.DimmedTextColor.r, self.DimmedTextColor.g, self.DimmedTextColor.b, self.DimmedTextColor.a, UIFont.Small, true)
			self.labelAdrenalineJunkieGain:setTooltip(getText("UI_ETW_GainTooltip"))
			self:addChild(self.labelAdrenalineJunkieGain)

			self.labelDesensitizedGain = ISLabel:new(barEndPosition, y, FONT_HGT_SMALL, "+ " .. getText("UI_trait_Desensitized"), self.DimmedTextColor.r, self.DimmedTextColor.g, self.DimmedTextColor.b, self.DimmedTextColor.a, UIFont.Small, false)
			self.labelDesensitizedGain:setTooltip(getText("UI_ETW_GainTooltip"))
			self:addChild(self.labelDesensitizedGain)

			y = y + FONT_HGT_SMALL
		end

		if ETWCommonLogicChecks.SmokerShouldExecute() and not MOvars.HideSmokerUI then
			y = y + FONT_HGT_SMALL / 2

			str = "- " .. getText("UI_trait_Smoker")
			self.labelSmokerLose = ISLabel:new(barOneFourthPosition - strLen(textManager, str)/2, y, FONT_HGT_SMALL, str, self.DimmedTextColor.r, self.DimmedTextColor.g, self.DimmedTextColor.b, self.DimmedTextColor.a, UIFont.Small, true)
			self.labelSmokerLose:setTooltip(getText("UI_ETW_GainTooltip"))
			self:addChild(self.labelSmokerLose)

			str = "+ " .. getText("UI_trait_Smoker")
			self.labelSmokerGain = ISLabel:new(barThreeFourthPosition - strLen(textManager, str)/2, y, FONT_HGT_SMALL, str, self.DimmedTextColor.r, self.DimmedTextColor.g, self.DimmedTextColor.b, self.DimmedTextColor.a, UIFont.Small, true)
			self.labelSmokerGain:setTooltip(getText("UI_ETW_LooseTooltip"))
			self:addChild(self.labelSmokerGain)

			y = y + FONT_HGT_SMALL

			self.labelSmokerBarName = ISLabel:new(barStartPosition - lineStartPosition, y, FONT_HGT_SMALL, getText("UI_trait_Smoker"), self.TextColor.r, self.TextColor.g, self.TextColor.b, self.TextColor.a, UIFont.Small, false)
			self.labelSmokerBarName:setTooltip(getText("Sandbox_ETW_SmokerCounter_tooltip"))
			self:addChild(self.labelSmokerBarName)

			self.barSmokerSystem = ISGradientBar:new(barStartPosition, y, barLength, FONT_HGT_SMALL)
			self.barSmokerSystem:setGradientTexture(greenYellowRedGradient)
			self.barSmokerSystem:setHighlightRadius(highlightRadius)
			self.barSmokerSystem:setDoKnob(false)
			self:addChild(self.barSmokerSystem)
		end

		y = y + FONT_HGT_SMALL * 1.5

		if ETWCommonLogicChecks.EagleEyedShouldExecute() then
			arrangeColumnsInTable();
			self.labelEagleEyedProgress = ISLabel:new(x, y, FONT_HGT_SMALL, "", self.TextColor.r, self.TextColor.g, self.TextColor.b, self.TextColor.a, UIFont.Small, true)
			self.labelEagleEyedProgress:setTooltip(getText("Sandbox_ETW_EagleEyedKills"))
			self:addChild(self.labelEagleEyedProgress)
		end

		if ETWCommonLogicChecks.HoarderShouldExecute() then
			arrangeColumnsInTable();
			self.labelHoarderProgress = ISLabel:new(x, y, FONT_HGT_SMALL, "", self.TextColor.r, self.TextColor.g, self.TextColor.b, self.TextColor.a, UIFont.Small, true)
			self.labelHoarderProgress:setTooltip(getText("Sandbox_ETW_HoarderSkill"))
			self:addChild(self.labelHoarderProgress)
		end

		if ETWCommonLogicChecks.GymRatShouldExecute() then
			arrangeColumnsInTable();
			self.labelGymRatProgress = ISLabel:new(x, y, FONT_HGT_SMALL, "", self.TextColor.r, self.TextColor.g, self.TextColor.b, self.TextColor.a, UIFont.Small, true)
			self.labelGymRatProgress:setTooltip(getText("Sandbox_ETW_GymRatSkill_tooltip"))
			self:addChild(self.labelGymRatProgress)
		end

		if ETWCommonLogicChecks.RunnerShouldExecute() then
			arrangeColumnsInTable();
			self.labelRunnerProgress = ISLabel:new(x, y, FONT_HGT_SMALL, "", self.TextColor.r, self.TextColor.g, self.TextColor.b, self.TextColor.a, UIFont.Small, true)
			self.labelRunnerProgress:setTooltip(getText("Sandbox_ETW_RunnerSkill"))
			self:addChild(self.labelRunnerProgress)
		end

		if ETWCommonLogicChecks.LightStepShouldExecute() then
			arrangeColumnsInTable();
			self.labelLightStepProgress = ISLabel:new(x, y, FONT_HGT_SMALL, "", self.TextColor.r, self.TextColor.g, self.TextColor.b, self.TextColor.a, UIFont.Small, true)
			self.labelLightStepProgress:setTooltip(getText("Sandbox_ETW_LightStepSkill"))
			self:addChild(self.labelLightStepProgress)
		end

		if ETWCommonLogicChecks.GymnastShouldExecute() then
			arrangeColumnsInTable();
			self.labelGymnastProgress = ISLabel:new(x, y, FONT_HGT_SMALL, getText(""), self.TextColor.r, self.TextColor.g, self.TextColor.b, self.TextColor.a, UIFont.Small, true)
			self.labelGymnastProgress:setTooltip(getText("Sandbox_ETW_GymnastSkill_tooltip"))
			self:addChild(self.labelGymnastProgress)
		end

		if ETWCommonLogicChecks.ClumsyShouldExecute() then
			arrangeColumnsInTable();
			self.labelClumsyProgress = ISLabel:new(x, y, FONT_HGT_SMALL, getText(""), self.TextColor.r, self.TextColor.g, self.TextColor.b, self.TextColor.a, UIFont.Small, true)
			self.labelClumsyProgress:setTooltip(getText("Sandbox_ETW_ClumsySkill_tooltip"))
			self:addChild(self.labelClumsyProgress)
		end

		if ETWCommonLogicChecks.GracefulShouldExecute() then
			arrangeColumnsInTable();
			self.labelGracefulProgress = ISLabel:new(x, y, FONT_HGT_SMALL, getText(""), self.TextColor.r, self.TextColor.g, self.TextColor.b, self.TextColor.a, UIFont.Small, true)
			self.labelGracefulProgress:setTooltip(getText("Sandbox_ETW_GracefulSkill_tooltip"))
			self:addChild(self.labelGracefulProgress)
		end

		if ETWCommonLogicChecks.BurglarShouldExecute() then
			arrangeColumnsInTable();
			self.labelBurglarProgress = ISLabel:new(x, y, FONT_HGT_SMALL, getText(""), self.TextColor.r, self.TextColor.g, self.TextColor.b, self.TextColor.a, UIFont.Small, true)
			self.labelBurglarProgress:setTooltip(getText("Sandbox_ETW_BurglarSkill_tooltip"))
			self:addChild(self.labelBurglarProgress)
		end

		if ETWCommonLogicChecks.LowProfileShouldExecute() then
			arrangeColumnsInTable();
			self.labelLowProfileProgress = ISLabel:new(x, y, FONT_HGT_SMALL, getText(""), self.TextColor.r, self.TextColor.g, self.TextColor.b, self.TextColor.a, UIFont.Small, true)
			self.labelLowProfileProgress:setTooltip(getText("Sandbox_ETW_LowProfileSkill"))
			self:addChild(self.labelLowProfileProgress)
		end

		if ETWCommonLogicChecks.ConspicuousShouldExecute() then
			arrangeColumnsInTable();
			self.labelConspicuousProgress = ISLabel:new(x, y, FONT_HGT_SMALL, getText(""), self.TextColor.r, self.TextColor.g, self.TextColor.b, self.TextColor.a, UIFont.Small, true)
			self.labelConspicuousProgress:setTooltip(getText("Sandbox_ETW_ConspicuousSkill"))
			self:addChild(self.labelConspicuousProgress)
		end

		if ETWCommonLogicChecks.InconspicuousShouldExecute() then
			arrangeColumnsInTable();
			self.labelInconspicuousProgress = ISLabel:new(x, y, FONT_HGT_SMALL, getText(""), self.TextColor.r, self.TextColor.g, self.TextColor.b, self.TextColor.a, UIFont.Small, true)
			self.labelInconspicuousProgress:setTooltip(getText("Sandbox_ETW_InconspicuousSkill"))
			self:addChild(self.labelInconspicuousProgress)
		end

		if ETWCommonLogicChecks.HunterShouldExecute() then
			local levels = sneaking + aiming + trapping + shortBlade;
			if sneaking < 2 or aiming < 2 or trapping < 2 or shortBlade < 2 or levels < SBvars.HunterSkill then
				arrangeColumnsInTable();
				self.labelHunterSkillProgress = ISLabel:new(x, y, FONT_HGT_SMALL, getText(""), self.TextColor.r, self.TextColor.g, self.TextColor.b, self.TextColor.a, UIFont.Small, true)
				self.labelHunterSkillProgress:setTooltip(getText("Sandbox_ETW_HunterSkill_tooltip"))
				self:addChild(self.labelHunterSkillProgress)
			end
			if (shortBladeKills + firearmKills) < SBvars.HunterKills then
				arrangeColumnsInTable();
				self.labelHunterKillsProgress = ISLabel:new(x, y, FONT_HGT_SMALL, getText(""), self.TextColor.r, self.TextColor.g, self.TextColor.b, self.TextColor.a, UIFont.Small, true)
				self.labelHunterKillsProgress:setTooltip(getText("Sandbox_ETW_HunterKills") .. " (" .. getText("Sandbox_ETW_HunterKills_tooltip").. ")")
				self:addChild(self.labelHunterKillsProgress)
			end
		end

		if ETWCommonLogicChecks.BrawlerShouldExecute() then
			if (axe + longBlunt) < SBvars.BrawlerSkill then
				arrangeColumnsInTable();
				self.labelBrawlerSkillProgress = ISLabel:new(x, y, FONT_HGT_SMALL, getText(""), self.TextColor.r, self.TextColor.g, self.TextColor.b, self.TextColor.a, UIFont.Small, true)
				self.labelBrawlerSkillProgress:setTooltip(getText("Sandbox_ETW_BrawlerSkill_tooltip"))
				self:addChild(self.labelBrawlerSkillProgress)
			end

			if (axeKills + longBluntKills) < SBvars.BrawlerKills then
				arrangeColumnsInTable();
				self.labelBrawlerKillsProgress = ISLabel:new(x, y, FONT_HGT_SMALL, getText(""), self.TextColor.r, self.TextColor.g, self.TextColor.b, self.TextColor.a, UIFont.Small, true)
				self.labelBrawlerKillsProgress:setTooltip(getText("Sandbox_ETW_BrawlerKills") .. " (" .. getText("Sandbox_ETW_BrawlerKills_tooltip").. ")")
				self:addChild(self.labelBrawlerKillsProgress)
			end
		end

		if ETWCommonLogicChecks.AxeThrowerShouldExecute() then
			if axe < SBvars.AxeThrowerSkill then
				arrangeColumnsInTable();
				self.labelAxeThrowerSkillProgress = ISLabel:new(x, y, FONT_HGT_SMALL, getText(""), self.TextColor.r, self.TextColor.g, self.TextColor.b, self.TextColor.a, UIFont.Small, true)
				self.labelAxeThrowerSkillProgress:setTooltip(getText("Sandbox_ETW_AxeThrowerSkill"))
				self:addChild(self.labelAxeThrowerSkillProgress)
			end
			if axeKills < SBvars.AxeThrowerKills then
				arrangeColumnsInTable();
				self.labelAxeThrowerKillsProgress = ISLabel:new(x, y, FONT_HGT_SMALL, getText(""), self.TextColor.r, self.TextColor.g, self.TextColor.b, self.TextColor.a, UIFont.Small, true)
				self.labelAxeThrowerKillsProgress:setTooltip(getText("Sandbox_ETW_AxeThrowerKills"))
				self:addChild(self.labelAxeThrowerKillsProgress)
			end
		end

		if ETWCommonLogicChecks.StickFighterShouldExecute() then
			if shortBlunt < SBvars.StickFighterSkill then
				arrangeColumnsInTable();
				self.labelStickFighterSkillProgress = ISLabel:new(x, y, FONT_HGT_SMALL, getText(""), self.TextColor.r, self.TextColor.g, self.TextColor.b, self.TextColor.a, UIFont.Small, true)
				self.labelStickFighterSkillProgress:setTooltip(getText("Sandbox_ETW_StickFighterSkill"))
				self:addChild(self.labelStickFighterSkillProgress)
			end
			if shortBluntKills < SBvars.StickFighterKills then
				arrangeColumnsInTable();
				self.labelStickFighterKillsProgress = ISLabel:new(x, y, FONT_HGT_SMALL, getText(""), self.TextColor.r, self.TextColor.g, self.TextColor.b, self.TextColor.a, UIFont.Small, true)
				self.labelStickFighterKillsProgress:setTooltip(getText("Sandbox_ETW_StickFighterKills"))
				self:addChild(self.labelStickFighterKillsProgress)
			end
		end

		if ETWCommonLogicChecks.KenshiShouldExecute() then
			if longBlade < SBvars.KenshiSkill then
				arrangeColumnsInTable();
				self.labelKenshiSkillProgress = ISLabel:new(x, y, FONT_HGT_SMALL, getText(""), self.TextColor.r, self.TextColor.g, self.TextColor.b, self.TextColor.a, UIFont.Small, true)
				self.labelKenshiSkillProgress:setTooltip(getText("Sandbox_ETW_KenshiSkill"))
				self:addChild(self.labelKenshiSkillProgress)
			end
			if longBladeKills < SBvars.KenshiKills then
				arrangeColumnsInTable();
				self.labelKenshiKillsProgress = ISLabel:new(x, y, FONT_HGT_SMALL, getText(""), self.TextColor.r, self.TextColor.g, self.TextColor.b, self.TextColor.a, UIFont.Small, true)
				self.labelKenshiKillsProgress:setTooltip(getText("Sandbox_ETW_KenshiKills"))
				self:addChild(self.labelKenshiKillsProgress)
			end
		end

		if ETWCommonLogicChecks.KnifeFighterShouldExecute() then
			if shortBlade < SBvars.KnifeFighterSkill then
				arrangeColumnsInTable();
				self.labelKnifeFighterSkillProgress = ISLabel:new(x, y, FONT_HGT_SMALL, getText(""), self.TextColor.r, self.TextColor.g, self.TextColor.b, self.TextColor.a, UIFont.Small, true)
				self.labelKnifeFighterSkillProgress:setTooltip(getText("Sandbox_ETW_KenshiSkill"))
				self:addChild(self.labelKnifeFighterSkillProgress)
			end
			if shortBladeKills < SBvars.KnifeFighterKills then
				arrangeColumnsInTable();
				self.labelKnifeFighterKillsProgress = ISLabel:new(x, y, FONT_HGT_SMALL, getText(""), self.TextColor.r, self.TextColor.g, self.TextColor.b, self.TextColor.a, UIFont.Small, true)
				self.labelKnifeFighterKillsProgress:setTooltip(getText("Sandbox_ETW_KenshiKills"))
				self:addChild(self.labelKnifeFighterKillsProgress)
			end
		end

		if ETWCommonLogicChecks.SojutsuShouldExecute() then
			if spear < SBvars.SojutsuSkill then
				arrangeColumnsInTable();
				self.labelSojutsuSkillProgress = ISLabel:new(x, y, FONT_HGT_SMALL, getText(""), self.TextColor.r, self.TextColor.g, self.TextColor.b, self.TextColor.a, UIFont.Small, true)
				self.labelSojutsuSkillProgress:setTooltip(getText("Sandbox_ETW_SojutsuSkill"))
				self:addChild(self.labelSojutsuSkillProgress)
			end
			if spearKills < SBvars.SojutsuKills then
				arrangeColumnsInTable();
				self.labelSojutsuKillsProgress = ISLabel:new(x, y, FONT_HGT_SMALL, getText(""), self.TextColor.r, self.TextColor.g, self.TextColor.b, self.TextColor.a, UIFont.Small, true)
				self.labelSojutsuKillsProgress:setTooltip(getText("Sandbox_ETW_SojutsuKills"))
				self:addChild(self.labelSojutsuKillsProgress)
			end
		end

		if ETWCommonLogicChecks.RestorationExpertShouldExecute() then
			arrangeColumnsInTable();
			self.labelRestorationExpertSkillProgress = ISLabel:new(x, y, FONT_HGT_SMALL, getText(""), self.TextColor.r, self.TextColor.g, self.TextColor.b, self.TextColor.a, UIFont.Small, true)
			self.labelRestorationExpertSkillProgress:setTooltip(getText("Sandbox_ETW_RestorationExpertSkill"))
			self:addChild(self.labelRestorationExpertSkillProgress)
		end

		if ETWCommonLogicChecks.HandyShouldExecute() then
			arrangeColumnsInTable();
			self.labelHandySkillProgress = ISLabel:new(x, y, FONT_HGT_SMALL, getText(""), self.TextColor.r, self.TextColor.g, self.TextColor.b, self.TextColor.a, UIFont.Small, true)
			self.labelHandySkillProgress:setTooltip(getText("Sandbox_ETW_HandySkill_tooltip"))
			self:addChild(self.labelHandySkillProgress)
		end

		if ETWCommonLogicChecks.FurnitureAssemblerShouldExecute() then
			arrangeColumnsInTable();
			self.labelFurnitureAssemblerProgress = ISLabel:new(x, y, FONT_HGT_SMALL, getText(""), self.TextColor.r, self.TextColor.g, self.TextColor.b, self.TextColor.a, UIFont.Small, true)
			self.labelFurnitureAssemblerProgress:setTooltip(getText("Sandbox_ETW_FurnitureAssemblerSkill"))
			self:addChild(self.labelFurnitureAssemblerProgress)
		end

		if ETWCommonLogicChecks.HomeCookShouldExecute() then
			arrangeColumnsInTable();
			self.labelHomeCookProgress = ISLabel:new(x, y, FONT_HGT_SMALL, getText(""), self.TextColor.r, self.TextColor.g, self.TextColor.b, self.TextColor.a, UIFont.Small, true)
			self.labelHomeCookProgress:setTooltip(getText("Sandbox_ETW_HomeCookSkill"))
			self:addChild(self.labelHomeCookProgress)
		end

		if ETWCommonLogicChecks.CookShouldExecute() then
			arrangeColumnsInTable();
			self.labelCookProgress = ISLabel:new(x, y, FONT_HGT_SMALL, getText(""), self.TextColor.r, self.TextColor.g, self.TextColor.b, self.TextColor.a, UIFont.Small, true)
			self.labelCookProgress:setTooltip(getText("Sandbox_ETW_CookSkill"))
			self:addChild(self.labelCookProgress)
		end

		if ETWCommonLogicChecks.FirstAidShouldExecute() then
			arrangeColumnsInTable();
			self.labelFirstAidProgress = ISLabel:new(x, y, FONT_HGT_SMALL, getText(""), self.TextColor.r, self.TextColor.g, self.TextColor.b, self.TextColor.a, UIFont.Small, true)
			self.labelFirstAidProgress:setTooltip(getText("Sandbox_ETW_FirstAidSkill"))
			self:addChild(self.labelFirstAidProgress)
		end

		if ETWCommonLogicChecks.AVClubShouldExecute() then
			arrangeColumnsInTable();
			self.labelAVClubProgress = ISLabel:new(x, y, FONT_HGT_SMALL, getText(""), self.TextColor.r, self.TextColor.g, self.TextColor.b, self.TextColor.a, UIFont.Small, true)
			self.labelAVClubProgress:setTooltip(getText("Sandbox_ETW_AVClubSkill"))
			self:addChild(self.labelAVClubProgress)
		end

		if ETWCommonLogicChecks.BodyWorkEnthusiastShouldExecute() then
			if metalworking + mechanics < SBvars.BodyworkEnthusiastSkill then
				arrangeColumnsInTable();
				self.labelBodyWorkEnthusiastSkillProgress = ISLabel:new(x, y, FONT_HGT_SMALL, getText(""), self.TextColor.r, self.TextColor.g, self.TextColor.b, self.TextColor.a, UIFont.Small, true)
				self.labelBodyWorkEnthusiastSkillProgress:setTooltip(getText("Sandbox_ETW_BodyworkEnthusiastSkill_tooltip"))
				self:addChild(self.labelBodyWorkEnthusiastSkillProgress)
			end
			local vehiclePartRepairs = (modData and modData.VehiclePartRepairs) or 0;
			if vehiclePartRepairs < SBvars.BodyworkEnthusiastRepairs then
				arrangeColumnsInTable();
				self.labelBodyWorkEnthusiastRepairsProgress = ISLabel:new(x, y, FONT_HGT_SMALL, getText(""), self.TextColor.r, self.TextColor.g, self.TextColor.b, self.TextColor.a, UIFont.Small, true)
				self.labelBodyWorkEnthusiastRepairsProgress:setTooltip(getText("Sandbox_ETW_BodyworkEnthusiastRepairs_tooltip"))
				self:addChild(self.labelBodyWorkEnthusiastRepairsProgress)
			end
		end

		if ETWCommonLogicChecks.MechanicsShouldExecute() then
			if mechanics < SBvars.MechanicsSkill then
				arrangeColumnsInTable();
				self.labelMechanicsSkillProgress = ISLabel:new(x, y, FONT_HGT_SMALL, getText(""), self.TextColor.r, self.TextColor.g, self.TextColor.b, self.TextColor.a, UIFont.Small, true)
				self.labelMechanicsSkillProgress:setTooltip(getText("Sandbox_ETW_MechanicsSkill"))
				self:addChild(self.labelMechanicsSkillProgress)
			end
			local vehiclePartRepairs = (modData and modData.VehiclePartRepairs) or 0;
			if vehiclePartRepairs < SBvars.MechanicsRepairs then
				arrangeColumnsInTable();
				self.labelMechanicsRepairsProgress = ISLabel:new(x, y, FONT_HGT_SMALL, getText(""), self.TextColor.r, self.TextColor.g, self.TextColor.b, self.TextColor.a, UIFont.Small, true)
				self.labelMechanicsRepairsProgress:setTooltip(getText("Sandbox_ETW_MechanicsRepairs_tooltip"))
				self:addChild(self.labelMechanicsRepairsProgress)
			end
		end

		if ETWCommonLogicChecks.TailorShouldExecute() then
			arrangeColumnsInTable();
			self.labelTailorProgress = ISLabel:new(x, y, FONT_HGT_SMALL, getText(""), self.TextColor.r, self.TextColor.g, self.TextColor.b, self.TextColor.a, UIFont.Small, true)
			self.labelTailorProgress:setTooltip(getText("Sandbox_ETW_SewerSkill"))
			self:addChild(self.labelTailorProgress)
		end

		if ETWCommonLogicChecks.GunEnthusiastShouldExecute() then
			if aiming + reloading < SBvars.GunEnthusiastSkill then
				arrangeColumnsInTable();
				self.labelGunEnthusiastSkillProgress = ISLabel:new(x, y, FONT_HGT_SMALL, getText(""), self.TextColor.r, self.TextColor.g, self.TextColor.b, self.TextColor.a, UIFont.Small, true)
				self.labelGunEnthusiastSkillProgress:setTooltip(getText("Sandbox_ETW_GunEnthusiastSkill_tooltip"))
				self:addChild(self.labelGunEnthusiastSkillProgress)
			end

			if firearmKills < SBvars.GunEnthusiastKills then
				arrangeColumnsInTable();
				self.labelGunEnthusiastKillsProgress = ISLabel:new(x, y, FONT_HGT_SMALL, getText(""), self.TextColor.r, self.TextColor.g, self.TextColor.b, self.TextColor.a, UIFont.Small, true)
				self.labelGunEnthusiastKillsProgress:setTooltip(getText("Sandbox_ETW_GunEnthusiastKills"))
				self:addChild(self.labelGunEnthusiastKillsProgress)
			end
		end

		if ETWCommonLogicChecks.AnglerShouldExecute() then
			arrangeColumnsInTable();
			self.labelAnglerProgress = ISLabel:new(x, y, FONT_HGT_SMALL, getText(""), self.TextColor.r, self.TextColor.g, self.TextColor.b, self.TextColor.a, UIFont.Small, true)
			self.labelAnglerProgress:setTooltip(getText("Sandbox_ETW_FishingSkill"))
			self:addChild(self.labelAnglerProgress)
		end

		if ETWCommonLogicChecks.HikerShouldExecute() then
			arrangeColumnsInTable();
			self.labelHikerProgress = ISLabel:new(x, y, FONT_HGT_SMALL, getText(""), self.TextColor.r, self.TextColor.g, self.TextColor.b, self.TextColor.a, UIFont.Small, true)
			self.labelHikerProgress:setTooltip(getText("Sandbox_ETW_HikerSkill_tooltip"))
			self:addChild(self.labelHikerProgress)
		end

		if ETWCommonLogicChecks.CatEyesShouldExecute() then
			arrangeColumnsInTable();
			self.labelCatEyesProgress = ISLabel:new(x, y, FONT_HGT_SMALL, getText(""), self.TextColor.r, self.TextColor.g, self.TextColor.b, self.TextColor.a, UIFont.Small, true)
			self.labelCatEyesProgress:setTooltip(getText("Sandbox_ETW_CatEyesCounter_tooltip"))
			self:addChild(self.labelCatEyesProgress)
		end

		if ETWCommonLogicChecks.HerbalistShouldExecute() then
			arrangeColumnsInTable();
			self.labelHerbalistProgress = ISLabel:new(x, y, FONT_HGT_SMALL, getText(""), self.TextColor.r, self.TextColor.g, self.TextColor.b, self.TextColor.a, UIFont.Small, true)
			self.labelHerbalistProgress:setTooltip(getText("Sandbox_ETW_HerbalistHerbsPicked_tooltip"))
			self:addChild(self.labelHerbalistProgress)
		end

		if ETWCommonLogicChecks.AxemanShouldExecute() then
			arrangeColumnsInTable();
			self.labelAxemanProgress = ISLabel:new(x, y, FONT_HGT_SMALL, getText(""), self.TextColor.r, self.TextColor.g, self.TextColor.b, self.TextColor.a, UIFont.Small, true)
			self.labelAxemanProgress:setTooltip(getText("Sandbox_ETW_AxemanTrees_tooltip"))
			self:addChild(self.labelAxemanProgress)
		end

		if SBvars.DelayedTraitsSystem then
			y = y + FONT_HGT_SMALL
			str = getText("Sandbox_ETW_DelayedTraitsSystem")
			self.labelDelayedTraitsSystem = ISLabel:new(WINDOW_WIDTH / 2 - strLen(textManager, str)/2, y, FONT_HGT_SMALL, str, self.TextColor.r, self.TextColor.g, self.TextColor.b, self.TextColor.a, UIFont.Small, true)
			self.labelDelayedTraitsSystem:setTooltip(getText("Sandbox_ETW_DelayedTraitsSystem_tooltip"))
			self:addChild(self.labelDelayedTraitsSystem)
		end

		WINDOW_HEIGHT = y + FONT_HGT_SMALL * 2;
		WINDOW_HEIGHT_AFTER_CHILDREN = WINDOW_HEIGHT;

		x = lineStartPosition
		y = 12
		nonBarsEntryNumber = 0
	end
end

function ISETWProgressUI:prerender()
	ISPanelJoypad.prerender(self);
	self:setStencilRect(0, 0, self.width, self.height)
end

local function updateBar(bar, value, tooltip)
	if bar then
		bar:setValue(value)
		bar:setTooltip(tooltip)
	end
end

local function updateLabel(label, value)
	if label then
		label:setName(value)
	end
end

function ISETWProgressUI:render()
	self:setWidthAndParentWidth(WINDOW_WIDTH);
	self:setHeightAndParentHeight(WINDOW_HEIGHT);

	local player = getPlayer();
	local modData = ETWCommonFunctions.getETWModData(player);

	local strength = player:getPerkLevel(Perks.Strength);
	local fitness = player:getPerkLevel(Perks.Fitness);
	local sprinting = player:getPerkLevel(Perks.Sprinting);
	local lightfooted = player:getPerkLevel(Perks.Lightfoot);
	local nimble = player:getPerkLevel(Perks.Nimble);
	local sneaking = player:getPerkLevel(Perks.Sneak);
	local axe = player:getPerkLevel(Perks.Axe);
	local longBlunt = player:getPerkLevel(Perks.Blunt);
	local shortBlunt = player:getPerkLevel(Perks.SmallBlunt);
	local longBlade = player:getPerkLevel(Perks.LongBlade);
	local shortBlade = player:getPerkLevel(Perks.SmallBlade);
	local spear = player:getPerkLevel(Perks.Spear);
	local maintenance = player:getPerkLevel(Perks.Maintenance);
	local carpentry = player:getPerkLevel(Perks.Woodwork);
	local cooking = player:getPerkLevel(Perks.Cooking);
	local farming = player:getPerkLevel(Perks.Farming);
	local firstAid = player:getPerkLevel(Perks.Doctor);
	local electrical = player:getPerkLevel(Perks.Electricity);
	local metalworking = player:getPerkLevel(Perks.MetalWelding);
	local mechanics = player:getPerkLevel(Perks.Mechanics);
	local tailoring = player:getPerkLevel(Perks.Tailoring);
	local aiming = player:getPerkLevel(Perks.Aiming);
	local reloading = player:getPerkLevel(Perks.Reloading);
	local fishing = player:getPerkLevel(Perks.Fishing);
	local trapping = player:getPerkLevel(Perks.Trapping);
	local foraging = player:getPerkLevel(Perks.PlantScavenging);

	local killCountModData = player:getModData().KillCount.WeaponCategory;
	local axeKills = killCountModData["Axe"].count;
	local longBluntKills = killCountModData["Blunt"].count;
	local shortBluntKills = killCountModData["SmallBlunt"].count;
	local longBladeKills = killCountModData["LongBlade"].count;
	local shortBladeKills = killCountModData["SmallBlade"].count;
	local spearKills = killCountModData["Spear"].count;
	local firearmKills = killCountModData["Firearm"].count;

	updateBar(self.barColdIllnessSystem, percentile(0, SBvars.ColdIllnessSystemColdsWeathered, modData.ColdSystem.ColdsWeathered), modData.ColdSystem.ColdsWeathered)
	updateBar(self.barSicknessSystem, percentile(0, SBvars.FoodSicknessSystemCounter, modData.FoodSicknessWeathered), modData.FoodSicknessWeathered)
	updateBar(self.barPainTolerance, percentile(0, SBvars.PainToleranceCounter, modData.PainToleranceCounter), modData.PainToleranceCounter)
	updateBar(self.barAsthmatic, percentile(SBvars.AsthmaticCounter * -2, SBvars.AsthmaticCounter * 2, modData.AsthmaticCounter), modData.AsthmaticCounter)
	updateBar(self.barBloodlust, percentile(0, SBvars.BloodlustProgress * 2, modData.BloodlustSystem.BloodlustProgress), modData.BloodlustSystem.BloodlustProgress)
	updateBar(self.barOutdoorsman, percentile(SBvars.OutdoorsmanCounter * -2, SBvars.OutdoorsmanCounter * 2, modData.OutdoorsmanSystem.OutdoorsmanCounter), modData.OutdoorsmanSystem.OutdoorsmanCounter)
	updateBar(self.barAgoraphobic, percentile(SBvars.FearOfLocationsSystemCounter * -2, SBvars.FearOfLocationsSystemCounter * 2, modData.LocationFearSystem.FearOfOutside), modData.LocationFearSystem.FearOfOutside)
	updateBar(self.barClaustrophobic, percentile(SBvars.FearOfLocationsSystemCounter * -2, SBvars.FearOfLocationsSystemCounter * 2, modData.LocationFearSystem.FearOfInside), modData.LocationFearSystem.FearOfInside)
	if self.barLuckSystem ~= nil then
		local totalPerkLevel = 0
		local totalMaxPerkLevel = 0;
		for i = 1, Perks.getMaxIndex() - 1 do
			local selectedPerk = Perks.fromIndex(i)
			if selectedPerk:getParent():getName() ~= "None" then
				local perkLevel = player:getPerkLevel(selectedPerk)
				totalPerkLevel = totalPerkLevel + perkLevel;
				totalMaxPerkLevel = totalMaxPerkLevel + 10;
			end
		end
		local percentageOfSkillLevels = totalPerkLevel / totalMaxPerkLevel * 100;
		self.barLuckSystem:setValue(percentageOfSkillLevels / 100)
		self.barLuckSystem:setTooltip(totalPerkLevel)
	end
	local levels = sprinting + lightfooted + nimble + sneaking + axe + longBlunt + shortBlunt + longBlade + shortBlade + spear
	updateBar(self.barHearingSystem, percentile(0, SBvars.HearingSystemSkill, levels), levels)
	levels = maintenance + carpentry + farming + firstAid + electrical + metalworking + mechanics + tailoring + cooking
	updateBar(self.barLearnerSystem, percentile(0, SBvars.LearnerSystemSkill, levels), levels)
	updateBar(self.barSleepSystem, percentile(-200, 200, modData.SleepSystem.SleepHealthinessBar), modData.SleepSystem.SleepHealthinessBar)
	updateBar(self.barSmokerSystem, percentile(SBvars.SmokerCounter * -2, SBvars.SmokerCounter * 2, modData.SmokeSystem.SmokingAddiction), modData.SmokeSystem.SmokingAddiction)
	updateBar(self.barRainSystem, percentile(SBvars.RainSystemCounter * -2, SBvars.RainSystemCounter * 2, modData.RainCounter), modData.RainCounter)
	updateBar(self.barFogSystem, percentile(SBvars.FogSystemCounter * -2, SBvars.FogSystemCounter * 2, modData.FogCounter), modData.FogCounter)
	if self.barInventoryTransferSystemWeight ~= nil or self.barInventoryTransferSystemItems ~= nil then
		local heightOfBox = FONT_HGT_SMALL * 3.5
		if self.barInventoryTransferSystemWeight ~= nil and self.barInventoryTransferSystemItems ~= nil then
			heightOfBox = FONT_HGT_SMALL * 6.5
		end
		local yPosition = (self.labelAllThumbsWeightLose and self.labelAllThumbsWeightLose:getY()) or (self.labelDisorganizedItemsLose and self.labelDisorganizedItemsLose:getY())
		self:drawRectBorder(lineStartPosition, yPosition - (FONT_HGT_SMALL / 4), self:getWidth() - lineStartPosition * 1.5, heightOfBox, self.DimmedTextColor.a, self.DimmedTextColor.r, self.DimmedTextColor.g, self.DimmedTextColor.b);
	end
	if player:HasTrait("butterfingers") then
		updateBar(self.barInventoryTransferSystemWeight, percentile(0, SBvars.InventoryTransferSystemWeight * 1.5, modData.TransferSystem.WeightTransferred), modData.TransferSystem.WeightTransferred)
	else
		updateBar(self.barInventoryTransferSystemWeight, percentile(0, SBvars.InventoryTransferSystemWeight, modData.TransferSystem.WeightTransferred), modData.TransferSystem.WeightTransferred)
	end
	if player:HasTrait("butterfingers") then
		updateBar(self.barInventoryTransferSystemItems, percentile(0, SBvars.InventoryTransferSystemItems * 1.5, modData.TransferSystem.ItemsTransferred), modData.TransferSystem.ItemsTransferred)
	else
		updateBar(self.barInventoryTransferSystemItems, percentile(0, SBvars.InventoryTransferSystemItems, modData.TransferSystem.ItemsTransferred), modData.TransferSystem.ItemsTransferred)
	end

	if self.barBravery ~= nil then
		local heightOfBox = FONT_HGT_SMALL * 3.5
		self:drawRectBorder(lineStartPosition, self.labelCowardlyLose:getY() - (FONT_HGT_SMALL / 4), self:getWidth() - lineStartPosition * 1.5, heightOfBox, self.DimmedTextColor.a, self.DimmedTextColor.r, self.DimmedTextColor.g, self.DimmedTextColor.b);
	end
	if self.barBravery ~= nil then
		local totalKills = player:getZombieKills();
		local fireKills = killCountModData["Fire"].count;
		local firearmsKills = killCountModData["Firearm"].count;
		local vehiclesKills = killCountModData["Vehicles"].count;
		local explosivesKills = killCountModData["Explosives"].count;
		local meleeKills = totalKills - firearmsKills - fireKills - vehiclesKills - explosivesKills;
		self.barBravery:setValue(percentile(0, SBvars.BraverySystemKills, totalKills + meleeKills))
		self.barBravery:setTooltip(totalKills + meleeKills)
	end

	updateLabel(self.labelEagleEyedProgress, getText("UI_trait_eagleeyed") .. ": " .. modData.EagleEyedKills .. "/" .. SBvars.EagleEyedKills)
	updateLabel(self.labelHoarderProgress, getText("UI_trait_Hoarder") .. ": " .. strength .. "/" .. SBvars.HoarderSkill)
	updateLabel(self.labelGymRatProgress, getText("UI_trait_GymRat") .. ": " .. strength + fitness .. "/" .. SBvars.GymRatSkill)
	updateLabel(self.labelRunnerProgress, getText("UI_trait_Jogger") .. ": " .. sprinting .. "/" .. SBvars.RunnerSkill)
	updateLabel(self.labelLightStepProgress, getText("UI_trait_LightStep") .. ": " .. lightfooted .. "/" .. SBvars.LightStepSkill)
	updateLabel(self.labelGymnastProgress, getText("UI_trait_Gymnast") .. ": " .. lightfooted + nimble .. "/" .. SBvars.GymnastSkill)
	updateLabel(self.labelClumsyProgress, getText("UI_trait_clumsy") .. ": " .. lightfooted + sneaking .. "/" .. SBvars.ClumsySkill)
	updateLabel(self.labelGracefulProgress, getText("UI_trait_graceful") .. ": " .. lightfooted + sneaking + nimble .. "/" .. SBvars.GracefulSkill)
	updateLabel(self.labelBurglarProgress, getText("UI_prof_Burglar") .. ": " .. electrical + mechanics + nimble .. "/" .. SBvars.BurglarSkill .. " | " .. electrical .. "/2 | " .. mechanics .. "/2")
	updateLabel(self.labelLowProfileProgress, getText("UI_trait_LowProfile") .. ": " .. sneaking .. "/" .. SBvars.LowProfileSkill)
	updateLabel(self.labelConspicuousProgress, getText("UI_trait_Conspicuous") .. ": " .. sneaking .. "/" .. SBvars.ConspicuousSkill)
	updateLabel(self.labelInconspicuousProgress, getText("UI_trait_Inconspicuous") .. ": " .. sneaking .. "/" .. SBvars.InconspicuousSkill)
	updateLabel(self.labelHunterSkillProgress, getText("UI_trait_Hunter") .. ": " .. sneaking + aiming + trapping + shortBlade .. "/" .. SBvars.HunterSkill .. " | " .. sneaking .. "/2 | " .. aiming .. "/2 | " .. trapping .. "/2 | " .. shortBlade .. "/2")
	updateLabel(self.labelHunterKillsProgress, getText("UI_trait_Hunter") .. ": " .. shortBladeKills + firearmKills .. "/" .. SBvars.HunterKills)
	updateLabel(self.labelBrawlerSkillProgress, getText("UI_trait_BarFighter") .. ": " .. axe + longBlunt .. "/" .. SBvars.BrawlerSkill)
	updateLabel(self.labelBrawlerKillsProgress, getText("UI_trait_BarFighter") .. ": " .. axeKills + longBluntKills .. "/" .. SBvars.BrawlerKills)
	updateLabel(self.labelAxeThrowerSkillProgress, getText("UI_trait_AxeThrower") .. ": " .. axe .. "/" .. SBvars.AxeThrowerSkill)
	updateLabel(self.labelAxeThrowerKillsProgress, getText("UI_trait_AxeThrower") .. ": " .. axeKills .. "/" .. SBvars.AxeThrowerKills)
	updateLabel(self.labelStickFighterSkillProgress, getText("UI_trait_StickFighter") .. ": " .. shortBlunt .. "/" .. SBvars.StickFighterSkill)
	updateLabel(self.labelStickFighterKillsProgress, getText("UI_trait_StickFighter") .. ": " .. shortBluntKills .. "/" .. SBvars.StickFighterKills)
	updateLabel(self.labelKenshiSkillProgress, getText("UI_trait_Kenshi") .. ": " .. longBlade .. "/" .. SBvars.KenshiSkill)
	updateLabel(self.labelKenshiKillsProgress, getText("UI_trait_Kenshi") .. ": " .. longBladeKills .. "/" .. SBvars.KenshiKills)
	updateLabel(self.labelKnifeFighterSkillProgress, getText("UI_trait_KnifeFighter") .. ": " .. shortBlade .. "/" .. SBvars.KnifeFighterSkill)
	updateLabel(self.labelKnifeFighterKillsProgress, getText("UI_trait_KnifeFighter") .. ": " .. shortBladeKills .. "/" .. SBvars.KnifeFighterKills)
	updateLabel(self.labelSojutsuSkillProgress, getText("UI_trait_Sojutsu") .. ": " .. spear .. "/" .. SBvars.SojutsuSkill)
	updateLabel(self.labelSojutsuKillsProgress, getText("UI_trait_Sojutsu") .. ": " .. spearKills .. "/" .. SBvars.SojutsuKills)
	updateLabel(self.labelRestorationExpertSkillProgress, getText("UI_trait_RestorationExpert") .. ": " .. maintenance .. "/" .. SBvars.RestorationExpertSkill)
	updateLabel(self.labelHandySkillProgress, getText("UI_trait_handy") .. ": " .. maintenance + carpentry .. "/" .. SBvars.HandySkill)
	updateLabel(self.labelFurnitureAssemblerProgress, getText("UI_trait_FurnitureAssembler") .. ": " .. carpentry .. "/" .. SBvars.FurnitureAssemblerSkill)
	updateLabel(self.labelHomeCookProgress, getText("UI_trait_HomeCook") .. ": " .. cooking .. "/" .. SBvars.HomeCookSkill)
	updateLabel(self.labelCookProgress, getText("UI_trait_Cook") .. ": " .. cooking .. "/" .. SBvars.CookSkill)
	updateLabel(self.labelFirstAidProgress, getText("UI_trait_FirstAid") .. ": " .. firstAid .. "/" .. SBvars.FirstAidSkill)
	updateLabel(self.labelAVClubProgress, getText("UI_trait_AVClub") .. ": " .. electrical .. "/" .. SBvars.AVClubSkill)
	updateLabel(self.labelBodyWorkEnthusiastSkillProgress, getText("UI_trait_BodyWorkEnthusiast") .. ": " .. metalworking + mechanics .. "/" .. SBvars.BodyworkEnthusiastSkill)
	updateLabel(self.labelBodyWorkEnthusiastRepairsProgress, getText("UI_trait_BodyWorkEnthusiast") .. ": " .. modData.VehiclePartRepairs .. "/" .. SBvars.BodyworkEnthusiastRepairs)
	updateLabel(self.labelMechanicsSkillProgress, getText("UI_trait_Mechanics") .. ": " .. mechanics .. "/" .. SBvars.MechanicsSkill)
	updateLabel(self.labelMechanicsRepairsProgress, getText("UI_trait_Mechanics") .. ": " .. math.floor(modData.VehiclePartRepairs) .. "/" .. SBvars.MechanicsRepairs)
	updateLabel(self.labelTailorProgress, getText("UI_trait_Tailor") .. ": " .. tailoring .. "/" .. SBvars.SewerSkill)
	updateLabel(self.labelGunEnthusiastSkillProgress, getText("UI_trait_GunEnthusiast") .. ": " .. aiming + reloading .. "/" .. SBvars.GunEnthusiastSkill)
	updateLabel(self.labelGunEnthusiastKillsProgress, getText("UI_trait_GunEnthusiast") .. ": " .. firearmKills .. "/" .. SBvars.GunEnthusiastKills)
	updateLabel(self.labelAnglerProgress, getText("UI_trait_Fishing") .. ": " .. fishing .. "/" .. SBvars.FishingSkill)
	updateLabel(self.labelHikerProgress, getText("UI_trait_Hiker") .. ": " .. trapping + foraging .. "/" .. SBvars.HikerSkill)
	updateLabel(self.labelCatEyesProgress, getText("UI_trait_NightVision") .. ": " .. math.floor(modData.CatEyesCounter) .. "/" .. SBvars.CatEyesCounter)
	updateLabel(self.labelHerbalistProgress, getText("UI_trait_Herbalist") .. ": " .. math.floor(modData.HerbsPickedUp) .. "/" .. SBvars.HerbalistHerbsPicked)
	updateLabel(self.labelAxemanProgress, getText("UI_trait_axeman") .. ": " .. modData.TreesChopped .. "/" .. SBvars.AxemanTrees)

	if self.labelDelayedTraitsSystem ~= nil then
		local textManager = getTextManager()
		local initialWindowHeight = WINDOW_HEIGHT_AFTER_CHILDREN
		local delayedY = initialWindowHeight - FONT_HGT_SMALL * 2
		local traitTable = player:getModData().EvolvingTraitsWorld.DelayedTraits
		local parts = {}
		for index, traitEntry in ipairs(traitTable) do
			local traitName, roll = traitEntry[1], traitEntry[2]
			local strAddition = traitName .. " (1 " .. getText("UI_ETW_Chance") .. " " .. roll .. ")"
			table.insert(parts, strAddition)
		end
		local combinedParts = table.concat(parts, ", ")
		local lines = {}
		local currentLine = getText("UI_ETW_ListOfDelayedTraits")
		local spaceLeft = WINDOW_WIDTH - lineStartPosition
		for part in combinedParts:gmatch("[^,]+") do
			local partWithComma = part .. ", "
			if strLen(textManager, currentLine .. partWithComma) > spaceLeft then
				table.insert(lines, currentLine)
				currentLine = partWithComma
			else
				currentLine = currentLine .. partWithComma
			end
		end
		if currentLine ~= "" then
			table.insert(lines, currentLine:sub(1, -3))
		end
		for i, line in ipairs(lines) do
			self:drawText(line, lineStartPosition, delayedY + (i * FONT_HGT_SMALL), self.TextColor.r, self.TextColor.g, self.TextColor.b, self.TextColor.a)
		end
		WINDOW_HEIGHT = initialWindowHeight + (#lines * FONT_HGT_SMALL)
		self:setHeightAndParentHeight(WINDOW_HEIGHT)
	end
	if not SBvars.UIPage then
		self:drawText(getText("UI_ETW_ProgressPageDisabled"), 10, 10, 1, 1, 1, 1)
	end
	self:clearStencilRect();

	if WINDOW_WIDTH ~= MOvars.UIWidth or nonBarsEntriesPerRow ~= MOvars.TraitColumns then
		WINDOW_WIDTH = MOvars.UIWidth
		nonBarsEntriesPerRow = MOvars.TraitColumns
		self:clearChildren()
		self:createChildren()
	end
end

function ISETWProgressUI:update()
	ISPanelJoypad.update(self)
end

function ISETWProgressUI:onMouseWheel(del)
	self:setYScroll(self:getYScroll() - del * 30)
	return true
end

function ISETWProgressUI:new(X, Y, width, height, playerNum)
	local o = ISPanelJoypad:new(X, Y, width, height)
	setmetatable(o, self)
	self.__index = self
	o.playerNum = playerNum
	o.char = getSpecificPlayer(playerNum)
	o:noBackground()
	o.categoryButtons = {}
	o.categoryXOffset = 20

	ISETWProgressUI.instance = o
	return o
end

function ISETWProgressUI:ensureVisible()
	if not self.joyfocus then return end
	local child = nil
	if not child then return end
	local Y = child:getY()
	if Y - 40 < 0 - self:getYScroll() then
		self:setYScroll(0 - Y + 40)
	elseif Y + child:getHeight() + 40 > 0 - self:getYScroll() + self:getHeight() then
		self:setYScroll(0 - (Y + child:getHeight() + 40 - self:getHeight()))
	end
end

function ISETWProgressUI:onGainJoypadFocus(joypadData)
	ISPanelJoypad.onGainJoypadFocus(self, joypadData)
	self.joypadIndex = nil
	self.barWithTooltip = nil
end

function ISETWProgressUI:onLoseJoypadFocus(joypadData)
	ISPanelJoypad.onLoseJoypadFocus(self, joypadData)
end

function ISETWProgressUI:onJoypadDown(button)
	if button == Joypad.AButton then
	end
	if button == Joypad.YButton then
	end
	if button == Joypad.BButton then
	end
	if button == Joypad.LBumper then
		getPlayerInfoPanel(self.playerNum):onJoypadDown(button)
	end
	if button == Joypad.RBumper then
		getPlayerInfoPanel(self.playerNum):onJoypadDown(button)
	end
end

function ISETWProgressUI:onJoypadDirDown()
	self.joypadIndex = self.joypadIndex + 1
	self:ensureVisible()
	self:updateTooltipForJoypad()
end

function ISETWProgressUI:onJoypadDirLeft()
end

function ISETWProgressUI:onJoypadDirRight()
end


addCharacterPageTab("ETW", ISETWProgressUI:new(0, 0, WINDOW_WIDTH, WINDOW_HEIGHT, 0))
