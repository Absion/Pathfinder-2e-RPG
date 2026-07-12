
# pf_combat_grid.gd
## Renders the tactical battlefield and calculates PF2E diagonal distance math.
class_name PFCombatGrid
extends Node3D

enum HighlightColor {
	MOVEMENT_BLUE,
	ATTACK_RED,
	HEAL_GREEN,
	ALLY_YELLOW
}

var multimesh_instance: MultiMeshInstance3D
var base_grid_instance: MultiMeshInstance3D
var cursor_mesh: MeshInstance3D

var _highlighted_tiles: Array[Vector3] = []
var _materials: Dictionary = {}

func _ready():
	_setup_materials()
	_setup_cursor()
	_setup_multimesh()

func _setup_materials():
	# Movement Blue
	var blue = StandardMaterial3D.new()
	blue.albedo_color = Color(0.1, 0.4, 1.0, 0.6)
	blue.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	blue.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_materials[HighlightColor.MOVEMENT_BLUE] = blue
	
	# Attack Red
	var red = StandardMaterial3D.new()
	red.albedo_color = Color(0.9, 0.1, 0.1, 0.6)
	red.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	red.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_materials[HighlightColor.ATTACK_RED] = red
	
	# Heal Green
	var green = StandardMaterial3D.new()
	green.albedo_color = Color(0.1, 0.8, 0.2, 0.6)
	green.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	green.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_materials[HighlightColor.HEAL_GREEN] = green
	
	# Ally Yellow
	var yellow = StandardMaterial3D.new()
	yellow.albedo_color = Color(0.9, 0.8, 0.1, 0.6)
	yellow.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	yellow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_materials[HighlightColor.ALLY_YELLOW] = yellow

func _setup_cursor():
	cursor_mesh = MeshInstance3D.new()
	var quad = QuadMesh.new()
	quad.size = Vector2(1, 1)
	quad.orientation = PlaneMesh.FACE_Y
	cursor_mesh.mesh = quad
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 1.0, 1.0, 0.8) # Bright white/yellowish glow
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cursor_mesh.material_override = mat
	cursor_mesh.position.y = 0.02 # Keep slightly above the multimesh grid
	add_child(cursor_mesh)

func _setup_multimesh():
	# 1. Setup Highlight Grid (Movement, Attack, etc)
	multimesh_instance = MultiMeshInstance3D.new()
	var multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.instance_count = 0
	
	var quad = QuadMesh.new()
	quad.size = Vector2(0.9, 0.9) # 0.9 creates a very clean natural 0.1 gap between tiles!
	quad.orientation = PlaneMesh.FACE_Y
	multimesh.mesh = quad
	
	multimesh_instance.multimesh = multimesh
	
	var mat = StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	multimesh_instance.material_override = mat
	multimesh_instance.position.y = 0.01 # Slightly above ground to prevent Z-fighting
	add_child(multimesh_instance)
	
	# 2. Setup Base Background Grid
	base_grid_instance = MultiMeshInstance3D.new()
	var base_multimesh = MultiMesh.new()
	base_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	base_multimesh.use_colors = true
	base_multimesh.instance_count = 0
	
	var base_quad = QuadMesh.new()
	base_quad.size = Vector2(0.95, 0.95) # 0.05 gap for thin base grid lines
	base_quad.orientation = PlaneMesh.FACE_Y
	base_multimesh.mesh = base_quad
	
	base_grid_instance.multimesh = base_multimesh
	
	var base_mat = StandardMaterial3D.new()
	base_mat.vertex_color_use_as_albedo = true
	base_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	base_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	base_grid_instance.material_override = base_mat
	base_grid_instance.position.y = 0.005 # Just below highlight grid
	
	add_child(base_grid_instance)

func highlight_tiles(tiles: Array[Vector3], color_type: HighlightColor):
	_highlighted_tiles = tiles
	var multimesh = multimesh_instance.multimesh
	multimesh.instance_count = tiles.size()
	
	var base_color = _materials[color_type].albedo_color
	
	for i in range(tiles.size()):
		var t = Transform3D()
		# Snap absolutely to grid integers
		t.origin = Vector3(round(tiles[i].x), 0, round(tiles[i].z))
		multimesh.set_instance_transform(i, t)
		multimesh.set_instance_color(i, base_color)

func clear_highlights():
	_highlighted_tiles.clear()
	multimesh_instance.multimesh.instance_count = 0

