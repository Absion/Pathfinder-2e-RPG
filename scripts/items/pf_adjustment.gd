# pf_adjustment.gd
## A modification that alters an item. An item can typically only have one adjustment.
class_name PFAdjustment
extends PFItem
var host_item: PFItem = null

const SHIELD_AUG_PRIMARY_CHOICES: Array[StringName] = [&"backswing", &"forceful"]
const SHIELD_AUG_SECONDARY_CHOICES: Array[StringName] = [&"disarm", &"nonlethal", &"shove", &"thrown_10", &"trip", &"versatile_s"]

var granted_traits: Array[StringName] = []
var valid_hosts: Array[String] = []

static func is_valid_shield_augmentation(traits_chosen: Array[StringName]) -> bool:
	# Rule: Either choose ONE primary trait...
	if traits_chosen.size() == 1:
		return SHIELD_AUG_PRIMARY_CHOICES.has(traits_chosen[0])
		
	# ...or TWO secondary traits
	if traits_chosen.size() == 2:
		for t in traits_chosen:
			if not SHIELD_AUG_SECONDARY_CHOICES.has(t):
				return false
		# Cannot pick the exact same trait twice
		return traits_chosen[0] != traits_chosen[1]
		
	return false

func _init(p_name: String = "", p_traits: Array[StringName] = [], p_level: int = 1, p_price_gp: float = 0.0) -> void:
	super._init(p_name, p_traits, p_level, p_price_gp)

## Applies the adjustment's effects to the target equipment.
func attach_to(item: PFItem) -> bool:
	if not _is_valid_host(item):
		print("    > [ERROR] Cannot apply %s to %s." % [entity_name, item.entity_name])
		return false
		
	# Detach from current host if any
	if host_item != null:
		detach()
		
	# Ensure the target can accept an adjustment
	if "adjustment" in item:
		if item.adjustment != null:
			print("    > [ERROR] %s already has an adjustment!" % item.entity_name)
			return false
			
		item.adjustment = self
		host_item = item
		
		# Apply granted traits
		for t in granted_traits:
			if not item.traits.has(t):
				item.traits.append(t)
				
		print("    > Adjusted %s with %s." % [item.entity_name, entity_name])
		return true
		
	print("    > [ERROR] %s cannot accept adjustments." % item.entity_name)
	return false

func detach() -> void:
	if host_item:
		# Remove granted traits from host
		for t in granted_traits:
			host_item.traits.erase(t)
			
		if "adjustment" in host_item:
			host_item.adjustment = null
			
		print("    > Removed adjustment %s from %s." % [entity_name, host_item.entity_name])
		host_item = null

func _is_valid_host(item: PFItem) -> bool:
	if valid_hosts.is_empty():
		return true # Can attach to anything
		
	# Check if item traits match any valid host trait
	for valid in valid_hosts:
		if item.has_trait(StringName(valid)):
			return true
			
	# Also check item type categories roughly
	if valid_hosts.has("weapon") and item is PFWeapon:
		return true
	if valid_hosts.has("shield") and item is PFShield:
		return true
	if valid_hosts.has("armor") and item is PFArmor:
		return true
		
	return false
