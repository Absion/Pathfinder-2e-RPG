# pf_action_form_up.gd
class_name PFActionFormUp
extends PFAction

var new_anchor: Vector3
var new_layout: Array[Vector3]

func _init(p_new_anchor: Vector3, p_new_layout: Array[Vector3]):
	super._init("Form Up", [&"move"], PFCombatConstants.ActionCost.ONE_ACTION)
	new_anchor = p_new_anchor
	new_layout = p_new_layout

func is_usable(user: PFActor) -> bool:
	if not user is PFTroop:
		print("    > Only Troops can Form Up.")
		return false
	
	var troop = user as PFTroop
	if new_layout.size() != troop.active_segments.size():
		print("    > Invalid layout: size mismatch.")
		return false
		
	# Contiguity check
	if not _is_contiguous(new_layout):
		print("    > Invalid layout: Segments must be contiguous.")
		return false
		
	# Distance check
	# We simply check if the new anchor is within the troop's speed
	# For full PF2e rules we'd check pathfinding for the lead segment, 
	# but for engine logic this suffices.
	var dist = PFCombatGrid.get_distance_pf2e(user.global_position, new_anchor)
	if dist > troop.movement.speed_land:
		print("    > Target anchor is beyond Troop's speed (%d > %d)." % [dist, troop.movement.speed_land])
		return false
		
	return true

func execute(user: PFActor, _target: PFActor = null) -> Variant:
	var troop = user as PFTroop
	print("%s uses Form Up! Moving to %s and reshaping." % [troop.entity_name, str(new_anchor)])
	
	troop.global_position = new_anchor
	troop.active_segments = new_layout.duplicate()
	
	return true

## Checks if an array of segment offsets forms a single contiguous group.
func _is_contiguous(layout: Array[Vector3]) -> bool:
	if layout.size() <= 1:
		return true
		
	# We use a simple flood fill to see if we can reach all segments from the first one.
	var visited = [0]
	var queue = [0]
	
	while queue.size() > 0:
		var current_idx = queue.pop_front()
		var current_pos = layout[current_idx]
		
		for i in range(layout.size()):
			if visited.has(i): continue
			var other_pos = layout[i]
			
			# Contiguous means sharing at least 5ft of an edge.
			# Since each segment is 2x2 (10x10ft), if their centers are 2 units apart 
			# on one axis and 0 units on the other, they share an edge.
			# Or if they are 1 unit apart (overlapping?), but they shouldn't overlap.
			var dx = abs(current_pos.x - other_pos.x)
			var dz = abs(current_pos.z - other_pos.z)
			
			# Check adjacency for 2x2 blocks:
			# Either perfectly aligned on X and separated by 2 on Z, OR
			# separated by 2 on X and perfectly aligned on Z OR
			# overlapping slightly? We assume they align to the 2x2 grid (dx/dz are multiples of 2)
			# But they can be offset by 1 if they share exactly 5ft.
			# Example: (0,0) and (1,2) -> they share a 5ft corner/edge? No, (1,2) would overlap.
			# The rules say "Each one has to share at least 5 feet of one of its edges with another segment"
			# This means dx <= 1 and dz == 2, or dz <= 1 and dx == 2.
			if (dx <= 1 and dz == 2) or (dz <= 1 and dx == 2):
				visited.append(i)
				queue.append(i)
				
	return visited.size() == layout.size()
