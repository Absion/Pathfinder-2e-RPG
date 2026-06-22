class_name PFMonsterRoadmaps
extends Object

## Base PF2e Monster Roadmaps, mapping stats to Table Brackets.
static var ROADMAPS: Dictionary = {
	&"Brute": {
		"hp": &"HIGH",
		"ac": &"LOW",
		"fort": &"HIGH",
		"ref": &"LOW",
		"wil": &"LOW",
		"per": &"LOW",
		"str": &"HIGH",
		"dex": &"LOW",
		"con": &"MODERATE",
		"int": &"LOW",
		"wis": &"LOW",
		"cha": &"LOW",
		"strikeBonus": &"HIGH",
		"strikeDamage": &"HIGH"
	},
	&"Skirmisher": {
		"hp": &"MODERATE",
		"ac": &"MODERATE",
		"fort": &"LOW",
		"ref": &"HIGH",
		"wil": &"MODERATE",
		"per": &"MODERATE",
		"str": &"MODERATE",
		"dex": &"HIGH",
		"con": &"MODERATE",
		"int": &"MODERATE",
		"wis": &"MODERATE",
		"cha": &"MODERATE",
		"strikeBonus": &"HIGH",
		"strikeDamage": &"MODERATE",
		"abilities": [&"sneak_attack"]
	},
	&"Sniper": {
		"hp": &"LOW",
		"ac": &"MODERATE",
		"fort": &"LOW",
		"ref": &"HIGH",
		"wil": &"MODERATE",
		"per": &"HIGH",
		"str": &"LOW",
		"dex": &"HIGH",
		"con": &"LOW",
		"int": &"MODERATE",
		"wis": &"MODERATE",
		"cha": &"MODERATE",
		"strikeBonus": &"HIGH",
		"strikeDamage": &"HIGH"
	},
	&"Soldier": {
		"hp": &"MODERATE",
		"ac": &"EXTREME",
		"fort": &"HIGH",
		"ref": &"MODERATE",
		"wil": &"MODERATE",
		"per": &"MODERATE",
		"str": &"HIGH",
		"dex": &"MODERATE",
		"con": &"HIGH",
		"int": &"LOW",
		"wis": &"MODERATE",
		"cha": &"LOW",
		"strikeBonus": &"HIGH",
		"strikeDamage": &"MODERATE"
	},
	&"Magical Striker": {
		"hp": &"MODERATE",
		"ac": &"MODERATE",
		"fort": &"MODERATE",
		"ref": &"MODERATE",
		"wil": &"HIGH",
		"per": &"MODERATE",
		"str": &"HIGH",
		"dex": &"MODERATE",
		"con": &"MODERATE",
		"int": &"MODERATE",
		"wis": &"MODERATE",
		"cha": &"MODERATE",
		"strikeBonus": &"HIGH",
		"strikeDamage": &"HIGH",
		"spellcasting": &"MODERATE"
	},
	&"Spellcaster": {
		"hp": &"LOW",
		"ac": &"LOW",
		"fort": &"LOW",
		"ref": &"MODERATE",
		"wil": &"HIGH",
		"per": &"MODERATE",
		"str": &"LOW",
		"dex": &"MODERATE",
		"con": &"LOW",
		"int": &"HIGH",
		"wis": &"HIGH",
		"cha": &"MODERATE",
		"strikeBonus": &"LOW",
		"strikeDamage": &"LOW",
		"spellcasting": &"HIGH"
	},
	&"Winged Beast": {
		"hp": &"MODERATE",
		"ac": &"MODERATE",
		"fort": &"MODERATE",
		"ref": &"HIGH",
		"wil": &"LOW",
		"per": &"HIGH",
		"str": &"MODERATE",
		"dex": &"HIGH",
		"con": &"MODERATE",
		"int": &"LOW",
		"wis": &"MODERATE",
		"cha": &"LOW",
		"strikeBonus": &"HIGH",
		"strikeDamage": &"MODERATE",
		"abilities": [&"fly_speed"]
	},
	&"Stealthy Beast": {
		"hp": &"MODERATE",
		"ac": &"MODERATE",
		"fort": &"MODERATE",
		"ref": &"HIGH",
		"wil": &"LOW",
		"per": &"MODERATE",
		"str": &"MODERATE",
		"dex": &"HIGH",
		"con": &"MODERATE",
		"int": &"LOW",
		"wis": &"MODERATE",
		"cha": &"LOW",
		"strikeBonus": &"HIGH",
		"strikeDamage": &"MODERATE",
		"abilities": [&"sneak_attack", &"stealth"]
	},
	&"Four-Legged Beast": {
		"hp": &"HIGH",
		"ac": &"MODERATE",
		"fort": &"HIGH",
		"ref": &"MODERATE",
		"wil": &"LOW",
		"per": &"MODERATE",
		"str": &"HIGH",
		"dex": &"MODERATE",
		"con": &"HIGH",
		"int": &"LOW",
		"wis": &"MODERATE",
		"cha": &"LOW",
		"strikeBonus": &"HIGH",
		"strikeDamage": &"MODERATE",
		"abilities": [&"fast_land_speed"]
	}
}

## Returns an array of available roadmap names.
static func get_all_roadmaps() -> Array[StringName]:
	return ROADMAPS.keys()

## Returns the dictionary for a specific roadmap.
static func get_roadmap(roadmap_name: String) -> Dictionary:
	var target = roadmap_name.to_lower()
	for key in ROADMAPS:
		if String(key).to_lower() == target:
			return ROADMAPS[key]
	return ROADMAPS[&"Brute"]
