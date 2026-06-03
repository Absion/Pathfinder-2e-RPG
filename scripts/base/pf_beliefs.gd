# pf_beliefs.gd
class_name PFBeliefs
extends RefCounted

const VALID_EDICTS: Array[String] = [
	"Create art",
	"Defend nature",
	"Protect the innocent",
	"Seek knowledge",
	"Destroy undead",
	"Uphold the law",
	"Farming Lore" # Added temporarily if used as an edict placeholder
]

const VALID_ANATHEMA: Array[String] = [
	"Create undead",
	"Despoil nature",
	"Harm the innocent",
	"Destroy knowledge",
	"Tell a lie",
	"Break a promise"
]

static func is_valid_edict(edict: String) -> bool:
	return VALID_EDICTS.has(edict)

static func is_valid_anathema(anathema: String) -> bool:
	return VALID_ANATHEMA.has(anathema)
