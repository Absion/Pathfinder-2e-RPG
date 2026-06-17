# pf_environment_manager.gd
## Manages global environment state, temperature, terrain conditions, and aquatic status.
## Handles periodic effects like extreme cold or heat damage during exploration.
class_name PFEnvironmentManager
extends Node

static var _instance: PFEnvironmentManager

var current_temperature: PFEnvironmentConstants.Temperature = PFEnvironmentConstants.Temperature.NORMAL
var current_terrain: PFEnvironmentConstants.TerrainType = PFEnvironmentConstants.TerrainType.NORMAL
var is_underwater: bool = false
var environment_level: int = 1 # Used for scaling passive hazards like Extreme Heat damage.

# Internal tracking for periodic damage
var _seconds_since_last_temp_tick: int = 0

func _init() -> void:
	_instance = self

func _ready() -> void:
	var tm = PFTimeManager.get_instance()
	if tm:
		tm.time_advanced.connect(_on_time_advanced)
		tm.rested_for_night.connect(_on_rested)

static func get_instance() -> PFEnvironmentManager:
	return _instance

## Utility to check if extreme temperatures apply
func _on_time_advanced(seconds: int) -> void:
	_seconds_since_last_temp_tick += seconds
	
	match current_temperature:
		PFEnvironmentConstants.Temperature.SEVERE_HEAT, PFEnvironmentConstants.Temperature.SEVERE_COLD:
			# Damage every hour
			if _seconds_since_last_temp_tick >= PFTimeManager.SECONDS_PER_HOUR:
				_apply_temperature_damage(PFEnvironmentConstants.EnvironmentDamageSeverity.MINOR)
				_seconds_since_last_temp_tick = 0
				
		PFEnvironmentConstants.Temperature.EXTREME_HEAT, PFEnvironmentConstants.Temperature.EXTREME_COLD:
			# Damage every 10 minutes
			if _seconds_since_last_temp_tick >= PFTimeManager.SECONDS_PER_MINUTE * 10:
				_apply_temperature_damage(PFEnvironmentConstants.EnvironmentDamageSeverity.MODERATE)
				_seconds_since_last_temp_tick = 0
				
		PFEnvironmentConstants.Temperature.INCREDIBLE_HEAT, PFEnvironmentConstants.Temperature.INCREDIBLE_COLD:
			# Damage every 1 minute
			if _seconds_since_last_temp_tick >= PFTimeManager.SECONDS_PER_MINUTE:
				_apply_temperature_damage(PFEnvironmentConstants.EnvironmentDamageSeverity.MAJOR)
				_seconds_since_last_temp_tick = 0
		_:
			# Mild or Normal temps do not deal periodic damage, but might cause fatigue (handled in survival/resting rules).
			_seconds_since_last_temp_tick = 0

func _on_rested() -> void:
	# Resting resets tick timer but could also trigger its own effects.
	_seconds_since_last_temp_tick = 0

func _apply_temperature_damage(severity: PFEnvironmentConstants.EnvironmentDamageSeverity) -> void:
	var dmg_type = PFCombatConstants.DamageType.FIRE if current_temperature >= PFEnvironmentConstants.Temperature.MILD_HEAT else PFCombatConstants.DamageType.COLD
	var temp_name = PFEnvironmentConstants.Temperature.keys()[current_temperature].capitalize()
	
	print("\n--- Environmental Hazard: %s ---" % temp_name)
	
	# Fetch party and apply damage
	for actor in PFContext.active_party:
		var dmg_result = PFGameMath.get_environmental_damage(environment_level, severity)
		print("    > %s takes %d %s damage from %s!" % [actor.entity_name, dmg_result.total, PFCombatConstants.DamageType.keys()[dmg_type].capitalize(), temp_name])
		actor.take_damage(dmg_result.total, dmg_type, [&"environmental", &"weather"])
