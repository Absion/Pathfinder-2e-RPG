# pf_actor.gd
# Represents any living, undead, or construct entity in the game: Players, NPCs, and Monsters.
## The core base class for any targetable and interactive entity in the game world.
#
class_name PFActor
extends Node3D


# --- CORE ENTITY DATA (Composition) ---
var core: PFEntity

var entity_name: String:
	get: return core.entity_name if core else ""
	set(val): if core: core.entity_name = val

var traits: Array[StringName]:
	get: return core.traits if core else []
	set(val): if core: core.traits = val

var rarity: PFBiographyConstants.Rarity:
	get: return core.rarity if core else PFBiographyConstants.Rarity.COMMON
	set(val): if core: core.rarity = val

var level: int = 1

# --- COMPONENTS ---
var health: PFHealthComponent
var action_economy: PFActionComponent

# --- ARCHITECTURE ---
var has_spirit: bool = true
var conditions: Array[PFCondition] = []
var has_raised_shield: bool = false
var is_dead: bool = false

# --- PASSIVES & FLAGS ---
var has_armor_specialization: bool = false
var passive_features: Array[StringName] = []

func _init(p_name: String, p_traits: Array[StringName], p_level: int, p_hp: int):
	
	core = PFEntity.new(p_name, p_traits)
	level = p_level
	
	# Component Initialization
	health = PFHealthComponent.new()
	health.initialize(p_hp)
	add_child(health)
	
	action_economy = PFActionComponent.new()
	add_child(action_economy)

func _ready() -> void:
	var tm = PFTimeManager.get_instance()
	if tm:
		tm.rested_for_night.connect(_on_rested_for_night)
		
	# Every actor gets Grab an Edge inherently
	PFReactionGrabEdge.register(self)

func _on_rested_for_night() -> void:
	# Base Healing: CON mod * Level (minimum 1)
	var con_mod = get_ability_modifier(&"CON")
	var amount_to_heal = maxi(1, con_mod) * level
	heal(amount_to_heal)
	print("    > %s recovers %d HP after a full night's rest." % [entity_name, amount_to_heal])
	
	# Condition reductions on rest
	if has_condition("doomed"): reduce_condition("doomed", 1)
	if has_condition("drained"): reduce_condition("drained", 1)
	if has_condition("fatigued"): remove_condition("fatigued")
	
	if "spellbook" in self and self.get(&"spellbook") != null:
		self.get(&"spellbook").restore_daily_slots()
		print("    > %s recovers all daily spell slots." % entity_name)
		
	# Sleeping in Armor Rule (Pathfinder 2e Remaster)
	var armor = get_worn_armor()
	if armor != null:
		var category = armor.category
		var is_medium_or_heavy = category == PFEquipmentConstants.ArmorCategory.MEDIUM or category == PFEquipmentConstants.ArmorCategory.HEAVY
		if is_medium_or_heavy and not armor.has_trait(&"comfort"):
			print("    > %s slept in uncomfortable %s armor!" % [entity_name, armor.entity_name])
			apply_condition(PFCondition.create("fatigued", 1))

func grant_reaction(reaction_class_name: String) -> void:
	# In a real system, we might look this up via a factory or load it
	# Since it's hardcoded classes for now, we just match on name
	match reaction_class_name:
		"Reactive Strike":
			var cond = Callable(PFReactionReactiveStrike, "condition").bind(self)
			var exec = Callable(PFReactionReactiveStrike, "execute").bind(self)
			PFContext.reaction_manager.register_listener(PFCombatConstants.ReactionTriggers.ON_LEAVE_SQUARE, self, &"Reactive Strike", cond, exec)
			PFContext.reaction_manager.register_listener(PFCombatConstants.ReactionTriggers.ON_MANIPULATE, self, &"Reactive Strike", cond, exec)
			PFContext.reaction_manager.register_listener(PFCombatConstants.ReactionTriggers.ON_RANGED_ATTACK, self, &"Reactive Strike", cond, exec)
		"Shield Block":
			var cond = Callable(PFReactionShieldBlock, "condition").bind(self)
			var exec = Callable(PFReactionShieldBlock, "execute").bind(self)
			PFContext.reaction_manager.register_listener(PFCombatConstants.ReactionTriggers.BEFORE_TAKE_DAMAGE, self, &"Shield Block", cond, exec)

func remove_reaction(reaction_id: StringName) -> void:
	if PFContext.reaction_manager:
		PFContext.reaction_manager.unregister_listener(self, reaction_id)

# --- PASSIVES & CAPABILITIES ---

func has_passive_feature(feature_id: StringName) -> bool:
	return passive_features.has(feature_id)

func can_be_flanked_by(attacker: PFActor) -> bool:
	# Rogue's Deny Advantage rule
	if has_passive_feature(&"deny_advantage"):
		if attacker.level <= self.level:
			return false
	return true

# ---------------------------------------------------------
# ---------------------------------------------------------
# ACTIVE CONDITIONS ENGINE
# ---------------------------------------------------------

func apply_condition(new_condition: PFCondition) -> void:
	# Check if condition already exists
	for c in conditions:
		if c.condition_id == new_condition.condition_id:
			# Condition exists. Max stacking rule.
			if new_condition.value > c.value:
				c.value = new_condition.value
				print("%s %s worsened to %d!" % [entity_name, c.condition_name, c.value])
			else:
				print("%s is already %s %d or higher." % [entity_name, c.condition_name, c.value])
			return
			
	if not new_condition.on_apply(self):
		return

	# We now append all conditions instead of overriding. 
	# get_condition_modifier will calculate the strongest ones.
	conditions.append(new_condition)
	print("%s is now %s %d!" % [entity_name, new_condition.condition_name, new_condition.value])

