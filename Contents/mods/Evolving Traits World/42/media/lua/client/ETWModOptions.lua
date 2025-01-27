---@diagnostic disable: undefined-global


local etwOptions = PZAPI.ModOptions:create("ETWModOptions", "ETW - Evolving Traits World")
etwOptions:addTitle("Evolving Traits World")

etwOptions:addKeyBind("UIToggle", getText("UI_optionscreen_binding_ETW_UI_Toggle"), Keyboard.KEY_LBRACKET, "Get the keybind by calling ETW_config.UIToggle:getValue()")

etwOptions:addTickBox("GatherDetailedDebug", getText("UI_ETW_Options_GatherDetailedDebug"), false, getText("UI_ETW_Options_GatherDetailedDebug_tooltip"))
etwOptions:addSeparator()
etwOptions:addTickBox("EnableSoundNotifications", getText("UI_ETW_Options_EnableSoundNotifications"), true, getText("UI_ETW_Options_EnableSoundNotifications_tooltip"))
local SoundNotificationSoundSelectComboBox = etwOptions:addMultipleTickBox("SoundNotificationSoundSelect", getText("UI_ETW_Options_SoundNotificationSoundSelect"))
SoundNotificationSoundSelectComboBox:addTickBox(getText("UI_ETW_Options_Sound_B42"), true)
SoundNotificationSoundSelectComboBox:addTickBox(getText("UI_ETW_Options_Sound_B41"), false)
SoundNotificationSoundSelectComboBox:addTickBox(getText("UI_ETW_Options_Sound_TheLastOfUs"), false)
SoundNotificationSoundSelectComboBox:addTickBox(getText("UI_ETW_Options_Sound_SkyrimSkill"), false)
SoundNotificationSoundSelectComboBox:addTickBox(getText("UI_ETW_Options_Sound_SkyrimLevel"), false)
SoundNotificationSoundSelectComboBox:addTickBox(getText("UI_ETW_Options_Sound_Oblivion"), false)
SoundNotificationSoundSelectComboBox:addTickBox(getText("UI_ETW_Options_Sound_Diablo2"), false)
SoundNotificationSoundSelectComboBox:addTickBox(getText("UI_ETW_Options_Sound_Witcher3"), false)
SoundNotificationSoundSelectComboBox:addTickBox(getText("UI_ETW_Options_Sound_FalloutNV"), false)
SoundNotificationSoundSelectComboBox:addTickBox(getText("UI_ETW_Options_Sound_AgeOfEmpires3"), false)
SoundNotificationSoundSelectComboBox:addTickBox(getText("UI_ETW_Options_Sound_WorldOfWarcraft"), false)
etwOptions:addSeparator()

function SoundNotificationSoundSelectComboBox:onChange(index, selected)
	if selected then
		local soundTable = {"ETW_b42", "ETW_b41", "ETW_TLOU", "ETW_SkyrimSkill", "ETW_SkyrimLevel", "ETW_Oblivion", "ETW_Diablo2", "ETW_Witcher3", "ETW_FalloutNV", "ETW_AoE3", "ETW_WoW"};
		getSoundManager():playUISound(soundTable[index]);
	end
end

etwOptions:addTickBox("EnableNotifications", getText("UI_ETW_Options_EnableNotifications"), true, getText("UI_ETW_Options_EnableNotifications_tooltip"))
etwOptions:addTickBox("EnableDelayedNotifications", getText("UI_ETW_Options_EnableDelayedNotifications"), true, getText("UI_ETW_Options_EnableDelayedNotifications_tooltip"))
etwOptions:addTickBox("EnableBloodLustMoodle", getText("UI_ETW_Options_EnableBloodLustMoodle"), true, getText("UI_ETW_Options_EnableBloodLustMoodle_tooltip"))
etwOptions:addTickBox("EnableSleepHealthMoodle", getText("UI_ETW_Options_EnableSleepHealthMoodle"), true, getText("UI_ETW_Options_EnableSleepHealthMoodle_tooltip"))

etwOptions:addDescription("Slders in new mod options don't properly display tooltip yet, so I'll put description here in the meantime.\n"..getText("UI_ETW_Options_UIWidth_tooltip").."\n"..getText("UI_ETW_Options_TraitColumns_tooltip"))

etwOptions:addSlider("UIWidth", getText("UI_ETW_Options_UIWidth"), 500, 1920, 10, 700, getText("UI_ETW_Options_UIWidth_tooltip"))
etwOptions:addSlider("TraitColumns", getText("UI_ETW_Options_TraitColumns"), 1, 10, 1, 4, getText("UI_ETW_Options_TraitColumns_tooltip"))

etwOptions:addTickBox("HideSmokerUI", getText("UI_ETW_Options_HideSmokerUI"), false, getText("UI_ETW_Options_HideSmokerUI_tooltip"))
etwOptions:addTickBox("HideReadMeUI", getText("UI_ETW_Options_HideReadMeUI"), false, getText("UI_ETW_Options_HideReadMeUI_tooltip"))
