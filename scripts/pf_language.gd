# pf_language.gd
class_name PFLanguage
extends RefCounted

# The master list of game languages
enum Type { 
	COMMON, DRACONIC, DWARVEN, ELVEN, GNOMISH, GOBLIN, 
	JOTUN, ORCISH, PETRAN, SAKVROTH, SYLVAN, UNDERCOMMON, IRUXI 
}

# Maps languages to their PF2e rarities
static func get_rarity(language: Type) -> PFEntity.Rarity:
	match language:
		# Uncommon Languages
		Type.DRACONIC, Type.SYLVAN, Type.UNDERCOMMON:
			return PFEntity.Rarity.UNCOMMON
		
		# Rare Languages (Placeholder for future expansion)
		# Type.SOMETHING_RARE: 
		#	return PFEntity.Rarity.RARE
			
		# Common Languages (Default)
		_:
			return PFEntity.Rarity.COMMON

# Helper for the Character Creator UI to fetch "any other languages to which you have access"
static func get_all_common_languages() -> Array[PFLanguage.Type]:
	var common_langs: Array[PFLanguage.Type] = []
	for key in Type.keys():
		var lang = Type[key] as PFLanguage.Type
		if get_rarity(lang) == PFEntity.Rarity.COMMON:
			common_langs.append(lang)
	return common_langs
