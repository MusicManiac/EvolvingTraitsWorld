local DEFAULT_ETW_TOOLTIP_WIDTH = 300
local modOptions

---@class ETWTooltipElement : ISUIElement
---@field etwUseCustomTooltipWidth boolean?
---@field tooltip string?
---@field tooltipUI ISToolTip?

---@class ETWIndicatorLabel : ISLabel
---@field etwGradientIndicatorBarPosition "above"|"below"?

---@class ETWGradientBar : ISGradientBar
---@field etwShowCurrentValueLine boolean?
---@field etwThresholdIndicators { x: number, fromTop: boolean }[]?
---@field etwUseCustomTooltipWidth boolean?
---@field tooltip string?
---@field tooltipUI ISToolTip?

---Returns the configured maximum width for tooltips belonging to ETW UI elements.
---@return number
local function getETWTooltipWidth()
	modOptions = modOptions or PZAPI.ModOptions:getOptions("ETWModOptions")
	local tooltipWidthOption = modOptions and modOptions:getOption("TooltipWidth")
	---@cast tooltipWidthOption umbrella.ModOptions.Slider?
	return tooltipWidthOption and tooltipWidthOption:getValue() or DEFAULT_ETW_TOOLTIP_WIDTH
end

---Applies the configured ETW tooltip width without affecting non-ETW UI elements.
---@param element ISUIElement
local function applyETWTooltipWidth(element)
	---@cast element ETWTooltipElement
	if element.etwUseCustomTooltipWidth and element.tooltipUI then
		element.tooltipUI.maxLineWidth = getETWTooltipWidth()
	end
end

local labelUpdateTooltip = ISLabel.updateTooltip
---@diagnostic disable-next-line: duplicate-set-field
function ISLabel:updateTooltip()
	labelUpdateTooltip(self)
	applyETWTooltipWidth(self)
end

local labelSetTooltip = ISLabel.setTooltip
---Associates an ETW threshold label with the gradient bar above or below it.
---@param tooltip string
---@param indicatorBarPosition "above"|"below"|nil
---@diagnostic disable-next-line: duplicate-set-field
function ISLabel:setTooltip(tooltip, indicatorBarPosition)
	labelSetTooltip(self, tooltip)
	---@cast self ETWIndicatorLabel
	self.etwGradientIndicatorBarPosition = indicatorBarPosition
end

local buttonUpdateTooltip = ISButton.updateTooltip
---@diagnostic disable-next-line: duplicate-set-field
function ISButton:updateTooltip()
	buttonUpdateTooltip(self)
	applyETWTooltipWidth(self)
end

local gradientPreRender = ISGradientBar.prerender
---Overwriting prerender to allow tooltips on gradient bars
---@diagnostic disable-next-line: duplicate-set-field
function ISGradientBar:prerender()
	self:updateTooltip()
	gradientPreRender(self)
end

local gradientRender = ISGradientBar.render
local THRESHOLD_TRIANGLE_HALF_WIDTHS = { 4, 3, 2, 2, 1, 1, 0 }

---Draws a pixel-symmetric triangle from a gradient bar edge toward its center.
---@param bar ISGradientBar
---@param markerX integer
---@param fromTop boolean
---@param color umbrella.RGBA
local function drawThresholdIndicator(bar, markerX, fromTop, color)
	---@cast bar.width integer
	markerX = math.max(0, math.min(bar.width - 1, markerX))
	for index, halfWidth in ipairs(THRESHOLD_TRIANGLE_HALF_WIDTHS) do
		local depth = index - 1
		local markerY = fromTop and depth or bar.height - 1 - depth
		bar:drawRect(markerX - halfWidth, markerY, halfWidth * 2 + 1, 1, color.a, color.r, color.g, color.b)
	end
end

---Returns the visual anchor of a label rather than assuming its text is left-aligned.
---@param label ETWIndicatorLabel
---@return number
local function getIndicatorAnchorX(label)
	if label.center then
		return label.x
	end
	if label.left then
		return label.x + label.width / 2
	end
	return label.originalX
