extends GdUnitTestSuite

var attacker: PFActor
var defender: PFActor
var trip_weapon: PFWeapon

func before_test():
	attacker = PFPlayerCharacter.new("Attacker", [&"humanoid"], 1, 20)
	defender = PFPlayerCharacter.new("Defender", [&"humanoid"], 1, 20)
	auto_free(attacker)
	auto_free(defender)
	add_child(attacker)
	add_child(defender)
	
	trip_weapon = PFWeapon.new("Whip", [&"trip", &"reach", &"finesse", &"nonlethal"], 1, 0.1, PFEquipmentConstants.WeaponType.MELEE, PFEquipmentConstants.WeaponCategory.MARTIAL, PFEquipmentConstants.WeaponGroup.FLAIL, 1, 4, PFCombatConstants.DamageType.SLASHING)
	auto_free(trip_weapon)
	
	attacker.global_position = Vector3(0, 0, 0)
	defender.global_position = Vector3(0, 0, 0)

func test_grapple():
	var grapple_action = PFActionManeuver.new(PFActionManeuver.ManeuverType.GRAPPLE)
	auto_free(grapple_action)
	var success = grapple_action.execute(attacker, defender)
	assert_bool(success).is_true()
	
func test_trip_with_weapon():
	var trip_action = PFActionManeuver.new(PFActionManeuver.ManeuverType.TRIP, trip_weapon)
	auto_free(trip_action)
	
	# Whip has reach 10ft, so from 10ft away it should work
	defender.global_position = Vector3(10, 0, 0)
	var success = trip_action.execute(attacker, defender)
	assert_bool(success).is_true()

func test_shove():
	var shove_action = PFActionManeuver.new(PFActionManeuver.ManeuverType.SHOVE)
	auto_free(shove_action)
	var success = shove_action.execute(attacker, defender)
	assert_bool(success).is_true()
