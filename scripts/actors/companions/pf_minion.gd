# pf_minion.gd
# Base class for minions such as familiars and animal companions. Minions have a master and unique action economy rules.
## A creature that only acts when commanded by its master.
class_name PFMinion
extends PFNpc

# --- COMPONENTS ---
var master: PFActor

# --- INITIALIZATION ---
func _init(p_name: String, p_master: PFActor, p_traits: Array[StringName] = [], p_level: int = 1,
		p_hp: int = 1, p_fort: int = 0, p_ref: int = 0, p_will: int = 0,
		p_str: int = 0, p_dex: int = 0, p_con: int = 0, p_int: int = 0, p_wis: int = 0, p_cha: int = 0,
		p_speed_land: int = 25, p_speed_fly: int = 0, p_speed_swim: int = 0,
		p_speed_climb: int = 0, p_speed_burrow: int = 0):
	
	# Add the minion trait if it's not already there
	if not p_traits.has(&"minion"):
		p_traits.append(&"minion")
		
	super._init(p_name, p_traits, p_level, p_hp, p_fort, p_ref, p_will, p_str, p_dex, p_con, p_int, p_wis, p_cha, p_speed_land, p_speed_fly, p_speed_swim, p_speed_climb, p_speed_burrow)
	master = p_master
	action_economy.actions_remaining = 0 # Minions do not get actions by default unless commanded
	
# --- ACTION ECONOMY ---
func receive_command() -> void:
	if action_economy.actions_remaining == 0:
		action_economy.actions_remaining = 2
		print("    > %s receives a command and gains 2 actions!" % entity_name)
	else:
		print("    > %s was already commanded this turn." % entity_name)

# Helper function to intercept the start of a turn if a turn manager tries to reset actions to 3
func start_turn() -> void:
	# Usually PFActor might reset actions_remaining to 3 here
	# But minions stay at 0 until commanded
	action_economy.actions_remaining = 0
	action_economy.reactions_remaining = 1
