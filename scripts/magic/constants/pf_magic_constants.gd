# pf_magic_constants.gd
## System-wide constants for spellcasting, traditions, and scaling.
class_name PFMagicConstants

enum MagicTradition { NONE = 0, ARCANE = 1, DIVINE = 2, OCCULT = 3, PRIMAL = 4 }
enum CasterType { NONE = 0, PREPARED = 1, SPONTANEOUS = 2, BOTH = 3 }
enum ScalingType { NONE = 0, PLUS_ONE = 1, PLUS_TWO = 2, PLUS_THREE = 3, PLUS_FOUR = 4 }
enum SpellCategory { SPELL = 0, CANTRIP = 1, FOCUS = 2 }
enum SpellProgression { NONE = 0, FULL_CASTER = 1, BOUNDED_CASTER = 2 }
