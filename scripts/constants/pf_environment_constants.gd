# pf_environment_constants.gd
class_name PFEnvironmentConstants
extends RefCounted

enum TerrainType {
	NORMAL,
	DIFFICULT,
	GREATER_DIFFICULT,
	HAZARDOUS
}

enum Temperature {
	INCREDIBLE_COLD, # Below -80 F
	EXTREME_COLD,    # -80 F to -20 F
	SEVERE_COLD,     # -20 F to 32 F
	MILD_COLD,       # 32 F to 50 F
	NORMAL,          # 50 F to 80 F
	MILD_HEAT,       # 80 F to 90 F
	SEVERE_HEAT,     # 90 F to 105 F
	EXTREME_HEAT,    # 105 F to 130 F
	INCREDIBLE_HEAT  # Above 130 F
}

enum EnvironmentDamageSeverity {
	MINOR,
	MODERATE,
	MAJOR,
	MASSIVE
}
