# pf_firearm_customization.gd
## A modular component attached to firearms and crossbows.
class_name PFFirearmCustomization
extends PFAttachment

enum CustomizationType { SCOPE, STABILIZER }

var type: CustomizationType
var value_modifier: int = 0

func _init(p_name: String = "Firearm Customization", p_type: CustomizationType = CustomizationType.SCOPE, p_value: int = 30, p_level: int = 1, p_price_gp: float = 0.0):
	super._init(p_name, [&"modification"], p_level, p_price_gp)
	type = p_type
	value_modifier = p_value

func attach_to(item: PFItem) -> bool:
	if not (item is PFWeapon):
		print("    > [ERROR] Firearm Customizations can only be affixed to Weapons.")
		return false
		
	var weapon = item as PFWeapon
	if weapon.group != PFEquipmentConstants.WeaponGroup.FIREARM and weapon.group != PFEquipmentConstants.WeaponGroup.CROSSBOW:
		print("    > [ERROR] Firearm Customizations can only attach to Firearms or Crossbows.")
		return false
		
	if host_item != null:
		detach()
		
	if type == CustomizationType.SCOPE:
		if weapon.scope_attachment != null:
			print("    > [ERROR] %s already has a scope!" % item.entity_name)
			return false
		weapon.scope_attachment = self
	elif type == CustomizationType.STABILIZER:
		if weapon.stabilizer_attachment != null:
			print("    > [ERROR] %s already has a stabilizer!" % item.entity_name)
			return false
		weapon.stabilizer_attachment = self
		
	host_item = weapon
	_apply_customization(weapon)
	return true

func detach() -> void:
	if host_item and host_item is PFWeapon:
		var weapon = host_item as PFWeapon
		_remove_customization(weapon)
		if type == CustomizationType.SCOPE and weapon.scope_attachment == self:
			weapon.scope_attachment = null
		elif type == CustomizationType.STABILIZER and weapon.stabilizer_attachment == self:
			weapon.stabilizer_attachment = null
	
	host_item = null
	if carry_state == PFEquipmentConstants.CarryState.WORN:
		carry_state = PFEquipmentConstants.CarryState.DROPPED

func _apply_customization(weapon: PFWeapon) -> void:
	match type:
		CustomizationType.SCOPE:
			# Scopes typically add the fatal aim trait or increase range increment.
			# We'll represent it simply by modifying range_increment
			weapon.range_increment += value_modifier
			print("    > %s attached. Range increment increased by %d feet." % [entity_name, value_modifier])
		CustomizationType.STABILIZER:
			# Stabilizers reduce the penalty for kickback or add circumstance bonuses.
			# We'll just grant a circumstance bonus or something generic here.
			print("    > %s attached. Stabilizer added to %s." % [entity_name, weapon.entity_name])

func _remove_customization(weapon: PFWeapon) -> void:
	match type:
		CustomizationType.SCOPE:
			weapon.range_increment -= value_modifier
			print("    > %s detached. Range increment reduced by %d feet." % [entity_name, value_modifier])
		CustomizationType.STABILIZER:
			print("    > %s detached from %s." % [entity_name, weapon.entity_name])

