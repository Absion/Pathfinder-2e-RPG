# pf_language.gd
## Represents a language that an actor can speak or understand.
class_name PFLanguage
extends RefCounted

# The master list of game languages
# Maps languages to their PF2e rarities
static func get_rarity(language: PFBiographyConstants.LanguageType) -> PFBiographyConstants.Rarity:
	match language:
		# Uncommon Languages
		PFBiographyConstants.LanguageType.DRACONIC, PFBiographyConstants.LanguageType.SYLVAN, PFBiographyConstants.LanguageType.UNDERCOMMON:
			return PFBiographyConstants.Rarity.UNCOMMON
		
		# Rare Languages (Placeholder for future expansion)
		# PFBiographyConstants.LanguageType.SOMETHING_RARE: 
		#	return PFBiographyConstants.Rarity.RARE
			
		# Common Languages (Default)
		_:
			return PFBiographyConstants.Rarity.COMMON

# Helper for the Character Creator UI to fetch "any other languages to which you have access"
static func get_all_common_languages() -> Array[PFBiographyConstants.LanguageType]:
	var common_langs: Array[PFBiographyConstants.LanguageType] = []
	for key in PFBiographyConstants.LanguageType.keys():
		var lang = PFBiographyConstants.LanguageType[key] as PFBiographyConstants.LanguageType
		if get_rarity(lang) == PFBiographyConstants.Rarity.COMMON:
			common_langs.append(lang)
	return common_langs
