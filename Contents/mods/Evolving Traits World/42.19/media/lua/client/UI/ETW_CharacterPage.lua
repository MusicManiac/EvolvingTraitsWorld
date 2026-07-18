---@diagnostic disable: param-type-mismatch, undefined-global
require("ISUI/ISPanelJoypad")
require("ISUI/ISRichTextPanel")
require("UI/CharacterInfoAddTab")
require("ETW_ModOptions")

local ETW_CommonFunctions = require("ETW_CommonFunctions")
local ETW_CommonLogicChecks = require("ETW_CommonLogicChecks")

local MarkDynamicTraitsFramework
if getActivatedMods():contains("MarkDynamicTraitsFramework") then
	MarkDynamicTraitsFramework = require("MDTF_Main")
end

---@type EvolvingTraitsWorldRegistries
local ETW_Registry = require("ETW_Registry")
---@type EvolvingTraitsWorldTraitsRegistries
local ETWTraitsRegistry = ETW_Registry.traits

local modOptions
local traitUINameCache = {}

---Returns a cached UI name for the provided trait, resolving and caching it on first lookup.
---@param traitOrRegistryId CharacterTrait|string
---@return string
local function getCachedTraitUIName(traitOrRegistryId)
	local traitRegistryId

	if instanceof(traitOrRegistryId, "CharacterTrait") then
		traitRegistryId = traitOrRegistryId:toString()
	elseif type(traitOrRegistryId) == "string" then
		traitRegistryId = traitOrRegistryId
	else
		return tostring(traitOrRegistryId)
	end

	local cachedName = traitUINameCache[traitRegistryId]
	if cachedName then
		return cachedName
	end

	local trait = ETW_CommonFunctions.resolveTrait(traitOrRegistryId)
	if not trait then
		return traitRegistryId
	end

	local traitDefinition = CharacterTraitDefinition.getCharacterTraitDefinition(trait)
	local uiName = traitRegistryId
	if traitDefinition then
		uiName = (MarkDynamicTraitsFramework and MarkDynamicTraitsFramework.getUndecoratedUIName(traitDefinition))
			or traitDefinition:getUIName()
	end
	traitUINameCache[traitRegistryId] = uiName
	return uiName
end

---Checks whether a trait is currently present in the player's delayed traits list.
---@param player IsoPlayer
---@param traitOrRegistryId CharacterTrait|string
---@return boolean
local function playerHasDelayedTraitNoCache(player, traitOrRegistryId)
	local modData = ETW_CommonFunctions.getETWModData(player)
	local delayedTraits = modData and modData.DelayedTraits
	local trait = ETW_CommonFunctions.resolveTrait(traitOrRegistryId)
	if not delayedTraits or not trait then
		return false
	end

	local traitRegistryId = trait:toString()
	for index = 1, #delayedTraits do
		if delayedTraits[index][1] == traitRegistryId then
			return true
		end
	end
	return false
end

---Builds a stable signature for the player's currently known traits.
---@param player IsoPlayer|nil
---@return string
local function getKnownTraitsLayoutSignature(player)
	if not player then
		return ""
	end

	local knownTraits = player:getCharacterTraits():getKnownTraits()
	local signatureParts = {}
	for index = 1, knownTraits:size() do
		signatureParts[index] = knownTraits:get(index - 1):toString()
	end
	table.sort(signatureParts)
	return table.concat(signatureParts, "|")
end

---Returns text describing a delayed trait entry based on whether it is still rolling or already waiting on its next trait-specific trigger.
---@param traitUIName string
---@param roll number
---@param gained boolean
---@return string
local function formatDelayedTraitStatus(traitUIName, roll, gained)
	if gained then
		return traitUIName .. " (" .. getText("UI_ETW_DelayedTraitReadyOnNextAction") .. ")"
	end

	return traitUIName .. " (1 " .. getText("UI_ETW_Chance") .. " " .. roll .. ")"
end

---Builds a stable signature for the player's delayed traits table.
---@param player IsoPlayer|nil
---@return string
local function getDelayedTraitsLayoutSignature(player)
	if not player then
		return ""
	end

	local modData = ETW_CommonFunctions.getETWModData(player)
	local delayedTraits = modData and modData.DelayedTraits
	if not delayedTraits then
		return ""
	end

	local signatureParts = {}
	for index = 1, #delayedTraits do
		local delayedTrait = delayedTraits[index]
		signatureParts[index] = tostring(delayedTrait[1])
			.. ":"
			.. tostring(delayedTrait[2])
			.. ":"
			.. tostring(delayedTrait[3])
	end
	return table.concat(signatureParts, "|")
end

---Combines trait-based layout inputs into a single signature used to detect when the UI must be rebuilt.
---@param player IsoPlayer|nil
---@return string
local function getLayoutSignature(player)
	return getKnownTraitsLayoutSignature(player) .. "||" .. getDelayedTraitsLayoutSignature(player)
end

---Closes a child tooltip before the child is removed from the panel.
---@param child ISUIElement
local function hideChildTooltip(child)
	if child and child.tooltipUI then
		child.tooltipUI:setVisible(false)
		child.tooltipUI:removeFromUIManager()
	end
end

---Function responsible for setting up mod options on character load
---@param playerIndex number
---@param player IsoPlayer
local function initializeModOptions(playerIndex, player)
	modOptions = PZAPI.ModOptions:getOptions("ETWModOptions")
end

Events.OnCreatePlayer.Remove(initializeModOptions)
Events.OnCreatePlayer.Add(initializeModOptions)

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)
local WINDOW_WIDTH = 700
local WINDOW_HEIGHT = 200
local WINDOW_HEIGHT_AFTER_CHILDREN = 700
local HELP_WINDOW_MIN_HEIGHT = 120
local HELP_WINDOW_MAX_HEIGHT = 500

local lineStartPosition = 5

local x
local y = 12

local columnGap

local nonBarsEntriesPerRow = 4
local nonBarsEntryNumber = 0

---Creates an isolated layout cursor so each subtab can track its own positions.
---@return {x:number, y:number, nonBarsEntryNumber:number}
local function newLayoutCursor()
	return {
		x = lineStartPosition,
		y = 12,
		nonBarsEntryNumber = 0,
	}
end

---Returns a bounded Help view height based on the rich text's paginated content.
---@param helpText ISRichTextPanel
---@return number
local function getHelpWindowHeight(helpText)
	local contentHeight = helpText:getScrollHeight() + 20
	return math.max(HELP_WINDOW_MIN_HEIGHT, math.min(HELP_WINDOW_MAX_HEIGHT, contentHeight))
end

---@type {x:number, y:number, nonBarsEntryNumber:number}|nil
local activeLayoutCursor

---Saves the active globals back into the currently-selected layout cursor.
local function storeActiveLayoutCursor()
	if not activeLayoutCursor then
		return
	end

	activeLayoutCursor.x = x
	activeLayoutCursor.y = y
	activeLayoutCursor.nonBarsEntryNumber = nonBarsEntryNumber
end

---Loads a layout cursor into the legacy global position variables.
---@param layoutCursor {x:number, y:number, nonBarsEntryNumber:number}
local function useLayoutCursor(layoutCursor)
	activeLayoutCursor = layoutCursor
	x = layoutCursor.x
	y = layoutCursor.y
	nonBarsEntryNumber = layoutCursor.nonBarsEntryNumber
end

---@type EvolvingTraitsWorldSandboxVars
local SBvars = SandboxVars.EvolvingTraitsWorld

ISETWUI = ISPanelJoypad:derive("ISETWUI")

---Converts a value within a min/max range into a 0..1 percentage for UI bars.
---@param minValue number
---@param maxValue number
---@param currentValue number
---@return number
local function percentile(minValue, maxValue, currentValue)
	return (currentValue - minValue) / (maxValue - minValue)
end

---Measures the rendered width of a string using the small UI font.
---@param textManager TextManager
---@param str string
---@return number
local function strLen(textManager, str)
	return textManager:MeasureStringX(UIFont.Small, str)
end

---Formats a numeric UI value with two decimals for compact tooltips and labels.
---@param value number|nil
---@return string
local function formatDecimal(value)
	return string.format("%.2f", value or 0)
end

