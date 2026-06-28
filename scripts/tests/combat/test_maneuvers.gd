extends GutTest

var attacker: PFActor
var defender: PFActor
var trip_weapon: PFWeapon

func before_each():
	PFContext.init_shared_services()
	attacker = autofree(PFPlayerCharacter.new("Attacker", [&"humanoid"], 1, 20, 0, 0, 0))
	defender = autofree(PFPlayerCharacter.new("Defender", [&"humanoid"], 1, 20, 0, 0, 0))
	add_child_autofree(attacker)
	add_child_autofree(defender)
	
	trip_weapon = PFWeapon.new("Whip", [&"trip", &"reach", &"finesse", &"nonlethal"], 1, 0.1, PFEquipmentConstants.WeaponType.MELEE, PFEquipmentConstants.WeaponCategory.MARTIAL, PFEquipmentConstants.WeaponGroup.FLAIL, 1, 4, PFCombatConstants.DamageType.SLASHING)
	
	attacker.global_position = Vector3(0, 0, 0)
	defender.global_position = Vector3(0, 0, 0)

func test_grapple():
	var grapple_action = PFActionManeuver.new(PFActionManeuver.ManeuverType.GRAPPLE)
	var success = grapple_action.execute(attacker, defender)
	assert_true(success)
	
func test_trip_with_weapon():
	var trip_action = PFActionManeuver.new(PFActionManeuver.ManeuverType.TRIP, trip_weapon)
	
	# Whip has reach 10ft, so from 10ft away it should work
	defender.global_position = Vector3(10, 0, 0)
	var success = trip_action.execute(attacker, defender)
	assert_true(success)

func test_shove():
	var shove_action = PFActionManeuver.new(PFActionManeuver.ManeuverType.SHOVE)
	var success = shove_action.execute(attacker, defender)
	assert_true(success)

func after_each():
	PFContext.cleanup_shared_services()