@warning_ignore("integer_division")
func draw_base_grid(width: int = 50, height: int = 50):
	var multimesh = base_grid_instance.multimesh
	multimesh.instance_count = width * height
	
	var faint_color = Color(1.0, 1.0, 1.0, 0.08) # Very faint white
	var i = 0
	
	var half_w = int(width / 2.0)
	var half_h = int(height / 2.0)
	
	for x in range(-half_w, width - half_w):
		for z in range(-half_h, height - half_h):
			var grid_transform = Transform3D()
			grid_transform.origin = Vector3(x, 0, z)
			multimesh.set_instance_transform(i, grid_transform)
			multimesh.set_instance_color(i, faint_color)
			i += 1

func clear_base_grid():
	base_grid_instance.multimesh.instance_count = 0

func update_cursor(pos: Vector3):
	# Snap the cursor to the nearest grid intersection
	cursor_mesh.position = Vector3(round(pos.x), 0.02, round(pos.z))

## Pathfinder 2e Distance Rules (1 unit = 1 square = 5 feet)
## Diagonals: 1st diagonal is 5ft, 2nd is 10ft, 3rd is 5ft, 4th is 10ft...
static func get_distance_pf2e(pos1: Vector3, pos2: Vector3) -> int:
	var delta_x = abs(round(pos1.x) - round(pos2.x))
	var delta_z = abs(round(pos1.z) - round(pos2.z))
	
	var min_d = min(delta_x, delta_z)
	var max_d = max(delta_x, delta_z)
	
	var diagonal_steps = min_d
	var straight_steps = max_d - min_d
	
	# Every 2nd diagonal step costs 2 units instead of 1
	var total_units = straight_steps + diagonal_steps + floor(diagonal_steps / 2.0)
	
	return int(total_units * 5)

## Checks if a grid position is occupied, accounting for PF2E overlap rules.
func is_space_occupied(target_pos: Vector3, mover: PFActor = null, end_of_move: bool = true) -> bool:
	if PFContext.active_turn_manager == null:
		return false
		
	# ⚡ Bolt: Cache mover calculations outside the loop, avoid array allocation
	var mover_is_swarm_or_tiny = false
	var mover_record = null
	var is_mover_troop = false
	var r_base_t_x = round(target_pos.x)
	var r_base_t_z = round(target_pos.z)
	var mover_y = 0.0

	if mover != null:
		is_mover_troop = mover is PFTroop
		mover_is_swarm_or_tiny = mover.has_trait(&"swarm") or mover.size_id == &"tiny"
		mover_record = PFContext.active_turn_manager.get_combatant_record(mover)
		mover_y = mover.global_position.y

	for record in PFContext.active_turn_manager.combatants:
		var actor = record.actor
		if actor == mover:
			continue
			
		var overlap = false
		if actor is PFTroop:
			for seg in actor.active_segments:
				var a_x = round(actor.global_position.x + seg.x)
				var a_z = round(actor.global_position.z + seg.z)
				if is_mover_troop:
					for mover_seg in mover.active_segments:
						var t_x = r_base_t_x + round(mover_seg.x)
						var t_z = r_base_t_z + round(mover_seg.z)
						if t_x == a_x and t_z == a_z:
							overlap = true
							break
					if overlap: break
				else:
					if r_base_t_x == a_x and r_base_t_z == a_z:
						overlap = true
						break
		else:
			var a_x = round(actor.global_position.x)
			var a_z = round(actor.global_position.z)
			if is_mover_troop:
				for mover_seg in mover.active_segments:
					var t_x = r_base_t_x + round(mover_seg.x)
					var t_z = r_base_t_z + round(mover_seg.z)
					if t_x == a_x and t_z == a_z:
						overlap = true
						break
			else:
				if r_base_t_x == a_x and r_base_t_z == a_z:
					overlap = true
			
		# If we aren't overlapping the XZ coordinate, it's free.
		if not overlap:
			continue
			
		# RULE 1: Swarms and Tiny creatures can share spaces.
		var target_is_swarm_or_tiny = actor.has_trait(&"swarm") or actor.size_id == &"tiny"
		if mover_is_swarm_or_tiny or target_is_swarm_or_tiny:
			continue
			
		# RULE 2: Flying or burrowing creates vertical separation. (Assuming Y threshold of 1.0 unit = 5ft)
		if mover != null and abs(mover_y - actor.global_position.y) >= 1.0:
			continue
			
		# RULE 3: You can move through an ally's space, but you cannot end your turn there.
		if not end_of_move and mover != null:
			if mover_record and mover_record.is_enemy == record.is_enemy:
				# It is an ally, we can pass through
				continue
				
		return true
		
	return false

