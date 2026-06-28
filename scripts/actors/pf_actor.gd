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
var immunities: Dictionary = {}
var has_raised_shield: bool = false
var is_dead: bool = false
var minions: Array[PFActor] = []

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
	var time_manager = PFTimeManager.get_instance()
	if time_manager:
		time_manager.rested_for_night.connect(_on_rested_for_night)
		time_manager.long_term_rested.connect(_on_long_term_rested)
		
	# Every actor gets Grab an Edge inherently
	PFReactionGrabEdge.register(self)

func _on_rested_for_night() -> void:
	var prep_manager = PFDailyPrepManager.get_instance()
	if prep_manager:
		prep_manager.rest_actor(self, false)

func _on_long_term_rested() -> void:
	var prep_manager = PFDailyPrepManager.get_instance()
	if prep_manager:
		prep_manager.rest_actor(self, true)

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

func expose_to_affliction(affliction_id: StringName) -> void:
	# Default affliction logic
	var affliction = PFCondition.create(affliction_id)
	if affliction is PFConditionAffliction:
		# Afflictions immediately prompt a save upon exposure (onset delay excluded for now)
		print("    > %s is exposed to %s! Attempting %s save (DC %d)..." % [entity_name, affliction.condition_name, affliction.save_stat, affliction.save_dc])
		var save_mod = get_save_bonus(affliction.save_stat)
		
		var roll = randi() % 20 + 1
		var total = roll + save_mod
		
		var degree = PFMathConstants.DegreeOfSuccess.FAIL
		if total >= affliction.save_dc + 10 or roll == 20: degree = PFMathConstants.DegreeOfSuccess.CRIT_SUCCESS
		elif total >= affliction.save_dc: degree = PFMathConstants.DegreeOfSuccess.SUCCESS
		elif total <= affliction.save_dc - 10 or roll == 1: degree = PFMathConstants.DegreeOfSuccess.CRIT_FAIL
		
		if roll == 20 and degree < PFMathConstants.DegreeOfSuccess.CRIT_SUCCESS: degree = (degree + 1) as PFMathConstants.DegreeOfSuccess
		elif roll == 1 and degree > PFMathConstants.DegreeOfSuccess.CRIT_FAIL: degree = (degree - 1) as PFMathConstants.DegreeOfSuccess
		
		if degree <= PFMathConstants.DegreeOfSuccess.FAIL:
			var stage = 1 if degree == PFMathConstants.DegreeOfSuccess.FAIL else 2
			print("    > [FAILED] %s contracts %s at Stage %d!" % [entity_name, affliction.condition_name, stage])
			affliction.current_stage = stage
			apply_condition(affliction)
		else:
			print("    > [SUCCESS] %s resists %s!" % [entity_name, affliction.condition_name])
	else:
		push_error("expose_to_affliction called with non-affliction ID: " + str(affliction_id))

func apply_condition(new_condition: PFCondition) -> void:
	var mgr = PFConditionManager.get_instance()
	if mgr: mgr.apply_condition(self, new_condition)

func add_immunity(immunity_id: StringName, duration_turns: int = -1) -> void:
	immunities[immunity_id] = duration_turns

func has_immunity(immunity_id: StringName) -> bool:
	return immunities.has(immunity_id)

func remove_condition(condition_id: String) -> void:
	var mgr = PFConditionManager.get_instance()
	if mgr: mgr.remove_condition(self, condition_id)

func reduce_condition(condition_id: String, amount: int = 1) -> void:
	var mgr = PFConditionManager.get_instance()
	if mgr: mgr.reduce_condition(self, condition_id, amount)
			
func has_condition(condition_id: String) -> bool:
	var mgr = PFConditionManager.get_instance()
	if mgr: return mgr.has_condition(self, condition_id)
	return false

func get_condition(condition_id: String) -> PFCondition:
	var mgr = PFConditionManager.get_instance()
	if mgr: return mgr.get_condition(self, condition_id)
	return null

func get_condition_modifier(context: StringName) -> int:
	var mgr = PFConditionManager.get_instance()
	if mgr: return mgr.get_condition_modifier(self, context)
	return 0

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

func get_save_bonus(_save_type: StringName) -> int:
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
	var cost_val = 0
	match action.cost:
		PFCombatConstants.ActionCost.ONE_ACTION: cost_val = 1
		PFCombatConstants.ActionCost.TWO_ACTIONS: cost_val = 2
		PFCombatConstants.ActionCost.THREE_ACTIONS: cost_val = 3
		
	if action.cost == PFCombatConstants.ActionCost.REACTION:
		if action_economy.reactions_remaining < 1:
			print("%s doesn't have enough reactions for %s." % [entity_name, action.entity_name])
			return
		action_economy.reactions_remaining -= 1
		print("[%s spends 1 reaction.]" % entity_name)
	else:
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
	
	if has_trait(&"minion"):
		action_economy.actions_remaining = 0
		action_economy.reactions_remaining = 0

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

func take_damage(amount: int, damage_type: PFCombatConstants.DamageType = PFCombatConstants.DamageType.UNTYPED, effect_traits: Array[StringName] = [], _source_actor: PFActor = null, _target_position: Vector3 = Vector3.INF) -> void:
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

