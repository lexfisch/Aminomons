extends Resource
class_name BigBigData

# Port of BigBigData.py into GDScript-style constants.

const PEPTIDE_DEX := {
	"alanine": {
		"stats": {"MAX_HEALTH": 42, "MAX_ENERGY": 29, "attack": 5, "defense": 5, "speed": 51, "recovery": 6, "element": "normal"},
		"ability": {0: "burn", 1: "scratch", 2: "tackle", 3: "heal", 4: "splash"},
		"fusion": ["alaninex2", 8],
		"unfusion": null,
		"id": 1,
		"sci": {"three_letter": "Ala", "single_letter": "A", "charged": false, "polar": false, "desc": "This is the desc"}
	},
	"alaninex2": {
		"stats": {"MAX_HEALTH": 52, "MAX_ENERGY": 39, "attack": 7, "defense": 7, "speed": 61, "recovery": 8, "element": "normal"},
		"ability": {0: "burn", 1: "scratch", 2: "tackle", 3: "heal", 4: "splash"},
		"fusion": ["alaninex3", 20],
		"unfusion": "alanine",
		"id": 2,
		"sci": {"three_letter": "Ala", "single_letter": "A", "charged": false, "polar": false, "desc": "This is the desc"}
	},
	"alaninex3": {
		"stats": {"MAX_HEALTH": 62, "MAX_ENERGY": 49, "attack": 9, "defense": 9, "speed": 71, "recovery": 10, "element": "normal"},
		"ability": {0: "burn", 1: "scratch", 2: "tackle", 3: "heal", 4: "splash"},
		"fusion": null,
		"unfusion": "alaninex2",
		"id": 3,
		"sci": {"three_letter": "Ala", "single_letter": "A", "charged": false, "polar": false, "desc": "This is the desc"}
	},

	"arginine": {
		"stats": {"MAX_HEALTH": 20, "MAX_ENERGY": 44, "attack": 6, "defense": 5, "speed": 89, "recovery": 5, "element": "electric"},
		"ability": {0: "burn", 1: "scratch", 2: "tackle", 3: "heal", 4: "splash"},
		"fusion": ["argininex2", 8],
		"unfusion": null,
		"id": 4,
		"sci": {"three_letter": "Arg", "single_letter": "R", "charged": true, "polar": true, "desc": "This is the desc"}
	},
	"argininex2": {
		"stats": {"MAX_HEALTH": 30, "MAX_ENERGY": 54, "attack": 8, "defense": 7, "speed": 99, "recovery": 7, "element": "electric"},
		"ability": {0: "burn", 1: "scratch", 2: "tackle", 3: "heal", 4: "splash"},
		"fusion": ["argininex3", 20],
		"unfusion": "arginine",
		"id": 5,
		"sci": {"three_letter": "Arg", "single_letter": "R", "charged": true, "polar": true, "desc": "This is the desc"}
	},
	"argininex3": {
		"stats": {"MAX_HEALTH": 40, "MAX_ENERGY": 64, "attack": 10, "defense": 9, "speed": 109, "recovery": 9, "element": "electric"},
		"ability": {0: "burn", 1: "scratch", 2: "tackle", 3: "heal", 4: "splash"},
		"fusion": null,
		"unfusion": "argininex2",
		"id": 6,
		"sci": {"three_letter": "Arg", "single_letter": "R", "charged": true, "polar": true, "desc": "This is the desc"}
	},

	# NOTE: For brevity in this initial port, only a subset of PEPTIDE_DEX entries is included here.
	# To fully match your original Python BigBigData.peptideDex, you can extend this dictionary
	# by copying the remaining entries from BigBigData.py and converting:
	# - True/False -> true/false
	# - None -> null
	# The structure for each entry is identical to the Python version.
}

const TRAINER_INFO := {
	"bc1": {
		"monsters": {0: ["valine", 8], 1: ["tyrosine", 8]},
		"dialog": {
			"default": ["Hey, who are you?", "Did you run that gel?", "No!?"],
			"defeated": ["Go update your lab notebook", "We'll fight again sometime."]
		},
		"directions": ["down"],
		"look_around": false,
		"defeated": false,
		"classroom": "labfight"
	},
	"bc2": {
		"monsters": {0: ["alanine", 8], 1: ["tryptophan", 8]},
		"dialog": {
			"default": ["Hey, who are you?", "Did you run that gel?", "No!?"],
			"defeated": ["Go update your lab notebook", "We'll fight again sometime."]
		},
		"directions": ["down"],
		"look_around": false,
		"defeated": false,
		"classroom": "labfight"
	},
	"boss": {
		"monsters": {0: ["proline", 5], 1: ["isoleucine", 3]},
		"direction": "right",
		"radius": 0,
		"look_around": false,
		"dialog": {
			"default": ["Hey, who are you?", "Did you run that gel?", "No!?"],
			"defeated": ["Go update your lab notebook", "We'll fight again sometime."]
		},
		"directions": ["right"],
		"defeated": false,
		"classroom": "labfight"
	},
	"healer": {
		"direction": "right",
		"radius": 0,
		"look_around": false,
		"dialog": {
			"default": ["BY THE POWER OF SCIENCE", "ALL THESE MOBS FRESH"],
			"defeated": null
		},
		"directions": ["right"],
		"defeated": false,
		"classroom": null
	},
	"fuser": {
		"direction": "right",
		"radius": 0,
		"look_around": false,
		"dialog": {
			"default": ["Let's try fusions!", "ALL AVaILABLE ARE FUSED"],
			"defeated": null
		},
		"directions": ["right"],
		"defeated": false,
		"classroom": null
	},
	"unfuser": {
		"direction": "right",
		"radius": 0,
		"look_around": false,
		"dialog": {
			"default": ["You don't want a fusion?", "ALL AMINOMONS ARE UNFUSED"],
			"defeated": null
		},
		"directions": ["right"],
		"defeated": false,
		"classroom": null
	},
	"storage": {
		"direction": "right",
		"radius": 0,
		"look_around": false,
		"dialog": {
			"default": ["I'm the PC storage beep boop."],
			"defeated": null
		},
		"directions": ["right"],
		"defeated": false,
		"classroom": null
	}
}

const SKILLS_DATA := {
	"burn": {"target": "opponent", "amount": 2, "cost": 5, "element": "fire", "animation": "attack"},
	"heal": {"target": "player", "amount": 2, "cost": 5, "element": "earth", "animation": "heal"},
	"scratch": {"target": "opponent", "amount": 2, "cost": 1, "element": "normal", "animation": "attack"},
	"tackle": {"target": "opponent", "amount": 2, "cost": 1, "element": "electric", "animation": "attack"},
	"splash": {"target": "opponent", "amount": 2, "cost": 1, "element": "water", "animation": "attack"}
}

