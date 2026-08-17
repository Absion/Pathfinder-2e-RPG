# pf_spatial_math.gd
## Static utility class for calculating complex grid and spatial mechanics.
class_name PFSpatialMath

## Checks if the attacker and ally are flanking the target.
static func is_flanking(attacker: PFActor, target: PFActor, ally: PFActor) -> bool:
	if not attacker or not target or not ally:
		return false
	
	# The ally must be able to act, wielding a melee weapon, etc. (Simplified for now)
	if ally.is_dead or ally.has_condition("unconscious") or ally.has_condition("paralyzed"):
		return false
		
	# ⚡ Bolt: Cache node properties to avoid redundant Godot C++ boundary crossings
	var attacker_pos = attacker.position
	var ally_pos = ally.position
	var target_pos = target.position

	# Both must have the target within melee reach.
	var dist_attacker = PFCombatGrid.get_distance_pf2e(attacker_pos, target_pos)
	var dist_ally = PFCombatGrid.get_distance_pf2e(ally_pos, target_pos)
	
	var attacker_reach = 5 # Default melee reach
	var ally_reach = 5
	
	if dist_attacker > attacker_reach or dist_ally > ally_reach:
		return false
		
	# Gang Up Exception: Bypasses the geometry check
	if attacker.has_passive_feature(&"gang_up"):
		return true
		
	# Target is immune to being flanked by this attacker? (e.g. Deny Advantage)
	if not target.can_be_flanked_by(attacker):
		return false

	# Geometric Flanking Check (Opposite Sides/Corners)
	# For a 1x1 target, they must be collinear with the target's center and on opposite sides.
	# We can use the dot product of the normalized directions from the target to the attackers.
	# If the dot product is less than -0.5, they are generally on opposite sides.
	# For a strict PF2e check on a grid, if the line intersects opposite edges of the target's bounding box.
	
	var a1 = Vector2(attacker_pos.x, attacker_pos.z)
	var a2 = Vector2(ally_pos.x, ally_pos.z)
	var target_pos2d = Vector2(target_pos.x, target_pos.z)
	
	# Simple PF2e logic for 1x1: A line between centers passes through opposite sides/corners.
	# This means the target must be exactly between them in either the X or Z axis, or both.
	# If Target is at (0,0), A1 at (-1,0), A2 must be at (1,0) (or 1,-1 or 1,1).
	var dir1 = (a1 - target_pos2d)
	var dir2 = (a2 - target_pos2d)
	
	# If they are on the exact same side, no flank.
	if sign(dir1.x) == sign(dir2.x) and sign(dir1.x) != 0:
		return false
	if sign(dir1.y) == sign(dir2.y) and sign(dir1.y) != 0:
		return false
		
	# To ensure the line actually passes THROUGH the target, we check the line segment distance to target center.
	# But since we snapped them to grid, if they are on opposite sides, the segment will pass through the 1x1 box.
	# In PF2e, you can flank if you are opposite on ANY axis (X or Z) as long as you draw a line through opposite edges.
	
	# For true line intersection with the 1x1 box at `target_pos2d`:
	# The box is [target_pos2d.x - 0.5, target_pos2d.x + 0.5] x [target_pos2d.y - 0.5, target_pos2d.y + 0.5]
	if _line_intersects_opposite_sides_of_rect(a1, a2, target_pos2d, 1.0):
		return true
		
	return false

## Helper for PF2e strict opposite sides/corners checking
static func _line_intersects_opposite_sides_of_rect(p1: Vector2, p2: Vector2, rect_center: Vector2, size: float) -> bool:
	var half_size = size / 2.0
	var min_x = rect_center.x - half_size
	var max_x = rect_center.x + half_size
	var min_y = rect_center.y - half_size
	var max_y = rect_center.y + half_size
	
	# Find intersections of line p1-p2 with the 4 infinite lines of the rect
	var delta_x = p2.x - p1.x
	var delta_y = p2.y - p1.y
	
	var hits_left = false
	var hits_right = false
	var hits_top = false
	var hits_bottom = false
	
	if delta_x != 0:
		var t_left = (min_x - p1.x) / delta_x
		var y_left = p1.y + t_left * delta_y
		if y_left >= min_y and y_left <= max_y and t_left >= 0 and t_left <= 1: hits_left = true
		
		var t_right = (max_x - p1.x) / delta_x
		var y_right = p1.y + t_right * delta_y
		if y_right >= min_y and y_right <= max_y and t_right >= 0 and t_right <= 1: hits_right = true

	if delta_y != 0:
		var t_top = (min_y - p1.y) / delta_y
		var x_top = p1.x + t_top * delta_x
		if x_top >= min_x and x_top <= max_x and t_top >= 0 and t_top <= 1: hits_top = true
		
		var t_bottom = (max_y - p1.y) / delta_y
		var x_bottom = p1.x + t_bottom * delta_x
		if x_bottom >= min_x and x_bottom <= max_x and t_bottom >= 0 and t_bottom <= 1: hits_bottom = true
		
	return (hits_left and hits_right) or (hits_top and hits_bottom)

