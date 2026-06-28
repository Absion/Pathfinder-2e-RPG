# pf_biography_constants.gd
## System-wide constants for lore, size, rarity, and world data.
class_name PFBiographyConstants

enum Gender { UNKNOWN, MALE, FEMALE, NON_BINARY, CONSTRUCT }
enum Vision { NORMAL, LOW_LIGHT, DARKVISION }
enum SenseType { VISION, HEARING, SCENT, TOUCH, TASTE, TREMORSENSE, LIFESENSE, MAGIC_SENSE }
enum SenseAcuity { PRECISE, IMPRECISE, VAGUE }
enum Rarity { COMMON, UNCOMMON, RARE, UNIQUE }
enum DivineBoonTier { MINOR, MODERATE, MAJOR }
enum DivineSanctification { NONE, CAN_CHOOSE_HOLY, CAN_CHOOSE_UNHOLY, CAN_CHOOSE_EITHER, MUST_CHOOSE_HOLY, MUST_CHOOSE_UNHOLY }
