# pf_inventory.gd
## Component that safely manages an actor's equipped items and total bulk.
class_name PFInventory
extends RefCounted

var owner: PFActor

# --- INVENTORY STORAGE ---
var items: Array[PFItem] = []
var containers: Array[PFItem] = [] 

# --- EQUIPPED & WORN ---
var worn_items: Array[PFItem] = []
var invested_items: Array[PFItem] = []
var max_invested_items: int = 10

# --- HAND USAGE ---
var held_main_hand: PFItem = null
var held_off_hand: PFItem = null
var two_handed_item: PFItem = null

# --- CURRENCY ---
var platinum: int = 0
var gold: int = 0
var silver: int = 0
var copper: int = 0

func _init(p_owner: PFActor):
	owner = p_owner

func is_lootable() -> bool:
	if owner == null:
		return true
	
	if owner.has_condition("unconscious") or owner.has_condition("dead"):
		return true
		
	return false

# ---------------------------------------------------------
# ITEM MANAGEMENT
# ---------------------------------------------------------

func add_item(item: PFItem) -> void:
	items.append(item)
	print("    > %s added %s to their inventory." % [owner.entity_name, item.entity_name])

func equip_item(item: PFItem) -> void:
	# If the item requires investment, verify it is invested first
	if item.requires_investment and not invested_items.has(item):
		print("    > [!] %s requires investment before it can be used!" % item.entity_name)
		return
		
	# Size enforcement for Armor
	if item is PFArmor:
		var db_inst = PFDatabase.get_instance()
		var owner_size_data = db_inst.get_size_data(owner.size_id) if (db_inst and "size_id" in owner) else {}
		var a_size = (owner_size_data.get("effective_size", 1) as int) if not owner_size_data.is_empty() else 1
		
		var item_size_data = db_inst.get_size_data(item.size_id) if db_inst else {}
		var i_size = (item_size_data.get("effective_size", 1) as int) if not item_size_data.is_empty() else 1
		
		if a_size != i_size:
			print("    > [ERROR] %s cannot wear %s. Armor must be the exact size!" % [owner.entity_name, item.entity_name])
			return
	
	worn_items.append(item)

# pf_inventory.gd

func hold_item(item: PFItem, main_hand: bool = true) -> void:
	# 1. Clear any two-handed item if we are about to hold something in one hand
	if two_handed_item != null:
		two_handed_item = null
		
	# 2. Check if the hand is free
	if main_hand:
		if held_main_hand != null:
			print("    > %s drops %s to hold %s." % [owner.entity_name, held_main_hand.entity_name, item.entity_name])
		held_main_hand = item
	else:
		if held_off_hand != null:
			print("    > %s drops %s to hold %s." % [owner.entity_name, held_off_hand.entity_name, item.entity_name])
		held_off_hand = item
		
	print("    > %s is now holding %s." % [owner.entity_name, item.entity_name])

func release_item(main_hand: bool = true) -> void:
	if main_hand:
		held_main_hand = null
	else:
		held_off_hand = null

func equip_weapon(weapon: PFItem, hands: int = 1, main_hand: bool = true) -> void:
	if weapon.requires_investment and not invested_items.has(weapon):
		print("    > [!] %s requires investment before it can be used!" % weapon.entity_name)
		return

	if hands == 2:
		two_handed_item = weapon
		held_main_hand = null
		held_off_hand = null
	elif main_hand:
		held_main_hand = weapon
		two_handed_item = null
	else:
		held_off_hand = weapon
		two_handed_item = null

func wield_as_improvised(item: PFItem, main_hand: bool = true, damage_type: PFCombatConstants.DamageType = PFCombatConstants.DamageType.BLUDGEONING) -> void:
	var improvised_weapon = PFWeapon.create_improvised(item, damage_type)
	if not items.has(item):
		add_item(item)
	hold_item(improvised_weapon, main_hand)

# Add this method to allow feats/effects to modify the limit
func set_max_invested_items(new_limit: int) -> void:
	max_invested_items = new_limit
	print("    > %s's investment capacity changed to %d." % [owner.entity_name, max_invested_items])

func invest_item(item: PFItem) -> void:
	if owner is PFNpc:
		invested_items.append(item)
		return
		
	# Now uses the dynamic variable instead of the constant
	if invested_items.size() >= max_invested_items:
		print("    > [ERROR] %s cannot invest more than %d items!" % [owner.entity_name, max_invested_items])
		return
		
	if not invested_items.has(item):
		invested_items.append(item)
		print("    > %s invested %s." % [owner.entity_name, item.entity_name])