## Casts a 3D ray to determine Cover Level.
static func get_cover_level(attacker: PFActor, target: PFActor, space_state: PhysicsDirectSpaceState3D) -> PFCombatConstants.CoverType:
	if not space_state: return PFCombatConstants.CoverType.NONE
	
	# Raycast from center to center. Usually PF2e characters are ~1.5m tall, center is at Y=1.0
	var start_pos = attacker.position + Vector3(0, 1.0, 0)
	var end_pos = target.position + Vector3(0, 1.0, 0)
	
	# Collision masks based on project.godot: 
	# Layer 1 = Environment (Bit 0) -> Value 1
	# Layer 2 = Actors (Bit 1) -> Value 2
	var mask = 1 | 2 # Check both Environment and Actors
	
	var exclude = []
	if attacker.has_method(&"get_rid"): exclude.append(attacker.get_rid())
	if target.has_method(&"get_rid"): exclude.append(target.get_rid())
	var query = PhysicsRayQueryParameters3D.create(start_pos, end_pos, mask, exclude)
	var result = space_state.intersect_ray(query)
	
	if result:
		var hit_collider = result.collider
		
		# Did we hit environment?
		if hit_collider.collision_layer & 1:
			return PFCombatConstants.CoverType.STANDARD
			
		# Did we hit an actor?
		if hit_collider.collision_layer & 2:
			var hit_actor = hit_collider as PFActor
			if hit_actor:
				var is_prone = hit_actor.has_condition("prone")
				var hit_size = _get_actor_effective_size(hit_actor)
				var a_size = _get_actor_effective_size(attacker)
				var t_size = _get_actor_effective_size(target)
				
				if is_prone:
					# Prone actors generally do not provide cover
					# Large/Huge Prone Allies Exception: Provide Lesser if 2+ sizes larger
					if hit_size >= a_size + 2 and hit_size >= t_size + 2:
						return PFCombatConstants.CoverType.LESSER
					return PFCombatConstants.CoverType.NONE
					
				# Check Giant Creature Rule (Standing)
				# If blocking creature is 2+ sizes larger than BOTH
				if hit_size >= a_size + 2 and hit_size >= t_size + 2:
					return PFCombatConstants.CoverType.STANDARD
					
			return PFCombatConstants.CoverType.LESSER
			
	return PFCombatConstants.CoverType.NONE

static func _get_actor_effective_size(actor: PFActor) -> int:
	# Mock up sizing logic
	# In a real system, query PFDatabase.get_size_data(actor.size_id)
	var size_id = actor.core.size_id if (actor and actor.core) else &"medium"
	
	match size_id:
		&"tiny": return 0
		&"small": return 1
		&"medium": return 1
		&"large": return 2
		&"huge": return 3
		&"gargantuan": return 4
	return 1

# --- VOLUMETRIC AOE MATH & LINE OF EFFECT ---

static func _check_line_of_effect(space_state: PhysicsDirectSpaceState3D, origin: Vector3, target: PFActor) -> bool:
	if not space_state: return false
	# Raycast from AoE origin to target center
	var target_pos = target.position + Vector3(0, 1.0, 0)
	# Layer 1 = Environment
	var query = PhysicsRayQueryParameters3D.create(origin, target_pos, 1)
	var result = space_state.intersect_ray(query)
	# If we hit environment before reaching target, LoE is blocked
	return not result

static func _filter_by_loe(space_state: PhysicsDirectSpaceState3D, origin: Vector3, raw_results: Array[Dictionary], ignores_cover: bool) -> Array[PFActor]:
	var hit_actors: Array[PFActor] = []
	for res in raw_results:
		var actor = res.collider as PFActor
		if actor and not hit_actors.has(actor):
			if ignores_cover or _check_line_of_effect(space_state, origin, actor):
				hit_actors.append(actor)
	return hit_actors

static func get_burst_targets(space_state: PhysicsDirectSpaceState3D, origin: Vector3, radius_feet: float, ignores_cover: bool = false) -> Array[PFActor]:
	if not space_state: return []
	var radius_meters = radius_feet / 5.0 # 5 feet = 1 meter/unit
	
	var shape = SphereShape3D.new()
	shape.radius = radius_meters
	
	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis(), origin)
	query.collision_mask = 2 # Layer 2 = Actors
	
	var raw_results = space_state.intersect_shape(query, 100)
	return _filter_by_loe(space_state, origin, raw_results, ignores_cover)

