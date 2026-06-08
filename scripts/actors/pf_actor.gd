# pf_actor.gd
# Represents any living, undead, or construct entity in the game: Players, NPCs, and Monsters.
## The core base class for any targetable and interactive entity in the game world.
#
class_name PFActor
extends Node3D

# --- BASE ENTITY DATA ---
var entity_name: String
var level: int = 1
var traits: Array[StringName] = []
var rarity: PFBiographyConstants.Rarity = PFBiographyConstants.Rarity.COMMON

# --- COMPONENTS ---
var health: PFHealthComponent
var action_economy: PFActionComponent

# --- ARCHITECTURE ---
var has_spirit: bool = true
var conditions: Array[PFCondition] = []
var has_raised_shield: bool = false

func _init(p_name: String, p_traits: Array[StringName], p_level: int, p_hp: int):
	
	entity_name = p_name
	level = p_level
	traits = p_traits
	
	# Component Initialization
	health = PFHealthComponent.new()
	health.initialize(p_hp)
	add_child(health)
	
	action_economy = PFActionComponent.new()
	add_child(action_economy)

# ---------------------------------------------------------
# ---------------------------------------------------------
# ACTIVE CONDITIONS ENGINE
# ---------------------------------------------------------

func apply_condition(new_condition: PFCondition) -> void:
	if not new_condition.on_apply(self):
		return

	# We now append all conditions instead of overriding. 
	# get_condition_modifier will calculate the strongest ones.
	conditions.append(new_condition)
	print("%s is now %s %d!" % [entity_name, new_condition.condition_name, new_condition.value])

func get_condition_modifier(context: StringName) -> int:
	var highest_status_bonus = 0
	var highest_circumstance_bonus = 0
	var highest_item_bonus = 0
	
	var highest_status_penalty = 0
	var highest_circumstance_penalty = 0
	var highest_item_penalty = 0
	
	var untyped_sum = 0
	
	for c in conditions:
		if c.is_active:
			var mod = c.get_modifier(context)
			if mod == 0: continue
			
			if c.modifier_type == "status":
				if mod > 0: highest_status_bonus = maxi(highest_status_bonus, mod)
				else: highest_status_penalty = mini(highest_status_penalty, mod)
			elif c.modifier_type == "circumstance":
				if mod > 0: highest_circumstance_bonus = maxi(highest_circumstance_bonus, mod)
				else: highest_circumstance_penalty = mini(highest_circumstance_penalty, mod)
			elif c.modifier_type == "item":
				if mod > 0: highest_item_bonus = maxi(highest_item_bonus, mod)
				else: highest_item_penalty = mini(highest_item_penalty, mod)
			else:
				untyped_sum += mod
				
	return highest_status_bonus + highest_circumstance_bonus + highest_item_bonus + \
		   highest_status_penalty + highest_circumstance_penalty + highest_item_penalty + \
		   untyped_sum

func get_actor_bulk() -> int:
	var base_bulk = 60 # Default Medium (6 Bulk)
	if "size_id" in self:
		var db_inst = PFDatabase.get_instance()
		var size_data = db_inst.get_size_data(self.get("size_id")) if db_inst else null
		if size_data:
			base_bulk = size_data.get("base_bulk", 60)
			
	var inventory_bulk = 0
	if "inventory" in self and self.get("inventory") != null:
		inventory_bulk = self.get("inventory").get_total_bulk()
		
	return base_bulk + inventory_bulk

# ---------------------------------------------------------
# THE UNIFIED MATH DELEGATES (VIRTUAL)
# These methods return 0 or null as placeholders to utilize
# Polymorphism. Subclasses (PFPlayerCharacter, PFNpc) must 
# override these to provide their specific math implementations.
# ---------------------------------------------------------

func get_ac() -> int:
	return 10 + get_condition_modifier(&"ac")

func get_strike_bonus(weapon: PFWeapon) -> int:
	return get_condition_modifier(&"attack")

func get_wielded_shield() -> PFShield:
	# Virtual function for polymorphism
	return null

func get_strike_damage_bonus(weapon: PFWeapon) -> int:
	# Virtual function for polymorphism
	return 0

func get_skill_bonus(skill: StringName) -> int:
	# Virtual function for polymorphism
	return 0

func get_ability_modifier(ability: StringName) -> int:
	# Virtual function for polymorphism
	return 0

func has_trait(trait_name: StringName) -> bool:
	return traits.has(trait_name)

func get_speed_land() -> int:
	# Virtual function for polymorphism
	return 0

# ---------------------------------------------------------
# ACTION ECONOMY & TURN HOOKS
# ---------------------------------------------------------

func start_turn() -> void:
	action_economy.actions_remaining = 3
	action_economy.reactions_remaining = 1
	action_economy.attack_stacks = 0 
	print("\n--- %s starts their turn! (3 Actions) ---" % entity_name)
	
	for c in conditions:
		if c.is_active: c.on_turn_start(self)
	conditions = conditions.filter(func(c): return c.is_active)

func use_action(action: PFAction, target: PFActor = null) -> void:
	var cost_val = action.cost
	
	if action_economy.actions_remaining < cost_val:
		print("%s doesn't have enough actions for %s." % [entity_name, action.entity_name])
		return
		
	action_economy.actions_remaining -= cost_val
	print("[%s spends %d action(s). %d remaining]" % [entity_name, cost_val, action_economy.actions_remaining])
	
	if action.execute(self, target):
		action_economy.attack_stacks += action.map_weight

func execute_subordinate_action(action: PFAction, target: PFActor = null) -> void:
	print("  > [Subordinate Action] %s performs %s" % [entity_name, action.entity_name])
	if action.execute(self, target):
		action_economy.attack_stacks += action.map_weight