---Formats a slice of rolling average samples into a compact space-separated string.
---@param samples number[]|nil
---@param startIndex integer
---@param endIndex integer
---@return string
local function formatSampleSlice(samples, startIndex, endIndex)
	if not samples or #samples == 0 then
		return ""
	end

	local parts = {}
	for index = math.min(endIndex, #samples), startIndex, -1 do
		parts[#parts + 1] = formatDecimal(samples[index])
	end
	return table.concat(parts, " ")
end

---Formats up to 24 hourly samples into a single compact row for display under a vitals bar.
---@param samples number[]|nil
---@return string
local function formatHourlySamples(samples)
	local values = formatSampleSlice(samples, 1, 24)
	if values == "" then
		return getText("UI_ETW_Vitals_LatestHourlyAverages") .. ":"
	end
	return getText("UI_ETW_Vitals_LatestHourlyAverages") .. ": " .. values
end

---Advances the column layout cursor for compact label rows, optionally forcing a new line.
---@param newLine boolean|nil
local function arrangeColumnsInTable(newLine)
	x = lineStartPosition
	nonBarsEntryNumber = nonBarsEntryNumber + 1
	if (nonBarsEntryNumber > nonBarsEntriesPerRow) or newLine then
		y = y + FONT_HGT_SMALL
		nonBarsEntryNumber = 1
	end
	if nonBarsEntryNumber ~= 1 then
		x = lineStartPosition + columnGap * (nonBarsEntryNumber - 1)
	end
	storeActiveLayoutCursor()
end

function ISETWUI:initialise()
	--ISPanelJoypad.initialise(self)
end

function ISETWUI:createChildren()
	local player = getSpecificPlayer(self.playerNum)

	-- ── Subtab setup ──────────────────────────────────────────────────────────
	-- Create the inner ISTabPanel that lives inside this ETW tab view.
	local TAB_H = getTextManager():getFontHeight(UIFont.Small) + 6
	self.subPanel = ISTabPanel:new(0, 0, self.width, self.height)
	self.subPanel:initialise()
	self.subPanel.equalTabWidth = false
	self.subPanel.tabPadX = 14
	self.subPanel.allowDraggingTabs = false
	self.subPanel.allowTornOffTabs = false

	-- Sub-view: Vitals
	self.subViewVitals = ISPanel:new(0, 0, self.width, self.height - TAB_H)
	self.subViewVitals:initialise()
	self.subViewVitals:noBackground()

	-- Sub-view: Permanent Traits
	self.subViewPermanentTraits = ISPanel:new(0, 0, self.width, self.height - TAB_H)
	self.subViewPermanentTraits:initialise()
	self.subViewPermanentTraits:noBackground()

	-- Sub-view: Non-permanent Traits
	self.subViewNonPermanentTraits = ISPanel:new(0, 0, self.width, self.height - TAB_H)
	self.subViewNonPermanentTraits:initialise()
	self.subViewNonPermanentTraits:noBackground()

	-- Sub-view: Help
	self.subViewHelp = ISPanel:new(0, 0, self.width, self.height - TAB_H)
	self.subViewHelp:initialise()
	self.subViewHelp:noBackground()

	self.helpText = ISRichTextPanel:new(10, 10, self.width - 20, HELP_WINDOW_MAX_HEIGHT - 20)
	self.helpText:initialise()
	self.helpText.background = false
	self.helpText.autosetheight = false
	self.helpText.clip = true
	self.helpText.marginRight = self.helpText.marginLeft
	self.helpText:addScrollBars()
	self.helpText:setText(getText("UI_ETW_Help_FAQ"))
	self.helpText:paginate()
	self.subViewHelp:addChild(self.helpText)
	self.helpWindowHeight = getHelpWindowHeight(self.helpText)

	local vitalsLayoutCursor = newLayoutCursor()
	local permanentTraitsLayoutCursor = newLayoutCursor()
	local nonPermanentTraitsLayoutCursor = newLayoutCursor()

	-- routeTo(subView): switches the addChild redirect to the given subview.
	-- Call this before each section to control which tab receives its widgets.
	local function routeTo(subView, layoutCursor)
		storeActiveLayoutCursor()
		self.addChild = function(s, child)
			subView:addChild(child)
		end
		useLayoutCursor(layoutCursor)
	end
	-- ── End subtab setup (redirect active) ──────────────────────────────────────────────────────────

	if SBvars.UIPage then
		local highlightRadius = 20
		columnGap = (WINDOW_WIDTH - 2 * lineStartPosition) / nonBarsEntriesPerRow

		local yellowGreenGradient = getTexture("media/ui/GradientBars/yellowGreenGradient.png")
		local greenYellowRedGradient = getTexture("media/ui/GradientBars/greenYellowRedGradient.png")
		local redYellowGreenGradient = getTexture("media/ui/GradientBars/redYellowGreenGradient.png")

		self.TextColor = { r = 1, g = 1, b = 1, a = 1 }
		self.DimmedTextColor = { r = 0.7, g = 0.7, b = 0.7, a = 1 }

		local textManager = getTextManager()
		local str

		local modData = ETW_CommonFunctions.getETWModData(player)
		local strength = player:getPerkLevel(Perks.Strength)
		local fitness = player:getPerkLevel(Perks.Fitness)
		local sprinting = player:getPerkLevel(Perks.Sprinting)
		local lightfooted = player:getPerkLevel(Perks.Lightfoot)
		local nimble = player:getPerkLevel(Perks.Nimble)
		local sneaking = player:getPerkLevel(Perks.Sneak)
		local axe = player:getPerkLevel(Perks.Axe)
		local longBlunt = player:getPerkLevel(Perks.Blunt)
		local shortBlunt = player:getPerkLevel(Perks.SmallBlunt)
		local longBlade = player:getPerkLevel(Perks.LongBlade)
		local shortBlade = player:getPerkLevel(Perks.SmallBlade)
		local spear = player:getPerkLevel(Perks.Spear)
		local maintenance = player:getPerkLevel(Perks.Maintenance)
		local carpentry = player:getPerkLevel(Perks.Woodwork)
		local cooking = player:getPerkLevel(Perks.Cooking)
		local farming = player:getPerkLevel(Perks.Farming)
		local firstAid = player:getPerkLevel(Perks.Doctor)
		local electrical = player:getPerkLevel(Perks.Electricity)
		local metalworking = player:getPerkLevel(Perks.MetalWelding)
		local mechanics = player:getPerkLevel(Perks.Mechanics)
		local tailoring = player:getPerkLevel(Perks.Tailoring)
		local aiming = player:getPerkLevel(Perks.Aiming)
		local reloading = player:getPerkLevel(Perks.Reloading)
		local fishing = player:getPerkLevel(Perks.Fishing)
		local trapping = player:getPerkLevel(Perks.Trapping)
		local foraging = player:getPerkLevel(Perks.PlantScavenging)
		local husbandry = player:getPerkLevel(Perks.Husbandry)
		local carving = player:getPerkLevel(Perks.Carving)
		local blacksmith = player:getPerkLevel(Perks.Blacksmith)
		local knapping = player:getPerkLevel(Perks.FlintKnapping)

		local function appendLeftBarLabel(labelTexts, labelText)
			if labelText and labelText ~= "" then
				labelTexts[#labelTexts + 1] = labelText
			end
		end

		local function getDynamicBarStartPosition()
			local labelTexts = {
				getText("UI_ETW_Vitals_Food"),
				getText("UI_ETW_Vitals_Thirst"),
				getText("UI_ETW_Vitals_Mental"),
			}

			if ETW_CommonLogicChecks.ImmunitySystemShouldExecute(player) then
				appendLeftBarLabel(labelTexts, getText("Sandbox_ETW_ImmunitySystem"))
			end
			if ETW_CommonLogicChecks.FoodSicknessSystemShouldExecute(player) then
				appendLeftBarLabel(labelTexts, getText("Sandbox_ETW_FoodSicknessSystem"))
			end
			if ETW_CommonLogicChecks.PainToleranceShouldExecute(player) then
				appendLeftBarLabel(labelTexts, getCachedTraitUIName(ETWTraitsRegistry.PAIN_TOLERANCE))
			end
			if ETW_CommonLogicChecks.HearingSystemShouldExecute(player) then
				appendLeftBarLabel(labelTexts, getText("Sandbox_ETW_HearingSystem"))
			end
			if ETW_CommonLogicChecks.LearnerSystemShouldExecute(player) then
				appendLeftBarLabel(labelTexts, getText("Sandbox_ETW_LearnerSystem"))
			end
			if ETW_CommonLogicChecks.ReaderSystemShouldExecute(player) then
				appendLeftBarLabel(labelTexts, getText("Sandbox_ETW_ReaderSystem"))
			end
			if ETW_CommonLogicChecks.InventoryTransferSystemShouldExecute(player) then
				local weightTransferred = (
					modData
					and modData.TransferSystem
					and modData.TransferSystem.WeightTransferred
				) or 0
				local itemsTransferred = (
					modData
					and modData.TransferSystem
					and modData.TransferSystem.ItemsTransferred
				) or 0
				if weightTransferred < SBvars.InventoryTransferSystemWeight then
					appendLeftBarLabel(labelTexts, getText("Sandbox_ETW_InventoryTransferSystemWeight"))
				end
				if itemsTransferred < SBvars.InventoryTransferSystemItems then
					appendLeftBarLabel(labelTexts, getText("Sandbox_ETW_InventoryTransferSystemItems"))
				end
			end
			if ETW_CommonLogicChecks.BraverySystemShouldExecute(player) then
				appendLeftBarLabel(labelTexts, getText("Sandbox_ETW_BraverySystem"))
			end
			if ETW_CommonLogicChecks.BloodlustShouldExecute(player) then
				appendLeftBarLabel(labelTexts, getCachedTraitUIName(ETWTraitsRegistry.BLOODLUST))
			end
			if ETW_CommonLogicChecks.AsthmaticShouldExecute(player) then
				appendLeftBarLabel(labelTexts, getCachedTraitUIName(CharacterTrait.ASTHMATIC))
			end
			if ETW_CommonLogicChecks.OutdoorsmanShouldExecute(player) then
				appendLeftBarLabel(labelTexts, getCachedTraitUIName(CharacterTrait.OUTDOORSMAN))
			end
			if ETW_CommonLogicChecks.FearOfLocationsSystemShouldExecute(player) then
				appendLeftBarLabel(labelTexts, getCachedTraitUIName(CharacterTrait.AGORAPHOBIC))
				appendLeftBarLabel(labelTexts, getCachedTraitUIName(CharacterTrait.CLAUSTROPHOBIC))
			end
			if ETW_CommonLogicChecks.SleepSystemShouldExecute(player) then
				appendLeftBarLabel(labelTexts, getText("Sandbox_ETW_SleepSystem"))
			end
			if ETW_CommonLogicChecks.RainSystemShouldExecute(player) then
				appendLeftBarLabel(labelTexts, getText("Sandbox_ETW_RainSystem"))
			end
			if ETW_CommonLogicChecks.FogSystemShouldExecute(player) then
				appendLeftBarLabel(labelTexts, getText("Sandbox_ETW_FogSystem"))
			end
			if
				ETW_CommonLogicChecks.SmokerShouldExecute(player)
				and ((not modOptions and true) or not modOptions:getOption("HideSmokerUI"):getValue())
			then
				appendLeftBarLabel(labelTexts, getCachedTraitUIName(CharacterTrait.SMOKER))
			end

			local maxWidth = 0
			for index = 1, #labelTexts do
				maxWidth = math.max(maxWidth, strLen(textManager, labelTexts[index]))
			end

			return math.max(150, maxWidth + (lineStartPosition * 2))
		end

		local barStartPosition = getDynamicBarStartPosition()
		local barEndPosition = WINDOW_WIDTH - lineStartPosition
		local barMidPosition = barStartPosition + (barEndPosition - barStartPosition) / 2
		local barLength = barEndPosition - barStartPosition
		local barOneFourthPosition = barMidPosition - barLength / 4
		local barThreeFourthPosition = barMidPosition + barLength / 4
		local barOneThirdPosition = barStartPosition + barLength / 3
		local barTwoThirdPosition = barOneThirdPosition + barLength / 3
		local vitalsLabelWidth = math.max(
			strLen(textManager, getText("UI_ETW_Vitals_Food")),
			strLen(textManager, getText("UI_ETW_Vitals_Thirst")),
			strLen(textManager, getText("UI_ETW_Vitals_Mental"))
		)
		-- Leave one extra gutter between the row labels and the group border.
		local vitalsBarStartPosition = lineStartPosition + vitalsLabelWidth + (lineStartPosition * 2)
		local vitalsBarLength = barEndPosition - vitalsBarStartPosition

		local killCountModData
		local axeKills = 0
		local longBluntKills = 0
		local shortBluntKills = 0
		local longBladeKills = 0
		local shortBladeKills = 0
		local spearKills = 0
		local firearmKills = 0
		if modData and modData.KillCount and modData.KillCount.WeaponCategory then
			killCountModData = modData.KillCount.WeaponCategory
			axeKills = killCountModData["Axe"].count or 0
			longBluntKills = killCountModData["Blunt"].count or 0
			shortBluntKills = killCountModData["SmallBlunt"].count or 0
			longBladeKills = killCountModData["LongBlade"].count or 0
			shortBladeKills = killCountModData["SmallBlade"].count or 0
			spearKills = killCountModData["Spear"].count or 0
			firearmKills = killCountModData["Firearm"].count or 0
		end

		local function buildVitalsSection()
			-- Vitals only needs room for its three short row labels. Keep the wider
			-- shared bar geometry for trait subtabs, whose labels can be much longer.
			local barStartPosition = vitalsBarStartPosition
			local barLength = vitalsBarLength

			str = getText("UI_ETW_Vitals_Last31Days")
			self.labelVitalsLast31Days = ISLabel:new(
				WINDOW_WIDTH / 2 - strLen(textManager, str) / 2,
				y,
				FONT_HGT_MEDIUM,
				str,
				self.TextColor.r,
				self.TextColor.g,
				self.TextColor.b,
				self.TextColor.a,
				UIFont.Small,
				true
			)
			self:addChild(self.labelVitalsLast31Days)

			y = y + FONT_HGT_MEDIUM + 4

			if ETW_CommonLogicChecks.FoodSystemShouldExecute(player) then
				str = "+ " .. getCachedTraitUIName(CharacterTrait.HEARTY_APPETITE)
				self.labelVitalsFoodGainNegative = ISLabel:new(
					barStartPosition
						+ (barLength * SBvars.FoodSystemGainNegativeThreshold)
						- strLen(textManager, str) / 2,
					y,
					FONT_HGT_SMALL,
					str,
					self.DimmedTextColor.r,
					self.DimmedTextColor.g,
					self.DimmedTextColor.b,
					self.DimmedTextColor.a,
					UIFont.Small,
					true
				)
				self.labelVitalsFoodGainNegative:setTooltip(getText("UI_ETW_GainTooltip"))
				self:addChild(self.labelVitalsFoodGainNegative)

				str = "- " .. getCachedTraitUIName(CharacterTrait.LIGHT_EATER)
				self.labelVitalsFoodLosePositive = ISLabel:new(
					barStartPosition
						+ (barLength * SBvars.FoodSystemLosePositiveThreshold)
						- strLen(textManager, str) / 2,
					y,
					FONT_HGT_SMALL,
					str,
					self.DimmedTextColor.r,
					self.DimmedTextColor.g,
					self.DimmedTextColor.b,
					self.DimmedTextColor.a,
					UIFont.Small,
					true
				)
				self.labelVitalsFoodLosePositive:setTooltip(getText("UI_ETW_LooseTooltip"))
				self:addChild(self.labelVitalsFoodLosePositive)

				y = y + FONT_HGT_SMALL
			end

			self.labelVitalsFood = ISLabel:new(
				barStartPosition - lineStartPosition,
				y,
				FONT_HGT_SMALL,
				getText("UI_ETW_Vitals_Food"),
				self.TextColor.r,
				self.TextColor.g,
				self.TextColor.b,
				self.TextColor.a,
				UIFont.Small,
				false
			)
			self:addChild(self.labelVitalsFood)

			self.barVitalsFood = ISGradientBar:new(barStartPosition, y, barLength, FONT_HGT_SMALL)
			self.barVitalsFood:setGradientTexture(redYellowGreenGradient)
			self.barVitalsFood:setHighlightRadius(highlightRadius)
			self.barVitalsFood:setDoKnob(false)
			self:addChild(self.barVitalsFood)

			y = y + FONT_HGT_SMALL + 2

			if ETW_CommonLogicChecks.FoodSystemShouldExecute(player) then
				str = "- " .. getCachedTraitUIName(CharacterTrait.HEARTY_APPETITE)
				self.labelVitalsFoodLose = ISLabel:new(
					barStartPosition
						+ (barLength * SBvars.FoodSystemLoseNegativeThreshold)
						- strLen(textManager, str) / 2,
					y,
					FONT_HGT_SMALL,
					str,
					self.DimmedTextColor.r,
					self.DimmedTextColor.g,
					self.DimmedTextColor.b,
					self.DimmedTextColor.a,
					UIFont.Small,
					true
				)
				self.labelVitalsFoodLose:setTooltip(getText("UI_ETW_LooseTooltip"))
				self:addChild(self.labelVitalsFoodLose)

				str = "+ " .. getCachedTraitUIName(CharacterTrait.LIGHT_EATER)
				self.labelVitalsFoodGain = ISLabel:new(
					barStartPosition
						+ (barLength * SBvars.FoodSystemGainPositiveThreshold)
						- strLen(textManager, str) / 2,
					y,
					FONT_HGT_SMALL,
					str,
					self.DimmedTextColor.r,
					self.DimmedTextColor.g,
					self.DimmedTextColor.b,
					self.DimmedTextColor.a,
					UIFont.Small,
					true
				)
				self.labelVitalsFoodGain:setTooltip(getText("UI_ETW_GainTooltip"))
				self:addChild(self.labelVitalsFoodGain)

				y = y + FONT_HGT_SMALL
			end

			self.labelVitalsFood24Hours = ISLabel:new(
				barStartPosition,
				y,
				FONT_HGT_SMALL,
				"",
				self.DimmedTextColor.r,
				self.DimmedTextColor.g,
				self.DimmedTextColor.b,
				self.DimmedTextColor.a,
				UIFont.Small,
				true
			)
			self:addChild(self.labelVitalsFood24Hours)

			y = y + FONT_HGT_SMALL + 6

			if ETW_CommonLogicChecks.ThirstSystemShouldExecute(player) then
				str = "+ " .. getCachedTraitUIName(CharacterTrait.HIGH_THIRST)
				self.labelVitalsThirstGainNegative = ISLabel:new(
					barStartPosition
						+ (barLength * SBvars.ThirstSystemGainNegativeThreshold)
						- strLen(textManager, str) / 2,
					y,
					FONT_HGT_SMALL,
					str,
					self.DimmedTextColor.r,
					self.DimmedTextColor.g,
					self.DimmedTextColor.b,
					self.DimmedTextColor.a,
					UIFont.Small,
					true
				)
				self.labelVitalsThirstGainNegative:setTooltip(getText("UI_ETW_GainTooltip"))
				self:addChild(self.labelVitalsThirstGainNegative)

				str = "- " .. getCachedTraitUIName(CharacterTrait.LOW_THIRST)
				self.labelVitalsThirstLosePositive = ISLabel:new(
					barStartPosition
						+ (barLength * SBvars.ThirstSystemLosePositiveThreshold)
						- strLen(textManager, str) / 2,
					y,
					FONT_HGT_SMALL,
					str,
					self.DimmedTextColor.r,
					self.DimmedTextColor.g,
					self.DimmedTextColor.b,
					self.DimmedTextColor.a,
					UIFont.Small,
					true
				)
				self.labelVitalsThirstLosePositive:setTooltip(getText("UI_ETW_LooseTooltip"))
				self:addChild(self.labelVitalsThirstLosePositive)

				y = y + FONT_HGT_SMALL
			end

			self.labelVitalsThirst = ISLabel:new(
				barStartPosition - lineStartPosition,
				y,
				FONT_HGT_SMALL,
				getText("UI_ETW_Vitals_Thirst"),
				self.TextColor.r,
				self.TextColor.g,
				self.TextColor.b,
				self.TextColor.a,
				UIFont.Small,
				false
			)
			self:addChild(self.labelVitalsThirst)

			self.barVitalsThirst = ISGradientBar:new(barStartPosition, y, barLength, FONT_HGT_SMALL)
			self.barVitalsThirst:setGradientTexture(redYellowGreenGradient)
			self.barVitalsThirst:setHighlightRadius(highlightRadius)
			self.barVitalsThirst:setDoKnob(false)
			self:addChild(self.barVitalsThirst)

			y = y + FONT_HGT_SMALL + 2

			if ETW_CommonLogicChecks.ThirstSystemShouldExecute(player) then
				str = "- " .. getCachedTraitUIName(CharacterTrait.HIGH_THIRST)
				self.labelVitalsThirstLose = ISLabel:new(
					barStartPosition
						+ (barLength * SBvars.ThirstSystemLoseNegativeThreshold)
						- strLen(textManager, str) / 2,
					y,
					FONT_HGT_SMALL,
					str,
					self.DimmedTextColor.r,
					self.DimmedTextColor.g,
					self.DimmedTextColor.b,
					self.DimmedTextColor.a,
					UIFont.Small,
					true
				)
				self.labelVitalsThirstLose:setTooltip(getText("UI_ETW_LooseTooltip"))
				self:addChild(self.labelVitalsThirstLose)

				str = "+ " .. getCachedTraitUIName(CharacterTrait.LOW_THIRST)
				self.labelVitalsThirstGain = ISLabel:new(
					barStartPosition
						+ (barLength * SBvars.ThirstSystemGainPositiveThreshold)
						- strLen(textManager, str) / 2,
					y,
					FONT_HGT_SMALL,
					str,
					self.DimmedTextColor.r,
					self.DimmedTextColor.g,
					self.DimmedTextColor.b,
					self.DimmedTextColor.a,
					UIFont.Small,
					true
				)
				self.labelVitalsThirstGain:setTooltip(getText("UI_ETW_GainTooltip"))
				self:addChild(self.labelVitalsThirstGain)

				y = y + FONT_HGT_SMALL
			end

			self.labelVitalsThirst24Hours = ISLabel:new(
				barStartPosition,
				y,
				FONT_HGT_SMALL,
				"",
				self.DimmedTextColor.r,
				self.DimmedTextColor.g,
				self.DimmedTextColor.b,
				self.DimmedTextColor.a,
				UIFont.Small,
				true
			)
			self:addChild(self.labelVitalsThirst24Hours)

			y = y + FONT_HGT_SMALL + 6

			self.labelVitalsMental = ISLabel:new(
				barStartPosition - lineStartPosition,
				y,
				FONT_HGT_SMALL,
				getText("UI_ETW_Vitals_Mental"),
				self.TextColor.r,
				self.TextColor.g,
				self.TextColor.b,
				self.TextColor.a,
				UIFont.Small,
				false
			)
			self:addChild(self.labelVitalsMental)

			self.barVitalsMental = ISGradientBar:new(barStartPosition, y, barLength, FONT_HGT_SMALL)
			self.barVitalsMental:setGradientTexture(redYellowGreenGradient)
			self.barVitalsMental:setHighlightRadius(highlightRadius)
			self.barVitalsMental:setDoKnob(false)
			self:addChild(self.barVitalsMental)

			y = y + FONT_HGT_SMALL + 2

			self.labelVitalsMental24Hours = ISLabel:new(
				barStartPosition,
				y,
				FONT_HGT_SMALL,
				"",
				self.DimmedTextColor.r,
				self.DimmedTextColor.g,
				self.DimmedTextColor.b,
				self.DimmedTextColor.a,
				UIFont.Small,
				true
			)
			self:addChild(self.labelVitalsMental24Hours)

			y = y + FONT_HGT_SMALL
		end

		local function buildPermanentTraitsSection()
			if ETW_CommonLogicChecks.ImmunitySystemShouldExecute(player) then
				self.labelProneToIllness = ISLabel:new(
					barMidPosition - strLen(textManager, str) / 2,
					y,
					FONT_HGT_SMALL,
					"- " .. getCachedTraitUIName(CharacterTrait.PRONE_TO_ILLNESS),
					self.DimmedTextColor.r,
					self.DimmedTextColor.g,
					self.DimmedTextColor.b,
					self.DimmedTextColor.a,
					UIFont.Small,
					true
				)
				self.labelProneToIllness:setTooltip(getText("UI_ETW_LooseTooltip"))
				self:addChild(self.labelProneToIllness)

				self.labelResilient = ISLabel:new(
					barEndPosition,
					y,
					FONT_HGT_SMALL,
					"+ " .. getCachedTraitUIName(CharacterTrait.RESILIENT),
					self.DimmedTextColor.r,
					self.DimmedTextColor.g,
					self.DimmedTextColor.b,
					self.DimmedTextColor.a,
					UIFont.Small,
					false
				)
				self.labelResilient:setTooltip(getText("UI_ETW_GainTooltip"))
				self:addChild(self.labelResilient)

				y = y + FONT_HGT_SMALL

				self.labelImmunitySystem = ISLabel:new(
					barStartPosition - lineStartPosition,
					y,
					FONT_HGT_SMALL,
					getText("Sandbox_ETW_ImmunitySystem"),
					self.TextColor.r,
					self.TextColor.g,
					self.TextColor.b,
					self.TextColor.a,
					UIFont.Small,
					false
				)
				self.labelImmunitySystem:setTooltip(getText("Sandbox_ETW_ImmunitySystemCounter_tooltip"))
				self:addChild(self.labelImmunitySystem)

				self.barImmunitySystem = ISGradientBar:new(barStartPosition, y, barLength, FONT_HGT_SMALL)
				self.barImmunitySystem:setGradientTexture(redYellowGreenGradient)
				self.barImmunitySystem:setHighlightRadius(highlightRadius)
				self.barImmunitySystem:setDoKnob(false)
				self:addChild(self.barImmunitySystem)

				y = y + FONT_HGT_SMALL
			end

			if ETW_CommonLogicChecks.FoodSicknessSystemShouldExecute(player) then
				self.labelWeakStomach = ISLabel:new(
					barMidPosition,
					y,
					FONT_HGT_SMALL,
					"- " .. getCachedTraitUIName(CharacterTrait.WEAK_STOMACH),
					self.DimmedTextColor.r,
					self.DimmedTextColor.g,
					self.DimmedTextColor.b,
					self.DimmedTextColor.a,
					UIFont.Small,
					true
				)
				self.labelWeakStomach.center = true
				self.labelWeakStomach:setTooltip(getText("UI_ETW_LooseTooltip"))
				self:addChild(self.labelWeakStomach)

				self.labelIronGut = ISLabel:new(
					barEndPosition,
					y,
					FONT_HGT_SMALL,
					"+ " .. getCachedTraitUIName(CharacterTrait.IRON_GUT),
					self.DimmedTextColor.r,
					self.DimmedTextColor.g,
					self.DimmedTextColor.b,
					self.DimmedTextColor.a,
					UIFont.Small,
					false
				)
				self.labelIronGut:setTooltip(getText("UI_ETW_GainTooltip"))
				self:addChild(self.labelIronGut)

				y = y + FONT_HGT_SMALL

				self.labelSicknessSystem = ISLabel:new(
					barStartPosition - lineStartPosition,
					y,
					FONT_HGT_SMALL,
					getText("Sandbox_ETW_FoodSicknessSystem"),
					self.TextColor.r,
					self.TextColor.g,
					self.TextColor.b,
					self.TextColor.a,
					UIFont.Small,
					false
				)
				self.labelSicknessSystem:setTooltip(getText("Sandbox_ETW_FoodSicknessSystemCounter_tooltip"))
				self:addChild(self.labelSicknessSystem)

				self.barSicknessSystem = ISGradientBar:new(barStartPosition, y, barLength, FONT_HGT_SMALL)
				self.barSicknessSystem:setGradientTexture(redYellowGreenGradient)
				self.barSicknessSystem:setHighlightRadius(highlightRadius)
				self.barSicknessSystem:setDoKnob(false)
				self:addChild(self.barSicknessSystem)

				y = y + FONT_HGT_SMALL
			end

			if ETW_CommonLogicChecks.PainToleranceShouldExecute(player) then
				self.labelPainTolerance = ISLabel:new(
					barEndPosition,
					y,
					FONT_HGT_SMALL,
					"+ " .. getCachedTraitUIName(ETWTraitsRegistry.PAIN_TOLERANCE),
					self.DimmedTextColor.r,
					self.DimmedTextColor.g,
					self.DimmedTextColor.b,
					self.DimmedTextColor.a,
					UIFont.Small,
					false
				)
				self.labelPainTolerance:setTooltip(getText("UI_ETW_GainTooltip"))
				self:addChild(self.labelPainTolerance)

				y = y + FONT_HGT_SMALL

				self.labelPainToleranceBarName = ISLabel:new(
					barStartPosition - lineStartPosition,
					y,
					FONT_HGT_SMALL,
					getCachedTraitUIName(ETWTraitsRegistry.PAIN_TOLERANCE),
					self.TextColor.r,
					self.TextColor.g,
					self.TextColor.b,
					self.TextColor.a,
					UIFont.Small,
					false
				)
				self.labelPainToleranceBarName:setTooltip(getText("Sandbox_ETW_PainToleranceCounter_tooltip"))
				self:addChild(self.labelPainToleranceBarName)

				self.barPainTolerance = ISGradientBar:new(barStartPosition, y, barLength, FONT_HGT_SMALL)
				self.barPainTolerance:setGradientTexture(redYellowGreenGradient)
				self.barPainTolerance:setHighlightRadius(highlightRadius)
				self.barPainTolerance:setDoKnob(false)
				self:addChild(self.barPainTolerance)

				y = y + FONT_HGT_SMALL
			end

			if ETW_CommonLogicChecks.HearingSystemShouldExecute(player) then
				str = "- " .. getCachedTraitUIName(CharacterTrait.HARD_OF_HEARING)
				self.labelHardOfHearingLose = ISLabel:new(
					barMidPosition - strLen(textManager, str) / 2,
					y,
					FONT_HGT_SMALL,
					str,
					self.DimmedTextColor.r,
					self.DimmedTextColor.g,
					self.DimmedTextColor.b,
					self.DimmedTextColor.a,
					UIFont.Small,
					true
				)
				self.labelHardOfHearingLose:setTooltip(getText("UI_ETW_LooseTooltip"))
				self:addChild(self.labelHardOfHearingLose)

				self.labelKeenHearingGain = ISLabel:new(
					barEndPosition,
					y,
					FONT_HGT_SMALL,
					"+ " .. getCachedTraitUIName(CharacterTrait.KEEN_HEARING),
					self.DimmedTextColor.r,
					self.DimmedTextColor.g,
					self.DimmedTextColor.b,
					self.DimmedTextColor.a,
					UIFont.Small,
					false
				)
				self.labelKeenHearingGain:setTooltip(getText("UI_ETW_GainTooltip"))
				self:addChild(self.labelKeenHearingGain)

				y = y + FONT_HGT_SMALL

				self.labelHearingSystemBarName = ISLabel:new(
					barStartPosition - lineStartPosition,
					y,
					FONT_HGT_SMALL,
					getText("Sandbox_ETW_HearingSystem"),
					self.TextColor.r,
					self.TextColor.g,
					self.TextColor.b,
					self.TextColor.a,
					UIFont.Small,
					false
				)
				self.labelHearingSystemBarName:setTooltip(getText("Sandbox_ETW_HearingSystemSkill_tooltip"))
				self:addChild(self.labelHearingSystemBarName)

				self.barHearingSystem = ISGradientBar:new(barStartPosition, y, barLength, FONT_HGT_SMALL)
				self.barHearingSystem:setGradientTexture(redYellowGreenGradient)
				self.barHearingSystem:setHighlightRadius(highlightRadius)
				self.barHearingSystem:setDoKnob(false)
				self:addChild(self.barHearingSystem)

				y = y + FONT_HGT_SMALL
			end

			if ETW_CommonLogicChecks.LearnerSystemShouldExecute(player) then
				str = "- " .. getCachedTraitUIName(CharacterTrait.SLOW_LEARNER)
				self.labelSlowLearnerLose = ISLabel:new(
					barMidPosition - strLen(textManager, str) / 2,
					y,
					FONT_HGT_SMALL,
					str,
					self.DimmedTextColor.r,
					self.DimmedTextColor.g,
					self.DimmedTextColor.b,
					self.DimmedTextColor.a,
					UIFont.Small,
					true
				)
				self.labelSlowLearnerLose:setTooltip(getText("UI_ETW_LooseTooltip"))
				self:addChild(self.labelSlowLearnerLose)

				self.labelFastLearnerGain = ISLabel:new(
					barEndPosition,
					y,
					FONT_HGT_SMALL,
					"+ " .. getCachedTraitUIName(CharacterTrait.FAST_LEARNER),
					self.DimmedTextColor.r,
					self.DimmedTextColor.g,
					self.DimmedTextColor.b,
					self.DimmedTextColor.a,
					UIFont.Small,
					false
				)
				self.labelFastLearnerGain:setTooltip(getText("UI_ETW_GainTooltip"))
				self:addChild(self.labelFastLearnerGain)

				y = y + FONT_HGT_SMALL

				self.labelLearnerSystemBarName = ISLabel:new(
					barStartPosition - lineStartPosition,
					y,
					FONT_HGT_SMALL,
					getText("Sandbox_ETW_LearnerSystem"),
					self.TextColor.r,
					self.TextColor.g,
					self.TextColor.b,
					self.TextColor.a,
					UIFont.Small,
					false
				)
				self.labelLearnerSystemBarName:setTooltip(getText("Sandbox_ETW_LearnerSystemSkill_tooltip"))
				self:addChild(self.labelLearnerSystemBarName)

				self.barLearnerSystem = ISGradientBar:new(barStartPosition, y, barLength, FONT_HGT_SMALL)
				self.barLearnerSystem:setGradientTexture(redYellowGreenGradient)
				self.barLearnerSystem:setHighlightRadius(highlightRadius)
				self.barLearnerSystem:setDoKnob(false)
				self:addChild(self.barLearnerSystem)

				y = y + FONT_HGT_SMALL
			end

			if ETW_CommonLogicChecks.ReaderSystemShouldExecute(player) then
				str = "- " .. getCachedTraitUIName(CharacterTrait.SLOW_READER)
				self.labelSlowReaderLose = ISLabel:new(
					barMidPosition - strLen(textManager, str) / 2,
					y,
					FONT_HGT_SMALL,
					str,
					self.DimmedTextColor.r,
					self.DimmedTextColor.g,
					self.DimmedTextColor.b,
					self.DimmedTextColor.a,
					UIFont.Small,
					true
				)
				self.labelSlowReaderLose:setTooltip(getText("UI_ETW_LooseTooltip"))
				self:addChild(self.labelSlowReaderLose)

				self.labelFastReaderGain = ISLabel:new(
					barEndPosition,
					y,
					FONT_HGT_SMALL,
					"+ " .. getCachedTraitUIName(CharacterTrait.FAST_READER),
					self.DimmedTextColor.r,
					self.DimmedTextColor.g,
					self.DimmedTextColor.b,
					self.DimmedTextColor.a,
					UIFont.Small,
					false
				)
				self.labelFastReaderGain:setTooltip(getText("UI_ETW_GainTooltip"))
				self:addChild(self.labelFastReaderGain)

				y = y + FONT_HGT_SMALL

				self.labelReaderSystemBarName = ISLabel:new(
					barStartPosition - lineStartPosition,
					y,
					FONT_HGT_SMALL,
					getText("Sandbox_ETW_ReaderSystem"),
					self.TextColor.r,
					self.TextColor.g,
					self.TextColor.b,
					self.TextColor.a,
					UIFont.Small,
					false
				)
				self.labelReaderSystemBarName:setTooltip(getText("Sandbox_ETW_ReaderSystemCounter_tooltip"))
				self:addChild(self.labelReaderSystemBarName)

				self.barReaderSystem = ISGradientBar:new(barStartPosition, y, barLength, FONT_HGT_SMALL)
				self.barReaderSystem:setGradientTexture(redYellowGreenGradient)
				self.barReaderSystem:setHighlightRadius(highlightRadius)
				self.barReaderSystem:setDoKnob(false)
				self:addChild(self.barReaderSystem)

				y = y + FONT_HGT_SMALL
			end

			if ETW_CommonLogicChecks.InventoryTransferSystemShouldExecute(player) then
				y = y + FONT_HGT_SMALL / 2

				local weightTransferred = (
					modData
					and modData.TransferSystem
					and modData.TransferSystem.WeightTransferred
				) or 0
				local targetWeight = SBvars.InventoryTransferSystemWeight
				if weightTransferred < targetWeight then
					str = "- " .. getCachedTraitUIName(CharacterTrait.ALL_THUMBS)
					local labelX = barOneThirdPosition - strLen(textManager, str) / 2
					self.labelAllThumbsWeightLose = ISLabel:new(
						labelX,
						y,
						FONT_HGT_SMALL,
						str,
						self.DimmedTextColor.r,
						self.DimmedTextColor.g,
						self.DimmedTextColor.b,
						self.DimmedTextColor.a,
						UIFont.Small,
						true
					)
					self.labelAllThumbsWeightLose:setTooltip(getText("UI_ETW_LooseTooltip"))
					self:addChild(self.labelAllThumbsWeightLose)

					str = "- " .. getCachedTraitUIName(CharacterTrait.DISORGANIZED)
					labelX = barTwoThirdPosition - strLen(textManager, str) / 2
					self.labelDisorganizedWeightLose = ISLabel:new(
						labelX,
						y,
						FONT_HGT_SMALL,
						str,
						self.DimmedTextColor.r,
						self.DimmedTextColor.g,
						self.DimmedTextColor.b,
						self.DimmedTextColor.a,
						UIFont.Small,
						true
					)
					self.labelDisorganizedWeightLose:setTooltip(getText("UI_ETW_LooseTooltip"))
					self:addChild(self.labelDisorganizedWeightLose)

					y = y + FONT_HGT_SMALL

					self.labelInventoryTransferSystemWeightBarName = ISLabel:new(
						barStartPosition - lineStartPosition,
						y,
						FONT_HGT_SMALL,
						getText("Sandbox_ETW_InventoryTransferSystemWeight"),
						self.TextColor.r,
						self.TextColor.g,
						self.TextColor.b,
						self.TextColor.a,
						UIFont.Small,
						false
					)
					self.labelInventoryTransferSystemWeightBarName:setTooltip(
						getText("Sandbox_ETW_InventoryTransferSystemWeight_tooltip")
					)
					self:addChild(self.labelInventoryTransferSystemWeightBarName)

					self.barInventoryTransferSystemWeight =
						ISGradientBar:new(barStartPosition, y, barLength, FONT_HGT_SMALL)
					self.barInventoryTransferSystemWeight:setGradientTexture(redYellowGreenGradient)
					self.barInventoryTransferSystemWeight:setHighlightRadius(highlightRadius)
					self.barInventoryTransferSystemWeight:setDoKnob(false)
					self:addChild(self.barInventoryTransferSystemWeight)

					y = y + FONT_HGT_SMALL

					str = "+ " .. getCachedTraitUIName(CharacterTrait.DEXTROUS)
					labelX = barTwoThirdPosition - strLen(textManager, str) / 2
					self.labelDextrousWeightGain = ISLabel:new(
						labelX,
						y,
						FONT_HGT_SMALL,
						str,
						self.DimmedTextColor.r,
						self.DimmedTextColor.g,
						self.DimmedTextColor.b,
						self.DimmedTextColor.a,
						UIFont.Small,
						true
					)
					self.labelDextrousWeightGain:setTooltip(getText("UI_ETW_GainTooltip"))
					self:addChild(self.labelDextrousWeightGain)

					str = "+ " .. getCachedTraitUIName(CharacterTrait.ORGANIZED)
					labelX = barEndPosition

					self.labelOrganizedWeightGain = ISLabel:new(
						labelX,
						y,
						FONT_HGT_SMALL,
						str,
						self.DimmedTextColor.r,
						self.DimmedTextColor.g,
						self.DimmedTextColor.b,
						self.DimmedTextColor.a,
						UIFont.Small,
						false
					)
					self.labelOrganizedWeightGain:setTooltip(getText("UI_ETW_GainTooltip"))
					self:addChild(self.labelOrganizedWeightGain)
					y = y + FONT_HGT_SMALL
				end

				local itemsTransferred = (
					modData
					and modData.TransferSystem
					and modData.TransferSystem.ItemsTransferred
				) or 0
				local targetItems = SBvars.InventoryTransferSystemItems
				if itemsTransferred < targetItems then
					str = "- " .. getCachedTraitUIName(CharacterTrait.DISORGANIZED)
					local labelX = barOneThirdPosition - strLen(textManager, str) / 2
					self.labelDisorganizedItemsLose = ISLabel:new(
						labelX,
						y,
						FONT_HGT_SMALL,
						str,
						self.DimmedTextColor.r,
						self.DimmedTextColor.g,
						self.DimmedTextColor.b,
						self.DimmedTextColor.a,
						UIFont.Small,
						true
					)
					self.labelDisorganizedItemsLose:setTooltip(getText("UI_ETW_LooseTooltip"))
					self:addChild(self.labelDisorganizedItemsLose)

					str = "- " .. getCachedTraitUIName(CharacterTrait.ALL_THUMBS)
					labelX = barTwoThirdPosition - strLen(textManager, str) / 2
					self.labelAllThumbsItemsLose = ISLabel:new(
						labelX,
						y,
						FONT_HGT_SMALL,
						str,
						self.DimmedTextColor.r,
						self.DimmedTextColor.g,
						self.DimmedTextColor.b,
						self.DimmedTextColor.a,
						UIFont.Small,
						true
					)
					self.labelAllThumbsItemsLose:setTooltip(getText("UI_ETW_LooseTooltip"))
					self:addChild(self.labelAllThumbsItemsLose)

					y = y + FONT_HGT_SMALL

					self.labelInventoryTransferSystemItemsBarName = ISLabel:new(
						barStartPosition - lineStartPosition,
						y,
						FONT_HGT_SMALL,
						getText("Sandbox_ETW_InventoryTransferSystemItems"),
						self.TextColor.r,
						self.TextColor.g,
						self.TextColor.b,
						self.TextColor.a,
						UIFont.Small,
						false
					)
					self.labelInventoryTransferSystemItemsBarName:setTooltip(
						getText("Sandbox_ETW_InventoryTransferSystemItems_tooltip")
					)
					self:addChild(self.labelInventoryTransferSystemItemsBarName)

					self.barInventoryTransferSystemItems =
						ISGradientBar:new(barStartPosition, y, barLength, FONT_HGT_SMALL)
					self.barInventoryTransferSystemItems:setGradientTexture(redYellowGreenGradient)
					self.barInventoryTransferSystemItems:setHighlightRadius(highlightRadius)
					self.barInventoryTransferSystemItems:setDoKnob(false)
					self:addChild(self.barInventoryTransferSystemItems)

					y = y + FONT_HGT_SMALL

					str = "+ " .. getCachedTraitUIName(CharacterTrait.ORGANIZED)
					labelX = barTwoThirdPosition - strLen(textManager, str) / 2
					self.labelOrganizedItemsGain = ISLabel:new(
						labelX,
						y,
						FONT_HGT_SMALL,
						str,
						self.DimmedTextColor.r,
						self.DimmedTextColor.g,
						self.DimmedTextColor.b,
						self.DimmedTextColor.a,
						UIFont.Small,
						true
					)
					self.labelOrganizedItemsGain:setTooltip(getText("UI_ETW_GainTooltip"))
					self:addChild(self.labelOrganizedItemsGain)

					str = "+ " .. getCachedTraitUIName(CharacterTrait.DEXTROUS)
					labelX = barEndPosition
					self.labelDextrousItemsGain = ISLabel:new(
						labelX,
						y,
						FONT_HGT_SMALL,
						str,
						self.DimmedTextColor.r,
						self.DimmedTextColor.g,
						self.DimmedTextColor.b,
						self.DimmedTextColor.a,
						UIFont.Small,
						false
					)
					self.labelDextrousItemsGain:setTooltip(getText("UI_ETW_GainTooltip"))
					self:addChild(self.labelDextrousItemsGain)
					y = y + FONT_HGT_SMALL
				end

				y = y + FONT_HGT_SMALL / 2
			end

			if ETW_CommonLogicChecks.BraverySystemShouldExecute(player) then
				str = "- " .. getCachedTraitUIName(CharacterTrait.COWARDLY)
				self.labelCowardlyLose = ISLabel:new(
					barStartPosition + barLength * 0.1 - strLen(textManager, str) / 2,
					y,
					FONT_HGT_SMALL,
					str,
					self.DimmedTextColor.r,
					self.DimmedTextColor.g,
					self.DimmedTextColor.b,
					self.DimmedTextColor.a,
					UIFont.Small,
					true
				)
				self.labelCowardlyLose:setTooltip(getText("UI_ETW_LooseTooltip"))
				self:addChild(self.labelCowardlyLose)

				str = "- " .. getCachedTraitUIName(CharacterTrait.PACIFIST)
				self.labelPacifistLose = ISLabel:new(
					barStartPosition + barLength * 0.3 - strLen(textManager, str) / 2,
					y,
					FONT_HGT_SMALL,
					str,
					self.DimmedTextColor.r,
					self.DimmedTextColor.g,
					self.DimmedTextColor.b,
					self.DimmedTextColor.a,
					UIFont.Small,
					true
				)
				self.labelPacifistLose:setTooltip(getText("UI_ETW_LooseTooltip"))
				self:addChild(self.labelPacifistLose)

				str = "+ " .. getCachedTraitUIName(CharacterTrait.BRAVE)
				self.labelBraveryGain = ISLabel:new(
					barStartPosition + barLength * 0.6 - strLen(textManager, str) / 2,
					y,
					FONT_HGT_SMALL,
					str,
					self.DimmedTextColor.r,
					self.DimmedTextColor.g,
					self.DimmedTextColor.b,
					self.DimmedTextColor.a,
					UIFont.Small,
					true
				)
				self.labelBraveryGain:setTooltip(getText("UI_ETW_GainTooltip"))
				self:addChild(self.labelBraveryGain)

				y = y + FONT_HGT_SMALL

				self.labelBraveryBarName = ISLabel:new(
					barStartPosition - lineStartPosition,
					y,
					FONT_HGT_SMALL,
					getText("Sandbox_ETW_BraverySystem"),
					self.TextColor.r,
					self.TextColor.g,
					self.TextColor.b,
					self.TextColor.a,
					UIFont.Small,
					false
				)
				self.labelBraveryBarName:setTooltip(getText("Sandbox_ETW_BraverySystemKills_tooltip"))
				self:addChild(self.labelBraveryBarName)

				self.barBravery = ISGradientBar:new(barStartPosition, y, barLength, FONT_HGT_SMALL)
				self.barBravery:setGradientTexture(redYellowGreenGradient)
				self.barBravery:setValue(1)
				self.barBravery:setHighlightRadius(highlightRadius)
				self.barBravery:setDoKnob(false)
				self:addChild(self.barBravery)

				y = y + FONT_HGT_SMALL

				str = "- " .. getCachedTraitUIName(CharacterTrait.HEMOPHOBIC)
				self.labelHemophobicLose = ISLabel:new(
					barStartPosition + barLength * 0.2 - strLen(textManager, str) / 2,
					y,
					FONT_HGT_SMALL,
					str,
					self.DimmedTextColor.r,
					self.DimmedTextColor.g,
					self.DimmedTextColor.b,
					self.DimmedTextColor.a,
					UIFont.Small,
					true
				)
				self.labelHemophobicLose:setTooltip(getText("UI_ETW_LooseTooltip"))
				self:addChild(self.labelHemophobicLose)

				str = "+ " .. getCachedTraitUIName(CharacterTrait.ADRENALINE_JUNKIE)
				self.labelAdrenalineJunkieGain = ISLabel:new(
					barStartPosition + barLength * 0.4 - strLen(textManager, str) / 2,
					y,
					FONT_HGT_SMALL,
					str,
					self.DimmedTextColor.r,
					self.DimmedTextColor.g,
					self.DimmedTextColor.b,
					self.DimmedTextColor.a,
					UIFont.Small,
					true
				)
				self.labelAdrenalineJunkieGain:setTooltip(getText("UI_ETW_GainTooltip"))
				self:addChild(self.labelAdrenalineJunkieGain)

				self.labelDesensitizedGain = ISLabel:new(
					barEndPosition,
					y,
					FONT_HGT_SMALL,
					"+ " .. getCachedTraitUIName(CharacterTrait.DESENSITIZED),
					self.DimmedTextColor.r,
					self.DimmedTextColor.g,
					self.DimmedTextColor.b,
					self.DimmedTextColor.a,
					UIFont.Small,
					false
				)
				self.labelDesensitizedGain:setTooltip(getText("UI_ETW_GainTooltip"))
				self:addChild(self.labelDesensitizedGain)

				y = y + FONT_HGT_SMALL
			end

			y = y + FONT_HGT_SMALL / 2

			if
				ETW_CommonLogicChecks.EagleEyedShouldExecute(player)
				and not playerHasDelayedTraitNoCache(player, CharacterTrait.EAGLE_EYED)
			then
				arrangeColumnsInTable()
				self.labelEagleEyedProgress = ISLabel:new(
					x,
					y,
					FONT_HGT_SMALL,
					"",
					self.TextColor.r,
					self.TextColor.g,
					self.TextColor.b,
					self.TextColor.a,
					UIFont.Small,
					true
				)
				self.labelEagleEyedProgress:setTooltip(getText("Sandbox_ETW_EagleEyedKills"))
				self:addChild(self.labelEagleEyedProgress)
			end

			if
				ETW_CommonLogicChecks.HoarderShouldExecute(player)
				and not playerHasDelayedTraitNoCache(player, ETWTraitsRegistry.HOARDER)
			then
				arrangeColumnsInTable()
				self.labelHoarderProgress = ISLabel:new(
					x,
					y,
					FONT_HGT_SMALL,
					"",
					self.TextColor.r,
					self.TextColor.g,
					self.TextColor.b,
					self.TextColor.a,
					UIFont.Small,
					true
				)
				self.labelHoarderProgress:setTooltip(getText("Sandbox_ETW_HoarderSkill"))
				self:addChild(self.labelHoarderProgress)
			end

			if
				ETW_CommonLogicChecks.GymRatShouldExecute(player)
				and not playerHasDelayedTraitNoCache(player, ETWTraitsRegistry.GYM_RAT)
			then
				arrangeColumnsInTable()
				self.labelGymRatProgress = ISLabel:new(
					x,
					y,
					FONT_HGT_SMALL,
					"",
					self.TextColor.r,
					self.TextColor.g,
					self.TextColor.b,
					self.TextColor.a,
					UIFont.Small,
					true
				)
				self.labelGymRatProgress:setTooltip(getText("Sandbox_ETW_GymRatSkill_tooltip"))
				self:addChild(self.labelGymRatProgress)
			end

			if
				ETW_CommonLogicChecks.RunnerShouldExecute(player)
				and not playerHasDelayedTraitNoCache(player, CharacterTrait.JOGGER)
			then
				arrangeColumnsInTable()
				self.labelRunnerProgress = ISLabel:new(
					x,
					y,
					FONT_HGT_SMALL,
					"",
					self.TextColor.r,
					self.TextColor.g,
					self.TextColor.b,
					self.TextColor.a,
					UIFont.Small,
					true
				)
				self.labelRunnerProgress:setTooltip(getText("Sandbox_ETW_RunnerSkill"))
				self:addChild(self.labelRunnerProgress)
			end

			if
				ETW_CommonLogicChecks.LightStepShouldExecute(player)
				and not playerHasDelayedTraitNoCache(player, ETWTraitsRegistry.LIGHTSTEP)
			then
				arrangeColumnsInTable()
				self.labelLightStepProgress = ISLabel:new(
					x,
					y,
					FONT_HGT_SMALL,
					"",
					self.TextColor.r,
					self.TextColor.g,
					self.TextColor.b,
					self.TextColor.a,
					UIFont.Small,
					true
				)
				self.labelLightStepProgress:setTooltip(getText("Sandbox_ETW_LightStepSkill"))
				self:addChild(self.labelLightStepProgress)
			end

			if
				ETW_CommonLogicChecks.GymnastShouldExecute(player)
				and not playerHasDelayedTraitNoCache(player, CharacterTrait.GYMNAST)
			then
				arrangeColumnsInTable()
				self.labelGymnastProgress = ISLabel:new(
					x,
					y,
					FONT_HGT_SMALL,
					getText(""),
					self.TextColor.r,
					self.TextColor.g,
					self.TextColor.b,
					self.TextColor.a,
					UIFont.Small,
					true
				)
				self.labelGymnastProgress:setTooltip(getText("Sandbox_ETW_GymnastSkill_tooltip"))
				self:addChild(self.labelGymnastProgress)
			end

			if
				ETW_CommonLogicChecks.ClumsyShouldExecute(player)
				and not playerHasDelayedTraitNoCache(player, CharacterTrait.CLUMSY)
			then
				arrangeColumnsInTable()
				self.labelClumsyProgress = ISLabel:new(
					x,
					y,
					FONT_HGT_SMALL,
					getText(""),
					self.TextColor.r,
					self.TextColor.g,
					self.TextColor.b,
					self.TextColor.a,
					UIFont.Small,
					true
				)
				self.labelClumsyProgress:setTooltip(getText("Sandbox_ETW_ClumsySkill_tooltip"))
				self:addChild(self.labelClumsyProgress)
			end

			if
				ETW_CommonLogicChecks.GracefulShouldExecute(player)
				and not playerHasDelayedTraitNoCache(player, CharacterTrait.GRACEFUL)
			then
				arrangeColumnsInTable()
				self.labelGracefulProgress = ISLabel:new(
					x,
					y,
					FONT_HGT_SMALL,
					getText(""),
					self.TextColor.r,
					self.TextColor.g,
					self.TextColor.b,
					self.TextColor.a,
					UIFont.Small,
					true
				)
				self.labelGracefulProgress:setTooltip(getText("Sandbox_ETW_GracefulSkill_tooltip"))
				self:addChild(self.labelGracefulProgress)
			end

			if
				ETW_CommonLogicChecks.BurglarShouldExecute(player)
				and not playerHasDelayedTraitNoCache(player, CharacterTrait.BURGLAR)
			then
				arrangeColumnsInTable()
				self.labelBurglarProgress = ISLabel:new(
					x,
					y,
					FONT_HGT_SMALL,
					getText(""),
					self.TextColor.r,
					self.TextColor.g,
					self.TextColor.b,
					self.TextColor.a,
					UIFont.Small,
					true
				)
				self.labelBurglarProgress:setTooltip(getText("Sandbox_ETW_BurglarSkill_tooltip"))
				self:addChild(self.labelBurglarProgress)
			end

			if
				ETW_CommonLogicChecks.LowProfileShouldExecute(player)
				and not playerHasDelayedTraitNoCache(player, ETWTraitsRegistry.LOW_PROFILE)
			then
				arrangeColumnsInTable()
				self.labelLowProfileProgress = ISLabel:new(
					x,
					y,
					FONT_HGT_SMALL,
					getText(""),
					self.TextColor.r,
					self.TextColor.g,
					self.TextColor.b,
					self.TextColor.a,
					UIFont.Small,
					true
				)
				self.labelLowProfileProgress:setTooltip(getText("Sandbox_ETW_LowProfileSkill"))
				self:addChild(self.labelLowProfileProgress)
			end

			if
				ETW_CommonLogicChecks.ConspicuousShouldExecute(player)
				and not playerHasDelayedTraitNoCache(player, CharacterTrait.CONSPICUOUS)
			then
				arrangeColumnsInTable()
				self.labelConspicuousProgress = ISLabel:new(
					x,
					y,
					FONT_HGT_SMALL,
					getText(""),
					self.TextColor.r,
					self.TextColor.g,
					self.TextColor.b,
					self.TextColor.a,
					UIFont.Small,
					true
				)
				self.labelConspicuousProgress:setTooltip(getText("Sandbox_ETW_ConspicuousSkill"))
				self:addChild(self.labelConspicuousProgress)
			end

			if
				ETW_CommonLogicChecks.InconspicuousShouldExecute(player)
				and not playerHasDelayedTraitNoCache(player, CharacterTrait.INCONSPICUOUS)
			then
				arrangeColumnsInTable()
				self.labelInconspicuousProgress = ISLabel:new(
					x,
					y,
					FONT_HGT_SMALL,
					getText(""),
					self.TextColor.r,
					self.TextColor.g,
					self.TextColor.b,
					self.TextColor.a,
					UIFont.Small,
					true
				)
				self.labelInconspicuousProgress:setTooltip(getText("Sandbox_ETW_InconspicuousSkill"))
				self:addChild(self.labelInconspicuousProgress)
			end

			if
				ETW_CommonLogicChecks.HunterShouldExecute(player)
				and not playerHasDelayedTraitNoCache(player, CharacterTrait.HUNTER)
			then
				local levels = sneaking + aiming + trapping + shortBlade
				if sneaking < 2 or aiming < 2 or trapping < 2 or shortBlade < 2 or levels < SBvars.HunterSkill then
					arrangeColumnsInTable()
					self.labelHunterSkillProgress = ISLabel:new(
						x,
						y,
						FONT_HGT_SMALL,
						getText(""),
						self.TextColor.r,
						self.TextColor.g,
						self.TextColor.b,
						self.TextColor.a,
						UIFont.Small,
						true
					)
					self.labelHunterSkillProgress:setTooltip(getText("Sandbox_ETW_HunterSkill_tooltip"))
					self:addChild(self.labelHunterSkillProgress)
				end
				if (shortBladeKills + firearmKills) < SBvars.HunterKills then
					arrangeColumnsInTable()
					self.labelHunterKillsProgress = ISLabel:new(
						x,
						y,
						FONT_HGT_SMALL,
						getText(""),
						self.TextColor.r,
						self.TextColor.g,
						self.TextColor.b,
						self.TextColor.a,
						UIFont.Small,
						true
					)
					self.labelHunterKillsProgress:setTooltip(
						getText("Sandbox_ETW_HunterKills") .. " (" .. getText("Sandbox_ETW_HunterKills_tooltip") .. ")"
					)
					self:addChild(self.labelHunterKillsProgress)
				end
			end

			if
				ETW_CommonLogicChecks.BladeEnthusiastShouldExecute(player)
				and not playerHasDelayedTraitNoCache(player, ETWTraitsRegistry.BLADE_ENTHUSIAST)
			then
				if longBlade < SBvars.BladeEnthusiastSkill then
					arrangeColumnsInTable()
					self.labelBladeEnthusiastSkillProgress = ISLabel:new(
						x,
						y,
						FONT_HGT_SMALL,
						getText(""),
						self.TextColor.r,
						self.TextColor.g,
						self.TextColor.b,
						self.TextColor.a,
						UIFont.Small,
						true
					)
					self.labelBladeEnthusiastSkillProgress:setTooltip(getText("Sandbox_ETW_BladeEnthusiastSkill"))
					self:addChild(self.labelBladeEnthusiastSkillProgress)
				end
				if longBladeKills < SBvars.BladeEnthusiastKills then
					arrangeColumnsInTable()
					self.labelBladeEnthusiastKillsProgress = ISLabel:new(
						x,
						y,
						FONT_HGT_SMALL,
						getText(""),
						self.TextColor.r,
						self.TextColor.g,
						self.TextColor.b,
						self.TextColor.a,
						UIFont.Small,
						true
					)
					self.labelBladeEnthusiastKillsProgress:setTooltip(getText("Sandbox_ETW_BladeEnthusiastKills"))
					self:addChild(self.labelBladeEnthusiastKillsProgress)
				end
			end

			if
				ETW_CommonLogicChecks.BrawlerShouldExecute(player)
				and not playerHasDelayedTraitNoCache(player, CharacterTrait.BRAWLER)
			then
				if (axe + longBlunt) < SBvars.BrawlerSkill then
					arrangeColumnsInTable()
					self.labelBrawlerSkillProgress = ISLabel:new(
						x,
						y,
						FONT_HGT_SMALL,
						getText(""),
						self.TextColor.r,
						self.TextColor.g,
						self.TextColor.b,
						self.TextColor.a,
						UIFont.Small,
						true
					)
					self.labelBrawlerSkillProgress:setTooltip(getText("Sandbox_ETW_BrawlerSkill_tooltip"))
					self:addChild(self.labelBrawlerSkillProgress)
				end

				if (axeKills + longBluntKills) < SBvars.BrawlerKills then
					arrangeColumnsInTable()
					self.labelBrawlerKillsProgress = ISLabel:new(
						x,
						y,
						FONT_HGT_SMALL,
						getText(""),
						self.TextColor.r,
						self.TextColor.g,
						self.TextColor.b,
						self.TextColor.a,
						UIFont.Small,
						true
					)
					self.labelBrawlerKillsProgress:setTooltip(
						getText("Sandbox_ETW_BrawlerKills")
							.. " ("
							.. getText("Sandbox_ETW_BrawlerKills_tooltip")
							.. ")"
					)
					self:addChild(self.labelBrawlerKillsProgress)
				end
			end

			if
				ETW_CommonLogicChecks.AxeThrowerShouldExecute(player)
				and not playerHasDelayedTraitNoCache(player, ETWTraitsRegistry.AXE_THROWER)
			then
				if axe < SBvars.AxeThrowerSkill then
					arrangeColumnsInTable()
					self.labelAxeThrowerSkillProgress = ISLabel:new(
						x,
						y,
						FONT_HGT_SMALL,
						getText(""),
						self.TextColor.r,
						self.TextColor.g,
						self.TextColor.b,
						self.TextColor.a,
						UIFont.Small,
						true
					)
					self.labelAxeThrowerSkillProgress:setTooltip(getText("Sandbox_ETW_AxeThrowerSkill"))
					self:addChild(self.labelAxeThrowerSkillProgress)
				end
				if axeKills < SBvars.AxeThrowerKills then
					arrangeColumnsInTable()
					self.labelAxeThrowerKillsProgress = ISLabel:new(
						x,
						y,
						FONT_HGT_SMALL,
						getText(""),
						self.TextColor.r,
						self.TextColor.g,
						self.TextColor.b,
						self.TextColor.a,
						UIFont.Small,
						true
					)
					self.labelAxeThrowerKillsProgress:setTooltip(getText("Sandbox_ETW_AxeThrowerKills"))
					self:addChild(self.labelAxeThrowerKillsProgress)
				end
			end

			if
				ETW_CommonLogicChecks.StickFighterShouldExecute(player)
				and not playerHasDelayedTraitNoCache(player, ETWTraitsRegistry.STICK_FIGHTER)
			then
				if shortBlunt < SBvars.StickFighterSkill then
					arrangeColumnsInTable()
					self.labelStickFighterSkillProgress = ISLabel:new(
						x,
						y,
						FONT_HGT_SMALL,
						getText(""),
						self.TextColor.r,
						self.TextColor.g,
						self.TextColor.b,
						self.TextColor.a,
						UIFont.Small,
						true
					)
					self.labelStickFighterSkillProgress:setTooltip(getText("Sandbox_ETW_StickFighterSkill"))
					self:addChild(self.labelStickFighterSkillProgress)
				end
				if shortBluntKills < SBvars.StickFighterKills then
					arrangeColumnsInTable()
					self.labelStickFighterKillsProgress = ISLabel:new(
						x,
						y,
						FONT_HGT_SMALL,
						getText(""),
						self.TextColor.r,
						self.TextColor.g,
						self.TextColor.b,
						self.TextColor.a,
						UIFont.Small,
						true
					)
					self.labelStickFighterKillsProgress:setTooltip(getText("Sandbox_ETW_StickFighterKills"))
					self:addChild(self.labelStickFighterKillsProgress)
				end
			end

			if
				ETW_CommonLogicChecks.KnifeFighterShouldExecute(player)
				and not playerHasDelayedTraitNoCache(player, ETWTraitsRegistry.KNIFE_FIGHTER)
			then
				if shortBlade < SBvars.KnifeFighterSkill then
					arrangeColumnsInTable()
					self.labelKnifeFighterSkillProgress = ISLabel:new(
						x,
						y,
						FONT_HGT_SMALL,
						getText(""),
						self.TextColor.r,
						self.TextColor.g,
						self.TextColor.b,
						self.TextColor.a,
						UIFont.Small,
						true
					)
					self.labelKnifeFighterSkillProgress:setTooltip(getText("Sandbox_ETW_KnifeFighterSkill"))
					self:addChild(self.labelKnifeFighterSkillProgress)
				end
				if shortBladeKills < SBvars.KnifeFighterKills then
					arrangeColumnsInTable()
					self.labelKnifeFighterKillsProgress = ISLabel:new(
						x,
						y,
						FONT_HGT_SMALL,
						getText(""),
						self.TextColor.r,
						self.TextColor.g,
						self.TextColor.b,
						self.TextColor.a,
						UIFont.Small,
						true
					)
					self.labelKnifeFighterKillsProgress:setTooltip(getText("Sandbox_ETW_KnifeFighterKills"))
					self:addChild(self.labelKnifeFighterKillsProgress)
				end
			end

			if
				ETW_CommonLogicChecks.PolearmFighterShouldExecute(player)
				and not playerHasDelayedTraitNoCache(player, ETWTraitsRegistry.POLEARM_FIGHTER)
			then
				if spear < SBvars.PolearmFighterSkill then
					arrangeColumnsInTable()
					self.labelPolearmFighterSkillProgress = ISLabel:new(
						x,
						y,
						FONT_HGT_SMALL,
						getText(""),
						self.TextColor.r,
						self.TextColor.g,
						self.TextColor.b,
						self.TextColor.a,
						UIFont.Small,
						true
					)
					self.labelPolearmFighterSkillProgress:setTooltip(getText("Sandbox_ETW_PolearmFighterSkill"))
					self:addChild(self.labelPolearmFighterSkillProgress)
				end
				if spearKills < SBvars.PolearmFighterKills then
					arrangeColumnsInTable()
					self.labelPolearmFighterKillsProgress = ISLabel:new(
						x,
						y,
						FONT_HGT_SMALL,
						getText(""),
						self.TextColor.r,
						self.TextColor.g,
						self.TextColor.b,
						self.TextColor.a,
						UIFont.Small,
						true
					)
					self.labelPolearmFighterKillsProgress:setTooltip(getText("Sandbox_ETW_PolearmFighterKills"))
					self:addChild(self.labelPolearmFighterKillsProgress)
				end
			end

			if
				ETW_CommonLogicChecks.RestorationExpertShouldExecute(player)
				and not playerHasDelayedTraitNoCache(player, ETWTraitsRegistry.RESTORATION_EXPERT)
			then
				arrangeColumnsInTable()
				self.labelRestorationExpertSkillProgress = ISLabel:new(
					x,
					y,
					FONT_HGT_SMALL,
					getText(""),
					self.TextColor.r,
					self.TextColor.g,
					self.TextColor.b,
					self.TextColor.a,
					UIFont.Small,
					true
				)
				self.labelRestorationExpertSkillProgress:setTooltip(getText("Sandbox_ETW_RestorationExpertSkill"))
				self:addChild(self.labelRestorationExpertSkillProgress)
			end

			if
				ETW_CommonLogicChecks.HandyShouldExecute(player)
				and not playerHasDelayedTraitNoCache(player, CharacterTrait.HANDY)
			then
				arrangeColumnsInTable()
				self.labelHandySkillProgress = ISLabel:new(
					x,
					y,
					FONT_HGT_SMALL,
					getText(""),
					self.TextColor.r,
					self.TextColor.g,
					self.TextColor.b,
					self.TextColor.a,
					UIFont.Small,
					true
				)
				self.labelHandySkillProgress:setTooltip(getText("Sandbox_ETW_HandySkill_tooltip"))
				self:addChild(self.labelHandySkillProgress)
			end

			if
				ETW_CommonLogicChecks.FurnitureAssemblerShouldExecute(player)
				and not playerHasDelayedTraitNoCache(player, ETWTraitsRegistry.FURNITURE_ASSEMBLER)
			then
				arrangeColumnsInTable()
				self.labelFurnitureAssemblerProgress = ISLabel:new(
					x,
					y,
					FONT_HGT_SMALL,
					getText(""),
					self.TextColor.r,
					self.TextColor.g,
					self.TextColor.b,
					self.TextColor.a,
					UIFont.Small,
					true
				)
				self.labelFurnitureAssemblerProgress:setTooltip(getText("Sandbox_ETW_FurnitureAssemblerSkill"))
				self:addChild(self.labelFurnitureAssemblerProgress)
			end

			if
				ETW_CommonLogicChecks.HomeCookShouldExecute(player)
				and not playerHasDelayedTraitNoCache(player, ETWTraitsRegistry.HOME_COOK)
			then
				arrangeColumnsInTable()
				self.labelHomeCookProgress = ISLabel:new(
					x,
					y,
					FONT_HGT_SMALL,
					getText(""),
					self.TextColor.r,
					self.TextColor.g,
					self.TextColor.b,
					self.TextColor.a,
					UIFont.Small,
					true
				)
				self.labelHomeCookProgress:setTooltip(getText("Sandbox_ETW_HomeCookSkill"))
				self:addChild(self.labelHomeCookProgress)
			end

			if
				ETW_CommonLogicChecks.CookShouldExecute(player)
				and not playerHasDelayedTraitNoCache(player, CharacterTrait.COOK)
			then
				arrangeColumnsInTable()
				self.labelCookProgress = ISLabel:new(
					x,
					y,
					FONT_HGT_SMALL,
					getText(""),
					self.TextColor.r,
					self.TextColor.g,
					self.TextColor.b,
					self.TextColor.a,
					UIFont.Small,
					true
				)
				self.labelCookProgress:setTooltip(getText("Sandbox_ETW_CookSkill"))
				self:addChild(self.labelCookProgress)
			end

			if
				ETW_CommonLogicChecks.FirstAidShouldExecute(player)
				and not playerHasDelayedTraitNoCache(player, CharacterTrait.FIRST_AID)
			then
				arrangeColumnsInTable()
				self.labelFirstAidProgress = ISLabel:new(
					x,
					y,
					FONT_HGT_SMALL,
					getText(""),
					self.TextColor.r,
					self.TextColor.g,
					self.TextColor.b,
					self.TextColor.a,
					UIFont.Small,
					true
				)
				self.labelFirstAidProgress:setTooltip(getText("Sandbox_ETW_FirstAidSkill"))
				self:addChild(self.labelFirstAidProgress)
			end

			if
				ETW_CommonLogicChecks.AVClubShouldExecute(player)
				and not playerHasDelayedTraitNoCache(player, ETWTraitsRegistry.AV_CLUB)
			then
				arrangeColumnsInTable()
				self.labelAVClubProgress = ISLabel:new(
					x,
					y,
					FONT_HGT_SMALL,
					getText(""),
					self.TextColor.r,
					self.TextColor.g,
					self.TextColor.b,
					self.TextColor.a,
					UIFont.Small,
					true
				)
				self.labelAVClubProgress:setTooltip(getText("Sandbox_ETW_AVClubSkill"))
				self:addChild(self.labelAVClubProgress)
			end

			if
				ETW_CommonLogicChecks.BodyWorkEnthusiastShouldExecute(player)
				and not playerHasDelayedTraitNoCache(player, ETWTraitsRegistry.BODYWORK_ENTHUSIAST)
			then
				if metalworking + mechanics < SBvars.BodyworkEnthusiastSkill then
					arrangeColumnsInTable()
					self.labelBodyWorkEnthusiastSkillProgress = ISLabel:new(
						x,
						y,
						FONT_HGT_SMALL,
						getText(""),
						self.TextColor.r,
						self.TextColor.g,
						self.TextColor.b,
						self.TextColor.a,
						UIFont.Small,
						true
					)
					self.labelBodyWorkEnthusiastSkillProgress:setTooltip(
						getText("Sandbox_ETW_BodyworkEnthusiastSkill_tooltip")
					)
					self:addChild(self.labelBodyWorkEnthusiastSkillProgress)
				end
				local vehiclePartRepairs = (modData and modData.VehiclePartRepairs) or 0
				if vehiclePartRepairs < SBvars.BodyworkEnthusiastRepairs then
					arrangeColumnsInTable()
					self.labelBodyWorkEnthusiastRepairsProgress = ISLabel:new(
						x,
						y,
						FONT_HGT_SMALL,
						getText(""),
						self.TextColor.r,
						self.TextColor.g,
						self.TextColor.b,
						self.TextColor.a,
						UIFont.Small,
						true
					)
					self.labelBodyWorkEnthusiastRepairsProgress:setTooltip(
						getText("Sandbox_ETW_BodyworkEnthusiastRepairs_tooltip")
					)
					self:addChild(self.labelBodyWorkEnthusiastRepairsProgress)
				end
			end

			if
				ETW_CommonLogicChecks.MechanicsShouldExecute(player)
				and not playerHasDelayedTraitNoCache(player, CharacterTrait.MECHANICS)
			then
				if mechanics < SBvars.MechanicsSkill then
					arrangeColumnsInTable()
					self.labelMechanicsSkillProgress = ISLabel:new(
						x,
						y,
						FONT_HGT_SMALL,
						getText(""),
						self.TextColor.r,
						self.TextColor.g,
						self.TextColor.b,
						self.TextColor.a,
						UIFont.Small,
						true
					)
					self.labelMechanicsSkillProgress:setTooltip(getText("Sandbox_ETW_MechanicsSkill"))
					self:addChild(self.labelMechanicsSkillProgress)
				end
				local vehiclePartRepairs = (modData and modData.VehiclePartRepairs) or 0
				if vehiclePartRepairs < SBvars.MechanicsRepairs then
					arrangeColumnsInTable()
					self.labelMechanicsRepairsProgress = ISLabel:new(
						x,
						y,
						FONT_HGT_SMALL,
						getText(""),
						self.TextColor.r,
						self.TextColor.g,
						self.TextColor.b,
						self.TextColor.a,
						UIFont.Small,
						true
					)
					self.labelMechanicsRepairsProgress:setTooltip(getText("Sandbox_ETW_MechanicsRepairs_tooltip"))
					self:addChild(self.labelMechanicsRepairsProgress)
				end
			end

			if
				ETW_CommonLogicChecks.SewerShouldExecute(player)
				and not playerHasDelayedTraitNoCache(player, CharacterTrait.TAILOR)
			then
				if tailoring < SBvars.SewerSkill then
					arrangeColumnsInTable()
					self.labelTailorSkillProgress = ISLabel:new(
						x,
						y,
						FONT_HGT_SMALL,
						getText(""),
						self.TextColor.r,
						self.TextColor.g,
						self.TextColor.b,
						self.TextColor.a,
						UIFont.Small,
						true
					)
					self.labelTailorSkillProgress:setTooltip(getText("Sandbox_ETW_SewerSkill"))
					self:addChild(self.labelTailorSkillProgress)
				end

				local uniqueClothingRipped = (
					modData
					and modData.UniqueClothingRipped
					and #modData.UniqueClothingRipped
				) or 0
				if uniqueClothingRipped < SBvars.SewerUniqueClothesRipped then
					arrangeColumnsInTable()
					self.labelTailorRippedClothesProgress = ISLabel:new(
						x,
						y,
						FONT_HGT_SMALL,
						getText(""),
						self.TextColor.r,
						self.TextColor.g,
						self.TextColor.b,
						self.TextColor.a,
						UIFont.Small,
						true
					)
					self.labelTailorRippedClothesProgress:setTooltip(
						getText("Sandbox_ETW_SewerUniqueClothesRipped_tooltip")
					)
					self:addChild(self.labelTailorRippedClothesProgress)
				end
			end

			if
				ETW_CommonLogicChecks.PetTherapyShouldExecute(player)
				and not playerHasDelayedTraitNoCache(player, ETWTraitsRegistry.PET_THERAPY)
			then
				if husbandry < SBvars.PetTherapySkill then
					arrangeColumnsInTable()
					self.labelPetTherapySkillProgress = ISLabel:new(
						x,
						y,
						FONT_HGT_SMALL,
						getText(""),
						self.TextColor.r,
						self.TextColor.g,
						self.TextColor.b,
						self.TextColor.a,
						UIFont.Small,
						true
					)
					self.labelPetTherapySkillProgress:setTooltip(getText("Sandbox_ETW_PetTherapySkill"))
					self:addChild(self.labelPetTherapySkillProgress)
				end

				local uniqueAnimalsPetted = (
					modData
					and modData.AnimalsSystem
					and modData.AnimalsSystem.UniqueAnimalsPetted
					and #modData.AnimalsSystem.UniqueAnimalsPetted
				) or 0
				if uniqueAnimalsPetted < SBvars.PetTherapyUniqueAnimalsPetted then
					arrangeColumnsInTable()
					self.labelPetTherapyPettingProgress = ISLabel:new(
						x,
						y,
						FONT_HGT_SMALL,
						getText(""),
						self.TextColor.r,
						self.TextColor.g,
						self.TextColor.b,
						self.TextColor.a,
						UIFont.Small,
						true
					)
					self.labelPetTherapyPettingProgress:setTooltip(
						getText("Sandbox_ETW_PetTherapyUniqueAnimalsPetted_tooltip")
					)
					self:addChild(self.labelPetTherapyPettingProgress)
				end
			end

			if
				ETW_CommonLogicChecks.GunEnthusiastShouldExecute(player)
				and not playerHasDelayedTraitNoCache(player, ETWTraitsRegistry.GUN_ENTHUSIAST)
			then
				if aiming + reloading < SBvars.GunEnthusiastSkill then
					arrangeColumnsInTable()
					self.labelGunEnthusiastSkillProgress = ISLabel:new(
						x,
						y,
						FONT_HGT_SMALL,
						getText(""),
						self.TextColor.r,
						self.TextColor.g,
						self.TextColor.b,
						self.TextColor.a,
						UIFont.Small,
						true
					)
					self.labelGunEnthusiastSkillProgress:setTooltip(getText("Sandbox_ETW_GunEnthusiastSkill_tooltip"))
					self:addChild(self.labelGunEnthusiastSkillProgress)
				end

				if firearmKills < SBvars.GunEnthusiastKills then
					arrangeColumnsInTable()
					self.labelGunEnthusiastKillsProgress = ISLabel:new(
						x,
						y,
						FONT_HGT_SMALL,
						getText(""),
						self.TextColor.r,
						self.TextColor.g,
						self.TextColor.b,
						self.TextColor.a,
						UIFont.Small,
						true
					)
					self.labelGunEnthusiastKillsProgress:setTooltip(getText("Sandbox_ETW_GunEnthusiastKills"))
					self:addChild(self.labelGunEnthusiastKillsProgress)
				end
			end

			if
				ETW_CommonLogicChecks.AnglerShouldExecute(player)
				and not playerHasDelayedTraitNoCache(player, CharacterTrait.FISHING)
			then
				arrangeColumnsInTable()
				self.labelAnglerProgress = ISLabel:new(
					x,
					y,
					FONT_HGT_SMALL,
					getText(""),
					self.TextColor.r,
					self.TextColor.g,
					self.TextColor.b,
					self.TextColor.a,
					UIFont.Small,
					true
				)
				self.labelAnglerProgress:setTooltip(getText("Sandbox_ETW_FishingSkill"))
				self:addChild(self.labelAnglerProgress)
			end

			if
				ETW_CommonLogicChecks.HikerShouldExecute(player)
				and not playerHasDelayedTraitNoCache(player, CharacterTrait.HIKER)
			then
				arrangeColumnsInTable()
				self.labelHikerProgress = ISLabel:new(
					x,
					y,
					FONT_HGT_SMALL,
					getText(""),
					self.TextColor.r,
					self.TextColor.g,
					self.TextColor.b,
					self.TextColor.a,
					UIFont.Small,
					true
				)
				self.labelHikerProgress:setTooltip(getText("Sandbox_ETW_HikerSkill_tooltip"))
				self:addChild(self.labelHikerProgress)
			end

			if
				ETW_CommonLogicChecks.CatEyesShouldExecute(player)
				and not playerHasDelayedTraitNoCache(player, CharacterTrait.NIGHT_VISION)
			then
				arrangeColumnsInTable()
				self.labelCatEyesProgress = ISLabel:new(
					x,
					y,
					FONT_HGT_SMALL,
					getText(""),
					self.TextColor.r,
					self.TextColor.g,
					self.TextColor.b,
					self.TextColor.a,
					UIFont.Small,
					true
				)
				self.labelCatEyesProgress:setTooltip(getText("Sandbox_ETW_CatEyesCounter_tooltip"))
				self:addChild(self.labelCatEyesProgress)
			end

			if
				ETW_CommonLogicChecks.HerbalistShouldExecute(player)
				and not playerHasDelayedTraitNoCache(player, CharacterTrait.HERBALIST)
			then
				arrangeColumnsInTable()
				self.labelHerbalistProgress = ISLabel:new(
					x,
					y,
					FONT_HGT_SMALL,
					getText(""),
					self.TextColor.r,
					self.TextColor.g,
					self.TextColor.b,
					self.TextColor.a,
					UIFont.Small,
					true
				)
				self.labelHerbalistProgress:setTooltip(getText("Sandbox_ETW_HerbalistHerbsPicked_tooltip"))
				self:addChild(self.labelHerbalistProgress)
			end

			if
				ETW_CommonLogicChecks.AxemanShouldExecute(player)
				and not playerHasDelayedTraitNoCache(player, CharacterTrait.AXEMAN)
			then
				arrangeColumnsInTable()
				self.labelAxemanProgress = ISLabel:new(
					x,
					y,
					FONT_HGT_SMALL,
					getText(""),
					self.TextColor.r,
					self.TextColor.g,
					self.TextColor.b,
					self.TextColor.a,
					UIFont.Small,
					true
				)
				self.labelAxemanProgress:setTooltip(getText("Sandbox_ETW_AxpertTrees_tooltip"))
				self:addChild(self.labelAxemanProgress)
			end

			if
				ETW_CommonLogicChecks.WhittlerShouldExecute(player)
				and not playerHasDelayedTraitNoCache(player, CharacterTrait.WHITTLER)
			then
				arrangeColumnsInTable()
				self.labelWhittlerProgress = ISLabel:new(
					x,
					y,
					FONT_HGT_SMALL,
					getText(""),
					self.TextColor.r,
					self.TextColor.g,
					self.TextColor.b,
					self.TextColor.a,
					UIFont.Small,
					true
				)
				self.labelWhittlerProgress:setTooltip(getText("Sandbox_ETW_WhittlerSkill"))
				self:addChild(self.labelWhittlerProgress)
			end

			if
				ETW_CommonLogicChecks.BlacksmithShouldExecute(player)
				and not playerHasDelayedTraitNoCache(player, CharacterTrait.BLACKSMITH)
			then
				arrangeColumnsInTable()
				self.labelBlacksmithProgress = ISLabel:new(
					x,
					y,
					FONT_HGT_SMALL,
					getText(""),
					self.TextColor.r,
					self.TextColor.g,
					self.TextColor.b,
					self.TextColor.a,
					UIFont.Small,
					true
				)
				self.labelBlacksmithProgress:setTooltip(getText("Sandbox_ETW_BlacksmithSkill_tooltip"))
				self:addChild(self.labelBlacksmithProgress)
			end

			if
				ETW_CommonLogicChecks.WildernessKnowledgeShouldExecute(player)
				and not playerHasDelayedTraitNoCache(player, CharacterTrait.WILDERNESS_KNOWLEDGE)
			then
				local levels = foraging + knapping + maintenance + carving
				if
					foraging < 2
					or knapping < 2
					or maintenance < 2
					or carving < 2
					or levels < SBvars.WildernessKnowledgeSkill
				then
					arrangeColumnsInTable(true)
					self.labelWildernessKnowledgeSkillProgress = ISLabel:new(
						x,
						y,
						FONT_HGT_SMALL,
						getText(""),
						self.TextColor.r,
						self.TextColor.g,
						self.TextColor.b,
						self.TextColor.a,
						UIFont.Small,
						true
					)
					self.labelWildernessKnowledgeSkillProgress:setTooltip(
						getText("Sandbox_ETW_WildernessKnowledgeSkill_tooltip")
					)
					self:addChild(self.labelWildernessKnowledgeSkillProgress)
				end
			end

			y = y + FONT_HGT_SMALL / 2

			if SBvars.DelayedTraitsSystem then
				y = y + FONT_HGT_SMALL * 1.5
				str = getText("Sandbox_ETW_DelayedTraitsSystem")
				self.labelDelayedTraitsSystem = ISLabel:new(
					WINDOW_WIDTH / 2 - strLen(textManager, str) / 2,
					y,
					FONT_HGT_SMALL,
					str,
					self.TextColor.r,
					self.TextColor.g,
					self.TextColor.b,
					self.TextColor.a,
					UIFont.Small,
					true
				)
				self.labelDelayedTraitsSystem:setTooltip(getText("Sandbox_ETW_DelayedTraitsSystem_tooltip"))
				self:addChild(self.labelDelayedTraitsSystem)

				self.buttonDelayedTraitsTooltip = ISButton:new(
					lineStartPosition,
					y + FONT_HGT_SMALL,
					WINDOW_WIDTH - lineStartPosition * 2,
					FONT_HGT_SMALL,
					"",
					self,
					nil
				)
				self.buttonDelayedTraitsTooltip:initialise()
				self.buttonDelayedTraitsTooltip.borderColor.a = 0
				self.buttonDelayedTraitsTooltip.backgroundColor.a = 0
				self.buttonDelayedTraitsTooltip.backgroundColorMouseOver.a = 0
				self.buttonDelayedTraitsTooltip:setTooltip(getText("Sandbox_ETW_DelayedTraitsSystem_tooltip"))
				self:addChild(self.buttonDelayedTraitsTooltip)
			end
		end

		local function buildNonPermanentTraitsSection()
			if ETW_CommonLogicChecks.BloodlustShouldExecute(player) then
				str = "- " .. getCachedTraitUIName(ETWTraitsRegistry.BLOODLUST)
				self.labelBloodlustLose = ISLabel:new(
					barOneFourthPosition - strLen(textManager, str) / 2,
					y,
					FONT_HGT_SMALL,
					str,
					self.DimmedTextColor.r,
					self.DimmedTextColor.g,
					self.DimmedTextColor.b,
					self.DimmedTextColor.a,
					UIFont.Small,
					true
				)
				self.labelBloodlustLose:setTooltip(getText("UI_ETW_LooseTooltip"))
				self:addChild(self.labelBloodlustLose)

				str = "+ " .. getCachedTraitUIName(ETWTraitsRegistry.BLOODLUST)
				self.labelBloodlustGain = ISLabel:new(
					barMidPosition,
					y,
					FONT_HGT_SMALL,
					str,
					self.DimmedTextColor.r,
					self.DimmedTextColor.g,
					self.DimmedTextColor.b,
					self.DimmedTextColor.a,
					UIFont.Small,
					true
				)
				self.labelBloodlustGain:setTooltip(getText("UI_ETW_GainTooltip"))
				self:addChild(self.labelBloodlustGain)

				y = y + FONT_HGT_SMALL

				self.labelBloodlustBarName = ISLabel:new(
					barStartPosition - lineStartPosition,
					y,
					FONT_HGT_SMALL,
					getCachedTraitUIName(ETWTraitsRegistry.BLOODLUST),
					self.TextColor.r,
					self.TextColor.g,
					self.TextColor.b,
					self.TextColor.a,
					UIFont.Small,
					false
				)
				self.labelBloodlustBarName:setTooltip(getText("Sandbox_ETW_BloodlustProgress_tooltip"))
				self:addChild(self.labelBloodlustBarName)

				self.barBloodlust = ISGradientBar:new(barStartPosition, y, barLength, FONT_HGT_SMALL)
				self.barBloodlust:setGradientTexture(redYellowGreenGradient)
				self.barBloodlust:setHighlightRadius(highlightRadius)
				self.barBloodlust:setDoKnob(false)
				self:addChild(self.barBloodlust)

				y = y + FONT_HGT_SMALL
			end

			if ETW_CommonLogicChecks.AsthmaticShouldExecute(player) then
				str = "+ " .. getCachedTraitUIName(CharacterTrait.ASTHMATIC)
				self.labelAsthmaticGain = ISLabel:new(
					barOneFourthPosition - strLen(textManager, str) / 2,
					y,
					FONT_HGT_SMALL,
					str,
					self.DimmedTextColor.r,
					self.DimmedTextColor.g,
					self.DimmedTextColor.b,
					self.DimmedTextColor.a,
					UIFont.Small,
					true
				)
				self.labelAsthmaticGain:setTooltip(getText("UI_ETW_GainTooltip"))
				self:addChild(self.labelAsthmaticGain)

				str = "- " .. getCachedTraitUIName(CharacterTrait.ASTHMATIC)
				self.labelAsthmaticLose = ISLabel:new(
					barThreeFourthPosition - strLen(textManager, str) / 2,
					y,
					FONT_HGT_SMALL,
					str,
					self.DimmedTextColor.r,
					self.DimmedTextColor.g,
					self.DimmedTextColor.b,
					self.DimmedTextColor.a,
					UIFont.Small,
					true
				)
				self.labelAsthmaticLose:setTooltip(getText("UI_ETW_LooseTooltip"))
				self:addChild(self.labelAsthmaticLose)

				y = y + FONT_HGT_SMALL

				self.labelAsthmaticBarName = ISLabel:new(
					barStartPosition - lineStartPosition,
					y,
					FONT_HGT_SMALL,
					getCachedTraitUIName(CharacterTrait.ASTHMATIC),
					self.TextColor.r,
					self.TextColor.g,
					self.TextColor.b,
					self.TextColor.a,
					UIFont.Small,
					false
				)
				self.labelAsthmaticBarName:setTooltip(getText("Sandbox_ETW_AsthmaticCounter_tooltip"))
				self:addChild(self.labelAsthmaticBarName)

				self.barAsthmatic = ISGradientBar:new(barStartPosition, y, barLength, FONT_HGT_SMALL)
				self.barAsthmatic:setGradientTexture(redYellowGreenGradient)
				self.barAsthmatic:setHighlightRadius(highlightRadius)
				self.barAsthmatic:setDoKnob(false)
				self:addChild(self.barAsthmatic)

				y = y + FONT_HGT_SMALL
			end

			if ETW_CommonLogicChecks.OutdoorsmanShouldExecute(player) then
				str = "- " .. getCachedTraitUIName(CharacterTrait.OUTDOORSMAN)
				self.labelOutdoorsmanLose = ISLabel:new(
					barOneThirdPosition - strLen(textManager, str) / 2,
					y,
					FONT_HGT_SMALL,
					str,
					self.DimmedTextColor.r,
					self.DimmedTextColor.g,
					self.DimmedTextColor.b,
					self.DimmedTextColor.a,
					UIFont.Small,
					true
				)
				self.labelOutdoorsmanLose:setTooltip(getText("UI_ETW_LooseTooltip"))
				self:addChild(self.labelOutdoorsmanLose)

				str = "+ " .. getCachedTraitUIName(CharacterTrait.OUTDOORSMAN)
				self.labelOutdoorsmanGain = ISLabel:new(
					barTwoThirdPosition - strLen(textManager, str) / 2,
					y,
					FONT_HGT_SMALL,
					str,
					self.DimmedTextColor.r,
					self.DimmedTextColor.g,
					self.DimmedTextColor.b,
					self.DimmedTextColor.a,
					UIFont.Small,
					true
				)
				self.labelOutdoorsmanGain:setTooltip(getText("UI_ETW_GainTooltip"))
				self:addChild(self.labelOutdoorsmanGain)

				y = y + FONT_HGT_SMALL

				self.labelOutdoorsmanBarName = ISLabel:new(
					barStartPosition - lineStartPosition,
					y,
					FONT_HGT_SMALL,
					getCachedTraitUIName(CharacterTrait.OUTDOORSMAN),
					self.TextColor.r,
					self.TextColor.g,
					self.TextColor.b,
					self.TextColor.a,
					UIFont.Small,
					false
				)
				self.labelOutdoorsmanBarName:setTooltip(getText("Sandbox_ETW_OutdoorsmanCounter_tooltip"))
				self:addChild(self.labelOutdoorsmanBarName)

				self.barOutdoorsman = ISGradientBar:new(barStartPosition, y, barLength, FONT_HGT_SMALL)
				self.barOutdoorsman:setGradientTexture(redYellowGreenGradient)
				self.barOutdoorsman:setHighlightRadius(highlightRadius)
				self.barOutdoorsman:setDoKnob(false)
				self:addChild(self.barOutdoorsman)

				y = y + FONT_HGT_SMALL
			end

			if ETW_CommonLogicChecks.FearOfLocationsSystemShouldExecute(player) then
				str = "+ " .. getCachedTraitUIName(CharacterTrait.AGORAPHOBIC)
				self.labelAgoraphobicGain = ISLabel:new(
					barOneThirdPosition - strLen(textManager, str) / 2,
					y,
					FONT_HGT_SMALL,
					str,
					self.DimmedTextColor.r,
					self.DimmedTextColor.g,
					self.DimmedTextColor.b,
					self.DimmedTextColor.a,
					UIFont.Small,
					true
				)
				self.labelAgoraphobicGain:setTooltip(getText("UI_ETW_GainTooltip"))
				self:addChild(self.labelAgoraphobicGain)

				str = "- " .. getCachedTraitUIName(CharacterTrait.AGORAPHOBIC)
				self.labelAgoraphobicLose = ISLabel:new(
					barTwoThirdPosition - strLen(textManager, str) / 2,
					y,
					FONT_HGT_SMALL,
					str,
					self.DimmedTextColor.r,
					self.DimmedTextColor.g,
					self.DimmedTextColor.b,
					self.DimmedTextColor.a,
					UIFont.Small,
					true
				)
				self.labelAgoraphobicLose:setTooltip(getText("UI_ETW_LooseTooltip"))
				self:addChild(self.labelAgoraphobicLose)

				y = y + FONT_HGT_SMALL

				self.labelAgoraphobicBarName = ISLabel:new(
					barStartPosition - lineStartPosition,
					y,
					FONT_HGT_SMALL,
					getCachedTraitUIName(CharacterTrait.AGORAPHOBIC),
					self.TextColor.r,
					self.TextColor.g,
					self.TextColor.b,
					self.TextColor.a,
					UIFont.Small,
					false
				)
				self.labelAgoraphobicBarName:setTooltip(getText("Sandbox_ETW_FearOfLocationsSystemCounter_tooltip"))
				self:addChild(self.labelAgoraphobicBarName)

				self.barAgoraphobic = ISGradientBar:new(barStartPosition, y, barLength, FONT_HGT_SMALL)
				self.barAgoraphobic:setGradientTexture(redYellowGreenGradient)
				self.barAgoraphobic:setHighlightRadius(highlightRadius)
				self.barAgoraphobic:setDoKnob(false)
				self:addChild(self.barAgoraphobic)

				y = y + FONT_HGT_SMALL

				str = "+ " .. getCachedTraitUIName(CharacterTrait.CLAUSTROPHOBIC)
				self.labelClaustrophobicGain = ISLabel:new(
					barOneThirdPosition - strLen(textManager, str) / 2,
					y,
					FONT_HGT_SMALL,
					str,
					self.DimmedTextColor.r,
					self.DimmedTextColor.g,
					self.DimmedTextColor.b,
					self.DimmedTextColor.a,
					UIFont.Small,
					true
				)
				self.labelClaustrophobicGain:setTooltip(getText("UI_ETW_GainTooltip"))
				self:addChild(self.labelClaustrophobicGain)

				str = "- " .. getCachedTraitUIName(CharacterTrait.CLAUSTROPHOBIC)
				self.labelClaustrophobicLose = ISLabel:new(
					barTwoThirdPosition - strLen(textManager, str) / 2,
					y,
					FONT_HGT_SMALL,
					str,
					self.DimmedTextColor.r,
					self.DimmedTextColor.g,
					self.DimmedTextColor.b,
					self.DimmedTextColor.a,
					UIFont.Small,
					true
				)
				self.labelClaustrophobicLose:setTooltip(getText("UI_ETW_LooseTooltip"))
				self:addChild(self.labelClaustrophobicLose)

				y = y + FONT_HGT_SMALL

				self.labelClaustrophobicBarName = ISLabel:new(
					barStartPosition - lineStartPosition,
					y,
					FONT_HGT_SMALL,
					getCachedTraitUIName(CharacterTrait.CLAUSTROPHOBIC),
					self.TextColor.r,
					self.TextColor.g,
					self.TextColor.b,
					self.TextColor.a,
					UIFont.Small,
					false
				)
				self.labelClaustrophobicBarName:setTooltip(getText("Sandbox_ETW_FearOfLocationsSystemCounter_tooltip"))
				self:addChild(self.labelClaustrophobicBarName)

				self.barClaustrophobic = ISGradientBar:new(barStartPosition, y, barLength, FONT_HGT_SMALL)
				self.barClaustrophobic:setGradientTexture(redYellowGreenGradient)
				self.barClaustrophobic:setHighlightRadius(highlightRadius)
				self.barClaustrophobic:setDoKnob(false)
				self:addChild(self.barClaustrophobic)

				y = y + FONT_HGT_SMALL
			end

			if ETW_CommonLogicChecks.SleepSystemShouldExecute(player) then
				str = "+ " .. getCachedTraitUIName(CharacterTrait.NEEDS_MORE_SLEEP)
				self.labelMoreSleepGain = ISLabel:new(
					barOneFourthPosition - strLen(textManager, str) / 2,
					y,
					FONT_HGT_SMALL,
					str,
					self.DimmedTextColor.r,
					self.DimmedTextColor.g,
					self.DimmedTextColor.b,
					self.DimmedTextColor.a,
					UIFont.Small,
					true
				)
				self.labelMoreSleepGain:setTooltip(getText("UI_ETW_GainTooltip"))
				self:addChild(self.labelMoreSleepGain)

				str = "+ " .. getCachedTraitUIName(CharacterTrait.NEEDS_LESS_SLEEP)
				self.labelLessSleepGain = ISLabel:new(
					barThreeFourthPosition - strLen(textManager, str) / 2,
					y,
					FONT_HGT_SMALL,
					str,
					self.DimmedTextColor.r,
					self.DimmedTextColor.g,
					self.DimmedTextColor.b,
					self.DimmedTextColor.a,
					UIFont.Small,
					true
				)
				self.labelLessSleepGain:setTooltip(getText("UI_ETW_GainTooltip"))
				self:addChild(self.labelLessSleepGain)

				y = y + FONT_HGT_SMALL

				self.labelSleepSystemBarName = ISLabel:new(
					barStartPosition - lineStartPosition,
					y,
					FONT_HGT_SMALL,
					getText("Sandbox_ETW_SleepSystem"),
					self.TextColor.r,
					self.TextColor.g,
					self.TextColor.b,
					self.TextColor.a,
					UIFont.Small,
					false
				)
				self.labelSleepSystemBarName:setTooltip(getText("Sandbox_ETW_SleepSystem_tooltip"))
				self:addChild(self.labelSleepSystemBarName)

				self.barSleepSystem = ISGradientBar:new(barStartPosition, y, barLength, FONT_HGT_SMALL)
				self.barSleepSystem:setGradientTexture(redYellowGreenGradient)
				self.barSleepSystem:setHighlightRadius(highlightRadius)
				self.barSleepSystem:setDoKnob(false)
				self:addChild(self.barSleepSystem)

				y = y + FONT_HGT_SMALL
			end

			if ETW_CommonLogicChecks.RainSystemShouldExecute(player) then
				str = "+/- " .. getCachedTraitUIName(ETWTraitsRegistry.PLUVIOPHOBIA)
				self.labelPluviophobia = ISLabel:new(
					barOneFourthPosition - strLen(textManager, str) / 2,
					y,
					FONT_HGT_SMALL,
					str,
					self.DimmedTextColor.r,
					self.DimmedTextColor.g,
					self.DimmedTextColor.b,
					self.DimmedTextColor.a,
					UIFont.Small,
					true
				)
				self.labelPluviophobia:setTooltip(getText("UI_ETW_GainLoseTooltip"))
				self:addChild(self.labelPluviophobia)

				str = "+/- " .. getCachedTraitUIName(ETWTraitsRegistry.PLUVIOPHILE)
				self.labelPluviophile = ISLabel:new(
					barThreeFourthPosition - strLen(textManager, str) / 2,
					y,
					FONT_HGT_SMALL,
					str,
					self.DimmedTextColor.r,
					self.DimmedTextColor.g,
					self.DimmedTextColor.b,
					self.DimmedTextColor.a,
					UIFont.Small,
					true
				)
				self.labelPluviophile:setTooltip(getText("UI_ETW_GainLoseTooltip"))
				self:addChild(self.labelPluviophile)

				y = y + FONT_HGT_SMALL

				self.labelRainSystemBarName = ISLabel:new(
					barStartPosition - lineStartPosition,
					y,
					FONT_HGT_SMALL,
					getText("Sandbox_ETW_RainSystem"),
					self.TextColor.r,
					self.TextColor.g,
					self.TextColor.b,
					self.TextColor.a,
					UIFont.Small,
					false
				)
				self.labelRainSystemBarName:setTooltip(getText("Sandbox_ETW_RainSystemCounter_tooltip"))
				self:addChild(self.labelRainSystemBarName)

				self.barRainSystem = ISGradientBar:new(barStartPosition, y, barLength, FONT_HGT_SMALL)
				self.barRainSystem:setGradientTexture(redYellowGreenGradient)
				self.barRainSystem:setHighlightRadius(highlightRadius)
				self.barRainSystem:setDoKnob(false)
				self:addChild(self.barRainSystem)

				y = y + FONT_HGT_SMALL
			end

			if ETW_CommonLogicChecks.FogSystemShouldExecute(player) then
				str = "+/- " .. getCachedTraitUIName(ETWTraitsRegistry.HOMICHLOPHOBIA)
				self.labelHomichlophobia = ISLabel:new(
					barOneFourthPosition - strLen(textManager, str) / 2,
					y,
					FONT_HGT_SMALL,
					str,
					self.DimmedTextColor.r,
					self.DimmedTextColor.g,
					self.DimmedTextColor.b,
					self.DimmedTextColor.a,
					UIFont.Small,
					true
				)
				self.labelHomichlophobia:setTooltip(getText("UI_ETW_GainLoseTooltip"))
				self:addChild(self.labelHomichlophobia)

				str = "+/- " .. getCachedTraitUIName(ETWTraitsRegistry.HOMICHLOPHILE)
				self.labelHomichlophile = ISLabel:new(
					barThreeFourthPosition - strLen(textManager, str) / 2,
					y,
					FONT_HGT_SMALL,
					str,
					self.DimmedTextColor.r,
					self.DimmedTextColor.g,
					self.DimmedTextColor.b,
					self.DimmedTextColor.a,
					UIFont.Small,
					true
				)
				self.labelHomichlophile:setTooltip(getText("UI_ETW_GainLoseTooltip"))
				self:addChild(self.labelHomichlophile)

				y = y + FONT_HGT_SMALL

				self.labelFogSystemBarName = ISLabel:new(
					barStartPosition - lineStartPosition,
					y,
					FONT_HGT_SMALL,
					getText("Sandbox_ETW_FogSystem"),
					self.TextColor.r,
					self.TextColor.g,
					self.TextColor.b,
					self.TextColor.a,
					UIFont.Small,
					false
				)
				self.labelFogSystemBarName:setTooltip(getText("Sandbox_ETW_FogSystemCounter_tooltip"))
				self:addChild(self.labelFogSystemBarName)

				self.barFogSystem = ISGradientBar:new(barStartPosition, y, barLength, FONT_HGT_SMALL)
				self.barFogSystem:setGradientTexture(redYellowGreenGradient)
				self.barFogSystem:setHighlightRadius(highlightRadius)
				self.barFogSystem:setDoKnob(false)
				self:addChild(self.barFogSystem)

				y = y + FONT_HGT_SMALL
			end

			if
				ETW_CommonLogicChecks.SmokerShouldExecute(player)
				and ((not modOptions and true) or not modOptions:getOption("HideSmokerUI"):getValue())
			then
				y = y + FONT_HGT_SMALL / 2

				str = "- " .. getCachedTraitUIName(CharacterTrait.SMOKER)
				self.labelSmokerLose = ISLabel:new(
					barOneFourthPosition - strLen(textManager, str) / 2,
					y,
					FONT_HGT_SMALL,
					str,
					self.DimmedTextColor.r,
					self.DimmedTextColor.g,
					self.DimmedTextColor.b,
					self.DimmedTextColor.a,
					UIFont.Small,
					true
				)
				self.labelSmokerLose:setTooltip(getText("UI_ETW_GainTooltip"))
				self:addChild(self.labelSmokerLose)

				str = "+ " .. getCachedTraitUIName(CharacterTrait.SMOKER)
				self.labelSmokerGain = ISLabel:new(
					barThreeFourthPosition - strLen(textManager, str) / 2,
					y,
					FONT_HGT_SMALL,
					str,
					self.DimmedTextColor.r,
					self.DimmedTextColor.g,
					self.DimmedTextColor.b,
					self.DimmedTextColor.a,
					UIFont.Small,
					true
				)
				self.labelSmokerGain:setTooltip(getText("UI_ETW_LooseTooltip"))
				self:addChild(self.labelSmokerGain)

				y = y + FONT_HGT_SMALL

				self.labelSmokerBarName = ISLabel:new(
					barStartPosition - lineStartPosition,
					y,
					FONT_HGT_SMALL,
					getCachedTraitUIName(CharacterTrait.SMOKER),
					self.TextColor.r,
					self.TextColor.g,
					self.TextColor.b,
					self.TextColor.a,
					UIFont.Small,
					false
				)
				self.labelSmokerBarName:setTooltip(getText("Sandbox_ETW_SmokerCounter_tooltip"))
				self:addChild(self.labelSmokerBarName)

				self.barSmokerSystem = ISGradientBar:new(barStartPosition, y, barLength, FONT_HGT_SMALL)
				self.barSmokerSystem:setGradientTexture(greenYellowRedGradient)
				self.barSmokerSystem:setHighlightRadius(highlightRadius)
				self.barSmokerSystem:setDoKnob(false)
				self:addChild(self.barSmokerSystem)

				y = y + FONT_HGT_SMALL
			end
		end

		routeTo(self.subViewVitals, vitalsLayoutCursor)
		buildVitalsSection()

		routeTo(self.subViewPermanentTraits, permanentTraitsLayoutCursor)
		buildPermanentTraitsSection()

		routeTo(self.subViewNonPermanentTraits, nonPermanentTraitsLayoutCursor)
		buildNonPermanentTraitsSection()

		storeActiveLayoutCursor()
		self.permanentTraitsWindowHeight = permanentTraitsLayoutCursor.y + FONT_HGT_SMALL * 2
		self.nonPermanentTraitsWindowHeight = nonPermanentTraitsLayoutCursor.y + FONT_HGT_SMALL * 0.5
		self.vitalsWindowHeight = vitalsLayoutCursor.y + FONT_HGT_SMALL * 0.5
		WINDOW_HEIGHT = self.permanentTraitsWindowHeight
		WINDOW_HEIGHT_AFTER_CHILDREN = self.permanentTraitsWindowHeight

		activeLayoutCursor = nil
		x = lineStartPosition
		y = 12
		nonBarsEntryNumber = 0
	end

	self.layoutSignature = getLayoutSignature(player)

	-- ── Restore real addChild and attach subtab to self ───────────────────────
	self.addChild = nil -- restore to prototype method

	-- Register the sub-views into the subtab panel
	self.subPanel:addView(getText("UI_ETW_SubTab_Vitals"), self.subViewVitals)
	self.subPanel:addView(getText("UI_ETW_SubTab_Progress"), self.subViewPermanentTraits)
	self.subPanel:addView(getText("UI_ETW_SubTab_NonPermanent"), self.subViewNonPermanentTraits)
	self.subPanel:addView(getText("UI_ETW_SubTab_Help"), self.subViewHelp)

	-- Attach the subtab panel to self (this is the real addChild now)
	ISETWUI.addChild(self, self.subPanel)
	-- ── End subtab restore ────────────────────────────────────────────────────
end

---Rebuilds every ETW child widget so conditional labels and bars can appear or disappear mid-game.
function ISETWUI:rebuildChildren()
	-- Hide tooltips on subViewPermanentTraits children before clearing
	if self.subViewPermanentTraits and self.subViewPermanentTraits.children then
		for _, child in pairs(self.subViewPermanentTraits.children) do
			hideChildTooltip(child)
		end
	end
	if self.subViewNonPermanentTraits and self.subViewNonPermanentTraits.children then
		for _, child in pairs(self.subViewNonPermanentTraits.children) do
			hideChildTooltip(child)
		end
	end
	if self.subViewVitals and self.subViewVitals.children then
		for _, child in pairs(self.subViewVitals.children) do
			hideChildTooltip(child)
		end
	end
	if self.subViewHelp and self.subViewHelp.children then
		for _, child in pairs(self.subViewHelp.children) do
			hideChildTooltip(child)
		end
	end
	-- Also hide tooltips on any direct children (safety)
	if self.children then
		for _, child in pairs(self.children) do
			hideChildTooltip(child)
		end
	end

	-- Clear the subtab references so createChildren re-creates them fresh
	self.subPanel = nil
	self.subViewPermanentTraits = nil
	self.subViewNonPermanentTraits = nil
	self.subViewVitals = nil
	self.subViewHelp = nil
	self.helpText = nil
	self:clearChildren()

	local widgetFields = {}
	for key in pairs(self) do
		if type(key) == "string" and (string.sub(key, 1, 5) == "label" or string.sub(key, 1, 3) == "bar") then
			widgetFields[#widgetFields + 1] = key
		end
	end
	for index = 1, #widgetFields do
		self[widgetFields[index]] = nil
	end

	self:createChildren()
end

---Rebuilds the ETW layout when known traits or delayed traits change.
function ISETWUI:refreshLayoutIfNeeded()
	local layoutSignature = getLayoutSignature(getPlayer())
	if self.layoutSignature ~= layoutSignature then
		self:rebuildChildren()
	end
end

function ISCharacterKills:setVisible(visible)
	self.javaObject:setVisible(visible)
end

function ISETWUI:prerender()
	ISPanelJoypad.prerender(self)
	self:setStencilRect(0, 0, self.width, self.height)
end

---Updates a gradient bar if it exists, including its current tooltip text.
---@param bar ISGradientBar|nil
---@param value number
---@param tooltip string|number
local function updateBar(bar, value, tooltip)
	if bar then
		bar:setValue(value)
		bar:setTooltip(tooltip)
	end
end

---Updates a label's displayed text if the label exists.
---@param label ISLabel|nil
---@param value string
local function updateLabel(label, value)
	if label then
		label:setName(value)
	end
end

function ISETWUI:render()
	self:refreshLayoutIfNeeded()

	local player = getPlayer()
	local modData = ETW_CommonFunctions.getETWModData(player)
	local isPermanentTraitsTabActive = not self.subPanel or self.subPanel:getActiveView() == self.subViewPermanentTraits
	local isVitalsTabActive = self.subPanel and self.subPanel:getActiveView() == self.subViewVitals
	local permanentTraitsSubviewOffsetY = (self.subPanel and self.subPanel.tabHeight) or 0
	local delayedTraitLines

	if isPermanentTraitsTabActive and self.labelDelayedTraitsSystem ~= nil then
		local textManager = getTextManager()
		local traitTable = player:getModData().EvolvingTraitsWorld.DelayedTraits
		local parts = {}
		for index = 1, #traitTable do
			local traitEntry = traitTable[index]
			local trait, roll, gained = traitEntry[1], traitEntry[2], traitEntry[3]
			local translationString = getCachedTraitUIName(trait)
			local strAddition = formatDelayedTraitStatus(translationString, roll, gained)
			table.insert(parts, strAddition)
		end
		local combinedParts = table.concat(parts, ", ")
		delayedTraitLines = {}
		local currentLine = getText("UI_ETW_ListOfDelayedTraits")
		local spaceLeft = WINDOW_WIDTH - lineStartPosition
		for part in combinedParts:gmatch("[^,]+") do
			local partWithComma = part .. ", "
			if strLen(textManager, currentLine .. partWithComma) > spaceLeft then
				table.insert(delayedTraitLines, currentLine)
				currentLine = partWithComma
			else
				currentLine = currentLine .. partWithComma
			end
		end
		if currentLine ~= "" then
			table.insert(delayedTraitLines, currentLine:sub(1, -3))
		end
	end

	local subTabHeight = (self.subPanel and self.subPanel.tabHeight) or 0
	local activeWindowHeight = self.permanentTraitsWindowHeight or WINDOW_HEIGHT
	if self.subPanel and self.subPanel:getActiveView() == self.subViewNonPermanentTraits then
		activeWindowHeight = self.nonPermanentTraitsWindowHeight or activeWindowHeight
	elseif self.subPanel and self.subPanel:getActiveView() == self.subViewVitals then
		activeWindowHeight = self.vitalsWindowHeight or activeWindowHeight
	elseif self.subPanel and self.subPanel:getActiveView() == self.subViewHelp then
		activeWindowHeight = self.helpWindowHeight or activeWindowHeight
	end
	if delayedTraitLines and #delayedTraitLines > 1 then
		activeWindowHeight = activeWindowHeight + ((#delayedTraitLines - 1) * FONT_HGT_SMALL)
	end
	WINDOW_HEIGHT = activeWindowHeight + subTabHeight

	self:setWidthAndParentWidth(WINDOW_WIDTH)
	self:setHeightAndParentHeight(WINDOW_HEIGHT)

	-- Keep the subtab panel and sub-views sized to match the parent
	if self.subPanel then
		local TAB_H = getTextManager():getFontHeight(UIFont.Small) + 6
		self.subPanel:setWidth(WINDOW_WIDTH)
		self.subPanel:setHeight(WINDOW_HEIGHT)
		if self.subViewPermanentTraits then
			self.subViewPermanentTraits:setWidth(WINDOW_WIDTH)
			self.subViewPermanentTraits:setHeight(WINDOW_HEIGHT - TAB_H)
		end
		if self.subViewNonPermanentTraits then
			self.subViewNonPermanentTraits:setWidth(WINDOW_WIDTH)
			self.subViewNonPermanentTraits:setHeight(WINDOW_HEIGHT - TAB_H)
		end
		if self.subViewVitals then
			self.subViewVitals:setWidth(WINDOW_WIDTH)
			self.subViewVitals:setHeight(WINDOW_HEIGHT - TAB_H)
		end
		if self.subViewHelp then
			self.subViewHelp:setWidth(WINDOW_WIDTH)
			self.subViewHelp:setHeight(WINDOW_HEIGHT - TAB_H)
		end
		if self.helpText then
			local helpTextWidth = WINDOW_WIDTH - 20
			if self.helpText:getWidth() ~= helpTextWidth then
				self.helpText:setWidth(helpTextWidth)
				self.helpText:paginate()
				self.helpWindowHeight = getHelpWindowHeight(self.helpText)
			end
			self.helpText:setHeight(WINDOW_HEIGHT - TAB_H - 20)
		end
	end

	-- Convert child-widget coordinates into this panel's coordinates for borders
	-- and other decorations drawn directly by the parent panel.
	local function getWidgetTop(widget)
		if not widget then
			return nil
		end
		return widget:getY() + permanentTraitsSubviewOffsetY
	end

	local function getWidgetBottom(widget)
		if not widget then
			return nil
		end
		local height = (widget.getHeight and widget:getHeight()) or widget.height or FONT_HGT_SMALL
		return widget:getY() + height + permanentTraitsSubviewOffsetY
	end

	local strength = player:getPerkLevel(Perks.Strength)
	local fitness = player:getPerkLevel(Perks.Fitness)
	local sprinting = player:getPerkLevel(Perks.Sprinting)
	local lightfooted = player:getPerkLevel(Perks.Lightfoot)
	local nimble = player:getPerkLevel(Perks.Nimble)
	local sneaking = player:getPerkLevel(Perks.Sneak)
	local axe = player:getPerkLevel(Perks.Axe)
	local longBlunt = player:getPerkLevel(Perks.Blunt)
	local shortBlunt = player:getPerkLevel(Perks.SmallBlunt)
	local longBlade = player:getPerkLevel(Perks.LongBlade)
	local shortBlade = player:getPerkLevel(Perks.SmallBlade)
	local spear = player:getPerkLevel(Perks.Spear)
	local maintenance = player:getPerkLevel(Perks.Maintenance)
	local carpentry = player:getPerkLevel(Perks.Woodwork)
	local cooking = player:getPerkLevel(Perks.Cooking)
	local farming = player:getPerkLevel(Perks.Farming)
	local firstAid = player:getPerkLevel(Perks.Doctor)
	local electrical = player:getPerkLevel(Perks.Electricity)
	local metalworking = player:getPerkLevel(Perks.MetalWelding)
	local mechanics = player:getPerkLevel(Perks.Mechanics)
	local tailoring = player:getPerkLevel(Perks.Tailoring)
	local aiming = player:getPerkLevel(Perks.Aiming)
	local reloading = player:getPerkLevel(Perks.Reloading)
	local fishing = player:getPerkLevel(Perks.Fishing)
	local trapping = player:getPerkLevel(Perks.Trapping)
	local foraging = player:getPerkLevel(Perks.PlantScavenging)
	local husbandry = player:getPerkLevel(Perks.Husbandry)
	local carving = player:getPerkLevel(Perks.Carving)
	local blacksmith = player:getPerkLevel(Perks.Blacksmith)
	local knapping = player:getPerkLevel(Perks.FlintKnapping)

	local mdRoot = player:getModData()
	local killCountModData = mdRoot.KillCount and mdRoot.KillCount.WeaponCategory
	local axeKills = killCountModData and (killCountModData["Axe"] or {}).count or 0
	local longBluntKills = killCountModData and (killCountModData["Blunt"] or {}).count or 0
	local shortBluntKills = killCountModData and (killCountModData["SmallBlunt"] or {}).count or 0
	local longBladeKills = killCountModData and (killCountModData["LongBlade"] or {}).count or 0
	local shortBladeKills = killCountModData and (killCountModData["SmallBlade"] or {}).count or 0
	local spearKills = killCountModData and (killCountModData["Spear"] or {}).count or 0
	local firearmKills = killCountModData and (killCountModData["Firearm"] or {}).count or 0

	updateBar(
		self.barImmunitySystem,
		percentile(0, SBvars.ImmunitySystemCounter, modData.ImmunitySystemCounter),
		getText("UI_ETW_CurrentValue") .. formatDecimal(modData.ImmunitySystemCounter)
	)
	updateBar(
		self.barSicknessSystem,
		percentile(0, SBvars.FoodSicknessSystemCounter, modData.FoodSicknessWeathered),
		getText("UI_ETW_CurrentValue") .. formatDecimal(modData.FoodSicknessWeathered)
	)
	updateBar(
		self.barPainTolerance,
		percentile(0, SBvars.PainToleranceCounter, modData.PainToleranceCounter),
		getText("UI_ETW_CurrentValue") .. formatDecimal(modData.PainToleranceCounter)
	)
	updateBar(
		self.barAsthmatic,
		percentile(SBvars.AsthmaticCounter * -2, SBvars.AsthmaticCounter * 2, modData.AsthmaticCounter),
		getText("UI_ETW_CurrentValue") .. formatDecimal(modData.AsthmaticCounter)
	)
	updateBar(
		self.barBloodlust,
		percentile(0, SBvars.BloodlustProgress * 2, modData.BloodlustSystem.BloodlustProgress),
		getText("UI_ETW_CurrentValue") .. formatDecimal(modData.BloodlustSystem.BloodlustProgress)
	)
	updateBar(
		self.barOutdoorsman,
		percentile(
			SBvars.OutdoorsmanCounter * -2,
			SBvars.OutdoorsmanCounter * 2,
			modData.OutdoorsmanSystem.OutdoorsmanCounter
		),
		getText("UI_ETW_CurrentValue") .. formatDecimal(modData.OutdoorsmanSystem.OutdoorsmanCounter)
	)
	updateBar(
		self.barAgoraphobic,
		percentile(
			SBvars.FearOfLocationsSystemCounter * -2,
			SBvars.FearOfLocationsSystemCounter * 2,
			modData.LocationFearSystem.FearOfOutside
		),
		getText("UI_ETW_CurrentValue") .. formatDecimal(modData.LocationFearSystem.FearOfOutside)
	)
	updateBar(
		self.barClaustrophobic,
		percentile(
			SBvars.FearOfLocationsSystemCounter * -2,
			SBvars.FearOfLocationsSystemCounter * 2,
			modData.LocationFearSystem.FearOfInside
		),
		getText("UI_ETW_CurrentValue") .. formatDecimal(modData.LocationFearSystem.FearOfInside)
	)
	if self.barLuckSystem ~= nil then
		local totalPerkLevel = 0
		local totalMaxPerkLevel = 0
		for i = 1, Perks.getMaxIndex() - 1 do
			local selectedPerk = Perks.fromIndex(i)
			if selectedPerk:getParent():getName() ~= "None" then
				local perkLevel = player:getPerkLevel(selectedPerk)
				totalPerkLevel = totalPerkLevel + perkLevel
				totalMaxPerkLevel = totalMaxPerkLevel + 10
			end
		end
		local percentageOfSkillLevels = totalPerkLevel / totalMaxPerkLevel * 100
		self.barLuckSystem:setValue(percentageOfSkillLevels / 100)
		self.barLuckSystem:setTooltip(totalPerkLevel)
	end
	local levels = sprinting
		+ lightfooted
		+ nimble
		+ sneaking
		+ axe
		+ longBlunt
		+ shortBlunt
		+ longBlade
		+ shortBlade
		+ spear
	updateBar(
		self.barHearingSystem,
		percentile(0, SBvars.HearingSystemSkill, levels),
		getText("UI_ETW_CurrentValue") .. levels
	)
	levels = maintenance + carpentry + farming + firstAid + electrical + metalworking + mechanics + tailoring + cooking
	updateBar(
		self.barLearnerSystem,
		percentile(0, SBvars.LearnerSystemSkill, levels),
		getText("UI_ETW_CurrentValue") .. levels
	)
	updateBar(
		self.barReaderSystem,
		percentile(0, SBvars.ReaderSystemCounter, modData.PagesReadCounter),
		getText("UI_ETW_CurrentValue") .. modData.PagesReadCounter
	)
	updateBar(
		self.barSleepSystem,
		percentile(-200, 200, modData.SleepSystem.SleepHealthinessBar),
		getText("UI_ETW_CurrentValue") .. formatDecimal(modData.SleepSystem.SleepHealthinessBar)
	)
	updateBar(
		self.barSmokerSystem,
		percentile(SBvars.SmokerCounter * -2, SBvars.SmokerCounter * 2, modData.SmokeSystem.SmokingAddiction),
		getText("UI_ETW_CurrentValue") .. modData.SmokeSystem.SmokingAddiction
	)
	updateBar(
		self.barRainSystem,
		percentile(SBvars.RainSystemCounter * -2, SBvars.RainSystemCounter * 2, modData.RainCounter),
		getText("UI_ETW_CurrentValue") .. formatDecimal(modData.RainCounter)
	)
	updateBar(
		self.barFogSystem,
		percentile(SBvars.FogSystemCounter * -2, SBvars.FogSystemCounter * 2, modData.FogCounter),
		getText("UI_ETW_CurrentValue") .. formatDecimal(modData.FogCounter)
	)
	if
		isPermanentTraitsTabActive
		and (self.barInventoryTransferSystemWeight ~= nil or self.barInventoryTransferSystemItems ~= nil)
	then
		local topY = getWidgetTop(self.labelAllThumbsWeightLose)
			or getWidgetTop(self.labelDisorganizedWeightLose)
			or getWidgetTop(self.labelDisorganizedItemsLose)
			or getWidgetTop(self.labelAllThumbsItemsLose)
			or getWidgetTop(self.labelInventoryTransferSystemWeightBarName)
			or getWidgetTop(self.labelInventoryTransferSystemItemsBarName)
		local bottomY = getWidgetBottom(self.labelOrganizedItemsGain)
			or getWidgetBottom(self.labelDextrousItemsGain)
			or getWidgetBottom(self.labelOrganizedWeightGain)
			or getWidgetBottom(self.labelDextrousWeightGain)
			or getWidgetBottom(self.barInventoryTransferSystemItems)
			or getWidgetBottom(self.barInventoryTransferSystemWeight)
		if topY and bottomY then
			topY = topY - (FONT_HGT_SMALL / 4)
			bottomY = bottomY + (FONT_HGT_SMALL / 4)
			self:drawRectBorder(
				lineStartPosition,
				topY,
				self:getWidth() - lineStartPosition * 1.5,
				bottomY - topY,
				self.DimmedTextColor.a,
				self.DimmedTextColor.r,
				self.DimmedTextColor.g,
				self.DimmedTextColor.b
			)
		end
	end
	updateBar(
		self.barInventoryTransferSystemWeight,
		percentile(0, SBvars.InventoryTransferSystemWeight, modData.TransferSystem.WeightTransferred),
		getText("UI_ETW_CurrentValue") .. modData.TransferSystem.WeightTransferred
	)
	updateBar(
		self.barInventoryTransferSystemItems,
		percentile(0, SBvars.InventoryTransferSystemItems, modData.TransferSystem.ItemsTransferred),
		getText("UI_ETW_CurrentValue") .. modData.TransferSystem.ItemsTransferred
	)
	updateBar(
		self.barVitalsFood,
		modData.RecentAverageFood,
		getText("UI_ETW_CurrentValue") .. formatDecimal(modData.RecentAverageFood)
	)
	updateBar(
		self.barVitalsThirst,
		modData.RecentAverageThirst,
		getText("UI_ETW_CurrentValue") .. formatDecimal(modData.RecentAverageThirst)
	)
	updateBar(
		self.barVitalsMental,
		modData.RecentAverageMental,
		getText("UI_ETW_CurrentValue") .. formatDecimal(modData.RecentAverageMental)
	)
	updateLabel(self.labelVitalsFood24Hours, formatHourlySamples(modData.FoodStateInLast24Hours))
	updateLabel(self.labelVitalsThirst24Hours, formatHourlySamples(modData.ThirstStateInLast24Hours))
	updateLabel(self.labelVitalsMental24Hours, formatHourlySamples(modData.MentalStateInLast24Hours))

	local function drawVitalsGroupBorder(topWidget, bottomWidget)
		if not isVitalsTabActive or not topWidget or not bottomWidget then
			return
		end

		local topY = getWidgetTop(topWidget) - (FONT_HGT_SMALL / 4)
		local bottomY = getWidgetBottom(bottomWidget) + (FONT_HGT_SMALL / 4)
		self:drawRectBorder(
			lineStartPosition,
			topY,
			self:getWidth() - lineStartPosition * 1.5,
			bottomY - topY,
			self.DimmedTextColor.a,
			self.DimmedTextColor.r,
			self.DimmedTextColor.g,
			self.DimmedTextColor.b
		)
	end

	drawVitalsGroupBorder(
		self.labelVitalsFoodGainNegative or self.labelVitalsFoodLosePositive or self.labelVitalsFood,
		self.labelVitalsFood24Hours
	)
	drawVitalsGroupBorder(
		self.labelVitalsThirstGainNegative or self.labelVitalsThirstLosePositive or self.labelVitalsThirst,
		self.labelVitalsThirst24Hours
	)
	drawVitalsGroupBorder(self.labelVitalsMental, self.labelVitalsMental24Hours)

	if isPermanentTraitsTabActive and self.barBravery ~= nil then
		local topY = getWidgetTop(self.labelCowardlyLose)
			or getWidgetTop(self.labelPacifistLose)
			or getWidgetTop(self.labelBraveryGain)
			or getWidgetTop(self.labelBraveryBarName)
		local bottomY = getWidgetBottom(self.labelDesensitizedGain)
			or getWidgetBottom(self.labelAdrenalineJunkieGain)
			or getWidgetBottom(self.labelHemophobicLose)
			or getWidgetBottom(self.barBravery)
		if topY and bottomY then
			topY = topY - (FONT_HGT_SMALL / 4)
			bottomY = bottomY + (FONT_HGT_SMALL / 4)
			self:drawRectBorder(
				lineStartPosition,
				topY,
				self:getWidth() - lineStartPosition * 1.5,
				bottomY - topY,
				self.DimmedTextColor.a,
				self.DimmedTextColor.r,
				self.DimmedTextColor.g,
				self.DimmedTextColor.b
			)
		end
	end
	if self.barBravery ~= nil then
		local totalKills = player:getZombieKills()
		local fireKills = killCountModData and (killCountModData["Fire"] or {}).count or 0
		local firearmsKills = killCountModData and (killCountModData["Firearm"] or {}).count or 0
		local vehiclesKills = killCountModData and (killCountModData["Vehicles"] or {}).count or 0
		local explosivesKills = killCountModData and (killCountModData["Explosives"] or {}).count or 0
		local meleeKills = totalKills - firearmsKills - fireKills - vehiclesKills - explosivesKills
		self.barBravery:setValue(percentile(0, SBvars.BraverySystemKills, totalKills + meleeKills))
		self.barBravery:setTooltip(totalKills + meleeKills)
	end

	updateLabel(
		self.labelEagleEyedProgress,
		getCachedTraitUIName(CharacterTrait.EAGLE_EYED)
			.. ": "
			.. modData.EagleEyedKills
			.. "/"
			.. SBvars.EagleEyedKills
	)
	updateLabel(
		self.labelHoarderProgress,
		getCachedTraitUIName(ETWTraitsRegistry.HOARDER) .. ": " .. strength .. "/" .. SBvars.HoarderSkill
	)
	updateLabel(
		self.labelGymRatProgress,
		getCachedTraitUIName(ETWTraitsRegistry.GYM_RAT) .. ": " .. strength + fitness .. "/" .. SBvars.GymRatSkill
	)
	updateLabel(
		self.labelRunnerProgress,
		getCachedTraitUIName(CharacterTrait.JOGGER) .. ": " .. sprinting .. "/" .. SBvars.RunnerSkill
	)
	updateLabel(
		self.labelLightStepProgress,
		getCachedTraitUIName(ETWTraitsRegistry.LIGHTSTEP) .. ": " .. lightfooted .. "/" .. SBvars.LightStepSkill
	)
	updateLabel(
		self.labelGymnastProgress,
		getCachedTraitUIName(CharacterTrait.GYMNAST) .. ": " .. lightfooted + nimble .. "/" .. SBvars.GymnastSkill
	)
	updateLabel(
		self.labelClumsyProgress,
		getCachedTraitUIName(CharacterTrait.CLUMSY) .. ": " .. lightfooted + sneaking .. "/" .. SBvars.ClumsySkill
	)
	updateLabel(
		self.labelGracefulProgress,
		getCachedTraitUIName(CharacterTrait.GRACEFUL)
			.. ": "
			.. lightfooted + sneaking + nimble
			.. "/"
			.. SBvars.GracefulSkill
	)
	updateLabel(
		self.labelBurglarProgress,
		getCachedTraitUIName(CharacterTrait.BURGLAR)
			.. ": "
			.. electrical + mechanics + nimble
			.. "/"
			.. SBvars.BurglarSkill
			.. " | "
			.. electrical
			.. "/2 | "
			.. mechanics
			.. "/2"
	)
	updateLabel(
		self.labelLowProfileProgress,
		getCachedTraitUIName(ETWTraitsRegistry.LOW_PROFILE) .. ": " .. sneaking .. "/" .. SBvars.LowProfileSkill
	)
	updateLabel(
		self.labelConspicuousProgress,
		getCachedTraitUIName(CharacterTrait.CONSPICUOUS) .. ": " .. sneaking .. "/" .. SBvars.ConspicuousSkill
	)
	updateLabel(
		self.labelInconspicuousProgress,
		getCachedTraitUIName(CharacterTrait.INCONSPICUOUS) .. ": " .. sneaking .. "/" .. SBvars.InconspicuousSkill
	)
	updateLabel(
		self.labelHunterSkillProgress,
		getCachedTraitUIName(CharacterTrait.HUNTER)
			.. ": "
			.. sneaking + aiming + trapping + shortBlade
			.. "/"
			.. SBvars.HunterSkill
			.. " | "
			.. sneaking
			.. "/2 | "
			.. aiming
			.. "/2 | "
			.. trapping
			.. "/2 | "
			.. shortBlade
			.. "/2"
	)
	updateLabel(
		self.labelHunterKillsProgress,
		getCachedTraitUIName(CharacterTrait.HUNTER)
			.. ": "
			.. shortBladeKills + firearmKills
			.. "/"
			.. SBvars.HunterKills
	)
	updateLabel(
		self.labelWildernessKnowledgeSkillProgress,
		getCachedTraitUIName(CharacterTrait.WILDERNESS_KNOWLEDGE)
			.. ": "
			.. foraging + knapping + maintenance + carving
			.. "/"
			.. SBvars.WildernessKnowledgeSkill
			.. " | "
			.. foraging
			.. "/2 | "
			.. knapping
			.. "/2 | "
			.. maintenance
			.. "/2 | "
			.. carving
			.. "/2"
	)
	updateLabel(
		self.labelBrawlerSkillProgress,
		getCachedTraitUIName(CharacterTrait.BRAWLER) .. ": " .. axe + longBlunt .. "/" .. SBvars.BrawlerSkill
	)
	updateLabel(
		self.labelBrawlerKillsProgress,
		getCachedTraitUIName(CharacterTrait.BRAWLER) .. ": " .. axeKills + longBluntKills .. "/" .. SBvars.BrawlerKills
	)
	updateLabel(
		self.labelAxeThrowerSkillProgress,
		getCachedTraitUIName(ETWTraitsRegistry.AXE_THROWER) .. ": " .. axe .. "/" .. SBvars.AxeThrowerSkill
	)
	updateLabel(
		self.labelAxeThrowerKillsProgress,
		getCachedTraitUIName(ETWTraitsRegistry.AXE_THROWER) .. ": " .. axeKills .. "/" .. SBvars.AxeThrowerKills
	)
	updateLabel(
		self.labelStickFighterSkillProgress,
		getCachedTraitUIName(ETWTraitsRegistry.STICK_FIGHTER) .. ": " .. shortBlunt .. "/" .. SBvars.StickFighterSkill
	)
	updateLabel(
		self.labelStickFighterKillsProgress,
		getCachedTraitUIName(ETWTraitsRegistry.STICK_FIGHTER)
			.. ": "
			.. shortBluntKills
			.. "/"
			.. SBvars.StickFighterKills
	)
	updateLabel(
		self.labelBladeEnthusiastSkillProgress,
		getCachedTraitUIName(ETWTraitsRegistry.BLADE_ENTHUSIAST)
			.. ": "
			.. longBlade
			.. "/"
			.. SBvars.BladeEnthusiastSkill
	)
	updateLabel(
		self.labelBladeEnthusiastKillsProgress,
		getCachedTraitUIName(ETWTraitsRegistry.BLADE_ENTHUSIAST)
			.. ": "
			.. longBladeKills
			.. "/"
			.. SBvars.BladeEnthusiastKills
	)
	updateLabel(
		self.labelKnifeFighterSkillProgress,
		getCachedTraitUIName(ETWTraitsRegistry.KNIFE_FIGHTER) .. ": " .. shortBlade .. "/" .. SBvars.KnifeFighterSkill
	)
	updateLabel(
		self.labelKnifeFighterKillsProgress,
		getCachedTraitUIName(ETWTraitsRegistry.KNIFE_FIGHTER)
			.. ": "
			.. shortBladeKills
			.. "/"
			.. SBvars.KnifeFighterKills
	)
	updateLabel(
		self.labelPolearmFighterSkillProgress,
		getCachedTraitUIName(ETWTraitsRegistry.POLEARM_FIGHTER) .. ": " .. spear .. "/" .. SBvars.PolearmFighterSkill
	)
	updateLabel(
		self.labelPolearmFighterKillsProgress,
		getCachedTraitUIName(ETWTraitsRegistry.POLEARM_FIGHTER)
			.. ": "
			.. spearKills
			.. "/"
			.. SBvars.PolearmFighterKills
	)
	updateLabel(
		self.labelRestorationExpertSkillProgress,
		getCachedTraitUIName(ETWTraitsRegistry.RESTORATION_EXPERT)
			.. ": "
			.. maintenance
			.. "/"
			.. SBvars.RestorationExpertSkill
	)
	updateLabel(
		self.labelHandySkillProgress,
		getCachedTraitUIName(CharacterTrait.HANDY) .. ": " .. maintenance + carpentry .. "/" .. SBvars.HandySkill
	)
	updateLabel(
		self.labelFurnitureAssemblerProgress,
		getCachedTraitUIName(ETWTraitsRegistry.FURNITURE_ASSEMBLER)
			.. ": "
			.. carpentry
			.. "/"
			.. SBvars.FurnitureAssemblerSkill
	)
	updateLabel(
		self.labelHomeCookProgress,
		getCachedTraitUIName(ETWTraitsRegistry.HOME_COOK) .. ": " .. cooking .. "/" .. SBvars.HomeCookSkill
	)
	updateLabel(
		self.labelCookProgress,
		getCachedTraitUIName(CharacterTrait.COOK) .. ": " .. cooking .. "/" .. SBvars.CookSkill
	)
	updateLabel(
		self.labelFirstAidProgress,
		getCachedTraitUIName(CharacterTrait.FIRST_AID) .. ": " .. firstAid .. "/" .. SBvars.FirstAidSkill
	)
	updateLabel(
		self.labelAVClubProgress,
		getCachedTraitUIName(ETWTraitsRegistry.AV_CLUB) .. ": " .. electrical .. "/" .. SBvars.AVClubSkill
	)
	updateLabel(
		self.labelBodyWorkEnthusiastSkillProgress,
		getCachedTraitUIName(ETWTraitsRegistry.BODYWORK_ENTHUSIAST)
			.. ": "
			.. metalworking + mechanics
			.. "/"
			.. SBvars.BodyworkEnthusiastSkill
	)
	updateLabel(
		self.labelBodyWorkEnthusiastRepairsProgress,
		getCachedTraitUIName(ETWTraitsRegistry.BODYWORK_ENTHUSIAST)
			.. ": "
			.. modData.VehiclePartRepairs
			.. "/"
			.. SBvars.BodyworkEnthusiastRepairs
	)
	updateLabel(
		self.labelMechanicsSkillProgress,
		getCachedTraitUIName(CharacterTrait.MECHANICS) .. ": " .. mechanics .. "/" .. SBvars.MechanicsSkill
	)
	updateLabel(
		self.labelMechanicsRepairsProgress,
		getCachedTraitUIName(CharacterTrait.MECHANICS)
			.. ": "
			.. math.floor(modData.VehiclePartRepairs)
			.. "/"
			.. SBvars.MechanicsRepairs
	)
	updateLabel(
		self.labelTailorSkillProgress,
		getCachedTraitUIName(CharacterTrait.TAILOR) .. ": " .. tailoring .. "/" .. SBvars.SewerSkill
	)
	updateLabel(
		self.labelTailorRippedClothesProgress,
		getCachedTraitUIName(CharacterTrait.TAILOR)
			.. ": "
			.. #modData.UniqueClothingRipped
			.. "/"
			.. SBvars.SewerUniqueClothesRipped
	)
	updateLabel(
		self.labelPetTherapySkillProgress,
		getCachedTraitUIName(ETWTraitsRegistry.PET_THERAPY) .. ": " .. husbandry .. "/" .. SBvars.PetTherapySkill
	)
	updateLabel(
		self.labelPetTherapyPettingProgress,
		getCachedTraitUIName(ETWTraitsRegistry.PET_THERAPY)
			.. ": "
			.. #modData.AnimalsSystem.UniqueAnimalsPetted
			.. "/"
			.. SBvars.PetTherapyUniqueAnimalsPetted
	)
	updateLabel(
		self.labelGunEnthusiastSkillProgress,
		getCachedTraitUIName(ETWTraitsRegistry.GUN_ENTHUSIAST)
			.. ": "
			.. aiming + reloading
			.. "/"
			.. SBvars.GunEnthusiastSkill
	)
	updateLabel(
		self.labelGunEnthusiastKillsProgress,
		getCachedTraitUIName(ETWTraitsRegistry.GUN_ENTHUSIAST)
			.. ": "
			.. firearmKills
			.. "/"
			.. SBvars.GunEnthusiastKills
	)
	updateLabel(
		self.labelAnglerProgress,
		getCachedTraitUIName(CharacterTrait.FISHING) .. ": " .. fishing .. "/" .. SBvars.FishingSkill
	)
	updateLabel(
		self.labelHikerProgress,
		getCachedTraitUIName(CharacterTrait.HIKER) .. ": " .. trapping + foraging .. "/" .. SBvars.HikerSkill
	)
	updateLabel(
		self.labelCatEyesProgress,
		getCachedTraitUIName(CharacterTrait.NIGHT_VISION)
			.. ": "
			.. math.floor(modData.CatEyesCounter)
			.. "/"
			.. SBvars.CatEyesCounter
	)
	updateLabel(
		self.labelHerbalistProgress,
		getCachedTraitUIName(CharacterTrait.HERBALIST)
			.. ": "
			.. math.floor(modData.HerbsPickedUp)
			.. "/"
			.. SBvars.HerbalistHerbsPicked
	)
	updateLabel(
		self.labelAxemanProgress,
		getCachedTraitUIName(CharacterTrait.AXEMAN) .. ": " .. modData.TreesChopped .. "/" .. SBvars.AxemanTrees
	)
	updateLabel(
		self.labelWhittlerProgress,
		getCachedTraitUIName(CharacterTrait.WHITTLER) .. ": " .. carving .. "/" .. SBvars.WhittlerSkill
	)
	updateLabel(
		self.labelBlacksmithProgress,
		getCachedTraitUIName(CharacterTrait.BLACKSMITH) .. ": " .. blacksmith .. "/" .. SBvars.BlacksmithSkill
	)

	if isPermanentTraitsTabActive and self.labelDelayedTraitsSystem ~= nil then
		local textManager = getTextManager()
		local initialWindowHeight = self.permanentTraitsWindowHeight or WINDOW_HEIGHT_AFTER_CHILDREN
		local delayedY = initialWindowHeight + permanentTraitsSubviewOffsetY - FONT_HGT_SMALL * 2
		local delayedLocalY = delayedY - permanentTraitsSubviewOffsetY
		self.labelDelayedTraitsSystem:setY(delayedLocalY)
		self.labelDelayedTraitsSystem:setX(
			WINDOW_WIDTH / 2 - strLen(textManager, self.labelDelayedTraitsSystem.name) / 2
		)
		local lines = delayedTraitLines or {}
		for i = 1, #lines do
			local line = lines[i]
			self:drawText(
				line,
				lineStartPosition,
				delayedY + (i * FONT_HGT_SMALL),
				self.TextColor.r,
				self.TextColor.g,
				self.TextColor.b,
				self.TextColor.a
			)
		end
		if self.buttonDelayedTraitsTooltip ~= nil then
			self.buttonDelayedTraitsTooltip:setX(lineStartPosition)
			self.buttonDelayedTraitsTooltip:setY(delayedLocalY + FONT_HGT_SMALL)
			self.buttonDelayedTraitsTooltip:setWidth(WINDOW_WIDTH - lineStartPosition * 2)
			self.buttonDelayedTraitsTooltip:setHeight(#lines * FONT_HGT_SMALL)
		end
	end
	if isPermanentTraitsTabActive and not SBvars.UIPage then
		self:drawText(getText("UI_ETW_ProgressPageDisabled"), 10, 10, 1, 1, 1, 1)
	end
	self:clearStencilRect()

	if
		modOptions
		and (
			WINDOW_WIDTH ~= modOptions:getOption("UIWidth"):getValue()
			or nonBarsEntriesPerRow ~= modOptions:getOption("TraitColumns"):getValue()
		)
	then
		WINDOW_WIDTH = modOptions:getOption("UIWidth"):getValue()
		nonBarsEntriesPerRow = modOptions:getOption("TraitColumns"):getValue()
		self:clearChildren()
		self:createChildren()
	end
end

function ISETWUI:update()
	ISPanelJoypad.update(self)
end

function ISETWUI:onMouseWheel(del)
	self:setYScroll(self:getYScroll() - del * 30)
	return true
end

function ISETWUI:new(X, Y, width, height, playerNum)
	local o = ISPanelJoypad:new(X, Y, width, height)
	setmetatable(o, self)
	self.__index = self
	o.playerNum = playerNum
	o.char = getSpecificPlayer(playerNum)
	o:noBackground()
	o.categoryButtons = {}
	o.categoryXOffset = 20

	ISETWUI.instance = o
	return o
end

function ISETWUI:ensureVisible()
	if not self.joyfocus then
		return
	end
	local child = nil
	if not child then
		return
	end
	local Y = child:getY()
	if Y - 40 < 0 - self:getYScroll() then
		self:setYScroll(0 - Y + 40)
	elseif Y + child:getHeight() + 40 > 0 - self:getYScroll() + self:getHeight() then
		self:setYScroll(0 - (Y + child:getHeight() + 40 - self:getHeight()))
	end
end

function ISETWUI:onGainJoypadFocus(joypadData)
	ISPanelJoypad.onGainJoypadFocus(self, joypadData)
	self.joypadIndex = nil
	self.barWithTooltip = nil
end

function ISETWUI:onLoseJoypadFocus(joypadData)
	ISPanelJoypad.onLoseJoypadFocus(self, joypadData)
end

function ISETWUI:onJoypadDown(button)
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

function ISETWUI:onJoypadDirDown()
	self.joypadIndex = self.joypadIndex + 1
	self:ensureVisible()
	self:updateTooltipForJoypad()
end

function ISETWUI:onJoypadDirLeft() end

function ISETWUI:onJoypadDirRight() end

addCharacterPageTab("ETW", ISETWUI:new(0, 0, WINDOW_WIDTH, WINDOW_HEIGHT, 0))