func remove_condition(condition_id: String) -> void:
	for i in range(conditions.size() - 1, -1, -1):
		if str(conditions[i].condition_id) == condition_id:
			var removed_condition = conditions[i]
			conditions.remove_at(i)
			removed_condition.on_remove(self)
			print("%s is no longer %s!" % [entity_name, removed_condition.condition_name])
			return

func reduce_condition(condition_id: String, amount: int = 1) -> void:
	for i in range(conditions.size() - 1, -1, -1):
		if str(conditions[i].condition_id) == condition_id:
			conditions[i].value -= amount
			if conditions[i].value <= 0:
				remove_condition(condition_id)
			else:
				print("%s's %s reduced to %d." % [entity_name, conditions[i].condition_name, conditions[i].value])
			return
			
func has_condition(condition_id: String) -> bool:
	for c in conditions:
		if str(c.condition_id) == condition_id:
			return true
	return false

func get_condition(condition_id: String) -> PFCondition:
	for c in conditions:
		if str(c.condition_id) == condition_id:
			return c
	return null


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
		if db_inst:
			var size_data = db_inst.get_size_data(self.get(&"size_id"))
			var eff_size = size_data.get(&"effective_size", 1) if size_data else 1
			if eff_size == 0: base_bulk = 30
			elif eff_size == 2: base_bulk = 120
			elif eff_size >= 3: base_bulk = 240
			
	var inventory_bulk = 0
	if "inventory" in self and self.get(&"inventory") != null:
		inventory_bulk = self.get(&"inventory").get_total_bulk()
		
	return base_bulk + inventory_bulk

func get_worn_armor() -> PFArmor:
	if "inventory" in self and self.get(&"inventory") != null:
		var armors = self.get(&"inventory").worn_items.filter(func(i): return i is PFArmor)
		if armors.size() > 0:
			return armors[0]
	return null

# ---------------------------------------------------------
# THE UNIFIED MATH DELEGATES (VIRTUAL)
# These methods return 0 or null as placeholders to utilize
# Polymorphism. Subclasses (PFPlayerCharacter, PFNpc) must 
# override these to provide their specific math implementations.
# ---------------------------------------------------------

func get_ac() -> int:
	return 10 + get_condition_modifier(&"ac")

func get_strike_bonus(_weapon: PFWeapon) -> int:
	return get_condition_modifier(&"attack")

func get_wielded_shield() -> PFShield:
	# Virtual function for polymorphism
	return null

func get_strike_damage_bonus(_weapon: PFWeapon) -> int:
	# Virtual function for polymorphism
	return 0

func get_skill_bonus(_skill: StringName) -> int:
	# Virtual function for polymorphism
	return 0

func get_skill_rank(_skill: StringName) -> int:
	# Virtual function. Defaults to UNTRAINED for NPCs unless overridden.
	return PFMathConstants.ProficiencyRank.UNTRAINED

func get_ability_modifier(_ability: StringName) -> int:
	# Virtual function for polymorphism
	return 0

func has_trait(trait_name: StringName) -> bool:
	return core.has_trait(trait_name) if core else false

func get_speed_land() -> int:
	# Virtual function for polymorphism
	return 0

func has_critical_specialization(_weapon_group: PFEquipmentConstants.WeaponGroup) -> bool:
	# Virtual function for polymorphism. Returns false by default.
	# Subclasses like PFPlayerCharacter will override this based on class features.
	return false

# ---------------------------------------------------------
# ACTION ECONOMY & TURN HOOKS
# ---------------------------------------------------------

func start_turn() -> void:
	action_economy.start_turn()
	print("\n--- %s starts their turn! (%d Actions) ---" % [entity_name, action_economy.actions_remaining])
	
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
	
	if await action.execute(self, target):
		action_economy.attack_stacks += action.map_weight

func execute_subordinate_action(action: PFAction, target: PFActor = null) -> void:
	print("  > [Subordinate Action] %s performs %s" % [entity_name, action.entity_name])
	if await action.execute(self, target):
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
			
	# Armor Specialization Processing
	if has_armor_specialization:
		var armor = get_worn_armor()
		if armor and armor.category in [PFEquipmentConstants.ArmorCategory.MEDIUM, PFEquipmentConstants.ArmorCategory.HEAVY]:
			var spec_base = 1 if armor.category == PFEquipmentConstants.ArmorCategory.MEDIUM else 2
			var spec_resist = spec_base + armor.potency_bonus
			var spec_crit = (4 if armor.category == PFEquipmentConstants.ArmorCategory.MEDIUM else 6) + armor.potency_bonus
			
			if armor.group == PFEquipmentConstants.ArmorGroup.LEATHER and damage_type == PFCombatConstants.DamageType.BLUDGEONING:
				highest_resistance = maxi(highest_resistance, spec_resist)
				print("    > Leather Armor Specialization grants %d resistance!" % spec_resist)
			elif armor.group == PFEquipmentConstants.ArmorGroup.COMPOSITE and damage_type == PFCombatConstants.DamageType.PIERCING:
				highest_resistance = maxi(highest_resistance, spec_resist)
				print("    > Composite Armor Specialization grants %d resistance!" % spec_resist)
			elif armor.group == PFEquipmentConstants.ArmorGroup.PLATE and damage_type == PFCombatConstants.DamageType.SLASHING:
				highest_resistance = maxi(highest_resistance, spec_resist)
				print("    > Plate Armor Specialization grants %d resistance!" % spec_resist)
			elif armor.group == PFEquipmentConstants.ArmorGroup.CHAIN and effect_traits.has(&"critical"):
				highest_resistance = maxi(highest_resistance, spec_crit)
				print("    > Chain Armor Specialization grants %d resistance against Critical Hits!" % spec_crit)
			
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
