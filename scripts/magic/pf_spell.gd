# pf_spell.gd
## Represents a magical spell that can be cast by an actor.
class_name PFSpell
extends PFEntity

var base_spell_rank: int
var cast_time: String # 1, 2, 3, reaction, free
var range_ft: int
var targets: String
var saving_throw: String
var duration: String
var is_cantrip: bool
var is_sustained: bool
var description: String
var script_path: String

# Basic Default Effect Properties
var damage_dice: int = 0
var die_faces: int = 4
var damage_type: PFCombatConstants.DamageType = PFCombatConstants.DamageType.UNTYPED
var scaling_rules: int = 0
var scaling_dice: int = 0

func _init(p_id: StringName):
	var db = PFDatabase.get_instance()
	var s_data = db.get_spell_data(p_id)
	
	if s_data.is_empty():
		entity_name = "Unknown Spell"
		return
		
	var spell_traits: Array[StringName] = []
	if s_data["traits"] and s_data["traits"] != "":
		var parsed = s_data["traits"].split(",", false)
		if parsed:
			for t in parsed: spell_traits.append(StringName(t.strip_edges()))
			
	entity_name = str(s_data["name"])
	traits = spell_traits
	rarity = PFBiographyConstants.Rarity.COMMON
	
	base_spell_rank = s_data.get(&"base_spell_rank", 1)
	cast_time = str(s_data.get(&"cast_time", "2"))
	range_ft = s_data.get(&"range_ft", 0)
	targets = str(s_data.get(&"targets", ""))
	saving_throw = str(s_data.get(&"saving_throw", ""))
	duration = str(s_data.get(&"duration", ""))
	is_cantrip = int(s_data.get(&"is_cantrip", 0)) == 1
	
	if duration != null and duration.to_lower().contains("sustained"):
		is_sustained = true
	else:
		is_sustained = false
		
	description = str(s_data.get(&"description", ""))
	
	scaling_rules = int(s_data.get(&"scaling_rules", 0))
	scaling_dice = int(s_data.get(&"scaling_dice", 0))
	script_path = str(s_data.get(&"script_path", ""))

static func create(p_id: StringName) -> PFSpell:
	var db = PFDatabase.get_instance()
	var s_data = db.get_spell_data(p_id)
	
	if s_data.has(&"script_path") and s_data["script_path"] != "":
		var custom_script = load(s_data["script_path"])
		if custom_script:
			return custom_script.new(p_id)
			
	return PFSpell.new(p_id)

func requires_attack_roll() -> bool:
	return has_trait(&"attack")

func get_saving_throw() -> StringName:
	if saving_throw == "":
		return &""
	return StringName(saving_throw.to_lower())

## Called when the spell is successfully sustained. Subclasses can override this.
func on_sustain(caster: PFActor, ___target: PFActor = null) -> void:
	print("    > %s sustains %s!" % [caster.entity_name, entity_name])

## Default effect resolution for spells.
## Can be overridden by custom spell scripts attached to complex spells.
func resolve_effect(_caster: PFActor, target: PFActor, degree: PFDice.Degree, rank: int) -> void:
	if damage_dice <= 0:
		return # No basic damage to deal
		
	var final_damage_dice = damage_dice
	if scaling_rules > 0 and rank > base_spell_rank:
		var rank_difference = rank - base_spell_rank
		var increments = floor(rank_difference / float(scaling_rules))
		final_damage_dice += (increments * scaling_dice)
		
	# Standard spell damage scaling based on degree of success
	var multiplier = 1.0
	
	if get_saving_throw() != &"":
		# Save spell
		match degree:
			PFDice.Degree.CRIT_SUCCESS:
				multiplier = 0.0 # No damage on crit save
			PFDice.Degree.SUCCESS:
				multiplier = 0.5 # Half damage on success save
			PFDice.Degree.FAIL:
				multiplier = 1.0 # Full damage on fail save
			PFDice.Degree.CRIT_FAIL:
				multiplier = 2.0 # Double damage on crit fail save
	else:
		# Attack spell (or automatic)
		match degree:
			PFDice.Degree.CRIT_SUCCESS:
				multiplier = 2.0 # Double damage on crit hit
			PFDice.Degree.SUCCESS:
				multiplier = 1.0 # Full damage on hit
			PFDice.Degree.FAIL, PFDice.Degree.CRIT_FAIL:
				multiplier = 0.0 # No damage on miss
				
	if multiplier > 0:
		var total_damage = 0
		for i in range(final_damage_dice):
			total_damage += PFDice.roll(1, die_faces).total
			
		total_damage = floor(total_damage * multiplier)
		print("    > %s deals %d %s damage to %s (Multiplier: %s)" % [entity_name, total_damage, PFCombatConstants.DamageType.keys()[damage_type], target.entity_name, multiplier])
		target.take_damage(total_damage, damage_type)
