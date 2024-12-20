require "Foraging/forageDefinitions";

if forageSkills then
	forageSkills.GunEnthusiast = {
		name = "GunEnthusiast",
		type = "trait",
		specialisations = {
			["Ammunition"] = 5,
		},
	};
	forageSkills.Hoarder = {
		name = "Hoarder",
		type = "trait",
		specialisations = {
			["Trash"] = 10,
		},
	};
	forageSkills.HomeCook = {
		name = "HomeCook",
		type = "trait",
		specialisations = {
			["Berries"] = 2,
			["Fruits"] = 2,
			["Vegetables"] = 2,
			["Mushrooms"] = 2,
		},
	};
end