func wield_item(item: PFItem, main_hand: bool = true) -> void:
	# Enforce investment
	if item.requires_investment and not invested_items.has(item):
		print("[!] %s requires investment!" % item.entity_name)
		return
		
	# Size enforcement for Weapons
	if item is PFWeapon:
		var db_inst = PFDatabase.get_instance()
		var owner_size_data = db_inst.get_size_data(owner.size_id) if (db_inst and "size_id" in owner) else {}
		var a_size = (owner_size_data.get("effective_size", 1) as int) if not owner_size_data.is_empty() else 1
		
		var item_size_data = db_inst.get_size_data(item.size_id) if db_inst else {}
		var i_size = (item_size_data.get("effective_size", 1) as int) if not item_size_data.is_empty() else 1
		var diff = i_size - a_size
		
		if abs(diff) > 1:
			print("    > [ERROR] %s cannot effectively wield %s due to the massive size difference!" % [owner.entity_name, item.entity_name])
			return
		
		if diff == 1:
			print("    > [WARNING] %s wields %s but it is oversized! Applying Clumsy 1." % [owner.entity_name, item.entity_name])
			var clumsy = PFCondition.new(&"clumsy")
			# We'll tag it with the item instance to remove it later, or the actor system will recalculate it.
			owner.apply_condition(clumsy)
			
	# Mark as wielded
	item.is_wielded = true
	hold_item(item, main_hand)

func can_raise_shield(shield: PFShield) -> bool:
	# 1. Is the shield wielded?
	if not shield.is_wielded: return false
	
	# 2. If it's not a buckler, standard shields just need to be wielded
	if not shield.has_trait(&"buckler"): return true
	
	# 3. BUCKLER LOGIC:
	# You can hold a light, non-weapon object. 
	# Let's check both hands.
	
	return _is_hand_free_for_buckler(held_main_hand) and _is_hand_free_for_buckler(held_off_hand)

func _is_hand_free_for_buckler(item: PFItem) -> bool:
	# An empty hand is always fine
	if item == null: return true
	
	# If the item is a weapon, you cannot raise the buckler
	if item is PFWeapon: return false
	
	# If the item is "heavy" (let's say Bulk 1 or more), you cannot raise it
	# (Assuming your items have a bulk_value property)
	if item.bulk_value >= 10: return false
	
	# Otherwise, it's a light, non-weapon object
	return true

# ---------------------------------------------------------
# IMPROVISED WEAPONS
# ---------------------------------------------------------
func create_improvised_weapon(item_name: String, traits: Array[StringName], dice_amount: int, die_faces: int, damage_type: PFCombatConstants.DamageType, range_increment: int = 0, hands: int = 1) -> PFWeapon:
	var imp_weapon = PFWeapon.new(item_name, traits, 1, 0.0)
	
	imp_weapon.weapon_type = PFEquipmentConstants.WeaponType.MELEE if range_increment == 0 else PFEquipmentConstants.WeaponType.RANGED
	imp_weapon.category = PFEquipmentConstants.WeaponCategory.SIMPLE
	imp_weapon.group = PFEquipmentConstants.WeaponGroup.NONE
	imp_weapon.dice_amount = dice_amount
	imp_weapon.die_faces = die_faces
	imp_weapon.base_damage_type = damage_type
	imp_weapon.active_damage_type = damage_type
	imp_weapon.item_material = PFEquipmentConstants.ItemMaterial.WOOD
	imp_weapon.hardness = 5
	imp_weapon.max_hp = 20
	imp_weapon.current_hp = 20
	imp_weapon.deadly_die = 0
	imp_weapon.fatal_die = 0
	imp_weapon.grade = PFEquipmentConstants.MaterialGrade.STANDARD
	imp_weapon.hands_required = hands
	imp_weapon.is_improvised = true
	imp_weapon.range_increment = range_increment
	
	if not imp_weapon.traits.has(&"improvised"):
		imp_weapon.traits.append(&"improvised")
		
	if range_increment > 0 and not imp_weapon.traits.has(&"thrown"):
		imp_weapon.traits.append(&"thrown")
	
	add_item(imp_weapon)
	wield_item(imp_weapon, true)
	print("    > %s quickly created and wielded an improvised weapon: %s!" % [owner.entity_name, item_name])
	return imp_weapon

# ---------------------------------------------------------
# CURRENCY & ECONOMY
# ---------------------------------------------------------

