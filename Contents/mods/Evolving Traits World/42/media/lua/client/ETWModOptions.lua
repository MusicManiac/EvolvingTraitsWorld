---@diagnostic disable: undefined-global

-- Storage array for all of the options
local ETW_config = {
    UIToggleKeybind = nil,
    GatherDetailedDebugCheckbox = nil,
    EnableSoundNotificationsCheckbox = nil,
    EnableNotifications = nil,
    EnableDelayedNotificationsCheckbox = nil,
    EnableBloodLustMoodleCheckbox = nil,
    EnableSleepHealthMoodleCheckbox = nil,
    UIWidthSlider = nil,
	TraitColumnsSlider = nil,
	HideSmokerUICheckbox = nil,
	HideReadMeUICheckbox = nil
}

local function ETWConfig()
    local options = PZAPI.ModOptions:create("ETWModOptions", "ETW - Evolving Traits World")
    options:addTitle("Evolving Traits World")

    ETW_config.UIToggleKeybind = options:addKeyBind("UIToggle", getText("UI_optionscreen_binding_ETW_UI_Toggle"), Keyboard.KEY_LBRACKET, "Get the keybind by calling ETW_config.UIToggle:getValue()")
    
	ETW_config.GatherDetailedDebugCheckbox = options:addTickBox("GatherDetailedDebug", getText("UI_ETW_Options_GatherDetailedDebug"), false, getText("UI_ETW_Options_GatherDetailedDebug_tooltip"))
    ETW_config.EnableSoundNotificationsCheckbox = options:addTickBox("EnableSoundNotifications", getText("UI_ETW_Options_EnableSoundNotifications"), true, getText("UI_ETW_Options_EnableSoundNotifications_tooltip"))
    ETW_config.EnableNotificationsCheckbox = options:addTickBox("EnableNotifications", getText("UI_ETW_Options_EnableNotifications"), true, getText("UI_ETW_Options_EnableNotifications_tooltip"))
	ETW_config.EnableDelayedNotificationsCheckbox = options:addTickBox("EnableDelayedNotifications", getText("UI_ETW_Options_EnableDelayedNotifications"), true, getText("UI_ETW_Options_EnableDelayedNotifications_tooltip"))
	ETW_config.EnableBloodLustMoodleCheckbox = options:addTickBox("EnableBloodLustMoodle", getText("UI_ETW_Options_EnableBloodLustMoodle"), true, getText("UI_ETW_Options_EnableBloodLustMoodle_tooltip"))
	ETW_config.EnableSleepHealthMoodleCheckbox = options:addTickBox("EnableSleepHealthMoodle", getText("UI_ETW_Options_EnableSleepHealthMoodle"), true, getText("UI_ETW_Options_EnableSleepHealthMoodle_tooltip"))
	
    options:addSeparator()
    options:addDescription("Slders in new mod options don't properly display tooltip yet, so I'll put description here in the meantime.\n"..getText("UI_ETW_Options_UIWidth_tooltip").."\n"..getText("UI_ETW_Options_TraitColumns_tooltip"))

    ETW_config.UIWidthSlider = options:addSlider("UIWidth", getText("UI_ETW_Options_UIWidth"), 500, 1920, 10, 700, getText("UI_ETW_Options_UIWidth_tooltip"))
	ETW_config.TraitColumnsSlider = options:addSlider("TraitColumns", getText("UI_ETW_Options_TraitColumns"), 1, 10, 1, 4, getText("UI_ETW_Options_TraitColumns_tooltip"))

	ETW_config.HideSmokerUICheckbox = options:addTickBox("HideSmokerUI", getText("UI_ETW_Options_HideSmokerUI"), false, getText("UI_ETW_Options_HideSmokerUI_tooltip"))
	ETW_config.HideReadMeUICheckbox = options:addTickBox("HideReadMeUI", getText("UI_ETW_Options_HideReadMeUI"), false, getText("UI_ETW_Options_HideReadMeUI_tooltip"))
end

ETWConfig()