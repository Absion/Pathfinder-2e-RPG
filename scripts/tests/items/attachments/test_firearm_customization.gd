extends "res://addons/gut/test.gd"

func test_firearm_customization():
	var firearm = PFWeapon.new("Musket", [], 1, 0, PFEquipmentConstants.WeaponType.RANGED, PFEquipmentConstants.WeaponCategory.MARTIAL, PFEquipmentConstants.WeaponGroup.FIREARM)
	firearm.range_increment = 60
	
	var scope = PFFirearmCustomization.new("Scope", PFFirearmCustomization.CustomizationType.SCOPE, 20)
	scope.attach_to(firearm)
	
	assert_eq(firearm.range_increment, 80, "Scope should increase range increment by 20")
