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
		
	# Both must have the target within melee reach.
	var dist_attacker = PFCombatGrid.get_distance_pf2e(attacker.position, target.position)
	var dist_ally = PFCombatGrid.get_distance_pf2e(ally.position, target.position)
	
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
	
	var a1 = Vector2(attacker.position.x, attacker.position.z)
	var a2 = Vector2(ally.position.x, ally.position.z)
	var t = Vector2(target.position.x, target.position.z)
	
	# Simple PF2e logic for 1x1: A line between centers passes through opposite sides/corners.
	# This means the target must be exactly between them in either the X or Z axis, or both.
	# If Target is at (0,0), A1 at (-1,0), A2 must be at (1,0) (or 1,-1 or 1,1).
	var dir1 = (a1 - t)
	var dir2 = (a2 - t)
	
	# If they are on the exact same side, no flank.
	if sign(dir1.x) == sign(dir2.x) and sign(dir1.x) != 0:
		return false
	if sign(dir1.y) == sign(dir2.y) and sign(dir1.y) != 0:
		return false
		
	# To ensure the line actually passes THROUGH the target, we check the line segment distance to target center.
	# But since we snapped them to grid, if they are on opposite sides, the segment will pass through the 1x1 box.
	# In PF2e, you can flank if you are opposite on ANY axis (X or Z) as long as you draw a line through opposite edges.
	
	# For true line intersection with the 1x1 box at `t`:
	# The box is [t.x - 0.5, t.x + 0.5] x [t.y - 0.5, t.y + 0.5]
	if _line_intersects_opposite_sides_of_rect(a1, a2, t, 1.0):
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
	var dx = p2.x - p1.x
	var dy = p2.y - p1.y
	
	var hits_left = false
	var hits_right = false
	var hits_top = false
	var hits_bottom = false
	
	if dx != 0:
		var t_left = (min_x - p1.x) / dx
		var y_left = p1.y + t_left * dy
		if y_left >= min_y and y_left <= max_y and t_left >= 0 and t_left <= 1: hits_left = true
		
		var t_right = (max_x - p1.x) / dx
		var y_right = p1.y + t_right * dy
		if y_right >= min_y and y_right <= max_y and t_right >= 0 and t_right <= 1: hits_right = true

	if dy != 0:
		var t_top = (min_y - p1.y) / dy
		var x_top = p1.x + t_top * dx
		if x_top >= min_x and x_top <= max_x and t_top >= 0 and t_top <= 1: hits_top = true
		
		var t_bottom = (max_y - p1.y) / dy
		var x_bottom = p1.x + t_bottom * dx
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
	
	var query = PhysicsRayQueryParameters3D.create(start_pos, end_pos, mask, [attacker.get_rid(), target.get_rid()])
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
