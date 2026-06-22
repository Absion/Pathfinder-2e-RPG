# pf_action_interact_attach.gd
class_name PFActionInteractAttach
extends PFAction

var attachment: PFAttachment
var target_item: PFItem

func _init(p_attachment: PFAttachment, p_target_item: PFItem) -> void:
	attachment = p_attachment
	target_item = p_target_item
	super._init("Interact (Attach %s to %s)" % [p_attachment.entity_name, p_target_item.entity_name], [&"manipulate"], PFCombatConstants.ActionCost.ONE_ACTION, 1)

func execute(user: PFActor, _target: PFActor = null) -> bool:
	if not attachment or not target_item:
		return false
		
	var inv = user.get(&"inventory")
	if inv:
		if not inv.items.has(attachment):
			print("    > [ERROR] %s does not have %s in their inventory!" % [user.entity_name, attachment.entity_name])
			return false
			
		if not inv.items.has(target_item) and not inv.worn_items.has(target_item):
			print("    > [ERROR] %s does not have %s!" % [user.entity_name, target_item.entity_name])
			return false
			
	if attachment.attach_to(target_item):
		if inv:
			inv.items.erase(attachment) # Remove from normal inventory pool since it's attached
		return true
		
	return false