static func get_splash_targets(space_state: PhysicsDirectSpaceState3D, target_pos: Vector3, splash_radius: float = 5.0, ignores_cover: bool = false) -> Array[PFActor]:
	return get_burst_targets(space_state, target_pos, splash_radius, ignores_cover)

static func get_emanation_targets(space_state: PhysicsDirectSpaceState3D, actor: PFActor, radius_feet: float, ignores_cover: bool = false) -> Array[PFActor]:
	if not space_state: return []
	var radius_meters = radius_feet / 5.0
	var actor_size = _get_actor_effective_size(actor)
	
	# Medium/Small = 1x1 (1 unit), Large = 2x2 (2 units), etc.
	# We want a box that is the actor's size + radius on all sides
	var base_width = 1.0 if actor_size <= 1 else float(actor_size)
	var box_width = base_width + (radius_meters * 2.0)
	var box_height = 2.0 + (radius_meters * 2.0) # Assume base actor is ~2 units tall
	
	var shape = BoxShape3D.new()
	shape.size = Vector3(box_width, box_height, box_width)
	
	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis(), actor.position + Vector3(0, 1.0, 0)) # Center of actor
	query.collision_mask = 2
	
	var raw_results = space_state.intersect_shape(query, 100)
	
	var hit_actors: Array[PFActor] = []
	var origin = actor.position + Vector3(0, 1.0, 0)
	for res in raw_results:
		var target_actor = res.collider as PFActor
		if target_actor and target_actor != actor and not hit_actors.has(target_actor):
			if ignores_cover or _check_line_of_effect(space_state, origin, target_actor):
				hit_actors.append(target_actor)
				
	return hit_actors

static func get_cone_targets(space_state: PhysicsDirectSpaceState3D, origin: Vector3, direction: Vector3, length_feet: float, ignores_cover: bool = false) -> Array[PFActor]:
	if not space_state: return []
	var length_meters = length_feet / 5.0
	
	# Construct a ConvexPolygonShape3D for a pyramid/cone
	var shape = ConvexPolygonShape3D.new()
	# Standard PF2e cone: spreads out 1 unit per 1 unit of length
	var spread = length_meters
	
	# Base point
	var p0 = Vector3(0, 0, 0)
	# 4 corners of the far plane (looking down -Z)
	var p1 = Vector3(-spread/2.0, -spread/2.0, -length_meters)
	var p2 = Vector3(spread/2.0, -spread/2.0, -length_meters)
	var p3 = Vector3(spread/2.0, spread/2.0, -length_meters)
	var p4 = Vector3(-spread/2.0, spread/2.0, -length_meters)
	
	shape.points = PackedVector3Array([p0, p1, p2, p3, p4])
	
	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	
	var transform = Transform3D()
	# Rotate to face direction
	if direction.length_squared() > 0.001:
		var normalized_dir = direction.normalized()
		var up = Vector3.UP
		if abs(normalized_dir.y) > 0.99:
			up = Vector3.RIGHT
		transform.basis = Basis.looking_at(normalized_dir, up)
	transform.origin = origin
	query.transform = transform
	query.collision_mask = 2
	
	var raw_results = space_state.intersect_shape(query, 100)
	return _filter_by_loe(space_state, origin, raw_results, ignores_cover)

static func get_line_targets(space_state: PhysicsDirectSpaceState3D, origin: Vector3, direction: Vector3, length_feet: float, ignores_cover: bool = false) -> Array[PFActor]:
	if not space_state: return []
	var length_meters = length_feet / 5.0
	
	var shape = BoxShape3D.new()
	# 5-foot wide, 5-foot tall, length long (1x1xL meters)
	shape.size = Vector3(1.0, 1.0, length_meters)
	
	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	
	var transform = Transform3D()
	if direction.length_squared() > 0.001:
		var normalized_dir = direction.normalized()
		var up = Vector3.UP
		if abs(normalized_dir.y) > 0.99:
			up = Vector3.RIGHT
		transform.basis = Basis.looking_at(normalized_dir, up)
	
	# The BoxShape's origin is its center, so we move it forward by half its length along the -Z axis
	transform.origin = origin + (transform.basis.z * (-length_meters / 2.0))
	query.transform = transform
	query.collision_mask = 2
	
	var raw_results = space_state.intersect_shape(query, 100)
	return _filter_by_loe(space_state, origin, raw_results, ignores_cover)

