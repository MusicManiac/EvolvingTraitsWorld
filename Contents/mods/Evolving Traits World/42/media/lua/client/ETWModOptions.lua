---@diagnostic disable: undefined-global

-- Storage array for all of the options
local ETW_config = {
    UIToggleKeybind = nil,
    GatherDebugCheckbox = nil,
    GatherDetailedDebugCheckbox = nil,
    EnableSoundNotificationsCheckbox = nil,
    EnableDelayedNotificationsCheckbox = nil,
    EnableBloodLustMoodleCheckbox = nil,
    EnableSleepHealthMoodleCheckbox = nil,
    UIWidthSlider = nil,
	TraitColumnsSlider = nil,
	HideSmokerUICheckbox = nil,
	HideReadMeUICheckbox = nil
}

local function ExampleConfig()
    -- Create the options! This is required when adding the new Mod Options
    local options = PZAPI.ModOptions:create("ETWModOptions", "ETW - Evolving Traits World")
    options:addTitle("Evolving Traits World")
    options:addDescription("A small description can be placed here")

    -- Add a Separator
    ---- Not required, just adds a horizontal line.
    ---- Can be used any time
   	-- options:addSeparator()

    -- Each option that you create is assigned an ID.
    -- In this example, I am just using stringified numbers, starting from 0.
    -- This ID MUST be a tring, and it MUST be unique to your options.
    -- If the ID is changed, then the saved option will not be preserved on next load!

    --- Each _tooltip is optional

    -- addKeyBind(ID, name, value, _tooltip)
	-- Get the keybind by calling ETW_config.UIToggleKeybind:getValue()
    ETW_config.UIToggleKeybind = options:addKeyBind("UIToggle", getText("UI_optionscreen_binding_ETW_UI_Toggle"), Keyboard.KEY_LBRACKET, "Get the keybind by calling ETW_config.UIToggle:getValue()")
    
    -- addTickBox(ID, name, value, _tooltip)
	-- Get value by calling ETW_config.GatherDebugCheckbox:getValue()
    ETW_config.GatherDebugCheckbox = options:addTickBox("GatherDebug", getText("UI_ETW_Options_GatherDebug"), false, getText("UI_ETW_Options_GatherDebug_tooltip"))
	ETW_config.GatherDetailedDebugCheckbox = options:addTickBox("GatherDetailedDebug", getText("UI_ETW_Options_GatherDetailedDebug"), false, getText("UI_ETW_Options_GatherDetailedDebug_tooltip"))
	ETW_config.EnableSoundNotificationsCheckbox = options:addTickBox("EnableSoundNotifications", getText("UI_ETW_Options_EnableSoundNotifications"), true, getText("UI_ETW_Options_EnableSoundNotifications_tooltip"))
	ETW_config.EnableDelayedNotificationsCheckbox = options:addTickBox("EnableDelayedNotifications", getText("UI_ETW_Options_EnableDelayedNotifications"), true, getText("UI_ETW_Options_EnableDelayedNotifications_tooltip"))
	ETW_config.EnableBloodLustMoodleCheckbox = options:addTickBox("EnableBloodLustMoodle", getText("UI_ETW_Options_EnableBloodLustMoodle"), true, getText("UI_ETW_Options_EnableBloodLustMoodle_tooltip"))
	ETW_config.EnableSleepHealthMoodleCheckbox = options:addTickBox("EnableSleepHealthMoodle", getText("UI_ETW_Options_EnableSleepHealthMoodle"), true, getText("UI_ETW_Options_EnableSleepHealthMoodle_tooltip"))
	
	-- addSlider(ID, name, min, max, step, value, _tooltip)
	-- Get value by calling ETW_config.UIWidthSlider:getValue()
    ETW_config.UIWidthSlider = options:addSlider("UIWidth", getText("UI_ETW_Options_UIWidth"), 500, 1000, 10, 700, getText("UI_ETW_Options_UIWidth_tooltip"))
	ETW_config.TraitColumnsSlider = options:addSlider("TraitColumns", getText("UI_ETW_Options_TraitColumns"), 1, 10, 1, 4, getText("UI_ETW_Options_TraitColumns_tooltip"))

	ETW_config.HideSmokerUICheckbox = options:addTickBox("HideSmokerUI", getText("UI_ETW_Options_HideSmokerUI"), false, getText("UI_ETW_Options_HideSmokerUI_tooltip"))
	ETW_config.HideReadMeUICheckbox = options:addTickBox("HideReadMeUI", getText("UI_ETW_Options_HideReadMeUI"), false, getText("UI_ETW_Options_HideReadMeUI_tooltip"))

    -- addTextEntry(ID, name, value, _tooltip)
    -- ETW_config.textEntry = options:addTextEntry("2", "Text Entry", "Enter Text Here!", "Get the value by calling config.textEntry:getValue()")

    -- addMultipleTickBox(ID, name, _tooltip)
    -- ETW_config.multiBox = options:addMultipleTickBox("3", "Multi-tick Box", "This one is unique, and can support many check boxes! You can get the value by calling config.multiBox.getValue(X), where X is the entry you want!")
    -- Create child boxes:
    --- addTickBox(name, value)
    -- ETW_config.multiBox:addTickBox("First Option", false)
    -- ETW_config.multiBox:addTickBox("Second Option", true)

    -- -- addComboBox(ID, name, _tooltip)
    -- ETW_config.comboBox = options:addComboBox("4", "Combo Box", "A combo box, with plenty of options. Get the value with config.comboBox:getValue()")
    -- -- Create entries:
    -- --- addItem(name, selected)
    -- ---- whichever is set to "true" will be the initially selected box.
    -- ETW_config.comboBox:addItem("First", false)
    -- ETW_config.comboBox:addItem("Second", true)
    -- ETW_config.comboBox:addItem("Third", false)

    -- addColorPicker(ID, name, r, g, b, a, _tooltip)
    -- ETW_config.colorPick = options:addColorPicker("5", "Color Pick", 0.5, 0.5, 0.5, 1.0, "Set the initial color as values from 0.0-1.0. Get the color with config.colorPicker:getValue()")
    -- NOTE: Color is stored as table { r, g, b, a }

	-- -- quick local function for next option
	-- local buttonFunc = function()
	-- 	print("HELLO!")
	-- 	-- NOTE: This prints to the log "HELLO!"
	-- end
	
	-- -- addButton(ID, name, tooltip, onclickfunc, target, arg1, arg2, arg3, arg4)
	-- config.button = options:addButton("7", "Button", "Click Me!", buttonFunc)


    --- You can retrieve any of the individual option objects by doing: 
    --- options:getOption(id)
end

ExampleConfig()

---Function responsible for opening up ETW UI
---@param keynum number
local function ETWShowUI(keynum)
	if keynum == ETW_config.UIToggleKeybind:getValue() and getPlayer() then
		local playerObj = getSpecificPlayer(0)
		xpUpdate.characterInfo = getPlayerInfoPanel(playerObj:getPlayerNum());
		xpUpdate.characterInfo:toggleView(xpSystemText.ETW);
	end
end

Events.OnKeyPressed.Add(ETWShowUI);