end

---Collects the gain/loss label positions adjoining an ETW gradient bar.
---@param bar ETWGradientBar
---@return { x: number, fromTop: boolean }[]
local function getThresholdIndicators(bar)
	if bar.etwThresholdIndicators then
		return bar.etwThresholdIndicators
	end

	if not bar.parent or not bar.parent.childrenInOrder then
		return {}
	end

	bar.etwThresholdIndicators = {}
	for _, child in ipairs(bar.parent.childrenInOrder) do
		---@cast child ETWIndicatorLabel
		if child.Type == "ISLabel" and child.etwGradientIndicatorBarPosition then
			local markerX = getIndicatorAnchorX(child) - bar.x
			if markerX >= 0 and markerX <= bar.width then
				local aboveGap = bar.y - (child.y + child.height)
				local belowGap = child.y - (bar.y + bar.height)
				if child.etwGradientIndicatorBarPosition == "below" and aboveGap >= 0 and aboveGap <= 2 then
					table.insert(bar.etwThresholdIndicators, { x = markerX, fromTop = true })
				elseif child.etwGradientIndicatorBarPosition == "above" and belowGap >= 0 and belowGap <= 2 then
					table.insert(bar.etwThresholdIndicators, { x = markerX, fromTop = false })
				end
			end
		end
	end
	return bar.etwThresholdIndicators
end

---Overwriting rerender to limit an area in which gradient bars are rendered (needed to make sure that shadow from value position is not rendered outside of the bar)
---@diagnostic disable-next-line: duplicate-set-field
function ISGradientBar:render()
	self:setStencilRect(0, 0, self.width, self.height)
	gradientRender(self)
	---@cast self ETWGradientBar
	if self.etwShowCurrentValueLine then
		local valueX = PZMath.clampFloat(self.value * self.width, 3, self.width - 3)
		self:drawRect(math.floor(valueX), 2, 1, self.height - 4, 0.45, 0, 0, 0)

		local indicatorColor = self.settings.colBorder
		for _, indicator in ipairs(getThresholdIndicators(self)) do
			local markerX = math.floor(indicator.x)
			drawThresholdIndicator(self, markerX, indicator.fromTop, indicatorColor)
		end
	end
	self:clearStencilRect()
end

---Function that renders a tooltip when hovering over gradient bar. Direct steal from ISLabel:updateTooltip()
function ISGradientBar:updateTooltip()
	---@cast self ETWGradientBar
	if self:isMouseOver() and self.tooltip then
		local text = self.tooltip
		if not self.tooltipUI then
			self.tooltipUI = ISToolTip:new()
			self.tooltipUI:setOwner(self)
			self.tooltipUI:setVisible(false)
			self.tooltipUI:setAlwaysOnTop(true)
		end
		if not self.tooltipUI:getIsVisible() then
			if self.etwUseCustomTooltipWidth then
				self.tooltipUI.maxLineWidth = getETWTooltipWidth()
			elseif string.contains(self.tooltip, "\n") then
				self.tooltipUI.maxLineWidth = 1000 -- don't wrap the lines
			else
				self.tooltipUI.maxLineWidth = 300
			end
			self.tooltipUI:addToUIManager()
			self.tooltipUI:setVisible(true)
		end
		self.tooltipUI.description = text
		applyETWTooltipWidth(self)
		self.tooltipUI:setX(self:getAbsoluteX())
		self.tooltipUI:setY(self:getAbsoluteY() + self:getHeight())
	else
		if self.tooltipUI and self.tooltipUI:getIsVisible() then
			self.tooltipUI:setVisible(false)
			self.tooltipUI:removeFromUIManager()
		end
	end
end

---Sets tooltip field for gradient bar
---@param tooltip string
function ISGradientBar:setTooltip(tooltip)
	---@cast self ETWGradientBar
	self.tooltip = tooltip
	self.etwShowCurrentValueLine = true
end
