# pf_alchemical_elixir.gd
## Represents an alchemical elixir or mutagen.
class_name PFAlchemicalElixir
extends PFConsumable

var is_mutagen: bool = false
var mutagen_benefit_modifier: PFModifier
var mutagen_drawback_modifier: PFModifier

func _init(p_id: String, p_name: String, p_level: int, p_is_mutagen: bool = false):
	super._init(p_id)
	
	if entity_name == "" or entity_name == "Unknown Consumable":
		# Was not found in the generic database yet, manually populate
		entity_name = p_name
		level = p_level
		consumable_type = "elixir"
		
	is_mutagen = p_is_mutagen
	
	if not traits.has(&"alchemical"):
		traits.append(&"alchemical")
	if not traits.has(&"consumable"):
		traits.append(&"consumable")
	if not traits.has(&"elixir"):
		traits.append(&"elixir")
	
	if is_mutagen and not traits.has(&"mutagen"):
		traits.append(&"mutagen")
		traits.append(&"polymorph")

## Overrides PFConsumable.on_consume
func on_consume(consumer: PFActor) -> bool:
	if charges <= 0:
		print("    > [ERROR] %s is empty!" % entity_name)
		return false
		
	if is_mutagen:
		print("    > %s drinks the %s! Their physical form aggressively mutates." % [consumer.entity_name, entity_name])
		_apply_mutagen(consumer)
	else:
		print("    > %s drinks the %s." % [consumer.entity_name, entity_name])
		# Normal elixir effects (e.g. healing) would be applied here based on properties
		
	charges -= 1
	return true

func _apply_mutagen(consumer: PFActor) -> void:
	if not "attributes" in consumer or not consumer.attributes:
		return
		
	# First, remove any existing mutagen modifiers (you can only benefit from one at a time)
	# This requires iterating through modifiers and checking if source has "mutagen"
	_remove_existing_mutagens(consumer)
	
	# Apply this mutagen's modifiers
	if mutagen_benefit_modifier:
		_apply_modifier_to_stat(consumer, mutagen_benefit_modifier)
	if mutagen_drawback_modifier:
		_apply_modifier_to_stat(consumer, mutagen_drawback_modifier)

func _remove_existing_mutagens(consumer: PFActor) -> void:
	var stats = [consumer.attributes.ac_modifiers, consumer.attributes.attack_modifiers, consumer.attributes.dc_modifiers, consumer.attributes.fort_save, consumer.attributes.ref_save, consumer.attributes.will_save]
	for stat in stats:
		for mod in stat.modifiers.duplicate():
			if mod.source.to_lower().contains("mutagen"):
				stat.remove_modifier_by_source(mod.source)

func _apply_modifier_to_stat(consumer: PFActor, modifier: PFModifier) -> void:
	# A real implementation would map a 'target_stat' string to the actual stat object.
	# For demonstration/testing, we assume the modifier has a target_stat property we added.
	var stat_name = modifier.get_meta(&"target_stat", "")
	match stat_name:
		"ac":
			consumer.attributes.ac_modifiers.add_modifier(modifier)
		"attack":
			consumer.attributes.attack_modifiers.add_modifier(modifier)
		"dc":
			consumer.attributes.dc_modifiers.add_modifier(modifier)
		"fortitude":
			consumer.attributes.fort_save.add_modifier(modifier)
		"reflex":
			consumer.attributes.ref_save.add_modifier(modifier)
		"will":
			consumer.attributes.will_save.add_modifier(modifier)