func end_turn() -> void:
	print("\n--- %s ends their turn. ---" % entity_name)
	
	for c in conditions:
		if c.is_active: c.on_turn_end(self)
	conditions = conditions.filter(func(c): return c.is_active)

# ---------------------------------------------------------
# HEALTH & DAMAGE LOGIC
# ---------------------------------------------------------

func grant_temp_hp(amount: int) -> void:
	if amount > health.temp_hp:
		health.temp_hp = amount
		print("%s gains %d Temporary HP! (Total Temp HP: %d)" % [entity_name, amount, health.temp_hp])

func heal(amount: int, heal_type: PFCombatConstants.DamageType = PFCombatConstants.DamageType.UNTYPED) -> void:
	if has_trait(&"construct") and (heal_type == PFCombatConstants.DamageType.VITALITY or heal_type == PFCombatConstants.DamageType.VOID):
		print("    > %s is a Construct and ignores Vitality/Void healing." % entity_name)
		return
		
	var has_void_healing = has_trait(&"undead") or has_trait(&"void_healing")
	
	if heal_type == PFCombatConstants.DamageType.VITALITY and has_void_healing:
		print("    > %s is harmed by Vitality! Reversing heal to damage." % entity_name)
		take_damage(amount, PFCombatConstants.DamageType.VITALITY)
		return
	elif heal_type == PFCombatConstants.DamageType.VOID and not has_void_healing:
		print("    > %s is harmed by Void! Reversing heal to damage." % entity_name)
		take_damage(amount, PFCombatConstants.DamageType.VOID)
		return

	health.current_hp += amount
	health.current_hp = mini(health.max_hp, health.current_hp) 
	print("%s heals %d! HP: %d/%d" % [entity_name, amount, health.current_hp, health.max_hp])

func take_damage(amount: int, damage_type: PFCombatConstants.DamageType = PFCombatConstants.DamageType.UNTYPED, effect_traits: Array[StringName] = []) -> void:
	var type_name = PFDamage.get_type_name(damage_type)
	
	if has_trait(&"construct") and (damage_type == PFCombatConstants.DamageType.VITALITY or damage_type == PFCombatConstants.DamageType.VOID):
		print("    > %s is a Construct and ignores Vitality/Void effects." % entity_name)
		return

	if not has_spirit and damage_type == PFCombatConstants.DamageType.SPIRIT:
		print("    > %s lacks a spirit and is immune to Spirit damage." % entity_name)
		return

	var has_void_healing = has_trait(&"undead") or has_trait(&"void_healing")
	
	if damage_type == PFCombatConstants.DamageType.VITALITY and not has_void_healing:
		print("    > %s is a living creature and immune to Vitality damage." % entity_name)
		return
	elif damage_type == PFCombatConstants.DamageType.VOID and has_void_healing:
		print("    > %s absorbs the Void damage as healing!" % entity_name)
		heal(amount, PFCombatConstants.DamageType.VOID)
		return

	if health.immunities.has(damage_type):
		print("    > %s is IMMUNE to %s damage! They take 0 damage." % [entity_name, type_name])
		return

	var final_damage = amount

	var total_weakness_damage = 0
	if health.weaknesses.has(damage_type):
		total_weakness_damage += health.weaknesses[damage_type]
		print("    > Weakness to %s adds %d damage!" % [type_name, health.weaknesses[damage_type]])
	
	for t in effect_traits:
		if health.trait_weaknesses.has(t):
			total_weakness_damage += health.trait_weaknesses[t]
			print("    > Weakness to '%s' adds %d damage!" % [t, health.trait_weaknesses[t]])
			
	if total_weakness_damage > 0:
		final_damage += total_weakness_damage
		print("    > Total Weakness Bonus Applied: +%d damage!" % total_weakness_damage)

	var highest_resistance = 0
	if health.resistances.has(damage_type):
		highest_resistance = health.resistances[damage_type]
		
	for t in effect_traits:
		if health.trait_resistances.has(t):
			highest_resistance = maxi(highest_resistance, health.trait_resistances[t])
			
	if highest_resistance > 0:
		final_damage -= highest_resistance
		print("    > RESISTANCE triggered! Reduces damage by %d!" % highest_resistance)

	final_damage = maxi(0, final_damage)
	
	if final_damage == 0:
		print("    > The attack deals no damage to %s." % entity_name)
		return

	var shield = get_wielded_shield()
	if shield and shield.can_block(damage_type) and has_raised_shield and action_economy.reactions_remaining > 0 and not shield.is_destroyed():
		action_economy.reactions_remaining -= 1
		var damage_through_shield = maxi(0, final_damage - shield.hardness)
		shield.take_item_damage(final_damage)
		final_damage = damage_through_shield
		
		if final_damage == 0:
			print("    > The Shield completely absorbed the impact!")
			return

	if health.temp_hp > 0:
		if health.temp_hp >= final_damage:
			health.temp_hp -= final_damage
			print("%s's Temp HP absorbs %d damage! (Temp HP left: %d)" % [entity_name, final_damage, health.temp_hp])
			final_damage = 0
		else:
			print("%s's Temp HP absorbs %d damage, but the shield shatters!" % [entity_name, health.temp_hp])
			final_damage -= health.temp_hp
			health.temp_hp = 0
			
	if final_damage > 0:
		health.current_hp -= final_damage
		health.current_hp = maxi(0, health.current_hp) 
		print(">> %s takes %d final %s damage! HP: %d/%d\n" % [entity_name, final_damage, type_name, health.current_hp, health.max_hp])

func get_spell_dc() -> int:
	return 10

func get_spell_attack() -> int:
	return 0
