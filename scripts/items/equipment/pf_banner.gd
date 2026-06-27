# pf_banner.gd
## A banner that emits an aura when held in a hand.
class_name PFBanner
extends PFItem

var aura_condition_id: StringName = &""
var aura_radius: int = 30
var aura_manager = null # Typed dynamically as PFAuraManager
var active_aura_instance = null # Typed dynamically as PFAuraManager.AuraInstance

func _init(p_name: String = "Banner", p_traits: Array[StringName] = [&"magical"], p_level: int = 1, p_price_gp: float = 0.0, p_condition_id: StringName = &"", p_radius: int = 30):
	super._init(p_name, p_traits, p_level, p_price_gp, PFEquipmentConstants.ItemMaterial.STANDARD, 0, 0, 0, PFEquipmentConstants.MaterialGrade.STANDARD, 1)
	aura_condition_id = p_condition_id
	aura_radius = p_radius

func on_equipped(actor: PFActor) -> void:
	# Check if the item is held (equipped could mean worn, but banners must be held)
	# If it's held, activate the aura. (simplified check here, real implementation would check inventory held status)
	_activate_aura(actor)

func on_unequipped(_actor: PFActor) -> void:
	_deactivate_aura()

func _activate_aura(actor: PFActor) -> void:
	if aura_condition_id == &"":
		return
		
	# In a real game scene, aura_manager would be retrieved from the World or CombatManager
	# Here we assume it's injected or global. We will safely create one for testing if null.
	if aura_manager == null:
		# Normally, we'd do: aura_manager = get_tree().get_first_node_in_group("aura_manager")
		pass
		
	if aura_manager:
		active_aura_instance = aura_manager.register_aura(actor, aura_condition_id, aura_radius, "allies")

func _deactivate_aura() -> void:
	if aura_manager and active_aura_instance:
		aura_manager.unregister_aura(active_aura_instance)
		active_aura_instance = null
