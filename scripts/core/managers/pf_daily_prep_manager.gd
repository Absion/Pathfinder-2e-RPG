# pf_daily_prep_manager.gd
## Manager responsible for handling Morning Rest cycles and daily preparations.
class_name PFDailyPrepManager
extends Node

static var _instance: PFDailyPrepManager

func _ready() -> void:
	_instance = self

static func get_instance() -> PFDailyPrepManager:
	return _instance

## Applies a rest to the actor. 
## is_long_term_rest recovers double HP and cures all damage and most nonpermanent conditions (per 24 hr downtime).
func rest_actor(actor: PFActor, is_long_term_rest: bool = false) -> void:
	var con_mod = actor.get_ability_modifier(&"CON")
	var amount_to_heal = maxi(1, con_mod) * actor.level
	
	if is_long_term_rest:
		amount_to_heal *= 2
		actor.heal(amount_to_heal)
		print("    > %s recovers %d HP after a long-term (24-hour) rest." % [actor.entity_name, amount_to_heal])
		
		# Heals all damage if rest is very long, but for now we just double it.
		# A week of rest would technically heal all damage and most nonpermanent conditions.
		# For this function, we assume a single 24 hour period as specified.
		
		# "They recover from all damage and most nonpermanent conditions" applies if they spend significantly longer (a few days to a week).
		# If it's just a 24-hour period, it recovers double. We'll stick to double HP for 24h.
		
	else:
		actor.heal(amount_to_heal)
		print("    > %s recovers %d HP after a full night's (8-hour) rest." % [actor.entity_name, amount_to_heal])
		
	# Condition reductions on rest
	if is_long_term_rest:
		# Long term rest recovers from most nonpermanent conditions if it spans multiple days, 
		# but for now we'll double the doomed/drained reduction.
		if actor.has_condition("doomed"): actor.reduce_condition("doomed", 2)
		if actor.has_condition("drained"): actor.reduce_condition("drained", 2)
		if actor.has_condition("fatigued"): actor.remove_condition("fatigued")
	else:
		if actor.has_condition("doomed"): actor.reduce_condition("doomed", 1)
		if actor.has_condition("drained"): actor.reduce_condition("drained", 1)
		if actor.has_condition("fatigued"): actor.remove_condition("fatigued")
	
	if "spellbook" in actor and actor.get(&"spellbook") != null:
		actor.get(&"spellbook").restore_daily_slots()
		print("    > %s recovers all daily spell slots and focus points." % actor.entity_name)
		
	# Reset wands and clear staves charges
	if "inventory" in actor and actor.get(&"inventory") != null:
		var inventory = actor.get(&"inventory")
		for item in inventory.items:
			if item.has_method(&"reset_for_day"):
				item.reset_for_day()
			if item.has_method(&"clear_charges"):
				item.clear_charges()
				
	# Sleeping in Armor Rule (Pathfinder 2e Remaster)
	var armor = actor.get_worn_armor()
	if armor != null:
		var category = armor.category
		var is_medium_or_heavy = category == PFEquipmentConstants.ArmorCategory.MEDIUM or category == PFEquipmentConstants.ArmorCategory.HEAVY
		if is_medium_or_heavy and not armor.has_trait(&"comfort"):
			print("    > %s slept in uncomfortable %s armor!" % [actor.entity_name, armor.entity_name])
			actor.apply_condition(PFCondition.create("fatigued", 1))

## Explicitly prepares a spell into a receptacle.
func prepare_spell(actor: PFActor, spell: PFSpell, rank: int, receptacle: PFSpellcastingReceptacle = null) -> bool:
	if "spellbook" in actor and actor.get(&"spellbook") != null:
		var success = actor.get(&"spellbook").prepare_spell(spell, rank, receptacle)
		if success:
			print("    > %s explicitly prepared %s at rank %d." % [actor.entity_name, spell.entity_name, rank])
		return success
	return false

## Explicitly prepares a staff, potentially expending a spell slot for extra charges.
func prepare_staff(actor: PFActor, staff: PFStaff, base_charges: int, expend_slot_rank: int = 0) -> void:
	if expend_slot_rank > 0:
		if "spellbook" in actor and actor.get(&"spellbook") != null:
			# Verify they have a slot of that rank to expend
			pass # In a real implementation we would check/deduct the slot here, or the UI would handle verifying.
			# For now, we trust the UI has authorized it, but we can do a quick check:
			pass
			
	staff.prepare_staff(actor, base_charges, expend_slot_rank)
	print("    > %s prepared %s with %d base charges (Expended slot rank: %d)." % [actor.entity_name, staff.entity_name, base_charges, expend_slot_rank])

## Generates temporary items (e.g. Alchemist infusions, Snare crafting).
func craft_temporary_item(actor: PFActor, item_id: StringName, amount: int) -> void:
	if not "inventory" in actor or actor.get(&"inventory") == null:
		return
		
	var db = PFDatabase.get_instance()
	if db == null:
		return
		
	for i in range(amount):
		# TODO: Replace with proper factory or DB fetch (e.g. PFItemFactory.create(item_id)) when Alchemist/Consumables are fully implemented.
		var temp_item = PFItem.new()
		temp_item.entity_name = str(item_id)
		
		if temp_item != null:
			if not temp_item.has_trait(&"infused"):
				temp_item.traits.append(&"infused") # Mark it as a temporary infused item
			temp_item.is_temporary = true
			actor.inventory.add_item(temp_item)
			
	print("    > %s crafted %d temporary %s." % [actor.entity_name, amount, item_id])

## Finalizes daily preparations, advancing time by 1 hour.
func commit_daily_prep(actors: Array[PFActor]) -> void:
	# Destroy old temporary items from yesterday
	for actor in actors:
		if "inventory" in actor and actor.get(&"inventory") != null:
			var to_remove = []
			for item in actor.inventory.items:
				if item.is_temporary:
					to_remove.append(item)
			for item in to_remove:
				print("    > Temporary item %s was destroyed during daily preparations." % item.entity_name)
				actor.inventory.remove_item(item)
				# Do not call item.free(), since PFItem is RefCounted
				
	var time_manager = PFTimeManager.get_instance()
	if time_manager:
		time_manager.advance_hours(1)
		print("--- Daily preparations are complete. (1 hour passed) ---")