func add_currency(p_gold: int, p_silver: int = 0, p_copper: int = 0, p_platinum: int = 0) -> void:
	gold += p_gold
	silver += p_silver
	copper += p_copper
	platinum += p_platinum
	
	if p_gold > 0 or p_silver > 0 or p_copper > 0 or p_platinum > 0:
		print("    > %s's wealth updated! (+%d gp, +%d sp, +%d cp, +%d pp)" % [owner.entity_name, p_gold, p_silver, p_copper, p_platinum])

func get_total_coin_value_in_copper() -> int:
	return (platinum * 1000) + (gold * 100) + (silver * 10) + copper

func get_total_wealth_in_copper() -> int:
	var total_cp = get_total_coin_value_in_copper()
	
	for item in items: total_cp += item.price_cp
	for item in worn_items: total_cp += item.price_cp
	for item in containers: total_cp += item.price_cp
	
	if held_main_hand: total_cp += held_main_hand.price_cp
	if held_off_hand: total_cp += held_off_hand.price_cp
	if two_handed_item: total_cp += two_handed_item.price_cp
	
	return total_cp

static func format_copper_to_string(total_cp: int) -> String:
	if total_cp == 0: return "0 cp"
		
	var pp = int(total_cp / 1000.0)
	var remainder = total_cp % 1000
	var gp = int(remainder / 100.0)
	remainder = remainder % 100
	var sp = int(remainder / 10.0)
	var cp = remainder % 10
	
	var parts: Array[String] = []
	if pp > 0: parts.append("%d pp" % pp)
	if gp > 0: parts.append("%d gp" % gp)
	if sp > 0: parts.append("%d sp" % sp)
	if cp > 0: parts.append("%d cp" % cp)
	
	return ", ".join(parts)

# ---------------------------------------------------------
# BULK CALCULATIONS
# ---------------------------------------------------------

func get_perceived_bulk(item: PFItem) -> int:
	var db_inst = PFDatabase.get_instance()
	var owner_size_data = db_inst.get_size_data(owner.size_id) if (db_inst and "size_id" in owner) else {}
	var a_size = (owner_size_data.get("effective_size", 1) as int) if not owner_size_data.is_empty() else 1
	
	var item_size_data = db_inst.get_size_data(item.size_id) if db_inst else {}
	var i_size = (item_size_data.get("effective_size", 1) as int) if not item_size_data.is_empty() else 1
	
	if a_size == i_size:
		return item.bulk_value
		
	var diff = a_size - i_size
	
	if diff > 0:
		# Actor is larger than item
		if diff == 1:
			return int(item.bulk_value / 10.0)
		else:
			return 0 # Negligible
	else:
		# Actor is smaller than item
		var multiplier = pow(2, -diff)
		return int(item.bulk_value * multiplier)

func get_total_bulk() -> int:
	# NPCs and Monsters don't track encumbrance normally
	if owner is PFNpc and not owner is PFMinion: return 0
		
	var total_bulk_units: int = 0
	
	for item in items + worn_items:
		total_bulk_units += get_perceived_bulk(item)
	if held_main_hand: total_bulk_units += get_perceived_bulk(held_main_hand)
	if held_off_hand: total_bulk_units += get_perceived_bulk(held_off_hand)
	if two_handed_item: total_bulk_units += get_perceived_bulk(two_handed_item)
		
	for container in containers:
		total_bulk_units += get_perceived_bulk(container)
		# Subtract the container's bulk reduction
		total_bulk_units += maxi(0, _calculate_container_contents(container) - container.bulk_reduction_value)
		
	return total_bulk_units

func _calculate_container_contents(container: PFItem) -> int:
	if not "stored_items" in container: return 0
	var total = 0
	for item in container.get("stored_items"):
		total += get_perceived_bulk(item)
	return total

func get_encumbered_limit() -> int:
	var str_mod = owner.attributes.str_mod if "attributes" in owner and owner.attributes else 0
	return (5 + str_mod) * 10

func get_maximum_bulk_limit() -> int:
	var str_mod = owner.attributes.str_mod if "attributes" in owner and owner.attributes else 0
	return (10 + str_mod) * 10

func is_encumbered() -> bool:
	return get_total_bulk() >= get_encumbered_limit()

func can_carry(item_bulk: int) -> bool:
	return (get_total_bulk() + item_bulk) <= get_maximum_bulk_limit()

func can_drag(item_bulk: int) -> bool:
	return (get_total_bulk() + item_bulk) <= (get_maximum_bulk_limit() * 2)
