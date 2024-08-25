EvolvingTraitsWorld = EvolvingTraitsWorld or {};
EvolvingTraitsWorld.settings = EvolvingTraitsWorld.SETTINGS or {};

if ModOptions and ModOptions.AddKeyBinding then
	EvolvingTraitsWorld.KEYS_Toggle = { name = "ETW_UI_Toggle", key = Keyboard.KEY_LBRACKET}
	ModOptions:AddKeyBinding("[UI]",EvolvingTraitsWorld.KEYS_Toggle)
end

if ModOptions and ModOptions.getInstance then
	local function onModOptionsApply(optionValues)
		local UIWidth = { 500, 550, 600, 650, 700, 750, 800, 850, 900 };
		local traitColumns = { 1, 2, 3, 4, 5, 6};
		EvolvingTraitsWorld.settings.GatherDebug = optionValues.settings.options.GatherDebug;
		EvolvingTraitsWorld.settings.GatherDetailedDebug = optionValues.settings.options.GatherDetailedDebug;
		EvolvingTraitsWorld.settings.EnableNotifications = optionValues.settings.options.EnableNotifications;
		EvolvingTraitsWorld.settings.EnableDelayedNotifications = optionValues.settings.options.EnableDelayedNotifications;
		EvolvingTraitsWorld.settings.EnableBloodLustMoodle = optionValues.settings.options.EnableBloodLustMoodle;
		EvolvingTraitsWorld.settings.EnableSleepHealthMoodle = optionValues.settings.options.EnableSleepHealthMoodle;
		EvolvingTraitsWorld.settings.UIWidth = UIWidth[optionValues.settings.options.UIWidth];
		EvolvingTraitsWorld.settings.TraitColumns = traitColumns[optionValues.settings.options.TraitColumns];
	end
	local SETTINGS = {
		options_data = {
			GatherDebug = {
				name = "UI_ETW_Options_GatherDebug",
				tooltip = "UI_ETW_Options_GatherDebug_tooltip",
				default = false,
				OnApplyMainMenu = onModOptionsApply,
				OnApplyInGame = onModOptionsApply,
			},
			GatherDetailedDebug = {
				name = "UI_ETW_Options_GatherDetailedDebug",
				tooltip = "UI_ETW_Options_GatherDetailedDebug_tooltip",
				default = false,
				OnApplyMainMenu = onModOptionsApply,
				OnApplyInGame = onModOptionsApply,
			},
			EnableNotifications = {
				name = "UI_ETW_Options_EnableNotifications",
				tooltip = "UI_ETW_Options_EnableNotifications_tooltip",
				default = true,
				OnApplyMainMenu = onModOptionsApply,
				OnApplyInGame = onModOptionsApply,
			},
			EnableDelayedNotifications = {
				name = "UI_ETW_Options_EnableDelayedNotifications",
				tooltip = "UI_ETW_Options_EnableDelayedNotifications_tooltip",
				default = true,
				OnApplyMainMenu = onModOptionsApply,
				OnApplyInGame = onModOptionsApply,
			},
			EnableBloodLustMoodle = {
				name = "UI_ETW_Options_EnableBloodLustMoodle",
				tooltip = "UI_ETW_Options_EnableBloodLustMoodle_tooltip",
				default = true,
				OnApplyMainMenu = onModOptionsApply,
				OnApplyInGame = onModOptionsApply,
			},
			EnableSleepHealthMoodle = {
				name = "UI_ETW_Options_EnableSleepHealthMoodle",
				tooltip = "UI_ETW_Options_EnableSleepHealthMoodle_tooltip",
				default = true,
				OnApplyMainMenu = onModOptionsApply,
				OnApplyInGame = onModOptionsApply,
			},
			UIWidth = {
				"500", "550", "600", "650", "700", "750", "800", "850", "900",
				name = "UI_ETW_Options_UIWidth",
				tooltip = "UI_ETW_Options_UIWidth_tooltip",
				default = 5,
				OnApplyMainMenu = onModOptionsApply,
				OnApplyInGame = onModOptionsApply,
			},
			TraitColumns = {
				"1", "2", "3", "4", "5", "6",
				name = "UI_ETW_Options_TraitColumns",
				tooltip = "UI_ETW_Options_TraitColumns_tooltip",
				default = 4,
				OnApplyMainMenu = onModOptionsApply,
				OnApplyInGame = onModOptionsApply,
			},
		},
		mod_id = 'EvolvingTraitsWorld',
		mod_shortname = 'Evolving Traits World',
		mod_fullname = 'Evolving Traits World',
	}
	ModOptions:getInstance(SETTINGS)
	ModOptions:loadFile()

	Events.OnPreMapLoad.Add(function()
		onModOptionsApply({ settings = SETTINGS })
	end)
end