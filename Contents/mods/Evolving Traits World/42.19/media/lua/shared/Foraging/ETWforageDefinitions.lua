---@diagnostic disable: undefined-global
require "Foraging/forageDefinitions"

if forageSkills then
	forageSkills.GunEnthusiast = {
		name = "GunEnthusiast",
		type = "trait",
		specialisations = {
			["Ammunition"] = 5,
		},
	}
	forageSkills.Hoarder = {
		name = "Hoarder",
		type = "trait",
		specialisations = {
			["Trash"] = 10,
		},
	}
	forageSkills.HomeCook = {
		name = "HomeCook",
		type = "trait",
		specialisations = {
			["Berries"] = 2,
			["Fruits"] = 2,
			["Vegetables"] = 2,
			["Mushrooms"] = 2,
		},
	}
	forageSkills.Gourmand = {
		name = "ETW:Gourmand",
		type = "trait",
		specialisations = {
			["Animals"] = 3,
			["Berries"] = 3,
			["Mushrooms"] = 25,
			["JunkFood"] = 3,
		},
	}
end
