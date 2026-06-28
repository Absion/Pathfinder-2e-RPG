# pf_attachment.gd
## A modular component that can be attached to weapons, armor, or shields.
class_name PFAttachment
extends PFItem

var host_item: PFItem = null
var granted_traits: Array[StringName] = []
var valid_hosts: Array[String] = []

# If this attachment grants its own weapon attack (like a bayonet)
var granted_weapon: PFWeapon = null

func _init(p_name: String = "", p_traits: Array[StringName] = [], p_level: int = 1, p_price_gp: float = 0.0) -> void:
	super._init(p_name, p_traits, p_level, p_price_gp)

## Applies the attachment's effects to the target equipment.
func attach_to(item: PFItem) -> bool:
	if not _is_valid_host(item):
		print("    > [ERROR] Cannot attach %s to %s." % [entity_name, item.entity_name])
		return false
		
	# Detach from current host if any
	if host_item != null:
		detach()
		
	# Ensure the target can accept an attachment
	if "attachment" in item:
		if item.attachment != null:
			print("    > [ERROR] %s already has an attachment!" % item.entity_name)
			return false
			
		item.attachment = self
		host_item = item
		
		# Apply granted traits
		for t in granted_traits:
			if not item.traits.has(t):
				item.traits.append(t)
				
		print("    > Attached %s to %s." % [entity_name, item.entity_name])
		return true
		
	print("    > [ERROR] %s cannot accept attachments." % item.entity_name)
	return false

func detach() -> void:
	if host_item:
		# Remove granted traits from host
		for t in granted_traits:
			host_item.traits.erase(t)
			
		if "attachment" in host_item:
			host_item.attachment = null
			
		print("    > Detached %s from %s." % [entity_name, host_item.entity_name])
		host_item = null

func _is_valid_host(item: PFItem) -> bool:
	if valid_hosts.is_empty():
		return true # Can attach to anything
		
	# Check if item traits match any valid host trait
	for valid in valid_hosts:
		if item.has_trait(StringName(valid)):
			return true
			
	# Also check item type categories roughly if needed
	if valid_hosts.has(&"weapon") and item is PFWeapon:
		return true
	if valid_hosts.has(&"shield") and item is PFShield:
		return true
	if valid_hosts.has(&"armor") and item is PFArmor:
		return true
		
	return false
