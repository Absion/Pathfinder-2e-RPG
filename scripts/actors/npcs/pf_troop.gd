# pf_troop.gd
## A singular entity composed of many intelligent creatures. Features specialized health tracking and area attacks.
class_name PFTroop
extends PFNpc

var active_segments: Array[Vector3] = []
var threshold_1: int
var threshold_2: int
var _previous_hp: int

# Cached damage info for segment removal
var _last_attacker: PFActor = null
var _last_target_pos: Vector3 = Vector3.INF
var _last_effect_traits: Array[StringName] = []

func _init(p_base_id: StringName, p_name: String, p_traits: Array[StringName], p_level: int,
		p_hp: int, p_fort: int, p_ref: int, p_will: int,
		p_str: int, p_dex: int, p_con: int, p_int: int, p_wis: int, p_cha: int,
		p_speed_land: int = 25, p_speed_fly: int = 0, p_speed_swim: int = 0,
		p_speed_climb: int = 0, p_speed_burrow: int = 0,
		p_description: String = "", 
		p_has_spirit: bool = true):
			
	if not p_traits.has(&"troop"):
		p_traits.append(&"troop")
		
	super._init(p_base_id, p_name, p_traits, p_level, p_hp, p_fort, p_ref, p_will, p_str, p_dex, p_con, p_int, p_wis, p_cha, p_speed_land, p_speed_fly, p_speed_swim, p_speed_climb, p_speed_burrow, p_description, p_has_spirit)
	
	# Troops are inherently immune to several conditions that target single creatures
	add_immunity(&"grabbed")
	add_immunity(&"prone")
	add_immunity(&"restrained")
	
	# Setup Thresholds and Segments
	threshold_1 = floori(p_hp * 2.0 / 3.0)
	threshold_2 = floori(p_hp / 3.0)
	_previous_hp = p_hp
	
	# By default, a troop starts as a 2x2 grid of 10x10 segments.
	# The actor's global_position acts as the anchor point (0,0).
	active_segments = [
		Vector3(0, 0, 0),
		Vector3(2, 0, 0),
		Vector3(0, 0, 2),
		Vector3(2, 0, 2)
	]
	
	health.hp_changed.connect(_on_hp_changed)

func take_damage(amount: int, damage_type: PFCombatConstants.DamageType = PFCombatConstants.DamageType.UNTYPED, effect_traits: Array[StringName] = [], source_actor: PFActor = null, target_position: Vector3 = Vector3.INF) -> void:
	_last_attacker = source_actor
	_last_target_pos = target_position
	_last_effect_traits = effect_traits
	super.take_damage(amount, damage_type, effect_traits, source_actor, target_position)

func _on_hp_changed(current_hp: int, _max_hp: int) -> void:
	if _previous_hp > threshold_1 and current_hp <= threshold_1:
		_remove_segment()
	if _previous_hp > threshold_2 and current_hp <= threshold_2:
		_remove_segment()
	
	_previous_hp = current_hp
	if current_hp <= 0:
		active_segments.clear()

func _remove_segment() -> void:
	if active_segments.size() <= 1:
		return
		
	var is_area = _last_effect_traits.has(&"area") or _last_effect_traits.has(&"splash")
	
	if is_area:
		# Randomly select a segment within the area.
		# For simplicity, we just pick a random segment.
		var random_idx = randi() % active_segments.size()
		active_segments.remove_at(random_idx)
	else:
		# Single Target: remove the targeted segment, or closest to the attacker
		var anchor = self.global_position if self.is_inside_tree() else Vector3.ZERO
		var target_loc = _last_target_pos
		
		# If no specific target location, default to the attacker's location
		if target_loc == Vector3.INF and _last_attacker != null and _last_attacker.is_inside_tree():
			target_loc = _last_attacker.global_position
			
		if target_loc != Vector3.INF:
			var closest_idx = -1
			var closest_dist_sq = INF
			var ties: Array[int] = []
			
			var relative_target = target_loc - anchor

			for i in range(active_segments.size()):
				var seg = active_segments[i]
				# ⚡ Bolt: Use native distance_squared_to instead of inline math
				# to leverage optimized C++ built-ins and maintain 2D/3D compatibility
				var dist_sq = seg.distance_squared_to(relative_target)

				if dist_sq < closest_dist_sq:
					closest_dist_sq = dist_sq
					closest_idx = i
					ties.clear()
					ties.append(i)
				elif is_equal_approx(dist_sq, closest_dist_sq):
					ties.append(i)
					
			if ties.size() > 1:
				active_segments.remove_at(ties[randi() % ties.size()])
			else:
				active_segments.remove_at(closest_idx)
		else:
			# Fallback: random
			var random_idx = randi() % active_segments.size()
			active_segments.remove_at(random_idx)

