---@diagnostic disable: undefined-global

local etwOptions = PZAPI.ModOptions:create("ETWModOptions", "ETW - Evolving Traits World")
etwOptions:addTitle("Evolving Traits World")

etwOptions:addKeyBind(
	"UIToggle",
	getText("UI_optionscreen_binding_ETW_UI_Toggle"),
	Keyboard.KEY_LBRACKET,
	"Get the keybind by calling ETW_config.UIToggle:getValue()"
)

etwOptions:addTickBox(
	"GatherDetailedDebug",
	getText("UI_ETW_Options_GatherDetailedDebug"),
	false,
	getText("UI_ETW_Options_GatherDetailedDebug_tooltip")
)
etwOptions:addSeparator()
etwOptions:addTickBox(
	"EnableSoundNotifications",
	getText("UI_ETW_Options_EnableSoundNotifications"),
	true,
	getText("UI_ETW_Options_EnableSoundNotifications_tooltip")
)
local SoundNotificationSoundSelectComboBox = etwOptions:addMultipleTickBox(
	"SoundNotificationSoundSelect",
	getText("UI_ETW_Options_SoundNotificationSoundSelect")
)
SoundNotificationSoundSelectComboBox:addTickBox(getText("UI_ETW_Options_Sound_B42"), false)
SoundNotificationSoundSelectComboBox:addTickBox(getText("UI_ETW_Options_Sound_B41"), false)
SoundNotificationSoundSelectComboBox:addTickBox(getText("UI_ETW_Options_Sound_TheLastOfUs"), true)
SoundNotificationSoundSelectComboBox:addTickBox(getText("UI_ETW_Options_Sound_SkyrimSkill"), false)
SoundNotificationSoundSelectComboBox:addTickBox(getText("UI_ETW_Options_Sound_SkyrimLevel"), false)
SoundNotificationSoundSelectComboBox:addTickBox(getText("UI_ETW_Options_Sound_Oblivion"), false)
SoundNotificationSoundSelectComboBox:addTickBox(getText("UI_ETW_Options_Sound_Diablo2"), false)
SoundNotificationSoundSelectComboBox:addTickBox(getText("UI_ETW_Options_Sound_Witcher3"), false)
SoundNotificationSoundSelectComboBox:addTickBox(getText("UI_ETW_Options_Sound_FalloutNV"), false)
SoundNotificationSoundSelectComboBox:addTickBox(getText("UI_ETW_Options_Sound_AgeOfEmpires3"), false)
SoundNotificationSoundSelectComboBox:addTickBox(getText("UI_ETW_Options_Sound_WorldOfWarcraft"), false)

function SoundNotificationSoundSelectComboBox:onChange(index, selected)
	if selected then
		local soundTable = {
			"ETW_b42",
			"ETW_b41",
			"ETW_TLOU",
			"ETW_SkyrimSkill",
			"ETW_SkyrimLevel",
			"ETW_Oblivion",
			"ETW_Diablo2",
			"ETW_Witcher3",
			"ETW_FalloutNV",
			"ETW_AoE3",
			"ETW_WoW",
		}
		getSoundManager():playUISound(soundTable[index])
	end
end

etwOptions:addDescription(getText("UI_ETW_Options_ParanoiaScreamVolume_tooltip"))
etwOptions:addSlider(
	"ParanoiaScreamVolume",
	"UI_ETW_Options_ParanoiaScreamVolume",
	0,
	100,
	5,
	100,
	"UI_ETW_Options_ParanoiaScreamVolume_tooltip"
)
etwOptions:addSeparator()

etwOptions:addTickBox(
	"EnableNotifications",
	getText("UI_ETW_Options_EnableNotifications"),
	true,
	getText("UI_ETW_Options_EnableNotifications_tooltip")
)
etwOptions:addTickBox(
	"EnableDelayedNotifications",
	getText("UI_ETW_Options_EnableDelayedNotifications"),
	true,
	getText("UI_ETW_Options_EnableDelayedNotifications_tooltip")
)
etwOptions:addTickBox(
	"EnableButterfingersPopup",
	getText("UI_ETW_Options_EnableButterfingersPopup"),
	true,
	getText("UI_ETW_Options_EnableButterfingersPopup_tooltip")
)
etwOptions:addTickBox(
	"EnableBloodLustMoodle",
	getText("UI_ETW_Options_EnableBloodLustMoodle"),
	true,
	getText("UI_ETW_Options_EnableBloodLustMoodle_tooltip")
)
etwOptions:addTickBox(
	"EnableSleepHealthMoodle",
	getText("UI_ETW_Options_EnableSleepHealthMoodle"),
	true,
	getText("UI_ETW_Options_EnableSleepHealthMoodle_tooltip")
)

etwOptions:addDescription(getText("UI_ETW_Options_UIWidth_tooltip"))
etwOptions:addSlider(
	"UIWidth",
	getText("UI_ETW_Options_UIWidth"),
	500,
	3000,
	10,
	900,
	getText("UI_ETW_Options_UIWidth_tooltip")
)
etwOptions:addDescription(getText("UI_ETW_Options_TooltipWidth_tooltip"))
etwOptions:addSlider(
	"TooltipWidth",
	getText("UI_ETW_Options_TooltipWidth"),
	100,
	2000,
	10,
	500,
	getText("UI_ETW_Options_TooltipWidth_tooltip")
)
etwOptions:addDescription(getText("UI_ETW_Options_TraitColumns_tooltip"))
etwOptions:addSlider(
	"TraitColumns",
	getText("UI_ETW_Options_TraitColumns"),
	1,
	10,
	1,
	4,
	getText("UI_ETW_Options_TraitColumns_tooltip")
)

etwOptions:addTickBox(
	"HideSmokerUI",
	getText("UI_ETW_Options_HideSmokerUI"),
	false,
	getText("UI_ETW_Options_HideSmokerUI_tooltip")
)
