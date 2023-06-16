EvolvingTraitsWorld = EvolvingTraitsWorld or {};
EvolvingTraitsWorld.settings = EvolvingTraitsWorld.SETTINGS or {};

if ModOptions and ModOptions.getInstance then
	local function onModOptionsApply(optionValues)
		local SmokerMoodleVisibilityValues = { 10, 20, 30, 40, 50, 60, 70, 80, 90, 100 };
		EvolvingTraitsWorld.settings.GatherDebug = optionValues.settings.options.GatherDebug;
		EvolvingTraitsWorld.settings.GatherDetailedDebug = optionValues.settings.options.GatherDetailedDebug;
		EvolvingTraitsWorld.settings.EnableNotifications = optionValues.settings.options.EnableNotifications;
		EvolvingTraitsWorld.settings.EnableDelayedNotifications = optionValues.settings.options.EnableDelayedNotifications;
		EvolvingTraitsWorld.settings.EnableBloodLustMoodle = optionValues.settings.options.EnableBloodLustMoodle;
		EvolvingTraitsWorld.settings.EnableSleepHealthMoodle = optionValues.settings.options.EnableSleepHealthMoodle;
		EvolvingTraitsWorld.settings.EnableSmokerMoodle = optionValues.settings.options.EnableSmokerMoodle;
		EvolvingTraitsWorld.settings.SmokerMoodleVisibilityValue = SmokerMoodleVisibilityValues[optionValues.settings.options.SmokerMoodleVisibilityValue];
	end
	local SETTINGS = {
		options_data = {
			GatherDebug = {
				name = "UI_EvolvingTraitsWorld_Options_GatherDebug",
				tooltip = "UI_EvolvingTraitsWorld_Options_GatherDebug_tooltip",
				default = true,
				OnApplyMainMenu = onModOptionsApply,
				OnApplyInGame = onModOptionsApply,
			},
			GatherDetailedDebug = {
				name = "UI_EvolvingTraitsWorld_Options_GatherDetailedDebug",
				tooltip = "UI_EvolvingTraitsWorld_Options_GatherDetailedDebug_tooltip",
				default = false,
				OnApplyMainMenu = onModOptionsApply,
				OnApplyInGame = onModOptionsApply,
			},
			EnableNotifications = {
				name = "UI_EvolvingTraitsWorld_Options_EnableNotifications",
				tooltip = "UI_EvolvingTraitsWorld_Options_EnableNotifications_tooltip",
				default = true,
				OnApplyMainMenu = onModOptionsApply,
				OnApplyInGame = onModOptionsApply,
			},
			EnableDelayedNotifications = {
				name = "UI_EvolvingTraitsWorld_Options_EnableDelayedNotifications",
				tooltip = "UI_EvolvingTraitsWorld_Options_EnableDelayedNotifications_tooltip",
				default = true,
				OnApplyMainMenu = onModOptionsApply,
				OnApplyInGame = onModOptionsApply,
			},
			EnableBloodLustMoodle = {
				name = "UI_EvolvingTraitsWorld_Options_EnableBloodLustMoodle",
				tooltip = "UI_EvolvingTraitsWorld_Options_EnableBloodLustMoodle_tooltip",
				default = true,
				OnApplyMainMenu = onModOptionsApply,
				OnApplyInGame = onModOptionsApply,
			},
			EnableSleepHealthMoodle = {
				name = "UI_EvolvingTraitsWorld_Options_EnableSleepHealthMoodle",
				tooltip = "UI_EvolvingTraitsWorld_Options_EnableSleepHealthMoodle_tooltip",
				default = true,
				OnApplyMainMenu = onModOptionsApply,
				OnApplyInGame = onModOptionsApply,
			},
			EnableSmokerMoodle = {
				name = "UI_EvolvingTraitsWorld_Options_EnableSmokerMoodle",
				tooltip = "UI_EvolvingTraitsWorld_Options_EnableSmokerMoodle_tooltip",
				default = true,
				OnApplyMainMenu = onModOptionsApply,
				OnApplyInGame = onModOptionsApply,
			},
			SmokerMoodleVisibilityValue = {
				"10", "20", "30", "40", "50", "60", "70", "80", "90", "100",
				name = "UI_EvolvingTraitsWorld_Options_SmokerMoodleVisibilityValue",
				tooltip = "UI_EvolvingTraitsWorld_Options_SmokerMoodleVisibilityValue_tooltip",
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