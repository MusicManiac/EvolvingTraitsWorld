local DEFAULT_ETW_TOOLTIP_WIDTH = 300
local modOptions

---Returns the configured maximum width for tooltips belonging to ETW UI elements.
---@return number
local function getETWTooltipWidth()
	modOptions = modOptions or PZAPI.ModOptions:getOptions("ETWModOptions")
	local tooltipWidthOption = modOptions and modOptions:getOption("TooltipWidth")
	return tooltipWidthOption and tooltipWidthOption:getValue() or DEFAULT_ETW_TOOLTIP_WIDTH
end

---Applies the configured ETW tooltip width without affecting non-ETW UI elements.
---@param element ISUIElement
local function applyETWTooltipWidth(element)
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

local buttonUpdateTooltip = ISButton.updateTooltip
---@diagnostic disable-next-line: duplicate-set-field
function ISButton:updateTooltip()
	buttonUpdateTooltip(self)
	applyETWTooltipWidth(self)
end

local gradientPreRender = ISGradientBar.prerender
---Overwriting pererender to allow tooltips on gradient bars
---@diagnostic disable-next-line: duplicate-set-field
function ISGradientBar:prerender()
	self:updateTooltip()
	gradientPreRender(self)
end

local gradientRender = ISGradientBar.render
---Overwriting rerender to limit an area in which gradient bars are rendered (needed to make sure that shadow from value position is not rendered outside of the bar)
---@diagnostic disable-next-line: duplicate-set-field
function ISGradientBar:render()
	self:setStencilRect(0, 0, self.width, self.height)
	gradientRender(self)
	self:clearStencilRect()
end

---Function that renders a tooltip when hovering over gradient bar. Direct steal from ISLabel:updateTooltip()
function ISGradientBar:updateTooltip()
	if self.disabled then return end
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
	self.tooltip = tooltip
end
