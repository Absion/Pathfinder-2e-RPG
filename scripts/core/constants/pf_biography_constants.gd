# pf_biography_constants.gd
## System-wide constants for lore, size, rarity, and world data.
class_name PFBiographyConstants

enum Gender { UNKNOWN, MALE, FEMALE, NON_BINARY, CONSTRUCT }
enum Region { UNKNOWN, LINVARRE, ABSALOM, ANDORAN, CHELIAX, TALDOR, QADIRA }
enum LanguageType { COMMON, DWARVEN, ELVEN, GNOMISH, GOBLIN, HALFLING, ORCISH, SYLVAN, UNDERCOMMON, DRACONIC, CELESTIAL, ABYSSAL, INFERNAL, DRUIDIC }
enum Size { TINY, SMALL, MEDIUM, LARGE, HUGE, GARGANTUAN }
enum Vision { NORMAL, LOW_LIGHT, DARKVISION }
enum SenseType { VISION, HEARING, SCENT, TOUCH, TASTE, TREMORSENSE, LIFESENSE, MAGIC_SENSE }
enum SenseAcuity { PRECISE, IMPRECISE, VAGUE }
enum Rarity { COMMON, UNCOMMON, RARE, UNIQUE }

## Returns a mathematical representation of size where Small and Medium are identical.
static func get_effective_size(size: Size) -> int:
	match size:
		Size.TINY: return 0
		Size.SMALL, Size.MEDIUM: return 1
		Size.LARGE: return 2
		Size.HUGE: return 3
		Size.GARGANTUAN: return 4
		_: return 1
